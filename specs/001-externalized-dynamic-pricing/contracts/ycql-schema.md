# YCQL Schema Contract — Externalized Dynamic Pricing

Additive DDL for `pricing-microservice`. All statements land in [resources/schema.cql](../../../resources/schema.cql) at the end of the existing file. No existing statements are altered. `cronos.orders` and `cronos.product_inventory` are **not** touched here (Principle II).

The one additive change to the existing order-line write path — the `unit_price_at_order` + `pricing_source_at_order` columns — is captured under [§ Additive order-line columns](#additive-order-line-columns) below and is applied by `checkout-microservice`'s existing schema authorship (not by pricing-microservice, per single-service ownership).

## Keyspace

Reuse the existing keyspace declared at the top of [resources/schema.cql](../../../resources/schema.cql):

```cql
-- (already present, no change)
CREATE KEYSPACE IF NOT EXISTS cronos
  WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 1 };
```

## New tables

### `cronos.price_rules`

The merchandiser-authored rule set. Matches [data-model.md § Price Rule (`cronos.price_rules`)](../data-model.md#1-price-rule-cronosprice_rules).

```cql
CREATE TABLE IF NOT EXISTS cronos.price_rules (
  rule_id       uuid,
  scope_kind    text,           -- ASIN | CATEGORY
  scope_value   text,           -- ASIN string or category id
  rule_kind     text,           -- LIST_PRICE_OVERRIDE | PROMOTION
  unit_price    decimal,
  starts_at     timestamp,      -- null for LIST_PRICE_OVERRIDE
  ends_at       timestamp,      -- null for LIST_PRICE_OVERRIDE
  priority      int,
  created_at    timestamp,
  created_by    text,
  updated_at    timestamp,
  updated_by    text,
  active        boolean,
  PRIMARY KEY (rule_id)
) WITH transactions = { 'enabled' : 'false' };
```

Rule-set lookup by scope is served by a secondary lookup table (avoiding a global-secondary-index scan):

```cql
CREATE TABLE IF NOT EXISTS cronos.price_rules_by_scope (
  scope_kind    text,           -- ASIN | CATEGORY
  scope_value   text,
  rule_id       uuid,
  active        boolean,
  PRIMARY KEY ((scope_kind, scope_value), rule_id)
) WITH transactions = { 'enabled' : 'false' };
```

- `price_rules_by_scope` is written by `PriceRuleWriteService` in the same request as `price_rules`. On retract (soft delete), the `active` column is flipped to `false` in both tables.
- The resolver reads by `(scope_kind = 'ASIN', scope_value = <asin>)` and by `(scope_kind = 'CATEGORY', scope_value = <category>)`, then does the point read of each returned `rule_id` in `price_rules`.

### `cronos.price_rule_history`

Append-only audit log. Matches [data-model.md § Price Rule History Entry (`cronos.price_rule_history`)](../data-model.md#2-price-rule-history-entry-cronosprice_rule_history).

```cql
CREATE TABLE IF NOT EXISTS cronos.price_rule_history (
  rule_id             uuid,
  event_at            timestamp,
  event_kind          text,     -- CREATED | UPDATED | RETRACTED
  actor               text,
  scope_kind          text,
  scope_value         text,
  rule_kind           text,
  unit_price_before   decimal,
  unit_price_after    decimal,
  starts_at_before    timestamp,
  starts_at_after     timestamp,
  ends_at_before      timestamp,
  ends_at_after       timestamp,
  priority_before     int,
  priority_after      int,
  PRIMARY KEY ((rule_id), event_at)
) WITH CLUSTERING ORDER BY (event_at DESC)
  AND transactions = { 'enabled' : 'false' };
```

Because Story 5 asks for history "by ASIN and by category" (FR-008), a companion lookup:

```cql
CREATE TABLE IF NOT EXISTS cronos.price_rule_history_by_scope (
  scope_kind    text,
  scope_value   text,
  event_at      timestamp,
  rule_id       uuid,
  event_kind    text,
  actor         text,
  PRIMARY KEY ((scope_kind, scope_value), event_at, rule_id)
) WITH CLUSTERING ORDER BY (event_at DESC, rule_id ASC)
  AND transactions = { 'enabled' : 'false' };
```

`price_rule_history_by_scope` is written in the same request as `price_rule_history` — it stores only the header fields needed to render the audit list; the caller loads full diffs from `price_rule_history` when a specific row is expanded.

## Additive order-line columns

Applied by whoever currently owns the order-line table under `cronos.orders` (verified in `/speckit.tasks` — the actual schema authorship for orders is in `checkout-microservice` per its `YugabyteYCQLConfig` `SchemaAction.CREATE_IF_NOT_EXISTS` behavior). The pricing feature only requires that these columns exist:

```cql
ALTER TABLE cronos.orders
  ADD unit_price_at_order    decimal;

ALTER TABLE cronos.orders
  ADD pricing_source_at_order text;   -- RULE | LIST_PRICE | LIST_PRICE_FALLBACK
```

If the order-line data is stored on a separate table (not on `cronos.orders` directly), the same two columns are added to that table instead. Task-generation confirms the current shape and picks the correct target.

- Existing columns on `cronos.orders` are untouched.
- `unit_price_at_order` is written **at order commit time** and is never rewritten (FR-007 / I-OL-1).
- `pricing_source_at_order` is written at the same instant. `LIST_PRICE_FALLBACK` marks orders placed under R-7 degradation.

## Notes on Yugabyte semantics

- `transactions = 'false'` matches `cronos.products` (verified in [resources/schema.cql](../../../resources/schema.cql)). Pricing writes do not need YCQL transactional semantics; the write path is per-rule and per-history-entry, and the read path is point-read + in-memory resolve.
- No `LWT` (`IF NOT EXISTS` at row level) is used. `rule_id` is server-generated as a UUID, making collisions negligible.
- Cassandra semantics do not enforce foreign-key integrity from `price_rules.scope_value` to a `products` row. Validation rule **V-3** in [data-model.md](../data-model.md#validation-rules-used-by-write-endpoints) catches unknown-ASIN writes application-side.
