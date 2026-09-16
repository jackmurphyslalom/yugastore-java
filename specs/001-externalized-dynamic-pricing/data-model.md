# Phase 1 — Data Model: Externalized Dynamic Pricing

Feature: [001-externalized-dynamic-pricing](spec.md) | Plan: [plan.md](plan.md) | Research: [research.md](research.md)

Business definitions live in [spec.md § Key Entities](spec.md#key-entities-include-if-feature-involves-data). This document translates those entities into concrete columns, invariants, and the effective-price precedence rules Phase 2 needs to implement.

The DDL is authoritative in [contracts/ycql-schema.md](contracts/ycql-schema.md); this document is the human-readable narrative of the same tables plus the entity-level invariants and state transitions.

## Entities

### 1. Price Rule (`cronos.price_rules`)

A merchandiser-authored statement that, for a given scope during a given window, the effective price is a specific value.

| Field                 | Type              | Required | Notes                                                                                                                                                    |
|-----------------------|-------------------|----------|----------------------------------------------------------------------------------------------------------------------------------------------------------|
| `rule_id`             | uuid              | yes      | Partition key. Server-generated.                                                                                                                          |
| `scope_kind`          | text              | yes      | `ASIN` \| `CATEGORY`. Discriminates `scope_value` interpretation.                                                                                          |
| `scope_value`         | text              | yes      | The ASIN string when `scope_kind = ASIN`, or the category identifier when `scope_kind = CATEGORY`.                                                          |
| `rule_kind`           | text              | yes      | `LIST_PRICE_OVERRIDE` \| `PROMOTION`. Distinguishes open-ended base-price changes from time-bound discounts.                                              |
| `unit_price`          | decimal           | yes      | The effective unit price this rule sets. Must be > 0. Currency is the storefront's single currency (see [spec.md § Edge Cases](spec.md#edge-cases)).       |
| `starts_at`           | timestamp         | when `rule_kind = PROMOTION` | Inclusive start. `NULL` for `LIST_PRICE_OVERRIDE`.                                                                        |
| `ends_at`             | timestamp         | when `rule_kind = PROMOTION` | Exclusive end. `NULL` for `LIST_PRICE_OVERRIDE`. Must be strictly after `starts_at`.                                       |
| `priority`            | int               | yes      | Non-negative. Higher wins on overlap. See [precedence](#effective-price-precedence).                                                                        |
| `created_at`          | timestamp         | yes      | Server-set at insert.                                                                                                                                     |
| `created_by`          | text              | yes      | The `X-Merchandiser-Id` header value that authored this rule (see [research.md R-5](research.md#r-5-merchandiser-admin-surface--auth-fr-015-resolution)). |
| `updated_at`          | timestamp         | yes      | Server-set on each mutation.                                                                                                                              |
| `updated_by`          | text              | yes      | The `X-Merchandiser-Id` header value that last mutated this rule.                                                                                          |
| `active`              | boolean           | yes      | Set to `false` on delete (soft delete). See [state transitions](#state-transitions).                                                                       |

Secondary index / lookup patterns supported:

- **By ASIN** — every rule where either (`scope_kind = ASIN` AND `scope_value = <asin>`) OR (`scope_kind = CATEGORY` AND `scope_value = <asin's category>`) with `active = true`. Implementation: two point-read queries (ASIN-scoped rules keyed by scope_value; category-scoped rules keyed by scope_value = category-id), unioned in memory.
- **By category** — every rule where `scope_kind = CATEGORY` AND `scope_value = <category>` AND `active = true`. Used by Story 5.

#### Invariants

- **I-PR-1**: `unit_price > 0`.
- **I-PR-2**: If `rule_kind = PROMOTION`, both `starts_at` and `ends_at` are non-null and `ends_at > starts_at`.
- **I-PR-3**: If `rule_kind = LIST_PRICE_OVERRIDE`, both `starts_at` and `ends_at` are null (open-ended).
- **I-PR-4**: `scope_value` matches the discriminator in `scope_kind` (an ASIN string vs. a category id).
- **I-PR-5**: A rule row is never physically deleted. `active = false` denotes a retracted rule; the row remains for audit joins (Story 5). See [state transitions](#state-transitions).
- **I-PR-6**: `priority >= 0`.

#### State transitions

```
        create                update                 retract (delete)
[none] ────────▶ ACTIVE ─────────────▶ ACTIVE (with new fields) ─────────▶ RETRACTED
                    │                                                       ▲
                    └──────────────── expire (window end)  ─────────────────┘
                                       (PROMOTION only, at ends_at)
```

- **ACTIVE**: `active = true`, current time is within `[starts_at, ends_at)` if promotion, or unconditionally if `LIST_PRICE_OVERRIDE`. Contributes to effective-price resolution.
- **RETRACTED**: `active = false`. Does not contribute to resolution. Still visible in Story 5's history query.
- **Expired**: not a stored state — a `PROMOTION` past `ends_at` is naturally excluded from active resolution by the time-window filter. History still shows it fired.

Every ACTIVE ↔ RETRACTED transition, and every field update, MUST also append a row to `cronos.price_rule_history` (see below). The transition itself is idempotent: retracting an already-retracted rule is a no-op that returns `409 Conflict`.

---

### 2. Price Rule History Entry (`cronos.price_rule_history`)

Append-only audit log of every merchandiser-initiated change (Story 5, FR-008).

| Field                  | Type      | Required | Notes                                                                                                     |
|------------------------|-----------|----------|-----------------------------------------------------------------------------------------------------------|
| `rule_id`              | uuid      | yes      | Partition key. Same as the rule the entry describes.                                                       |
| `event_at`             | timestamp | yes      | Clustering key, DESC. The moment the change was committed.                                                 |
| `event_kind`           | text      | yes      | `CREATED` \| `UPDATED` \| `RETRACTED`.                                                                     |
| `actor`                | text      | yes      | The `X-Merchandiser-Id` at the moment of the change.                                                       |
| `scope_kind`           | text      | yes      | Snapshot of the rule's scope at this event.                                                                |
| `scope_value`          | text      | yes      | Snapshot.                                                                                                  |
| `rule_kind`            | text      | yes      | Snapshot.                                                                                                  |
| `unit_price_before`    | decimal   | when `event_kind ∈ {UPDATED, RETRACTED}` | Null on `CREATED`.                                                    |
| `unit_price_after`     | decimal   | when `event_kind ∈ {CREATED, UPDATED}`   | Null on `RETRACTED`.                                                  |
| `starts_at_before`     | timestamp | optional | Only populated when the window changed.                                                                    |
| `starts_at_after`      | timestamp | optional | Only populated when the window changed.                                                                    |
| `ends_at_before`       | timestamp | optional | Only populated when the window changed.                                                                    |
| `ends_at_after`        | timestamp | optional | Only populated when the window changed.                                                                    |
| `priority_before`      | int       | optional | Only populated when priority changed.                                                                      |
| `priority_after`       | int       | optional | Only populated when priority changed.                                                                      |

#### Invariants

- **I-HIST-1**: History rows are **append-only**. `PriceRuleHistoryRepository` MUST NOT expose an update or delete API.
- **I-HIST-2**: Every state transition of a `price_rules` row produces exactly one `price_rule_history` row committed in the same request as the rule mutation. If the history write fails, the whole request MUST fail (see the write-side saga in [contracts/pricing-rest.openapi.yaml](contracts/pricing-rest.openapi.yaml) for the `500` semantics).
- **I-HIST-3**: `event_at` is server-set. Callers cannot backdate history.

---

### 3. Effective Price (transport-only, not persisted)

A DTO returned to shopper/reader clients. Never stored.

| Field              | Type       | Notes                                                                                                                    |
|--------------------|------------|--------------------------------------------------------------------------------------------------------------------------|
| `asin`             | text       | The product asked about.                                                                                                  |
| `unit_price`       | decimal    | The resolved effective price.                                                                                             |
| `source`           | text       | `RULE` \| `LIST_PRICE`. When `RULE`, the caller can inspect `source_rule_id`.                                              |
| `source_rule_id`   | uuid       | Set when `source = RULE`. The `price_rules.rule_id` that won.                                                              |
| `list_price`       | decimal    | Always populated. Enables clients to render "was $10, now $8" without a second call to the catalog.                        |
| `resolved_at`      | timestamp  | Server-set at read time.                                                                                                  |
| `serving_mode`     | text       | `SOURCE` \| `CACHE` \| `LIST_PRICE_FALLBACK`. Exposes R-7 degradation state to caller and to `/actuator/info` aggregators. |

Related invariants:

- **I-EP-1**: `unit_price > 0`.
- **I-EP-2**: When `source = LIST_PRICE`, `source_rule_id` is null and `unit_price = list_price`.
- **I-EP-3**: When `serving_mode = LIST_PRICE_FALLBACK`, `source = LIST_PRICE` and the caller should treat this as a degraded read (see R-7).

---

### 4. Order Line Price Snapshot (additive column on the existing order line)

**Additive**, not a new entity. Preserves Principle II (`cronos.orders` write path is untouched except for one new column).

| Field                      | Type      | Required | Notes                                                                                                                                                                        |
|----------------------------|-----------|----------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `unit_price_at_order`      | decimal   | yes      | The effective price at the instant of order placement. Immutable after commit (**FR-007**).                                                                                    |
| `pricing_source_at_order`  | text      | yes      | `RULE` \| `LIST_PRICE` \| `LIST_PRICE_FALLBACK`. Captures whether the checkout resolve saw a rule, saw only list price, or fell back because pricing was unavailable (R-7). |

- **I-OL-1**: Once committed, `unit_price_at_order` and `pricing_source_at_order` are read-only. Order-refund and order-history flows read but do not rewrite these values.
- **I-OL-2**: Existing order columns (product, quantity, order-total math) are unaffected. The new columns are additive; the transactional stock-check + inventory-decrement is untouched (Principle II, FR-009).

---

### 5. Merchandiser (actor, not a persisted entity in this iteration)

A merchandiser is identified by the value of the `X-Merchandiser-Id` request header, checked against an allow-list in `application.yml` (see [research.md R-5](research.md#r-5-merchandiser-admin-surface--auth-fr-015-resolution)).

- No `merchandisers` table is created in this iteration.
- The header value is stored verbatim in `price_rules.created_by` / `updated_by` and in `price_rule_history.actor`.
- When merchandiser SSO is scoped in a future iteration, this entity graduates to a persisted actor — the audit log stays intact because it stored the identifier by value.

---

## Effective-price precedence

The resolver applies the following rules against the active-rule set for a given ASIN at time `now`:

1. Start with `effective_price = list_price` from the catalog (`products-microservice.getProductDetails(asin).price`).
2. Filter the union of ASIN-scoped and category-scoped active rules for that ASIN to those "in window" at `now`:
   - `LIST_PRICE_OVERRIDE` rules are always in window if `active = true`.
   - `PROMOTION` rules are in window if `active = true` AND `starts_at <= now < ends_at`.
3. If the filtered set is empty → return `effective_price = list_price`, `source = LIST_PRICE`.
4. Otherwise sort by:
   1. **`priority` descending** (highest priority wins);
   2. **`scope_kind` = ASIN** beats `scope_kind` = CATEGORY on ties (an ASIN-specific rule always beats a category rule at equal priority);
   3. **`rule_kind` = PROMOTION** beats `LIST_PRICE_OVERRIDE` on ties (an active promotion always wins over an open-ended override when priority and scope tie);
   4. **`created_at` descending** as final tiebreak (last authored wins).
5. Pick the first rule. `effective_price = rule.unit_price`, `source = RULE`, `source_rule_id = rule.rule_id`.

Observability: `PriceRuleResolver` MUST log, at DEBUG, the winning rule id and the rank order of the top 3 candidates when more than one candidate exists. This satisfies FR-003 ("using a deterministic precedence order that is documented and observable").

## Validation rules (used by write endpoints)

- **V-1** (FR-006): `unit_price > 0`. Reject with `400 Bad Request` `{ code: "PRICE_NON_POSITIVE" }`.
- **V-2** (FR-006): For `PROMOTION`, `starts_at < ends_at` and `ends_at > server_now`. Reject stale promotions with `400 Bad Request` `{ code: "PROMOTION_WINDOW_INVALID" }`.
- **V-3** (FR-006): `scope_value` non-empty and, when `scope_kind = ASIN`, resolves to a real product (checked via `ProductCatalogRestClient.getProductDetails(asin)`; a 404 from the catalog is a `400 Bad Request` `{ code: "UNKNOWN_ASIN" }`). Category ids are not verified against a catalog list in this iteration (no category-list endpoint exists; a follow-up task can add one).
- **V-4** (FR-006): `priority >= 0`. Reject with `400 Bad Request` `{ code: "PRIORITY_NEGATIVE" }`.
- **V-5** (FR-015): `X-Merchandiser-Id` header present and in the allow-list. Absent → `401 Unauthorized`. Not in allow-list → `403 Forbidden`.

## Relationships

- `Price Rule 1..* ─▶ Price Rule History Entry` (one rule → many history entries; append-only)
- `Order Line 1..1 ─▶ Order Line Price Snapshot` (the snapshot is a pair of additive columns on the order line, not a separate row)
- `Product (catalog) 1..* ◀── Price Rule` (a rule references an ASIN or category id but does not enforce foreign-key-shaped integrity — Cassandra semantics; V-3 catches unknown ASINs at write time)
