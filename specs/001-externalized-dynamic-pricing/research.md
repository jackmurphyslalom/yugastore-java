# Phase 0 — Research: Externalized Dynamic Pricing

Feature: [001-externalized-dynamic-pricing](spec.md) | Constitution: [v1.0.1](../../.specify/memory/constitution.md)

This document records the decisions Phase 1 relies on. Each decision resolves either a spec-side `[NEEDS CLARIFICATION]` marker or a plan-side unknown surfaced by the preflight. Alternatives considered are listed with the reason each was rejected so a future spec cycle can revisit if constraints change.

Format for each decision:

- **Decision** — what the plan will assume.
- **Rationale** — why this choice, cited to concrete evidence in the repo.
- **Alternatives considered** — what else was on the table and why not.
- **Reversal criteria** — the observable conditions under which we would come back and re-open the decision via `/speckit.clarify` or `/speckit.iterate.define`.

## R-1 — Service boundary + integration shape

### Decision

A new Spring Boot 2.6.3 module named `pricing-microservice` is added to the reactor. It registers with `eureka-server-local` and is fronted by a new gateway triad `PricingController` → `PricingServiceRest[Impl]` → `PricingRestClient` in `api-gateway-microservice`, mirroring the three existing pairs (`ProductCatalog`, `ShoppingCart`, `Checkout`).

`checkout-microservice` gets its own `PricingRestClient` under `.../cronoscheckoutapi/rest/clients/`, discovered via Eureka the same way its existing `ProductCatalogRestClient` is discovered. That peer call resolves the effective unit price at order-placement time. This is an internal-reactor peer call, not an external one, and it does not violate Principle I (which governs external and UI traffic).

### Rationale

- **Principle I (Gateway-Only Service Boundary)** requires every externally reachable capability to sit behind `api-gateway-microservice` and register with Eureka. The gateway triad shape is the only integration pattern proven in this repo — see [api-gateway-microservice/.../controller/](../../api-gateway-microservice/src/main/java/com/yugabyte/app/yugastore/controller/), [.../service/impl/](../../api-gateway-microservice/src/main/java/com/yugabyte/app/yugastore/service/impl/), and [.../rest/clients/](../../api-gateway-microservice/src/main/java/com/yugabyte/app/yugastore/rest/clients/) which today has three matched pairs.
- **Peer call at checkout is precedented**: `checkout-microservice` already calls `products-microservice` peer-to-peer via its own client at [checkout-microservice/.../rest/clients/ProductCatalogRestClient.java](../../checkout-microservice/src/main/java/com/yugabyte/app/yugastore/cronoscheckoutapi/rest/clients/ProductCatalogRestClient.java). Adding a sibling client for pricing follows the same pattern with no new abstraction.
- **A new module (as opposed to an add-on inside products-microservice)** keeps rule-authoring writes and read-time price resolution off the products-catalog write path, honoring FR-014 ("independently addressable so a slow rule-authoring surface does not block shopper reads").

### Alternatives considered

- **Fold pricing into `products-microservice`**. Rejected: violates FR-014 (rule authoring and effective-price reads would share a service and a data store with the catalog), and would make Story 4's fallback story harder because a pricing-write incident would take the catalog down with it.
- **Route the checkout→pricing call through the gateway**. Rejected: would inflate the gateway with an internal-only responsibility (the gateway does not sit in front of `checkout → products` today either) and would add a second network hop to every order-place, hurting the Principle II transactional-write path indirectly. Peer-to-peer via Eureka is the pattern already in the code.
- **Add pricing endpoints to the gateway that call a library**. Rejected: no shared-library pattern exists in this reactor. Adding one for pricing would be a larger structural change than adding a new microservice and would blur the Eureka-registration expectation set by Principle I.

### Reversal criteria

- If Story 1's Independent Test drops the "no engineering redeploy" clause, an in-process pricing library becomes viable.
- If a shared-library pattern lands in the reactor (e.g., a `pricing-lib` module used by both gateway and checkout), reconsider whether a service is still warranted.

## R-2 — Checkout integration point

### Decision

At order placement, `CheckoutServiceImpl.checkout(String userId)` calls the new `PricingRestClient.getEffectivePrice(asin)` for each product in the cart, and passes the resolved unit price into the order-write step. `getTotal(Map<String, Integer>)` is updated to accept a resolved unit-price supplier (or is called with a pre-resolved unit-price map) instead of reading unit price from `productDetails.getPrice()` directly. The transactional stock-check + inventory-decrement + order-write sequence is untouched; the resolved unit price is written onto the order line at commit time (see R-4).

### Rationale

- The spec's Assumptions block names `CheckoutServiceImpl.calculatePrice()`; that method does not exist. The actual methods (verified in the preflight) are `checkout(String userId)` and `getTotal(Map<String, Integer>)`, with unit price read from `productDetails.getPrice()` where `productDetails` comes from `productCatalogRestClient.getProductDetails(asin)` — see [checkout-microservice/.../service/CheckoutServiceImpl.java](../../checkout-microservice/src/main/java/com/yugabyte/app/yugastore/cronoscheckoutapi/service/CheckoutServiceImpl.java).
- Doing the resolve inside `checkout(...)` (before the transactional write) keeps the transactional block as short as it is today, honoring Principle II.
- Passing the resolved unit price into `getTotal(...)` rather than having `getTotal` reach across to the pricing service keeps `getTotal` pure and testable without a Spring context — this makes Principle V behavioral tests trivial to write.

### Alternatives considered

- **Rename the method to `calculatePrice()` to match the spec**. Rejected: churn without benefit; the plan will note the anchor mismatch for `/speckit.tasks` to fix on the spec side rather than the code side.
- **Do the resolve inside `productCatalogRestClient.getProductDetails(asin)`** by decorating that client. Rejected: it couples "product catalog" with "pricing" at the client layer and blurs the FR-014 separation between rule-authoring and read-time resolution. It also makes fallback behavior (R-7) harder to observe distinctly from a catalog fault.

### Reversal criteria

- If a future feature introduces a shared "order build" helper across cart, checkout, and admin, revisit whether the resolve should move up one layer.

## R-3 — Pricing store choice

**Resolves FR-017.**

### Decision

Two new YCQL tables under the existing `cronos` keyspace, owned by `pricing-microservice`, with `WITH transactions = { 'enabled' : 'false' }` matching `cronos.products`:

- `cronos.price_rules` — the merchandiser-authored rules.
- `cronos.price_rule_history` — the append-only change log queried by Story 5.

DDL lands additively in [resources/schema.cql](../../resources/schema.cql). No changes are made to `cronos.orders` or `cronos.product_inventory`.

### Rationale

- [resources/schema.cql](../../resources/schema.cql) already houses `cronos.products` under the same keyspace with `transactions = 'false'`, so the pattern is precedented.
- `products-microservice`'s [YugabyteYCQLConfig.java](../../products-microservice/src/main/java/com/yugabyte/app/yugastore/config/YugabyteYCQLConfig.java) with `SchemaAction.CREATE_IF_NOT_EXISTS` gives us localhost-first bring-up behavior with no manual DDL step. Reusing that config in the new service means the module is production-ready-shaped without any bespoke bootstrap.
- `cart-microservice` is the only YSQL consumer. Adding YSQL to `pricing-microservice` would double the datastore matrix for one module without a use case in the current spec (no transactional multi-row rule invariant is required by any FR).
- SC-001 ("< 5 minutes propagation") and SC-005 ("< 1 minute history query") are easily met by an in-cluster YCQL point-read + short-TTL cache. A config-managed store (rules committed to a file) would fail SC-001 and FR-005 ("without any redeploy … or manual catalog reload") because a merchandiser change would require, at minimum, a config-service push.
- Principle II is preserved: pricing writes never touch the transactional tables.

### Alternatives considered

- **New YSQL schema (peer to `shopping_cart`)**. Rejected: adds a second datastore to a single new service; no FR requires SQL-level constraints (uniqueness of rules is enforced at write time by `PriceRuleWriteService`, not by a DB constraint). Adds Flyway/Liquibase-shaped concerns not present anywhere else in the reactor.
- **Config-managed store (rules in a versioned file / config server)**. Rejected: incompatible with FR-005 ("no redeploy or manual catalog reload") and with SC-001 ("< 5 minutes"); merchandisers would need engineering to commit a file.
- **Extend the existing `cronos.products` row with a JSON `pricing_rules` column**. Rejected: creates a hot spot on catalog writes for every pricing change, violates FR-014 (rule authoring would share the catalog write path), and makes Story 5's history much harder (would need row-level change data capture on the catalog table).

### Reversal criteria

- If a future rule kind requires cross-row transactional invariants (e.g., "cheapest of A or B, but never both discounted at once"), YSQL becomes attractive and the choice reopens.
- If the reactor grows a shared config service worth reusing, config-managed baseline rules could become a hybrid option (baseline in config, promotions in YCQL).

## R-4 — Order-line price snapshot

### Decision

The order-line record captured at order placement includes an immutable `unit_price_at_order` column, populated with the effective price resolved by R-2 at commit time. Once the order row is committed, this value is never rewritten. Existing order fields, keyspace, and the transactional `cronos.orders` / `cronos.product_inventory` write remain untouched **except for this one additive column**.

### Rationale

- **FR-007** requires that "the unit price captured on each order line MUST be immutable regardless of subsequent price-rule changes, promotion expirations, or list-price changes." A snapshot column on the order line is the direct realization of this requirement.
- The alternative (compute historical price by replaying rules at the moment of order lookup) would tightly couple the order-read path to the pricing service and its historical rule state, and would fail Story 3's acceptance test ("placed order still shows $8 for that line and the same total it was placed at") the first time a merchandiser deletes an old rule.
- Adding a single additive column to `cronos.orders` (or to the order-line side of the existing order write, depending on the current shape — verified in tasks) is not a change to consistency semantics: it is written by the same transactional put that writes the rest of the order line.

### Alternatives considered

- **Snapshot resolved-rule identifiers on the order line instead of the numeric price** (so the price can be "recomputed" later). Rejected: does not satisfy FR-007 (deleting the rule row would invalidate the recomputation), and adds a stale-reference concern for no benefit.
- **Do not snapshot — recompute at read**. Rejected: fails Story 3 acceptance scenario 1.

### Reversal criteria

- If a future feature requires "always compute historical price" for reporting reasons (e.g., audit against list-price at time of order), that becomes a **new column** for that purpose; it does not replace the snapshot.

## R-5 — Merchandiser admin surface + auth (FR-015 resolution)

**Resolves FR-015.**

### Decision

For this iteration, the merchandiser surface is **API-only**, reachable through the gateway:

- `POST /pricing/rules` — create a rule
- `PUT /pricing/rules/{id}` — update or reschedule a rule
- `DELETE /pricing/rules/{id}` — retract a rule
- `GET /pricing/rules/history?asin=…&category=…` — Story 5 audit read

Authorization is a documented local-only mechanism: a required `X-Merchandiser-Id` header, checked against an allow-list configured in `application.yml` under `cronos.pricing.admin.allowed-merchandisers`. This produces a `403` when the header is absent or the id is not on the list. No `react-ui` merchandiser console is built in this iteration. No `login-microservice` dependency is introduced.

### Rationale

- Constitution's Deployment & Scope Boundaries section: "`login-microservice` is unfinished and has no `api-gateway-microservice` REST client wired to it. Completing or integrating it is out of scope by default; any change to wire it in MUST go through `/speckit.specify` first."
- ADR-0001 pins deployment to localhost only. Localhost-only deployment makes an allow-list-header identification model reasonable for iteration 1: nothing here is exposed to the internet.
- Story 1's Independent Test explicitly permits an API-only surface: "even with no admin UI, an API-only surface would let a merchandiser (or their engineering partner) change prices without a release."
- The auth mechanism is presented as *identification*, not authentication, and the plan is explicit that this is an iteration-1 local-only choice — reinforced by the new gaps.md entry proposed in the plan's Constitution Check.

### Alternatives considered

- **New admin UI in `react-ui`**. Rejected for iteration 1: pulls in a UI slice that no user-story Independent Test requires and materially grows the backlog. Reopens with a follow-up spec when merchandiser UX is prioritized.
- **Wire in `login-microservice`**. Rejected for iteration 1: constitution requires a separate `/speckit.specify` cycle before integrating `login-microservice`, and no scope decision has been made.
- **HTTP basic auth against a hardcoded credential**. Rejected: adds Spring Security to a module that has no other auth surface, for a benefit no lower than the header-based allow-list gives.

### Reversal criteria — escalate to `/speckit.clarify` or a new `/speckit.specify` cycle if any of the following becomes true

- Merchandisers request a UI (Story 1 Independent Test grows a UI requirement).
- The engagement scopes in `login-microservice` (the ratified constitution requires that path).
- The deployment target changes off `localhost only` (ADR-0001 supersession) — a header allow-list is not appropriate for a public endpoint.

## R-6 — Rules vs. rules + A/B experimentation (FR-016 resolution)

**Resolves FR-016.**

### Decision

This iteration ships **rules only**. Nothing about A/B variant selection is built. The rule-resolver, however, is deliberately shaped as a single interface `PriceRuleResolver` with a method that accepts an ASIN and a "resolution context" (currently containing only `now: Instant`). A future variant-selector can be inserted as a decorator around this interface without redesigning the read path.

### Rationale

- None of the five user stories in the spec covers experiment authoring or variant assignment. Stories 1–5 are exclusively merchandiser / shopper / order pricing.
- SC-001 through SC-006 make no reference to variants or experiment outcomes.
- The client interview treats "pricing and A/B experimentation" as coupled, but the coupling is at the **problem** level (both are merchandiser levers); the delivery team is explicitly deferred to for whether they ship together. Delivering them together would introduce at minimum two new user stories (shopper variant assignment stability, experimenter persona) and new entities (`Variant`, `Experiment`, `Assignment`) that are not modeled in the current spec.
- Principle IV requires cited evidence for scope decisions. None exists in-repo for pulling A/B into iteration 1; a separate future-state track already exists at `meta/future-state/experimentation.md`.

### Alternatives considered

- **Rules + shopper-consistent A/B assignment**. Rejected for iteration 1: doubles the story count and forces Story 2 ("consistent effective price everywhere") to be redefined around a shopper-scoped variant, materially raising scope. Reopens naturally after this feature ships.
- **Rules with a `variant_id` column pre-baked into `cronos.price_rules`**. Rejected: bakes a concept nothing consumes into the durable schema. If A/B is added later, the schema migration will be shaped by that feature's requirements, not by an unused column.

### Reversal criteria

- Product prioritizes A/B pricing experiments in the next iteration → the `PriceRuleResolver` decorator seam is the intended insertion point, and a new `/speckit.specify` cycle will describe the variant-assignment story.

## R-7 — Graceful degradation of pricing dependency

### Decision

`api-gateway-microservice`'s `PricingRestClient` and `checkout-microservice`'s `PricingRestClient` both wrap the remote call with:

1. A short deadline (default: 300 ms shopper-read, 500 ms checkout-write).
2. A last-known-value cache keyed by ASIN, TTL 5 minutes, refreshed on successful reads. When the deadline blows, the cache serves.
3. A `list_price` fallback if the cache is cold. `list_price` is already available from the products service.
4. A per-service boolean `pricing.serving.mode = SOURCE | CACHE | LIST_PRICE_FALLBACK` exposed via `/actuator/info`, so operators can see which mode is active (FR-011).

Checkout's fallback rule: if the pricing service is unavailable at the moment of order placement, the checkout takes the documented action recorded in `application.yml` under `cronos.pricing.fallback.checkout` — for iteration 1, default `ALLOW_WITH_LIST_PRICE`, which snapshots the list price onto the order line and marks the order with an operator-visible `pricing_source_at_order = LIST_PRICE_FALLBACK` flag.

### Rationale

- FR-010 requires "a documented fallback effective price rather than failing, and checkout MUST take a single documented action."
- FR-011 requires operator visibility into "whether effective prices are currently being served from the pricing source or from the documented fallback."
- Story 4's Independent Test asks specifically for "a clear indicator to internal operators that fallback is in effect."
- SC-004 asks for ">= 99% availability of storefront product-list requests during a simulated 5-minute pricing outage." A last-known-value cache with a 5-minute TTL trivially meets this for any ASIN read at least once during the preceding cache window.
- The plan intentionally does **not** invent a new resilience mechanism. It reuses last-known-value caching, which is a standard degradation pattern that will fit alongside whatever `specs/002-graceful-degradation-resilience/` codifies as the reactor's general resilience contract.

### Alternatives considered

- **Fail closed** (refuse to serve list pages if pricing is down). Rejected: violates FR-010 and SC-004.
- **Serve last-known values with no operator signal**. Rejected: violates FR-011 and Story 4's Independent Test.
- **Circuit-breaker library (Resilience4j)**. Not rejected on merit — kept simple for iteration 1 because a bounded timeout + cache already meets the FRs. If `specs/002-graceful-degradation-resilience/` mandates a specific library, this decision would migrate to that library in a follow-up.

### Reversal criteria

- `specs/002-graceful-degradation-resilience/` ratifies a specific resilience library or pattern the reactor must standardize on.
- Operational data shows the cache-TTL choice (5 minutes) causes a shopper-visible price to lag a merchandiser change past SC-001's 5-minute budget in the "cache is warm from a prior read, then rule changes, then dependency drops" edge case.

## R-8 — Testing shape

### Decision

Behavioral tests for `pricing-microservice` land in three tiers:

1. **Pure resolver tests** — [PriceRuleResolverTests](../../pricing-microservice/src/test/java/com/yugabyte/app/yugastore/pricing/service/PriceRuleResolverTests.java) — no Spring context, no I/O. Covers: precedence between overlapping rules, time-window boundary math, list-price default, invalid rule rejection.
2. **WebMvc slice tests** — [PricingReadControllerWebMvcTests](../../pricing-microservice/src/test/java/com/yugabyte/app/yugastore/pricing/controller/PricingReadControllerWebMvcTests.java) and [PricingRulesAdminControllerWebMvcTests](../../pricing-microservice/src/test/java/com/yugabyte/app/yugastore/pricing/controller/PricingRulesAdminControllerWebMvcTests.java). Covers: request validation, `X-Merchandiser-Id` allow-list, error body shape.
3. **End-to-end** — [PricingEndToEndTests](../../pricing-microservice/src/test/java/com/yugabyte/app/yugastore/pricing/e2e/PricingEndToEndTests.java) — `@SpringBootTest` with a container-backed YCQL. Covers: change a rule, then a follow-up effective-price read reflects it within a bounded time.

For the integration seam, `checkout-microservice` gets a behavioral test that mocks `PricingRestClient` and asserts:

- Effective price from pricing is used at order-line snapshot time.
- Stock-check + order-write path is untouched.
- Fallback path (client throws) snapshots the list price and marks the order.

### Rationale

- Principle V requires behavioral tests for new work, not context-load smokes.
- Every existing module has exactly one Spring context-load test today (verified in preflight) — those are grandfathered, not extended.
- Every module's `pom.xml` binds `jacoco-maven-plugin` to `prepare-agent` + `report` only (no `check` goal). This means the Maven wrapper is a safe focused runner and no whole-suite coverage gate silently fires when you invoke `./mvnw -pl pricing-microservice -am test`.

### Commands (final authority is the broadest suite)

- Targeted: `./mvnw -pl pricing-microservice -Dtest=PriceRuleResolverTests test`
- Focused module: `./mvnw -pl pricing-microservice -am test`
- CI-equivalent: `./mvnw -B test`
- Broadest / final authority: `./mvnw -B verify`

### Alternatives considered

- **Add a repo-wide JaCoCo coverage floor**. Not rejected on merit but out of scope for this feature; a floor should be introduced by the CI-pipeline feature (see [specs/003-ci-test-pipeline](../003-ci-test-pipeline/)) rather than by this one.

### Reversal criteria

- The CI-pipeline feature introduces a coverage gate — the commands above need to be re-verified against the wrapper script the CI feature standardizes on.

## R-9 — Deployment glue (localhost only)

### Decision

- `pricing-microservice` ships a `Dockerfile` mirroring the shape of `products-microservice/Dockerfile`.
- `docker-run.sh` gains a start block for `pricing-microservice` bound to a new port `8083` (verified free — the existing services take `8080` (gateway), `8081` (products), `8082` (checkout), `8761` (Eureka); the local `cart-microservice`/`login-microservice` ports do not collide with `8083` in current config).
- No `manifest.yml` is added, per ADR-0001 (the existing dormant `manifest.yml` files remain untouched and no new cloud manifest is introduced).

### Rationale

- ADR-0001 constrains deployment to localhost. `docker-run.sh` and `mvn spring-boot:run` are the two supported bring-up paths, and both must work for the new module.
- Not adding `manifest.yml` prevents accidentally re-signaling "cloud is on the table."

### Alternatives considered

- **Introduce a `docker-compose.yml`**. Not rejected on merit; deferred because `docker-run.sh` is the current pattern and mixing patterns in one feature adds churn.

### Reversal criteria

- Deployment target changes (ADR-0001 supersession).

## Open items carried into Phase 1

All three `[NEEDS CLARIFICATION]` markers in the spec (FR-015, FR-016, FR-017) are resolved above with an in-plan default plus documented reversal criteria. Phase 1 proceeds under these defaults.

One small spec-side correction (`calculatePrice` → `checkout` / `getTotal`) is queued as a follow-up task for `/speckit.tasks`. It is a documentation error in the spec's Assumptions block, not a change of behavior.
