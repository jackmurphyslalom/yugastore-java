---
description: "Task list for Externalized Dynamic Pricing"
---

# Tasks: Externalized Dynamic Pricing

**Input**: Design documents from [specs/001-externalized-dynamic-pricing/](.).

**Prerequisites**: [plan.md](plan.md) (required), [spec.md](spec.md) (required for user stories), [research.md](research.md), [data-model.md](data-model.md), [contracts/](contracts/), [quickstart.md](quickstart.md).

**Tests**: Included. Behavioral tests are required by [research.md § R-8](research.md#r-8-testing-shape) and by Constitution Principle V. Context-load smoke tests are NOT sufficient for new work.

**Organization**: Grouped by user story. US1, US2, US3 are all P1 (spec.md); US4 is P2; US5 is P3. Each story is independently testable after Phase 2.

## Format: `[ID] [P?] [Story] Description with file path`

- **[P]** — task touches a different file than other [P]-tagged tasks and has no dependency on any incomplete task; safe to run in parallel.
- **[Story]** — story label used only for Phase 3+ story tasks (US1–US5). Setup, Foundational, and Polish phases carry no story label.
- Every task names an exact target file.

## Path conventions

- New Spring Boot module at `pricing-microservice/…` (mirrors `products-microservice/` shape).
- Existing modules extended with additive changes: `api-gateway-microservice/…`, `checkout-microservice/…`, `react-ui/…`.
- Shared schema at `resources/schema.cql`; docker glue at `docker-run.sh`; reactor pom at `pom.xml`.
- Doc artifacts at `docs/product/glossary.md`, `docs/decisions/…`, `docs/patterns/…`, `docs/context/gaps.md`.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Bring the new `pricing-microservice` module into the reactor and add the additive DDL. No behavior yet.

- [ ] T001 Create the new module directory `pricing-microservice/` with the standard Maven layout: `src/main/java/com/yugabyte/app/yugastore/pricing/`, `src/main/resources/`, `src/test/java/com/yugabyte/app/yugastore/pricing/`, and `src/test/resources/`.
- [ ] T002 Add `pricing-microservice/pom.xml` inheriting from the root `pom.xml` parent, matching the dependency set in `products-microservice/pom.xml` (Spring Boot 2.6.3, Spring Cloud 2021.0.0 BOM, `spring-boot-starter-web`, `spring-boot-starter-data-cassandra`, `spring-boot-starter-actuator`, `spring-cloud-starter-netflix-eureka-client`, `spring-boot-starter-test`, `jacoco-maven-plugin` bound to `prepare-agent` + `report` only — no `check` goal).
- [ ] T003 Add `<module>pricing-microservice</module>` to the reactor `<modules>` list in the root `pom.xml` (place after `products-microservice`).
- [ ] T004 Create `pricing-microservice/application.yml` with server port `8083`, application name `pricing-microservice`, Eureka client pointing at `http://localhost:8761/eureka/`, and a `cronos.pricing.admin.allowed-merchandisers` list bound to an env var default.
- [ ] T005 Create `pricing-microservice/Dockerfile` mirroring `products-microservice/Dockerfile`.
- [ ] T006 Update `docker-run.sh` with a start stanza for `pricing-microservice` on port `8083` after the products/checkout stanzas.
- [ ] T007 [P] Append the four new DDL statements to `resources/schema.cql` per [contracts/ycql-schema.md](contracts/ycql-schema.md): `cronos.price_rules`, `cronos.price_rules_by_scope`, `cronos.price_rule_history`, `cronos.price_rule_history_by_scope`. All four use `WITH transactions = { 'enabled' : 'false' }`. Do not touch existing statements.

**Checkpoint**: `./mvnw -pl pricing-microservice -am compile` succeeds; `docker-run.sh` no-ops for the new stanza until Phase 2 supplies a `@SpringBootApplication`.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Wire the new module into the reactor at runtime, provide the YCQL config and shared domain classes every user story needs, and land the durable doc artifacts required by Principles III + IV. **No user-story work may begin until this phase is complete.**

- [ ] T008 Create `pricing-microservice/src/main/java/com/yugabyte/app/yugastore/pricing/PricingServiceApplication.java` with `@SpringBootApplication` and `@EnableEurekaClient`.
- [ ] T009 Create `pricing-microservice/src/main/java/com/yugabyte/app/yugastore/pricing/config/YugabyteYCQLConfig.java` mirroring `products-microservice/src/main/java/com/yugabyte/app/yugastore/config/YugabyteYCQLConfig.java` (single YCQL config, `SchemaAction.CREATE_IF_NOT_EXISTS`, `@Profile("local")`).
- [ ] T010 [P] Create `pricing-microservice/src/test/resources/application-test.yml` bypassing the `@Profile("local")` YCQL config for context-free unit tests, mirroring `products-microservice/src/test/resources/application-test.yml`.
- [ ] T011 [P] Create the domain enums in `pricing-microservice/src/main/java/com/yugabyte/app/yugastore/pricing/domain/`: `PriceRuleScope.java` (`ASIN | CATEGORY`), `PriceRuleKind.java` (`LIST_PRICE_OVERRIDE | PROMOTION`), `ServingMode.java` (`SOURCE | CACHE | LIST_PRICE_FALLBACK`), `PricingSource.java` (`RULE | LIST_PRICE | LIST_PRICE_FALLBACK`). Matches [data-model.md](data-model.md).
- [ ] T012 [P] Create `pricing-microservice/src/main/java/com/yugabyte/app/yugastore/pricing/domain/PriceRule.java` (`@Table("price_rules")`) with columns from [data-model.md § 1](data-model.md#1-price-rule-cronosprice_rules) and `@PrimaryKey UUID ruleId`.
- [ ] T013 [P] Create `pricing-microservice/src/main/java/com/yugabyte/app/yugastore/pricing/domain/PriceRuleByScope.java` (`@Table("price_rules_by_scope")`) with `@PrimaryKeyClass` covering `(scope_kind, scope_value)` partition + `rule_id` clustering.
- [ ] T014 [P] Create `pricing-microservice/src/main/java/com/yugabyte/app/yugastore/pricing/domain/PriceRuleHistoryEntry.java` (`@Table("price_rule_history")`) and `pricing-microservice/src/main/java/com/yugabyte/app/yugastore/pricing/domain/PriceRuleHistoryByScope.java` (`@Table("price_rule_history_by_scope")`) matching [contracts/ycql-schema.md](contracts/ycql-schema.md).
- [ ] T015 [P] Create `pricing-microservice/src/main/java/com/yugabyte/app/yugastore/pricing/domain/EffectivePrice.java` DTO (transport-only, not persisted) with fields from [data-model.md § 3](data-model.md#3-effective-price-transport-only-not-persisted).
- [ ] T016 Add the five new terms **Effective Price**, **List Price**, **Price Rule**, **Promotion**, **Merchandiser** to `docs/product/glossary.md`, wording taken verbatim from [spec.md § Key Entities](spec.md#key-entities-include-if-feature-involves-data). Required by FR-012 / Principle III.
- [ ] T017 [P] Create `docs/decisions/2026-09-15-pricing-store-choice.md` from [research.md § R-3](research.md#r-3-pricing-store-choice) and `docs/decisions/2026-09-15-pricing-service-boundary.md` from [research.md § R-1](research.md#r-1-service-boundary--integration-shape) and [R-4](research.md#r-4-order-line-price-snapshot). Required by Principle IV.

**Checkpoint**: `./mvnw -pl pricing-microservice -am spring-boot:run` starts on `:8083` and registers with Eureka; `./mvnw -pl pricing-microservice -am test` passes (no behavior tests yet, but the context wires cleanly). User story work can now begin.

---

## Phase 3: User Story 1 — Merchandiser changes an effective price without an engineering release (Priority: P1) 🎯 MVP

**Goal**: A merchandiser calls the gateway to create/update/retract a `PriceRule` for an ASIN or category, and a follow-up `GET /pricing/effective?asin=…` reflects the change.

**Independent Test** (from [spec.md § US1](spec.md#user-story-1---merchandiser-changes-an-effective-price-without-an-engineering-release-priority-p1)): create a rule at $8 for an ASIN; read effective price and see `source = RULE`, `unit_price = 8.00`; verify no module was rebuilt/redeployed. Reproduces [quickstart.md § Story 1](quickstart.md#story-1--merchandiser-changes-an-effective-price-without-an-engineering-release).

### Tests for User Story 1 (write first, ensure they fail before implementation)

- [ ] T018 [P] [US1] Write `pricing-microservice/src/test/java/com/yugabyte/app/yugastore/pricing/service/PriceRuleResolverTests.java` — pure JUnit, no Spring context. Cover: list-price default when no rule; single ASIN rule wins over category rule at equal priority; higher priority wins; PROMOTION beats LIST_PRICE_OVERRIDE on tie; promotion outside `[starts_at, ends_at)` does not apply; `created_at` desc as final tiebreak. Matches [data-model.md § Effective-price precedence](data-model.md#effective-price-precedence).
- [ ] T019 [P] [US1] Write `pricing-microservice/src/test/java/com/yugabyte/app/yugastore/pricing/service/PriceRuleWriteServiceTests.java` — repositories mocked. Cover validation codes `PRICE_NON_POSITIVE` (V-1), `PROMOTION_WINDOW_INVALID` (V-2), `UNKNOWN_ASIN` (V-3), `PRIORITY_NEGATIVE` (V-4) from [data-model.md § Validation rules](data-model.md#validation-rules-used-by-write-endpoints).
- [ ] T020 [P] [US1] Write `pricing-microservice/src/test/java/com/yugabyte/app/yugastore/pricing/controller/PricingRulesAdminControllerWebMvcTests.java` (`@WebMvcTest(PricingRulesAdminController.class)`) covering `POST /pricing/rules`, `PUT /pricing/rules/{id}`, `DELETE /pricing/rules/{id}` — status codes, `X-Merchandiser-Id` allow-list checks (401/403), and RFC 7807 error body shape per [contracts/pricing-rest.openapi.yaml § Problem](contracts/pricing-rest.openapi.yaml).
- [ ] T021 [P] [US1] Write `pricing-microservice/src/test/java/com/yugabyte/app/yugastore/pricing/controller/PricingReadControllerWebMvcTests.java` (`@WebMvcTest(PricingReadController.class)`) covering `GET /pricing/effective?asin=…` — 200 shape (`EffectivePrice` DTO), 404 for unknown ASIN.
- [ ] T022 [P] [US1] Write `pricing-microservice/src/test/java/com/yugabyte/app/yugastore/pricing/e2e/PricingEndToEndTests.java` (`@SpringBootTest`) covering the round-trip: `POST /pricing/rules` → follow-up `GET /pricing/effective?asin=…` reflects the change; DELETE retracts and the follow-up read reverts to list price.

### Implementation for User Story 1

- [ ] T023 [P] [US1] Implement `pricing-microservice/src/main/java/com/yugabyte/app/yugastore/pricing/repository/PriceRuleRepository.java` (`extends CassandraRepository<PriceRule, UUID>`) and `PriceRuleByScopeRepository.java` — plain finders keyed by `(scope_kind, scope_value)`.
- [ ] T024 [P] [US1] Implement `pricing-microservice/src/main/java/com/yugabyte/app/yugastore/pricing/repository/PriceRuleHistoryRepository.java` and `PriceRuleHistoryByScopeRepository.java` — append-only interface (no update/delete methods exposed; invariant I-HIST-1 in [data-model.md](data-model.md#invariants-1)).
- [ ] T025 [US1] Implement `pricing-microservice/src/main/java/com/yugabyte/app/yugastore/pricing/service/PriceRuleResolver.java` — pure Java, no Spring beans. Method: `EffectivePrice resolve(String asin, BigDecimal listPrice, List<PriceRule> candidates, Instant now)`. Implements the full precedence order from [data-model.md](data-model.md#effective-price-precedence). Depends on T011, T012, T015.
- [ ] T026 [US1] Implement `pricing-microservice/src/main/java/com/yugabyte/app/yugastore/pricing/service/EffectivePriceService.java` — orchestrates: fetch rules from both scope tables → point-load `PriceRule` bodies → call `PriceRuleResolver.resolve(...)`. Reads list price from the products service via a new `ProductCatalogRestClient` internal client (add under `pricing-microservice/.../rest/clients/ProductCatalogRestClient.java` to mirror the checkout pattern). Depends on T023, T025.
- [ ] T027 [US1] Implement `pricing-microservice/src/main/java/com/yugabyte/app/yugastore/pricing/service/PriceRuleWriteService.java` — validates per [data-model.md § Validation rules](data-model.md#validation-rules-used-by-write-endpoints), writes to `price_rules` + `price_rules_by_scope` + `price_rule_history` + `price_rule_history_by_scope` in a single request (invariant I-HIST-2), throws stable `ValidationException` types carrying validation `code` values. Depends on T023, T024.
- [ ] T028 [US1] Implement `pricing-microservice/src/main/java/com/yugabyte/app/yugastore/pricing/service/MerchandiserAuthorizer.java` — reads `cronos.pricing.admin.allowed-merchandisers` from config; throws distinct exceptions for missing header (401) vs. not-in-allow-list (403). Matches [research.md § R-5](research.md#r-5-merchandiser-admin-surface--auth-fr-015-resolution).
- [ ] T029 [US1] Implement `pricing-microservice/src/main/java/com/yugabyte/app/yugastore/pricing/web/ProblemDetailAdvice.java` — `@RestControllerAdvice` mapping validation, authz, and not-found exceptions to RFC 7807 bodies with the stable `code` field.
- [ ] T030 [US1] Implement `pricing-microservice/src/main/java/com/yugabyte/app/yugastore/pricing/controller/PricingRulesAdminController.java` — `POST /pricing/rules`, `PUT /pricing/rules/{id}`, `DELETE /pricing/rules/{id}`. Delegates to `MerchandiserAuthorizer` + `PriceRuleWriteService`. Contract: [contracts/pricing-rest.openapi.yaml](contracts/pricing-rest.openapi.yaml).
- [ ] T031 [US1] Implement `pricing-microservice/src/main/java/com/yugabyte/app/yugastore/pricing/controller/PricingReadController.java` — `GET /pricing/effective?asin=…`. Delegates to `EffectivePriceService`. Contract: [contracts/pricing-rest.openapi.yaml](contracts/pricing-rest.openapi.yaml).
- [ ] T032 [US1] Add the gateway triad in `api-gateway-microservice`: `controller/PricingController.java`, `service/PricingServiceRest.java` + `service/impl/PricingServiceRestImpl.java`, and `rest/clients/PricingRestClient.java`. Proxies the same paths (`GET /pricing/effective`, `POST/PUT/DELETE /pricing/rules`) to Eureka-discovered `pricing-microservice`. Mirrors the shape of the existing three triads. Contract: same [contracts/pricing-rest.openapi.yaml](contracts/pricing-rest.openapi.yaml).

**Checkpoint**: [quickstart.md § Story 1](quickstart.md#story-1--merchandiser-changes-an-effective-price-without-an-engineering-release) validates end-to-end through `http://localhost:8080`. `./mvnw -pl pricing-microservice -am test` and `./mvnw -pl api-gateway-microservice -am test` pass. User Story 1 is independently demoable.

---

## Phase 4: User Story 2 — Shopper sees a single, consistent effective price everywhere (Priority: P1)

**Goal**: Product list, product detail, cart, and checkout unit-price rendering all read the same `EffectivePrice` from `pricing-microservice`, so no surface disagrees at the same instant.

**Independent Test** (from [spec.md § US2](spec.md#user-story-2---shopper-sees-a-single-consistent-effective-price-everywhere-priority-p1)): with a rule at $8 for an ASIN, hit product-list, product-detail, cart, and checkout preview through the gateway; assert `$8.00` appears in every response for that ASIN in the same session.

### Tests for User Story 2

- [ ] T033 [P] [US2] Add `pricing-microservice/src/test/java/com/yugabyte/app/yugastore/pricing/service/EffectivePriceBatchServiceTests.java` — asserts batch resolve fans out to per-ASIN resolves, coalesces `unknown_asins`, and returns a single `serving_mode` for the batch.
- [ ] T034 [P] [US2] Add `pricing-microservice/src/test/java/com/yugabyte/app/yugastore/pricing/controller/PricingBatchReadControllerWebMvcTests.java` (`@WebMvcTest`) — covers `POST /pricing/effective/batch` request/response shape from [contracts/pricing-rest.openapi.yaml](contracts/pricing-rest.openapi.yaml) (1–500 ASINs, oversized batch → 400, empty → 400).

### Implementation for User Story 2

- [ ] T035 [US2] Extend `pricing-microservice/src/main/java/com/yugabyte/app/yugastore/pricing/service/EffectivePriceService.java` with `batchResolve(List<String> asins)` — single-pass rule fetch by scope-value union across the batch, then resolves per ASIN. Depends on T026.
- [ ] T036 [US2] Extend `pricing-microservice/src/main/java/com/yugabyte/app/yugastore/pricing/controller/PricingReadController.java` with `POST /pricing/effective/batch`. Contract: [contracts/pricing-rest.openapi.yaml](contracts/pricing-rest.openapi.yaml).
- [ ] T037 [P] [US2] Add nullable `Double effectivePrice` to `products-microservice/src/main/java/com/yugabyte/app/yugastore/domain/ProductMetadata.java` (Jackson getter/setter; not persisted — `@Transient` or excluded from `@Table` mapping).
- [ ] T038 [P] [US2] Add nullable `Double effectivePrice` to `checkout-microservice/src/main/java/com/yugabyte/app/yugastore/cronoscheckoutapi/domain/ProductMetadata.java`.
- [ ] T039 [P] [US2] Add nullable `Double effectivePrice` to `api-gateway-microservice/src/main/java/com/yugabyte/app/yugastore/domain/ProductMetadata.java`.
- [ ] T040 [P] [US2] Add nullable `Double effectivePrice` to `react-ui/src/main/java/com/yugabyte/yugastore/ui/model/ProductMetadata.java`.
- [ ] T041 [US2] In `api-gateway-microservice`, extend the existing product-list and product-detail controllers (`ProductCatalogController` + service) to enrich responses by calling `PricingRestClient.batchGetEffectivePrice(...)` and populating `ProductMetadata.effectivePrice` on each returned item. Preserve current `price` field (list price) unchanged. Depends on T032.
- [ ] T042 [US2] In `api-gateway-microservice`, extend the existing cart-render path (through `ShoppingCartServiceRestImpl` / cart controller) to populate `effectivePrice` on each cart line by calling the batch pricing endpoint. Preserve line quantity and ASIN keys unchanged.
- [ ] T043 [US2] Update the `react-ui` frontend rendering in `react-ui/frontend/src/` to prefer `effectivePrice` when present, otherwise fall back to `price`, on product-list, product-detail, and cart views. Use the field values only for display; do not change routing.
- [ ] T044 [US2] Add `pricing-microservice/src/test/java/com/yugabyte/app/yugastore/pricing/e2e/EffectivePriceParityTests.java` — end-to-end parity check: for a set of ASINs (with and without an active rule), assert `unit_price` returned by `GET /pricing/effective?asin=<a>` matches every element of `POST /pricing/effective/batch` and matches what the gateway-embedded product-list, product-detail, and cart render for the same ASIN in the same test-clock instant. Realizes SC-002.

**Checkpoint**: [quickstart.md § Story 2](quickstart.md#story-2--shopper-sees-a-single-consistent-effective-price-everywhere) passes end-to-end. User Story 2 is independently demoable and does not depend on Order Line changes.

---

## Phase 5: User Story 3 — Placed orders keep the price they were placed at (Priority: P1)

**Goal**: At order placement, the resolved effective price is snapshotted onto the order line as `unit_price_at_order` and never changes thereafter. The transactional stock-check + inventory-decrement + order-write path is untouched.

**Independent Test** (from [spec.md § US3](spec.md#user-story-3---placed-orders-keep-the-price-they-were-placed-at-priority-p1)): place an order at a promotional price; retract the rule; re-read the order and see the original unit price unchanged.

### Tests for User Story 3

- [ ] T045 [P] [US3] Add `checkout-microservice/src/test/java/com/yugabyte/app/yugastore/cronoscheckoutapi/service/CheckoutServiceImplPricingIntegrationTests.java` — mocks `PricingRestClient` (returns known effective price) and `ProductCatalogRestClient`; asserts: (a) `checkout(String userId)` uses effective price from pricing client (not `productDetails.getPrice()`) for order-line snapshot, (b) stock-check + `NotEnoughProductsInStockException` behavior unchanged, (c) the order write is called with the snapshot column populated. Realizes FR-007, FR-009, Principle II.
- [ ] T046 [P] [US3] Add `checkout-microservice/src/test/java/com/yugabyte/app/yugastore/cronoscheckoutapi/service/CheckoutServiceImplFallbackTests.java` — mocks `PricingRestClient` to throw. Asserts: (a) default `cronos.pricing.fallback.checkout = ALLOW_WITH_LIST_PRICE` snapshots the list price and marks `pricing_source_at_order = LIST_PRICE_FALLBACK`, (b) the order still commits, (c) the transactional path is unchanged.

### Implementation for User Story 3

- [ ] T047 [US3] Append the two additive column ALTERs to `resources/schema.cql` per [contracts/ycql-schema.md § Additive order-line columns](contracts/ycql-schema.md#additive-order-line-columns): `ALTER TABLE cronos.orders ADD unit_price_at_order decimal;` and `ALTER TABLE cronos.orders ADD pricing_source_at_order text;`. Confirm the target table by inspecting the existing DDL in `resources/schema.cql`; if order-line data lives on a separate table, ALTER that instead.
- [ ] T048 [US3] Modify the order-line entity in `checkout-microservice/src/main/java/com/yugabyte/app/yugastore/cronoscheckoutapi/domain/` (the class currently mapped to the order-line row — verify via `lsp_java_getFileStructure` on the domain package): add `BigDecimal unitPriceAtOrder` and `String pricingSourceAtOrder` fields with getters only (setters package-private; immutable after commit — invariant I-OL-1 in [data-model.md](data-model.md#4-order-line-price-snapshot-additive-column-on-the-existing-order-line)).
- [ ] T049 [US3] Create `checkout-microservice/src/main/java/com/yugabyte/app/yugastore/cronoscheckoutapi/rest/clients/PricingRestClient.java` — mirrors the shape of `ProductCatalogRestClient.java` in the same package (Eureka-discovered peer call to `pricing-microservice`). Exposes `EffectivePrice getEffectivePrice(String asin)` and `Map<String, EffectivePrice> batchGetEffectivePrice(List<String> asins)`. Contract: [contracts/pricing-peer.openapi.yaml](contracts/pricing-peer.openapi.yaml).
- [ ] T050 [US3] Add a checkout-side copy of `EffectivePrice` DTO at `checkout-microservice/src/main/java/com/yugabyte/app/yugastore/cronoscheckoutapi/domain/EffectivePrice.java` — matches the DTO defined in T015 (this reactor does not share domain across modules; the four-copy pattern is preserved).
- [ ] T051 [US3] Modify `checkout-microservice/src/main/java/com/yugabyte/app/yugastore/cronoscheckoutapi/service/CheckoutServiceImpl.java`: in the actual entry-point method `checkout(String userId)` (NOTE: spec calls this `calculatePrice()` but the real method is `checkout(...)` / `getTotal(Map<String,Integer>)` — see plan.md § Anchor mismatch), resolve unit price per ASIN via `PricingRestClient.batchGetEffectivePrice(...)` **before** the transactional stock-check + order-write step. Pass the resolved unit-price map into `getTotal(...)` (adjust signature to accept a resolver or a pre-resolved map). Do NOT change `getTotal`'s use of `Map<String,Integer>` for quantities; only the unit-price source changes. Snapshot each order line with `unitPriceAtOrder = effective.unit_price` and `pricingSourceAtOrder = effective.serving_mode == LIST_PRICE_FALLBACK ? "LIST_PRICE_FALLBACK" : (effective.source == RULE ? "RULE" : "LIST_PRICE")`. Fallback behavior wired here reads `cronos.pricing.fallback.checkout` (default `ALLOW_WITH_LIST_PRICE`).
- [ ] T052 [US3] Add `cronos.pricing.fallback.checkout=ALLOW_WITH_LIST_PRICE` to `checkout-microservice/src/main/resources/application.yml` and document values (`ALLOW_WITH_LIST_PRICE` | `REFUSE`) inline.
- [ ] T053 [US3] Extend the order-read path (whichever controller/service in `checkout-microservice` returns an order to the gateway) to include `unitPriceAtOrder` and `pricingSourceAtOrder` on each line in the response body.
- [ ] T054 [US3] Update the gateway-side checkout preview response through `api-gateway-microservice/.../CheckoutController` (existing) so `unit_price_at_order` (once an order is placed) reads back with the snapshotted value, not a re-resolved effective price. Add a passthrough test in the WebMvc slice for `CheckoutController` if one exists; otherwise add one at `api-gateway-microservice/src/test/java/com/yugabyte/app/yugastore/controller/CheckoutControllerWebMvcTests.java`.
- [ ] T055 [US3] Add `checkout-microservice/src/test/java/com/yugabyte/app/yugastore/cronoscheckoutapi/service/CheckoutOrderSnapshotImmutabilityTests.java` — places an order (with an in-memory or embedded YCQL), retracts the pricing rule that produced the unit price, re-reads the order and asserts the snapshotted unit price is unchanged. Realizes SC-003.
- [ ] T056 [US3] Fix the anchor mismatch in `specs/001-externalized-dynamic-pricing/spec.md` § Assumptions: change the bullet naming `CheckoutServiceImpl.calculatePrice()` to reference `CheckoutServiceImpl.checkout(String userId)` and `getTotal(Map<String, Integer>)` (the actual method names). See plan.md § Anchor mismatch for the correct wording.

**Checkpoint**: [quickstart.md § Story 3](quickstart.md#story-3--placed-orders-keep-the-price-they-were-placed-at) validates; `./mvnw -pl checkout-microservice -am test` and `./mvnw -pl pricing-microservice -am test` both pass. Consistency-sensitive Principle II is preserved (T045 and T055 assert this behaviorally).

---

## Phase 6: User Story 4 — Shopping continues when the pricing source degrades (Priority: P2)

**Goal**: When `pricing-microservice` is unresponsive, gateway reads and checkout writes gracefully degrade using a per-service last-known-value cache with a `list_price` fallback, and expose `serving_mode` for operator visibility.

**Independent Test** (from [spec.md § US4](spec.md#user-story-4---shopping-continues-when-the-pricing-source-degrades-priority-p2)): `docker stop pricing-microservice`, load the storefront product list, verify non-empty response and `serving_mode` on `/actuator/info`; place an order and verify `pricing_source_at_order = LIST_PRICE_FALLBACK`.

### Tests for User Story 4

- [ ] T057 [P] [US4] Add `api-gateway-microservice/src/test/java/com/yugabyte/app/yugastore/rest/clients/PricingRestClientResilienceTests.java` — mocks the remote call to time out. Asserts: (a) first call returns list-price fallback with `serving_mode = LIST_PRICE_FALLBACK`, (b) after a successful call warms the cache, subsequent timeouts return cached values with `serving_mode = CACHE`, (c) after recovery, `serving_mode` returns to `SOURCE`.
- [ ] T058 [P] [US4] Add `checkout-microservice/src/test/java/com/yugabyte/app/yugastore/cronoscheckoutapi/rest/clients/PricingRestClientCheckoutFallbackTests.java` — mirror of T057 for checkout's client, additionally asserts that `cronos.pricing.fallback.checkout=REFUSE` causes an order-refusal with a clear error body per FR-010.

### Implementation for User Story 4

- [ ] T059 [US4] Add a bounded last-known-value cache inside `api-gateway-microservice/src/main/java/com/yugabyte/app/yugastore/rest/clients/PricingRestClient.java` — Caffeine or an in-memory Map with a 5-minute TTL, keyed by ASIN. Deadline: 300 ms shopper read, 500 ms merchandiser write. On timeout/error: serve from cache; if cache-cold, fetch list price via `ProductCatalogRestClient` and mark `serving_mode = LIST_PRICE_FALLBACK`. Realizes [research.md § R-7](research.md#r-7-graceful-degradation-of-pricing-dependency).
- [ ] T060 [US4] Add the same cache + fallback pattern to `checkout-microservice/src/main/java/com/yugabyte/app/yugastore/cronoscheckoutapi/rest/clients/PricingRestClient.java` (T049 extension). Read `cronos.pricing.fallback.checkout` to decide `ALLOW_WITH_LIST_PRICE` vs `REFUSE`.
- [ ] T061 [P] [US4] Add `api-gateway-microservice/src/main/java/com/yugabyte/app/yugastore/actuator/PricingServingModeInfoContributor.java` implementing `InfoContributor` — surfaces the current mode (`SOURCE | CACHE | LIST_PRICE_FALLBACK`) at `/actuator/info` under key `pricing.serving_mode`. Realizes FR-011.
- [ ] T062 [P] [US4] Add `checkout-microservice/src/main/java/com/yugabyte/app/yugastore/cronoscheckoutapi/actuator/PricingServingModeInfoContributor.java` — same shape, exposed at checkout's `/actuator/info`.
- [ ] T063 [US4] Ensure `management.endpoints.web.exposure.include=info` (and any pre-existing exposures) in both `api-gateway-microservice/application.yml` and `checkout-microservice/application.yml` so `PricingServingModeInfoContributor` output is externally visible.
- [ ] T064 [US4] Add `pricing-microservice/src/test/java/com/yugabyte/app/yugastore/pricing/e2e/PricingDegradationE2ETests.java` — programmatically stops the mocked pricing dependency (or uses a WireMock stand-in), performs product-list + checkout flows through the gateway, and asserts SC-004 (≥99% availability of storefront product-list during a simulated 5-minute outage).

**Checkpoint**: [quickstart.md § Story 4](quickstart.md#story-4--shopping-continues-when-the-pricing-source-degrades) validates. User Story 4 is independently demoable via `docker stop pricing-microservice`.

---

## Phase 7: User Story 5 — Merchandiser can review and audit their pricing changes (Priority: P3)

**Goal**: Query change history by ASIN or by category; every `CREATED`/`UPDATED`/`RETRACTED` event is recorded with actor + before/after values.

**Independent Test** (from [spec.md § US5](spec.md#user-story-5---merchandiser-can-review-and-audit-their-pricing-changes-priority-p3)): make CREATE→UPDATE→DELETE against a rule; query history by ASIN and verify three ordered entries with correct actor and diffs.

### Tests for User Story 5

- [ ] T065 [P] [US5] Add `pricing-microservice/src/test/java/com/yugabyte/app/yugastore/pricing/controller/PricingHistoryControllerWebMvcTests.java` (`@WebMvcTest`) — covers `GET /pricing/rules/history?asin=…` and `?category=…`, requires the merchandiser header, rejects both-or-neither query params with 400, respects `limit` clamp.
- [ ] T066 [P] [US5] Add `pricing-microservice/src/test/java/com/yugabyte/app/yugastore/pricing/service/PriceRuleHistoryQueryServiceTests.java` — repositories mocked. Asserts ordering `event_at DESC`, joins between `price_rule_history_by_scope` (scope lookup) and `price_rule_history` (full diffs).

### Implementation for User Story 5

- [ ] T067 [US5] Extend `pricing-microservice/src/main/java/com/yugabyte/app/yugastore/pricing/service/PriceRuleWriteService.java` (from T027) to also write a `PriceRuleHistoryEntry` + `PriceRuleHistoryByScope` row on every `CREATED`/`UPDATED`/`RETRACTED` operation, populating only the fields that changed per [data-model.md § 2](data-model.md#2-price-rule-history-entry-cronosprice_rule_history). Invariant I-HIST-2: history write and rule write commit in the same request; either both succeed or the whole request fails 500.
- [ ] T068 [US5] Create `pricing-microservice/src/main/java/com/yugabyte/app/yugastore/pricing/service/PriceRuleHistoryQueryService.java` — reads by `(scope_kind, scope_value)` from `price_rule_history_by_scope`, then batch-loads full diffs from `price_rule_history` keyed by `(rule_id, event_at)`.
- [ ] T069 [US5] Create `pricing-microservice/src/main/java/com/yugabyte/app/yugastore/pricing/controller/PricingHistoryController.java` — `GET /pricing/rules/history?asin=…` and `?category=…&limit=…` per [contracts/pricing-rest.openapi.yaml](contracts/pricing-rest.openapi.yaml). Requires `X-Merchandiser-Id` header (calls `MerchandiserAuthorizer`).
- [ ] T070 [US5] Extend the gateway triad added in T032 to proxy `GET /pricing/rules/history` to `pricing-microservice`. Update `PricingRestClient.java`, `PricingServiceRest[Impl].java`, and `PricingController.java` in `api-gateway-microservice`.
- [ ] T071 [US5] Add `pricing-microservice/src/test/java/com/yugabyte/app/yugastore/pricing/e2e/PricingHistoryEndToEndTests.java` (`@SpringBootTest`) — performs a CREATE → UPDATE → RETRACT sequence via `POST/PUT/DELETE /pricing/rules`, then queries `GET /pricing/rules/history?asin=…` and asserts three entries in `event_at DESC` order with correct actor and before/after diffs. Realizes SC-005.
- [ ] T072 [US5] Add a spec-mentioned "rollback recorded as a distinct change" test to T071: after a RETRACT, POST a new rule that restores the prior `unit_price`; assert a fourth `CREATED` entry appears in history rather than a mutation of the retracted rule (matches spec.md Story 5 acceptance scenario 3).

**Checkpoint**: [quickstart.md § Story 5](quickstart.md#story-5--merchandiser-can-review-and-audit-their-pricing-changes) validates. All five user stories are now independently functional.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Documentation follow-ups, durable-context updates, and the broadest-suite verification.

- [ ] T073 [P] Create `docs/patterns/gateway-fanout.md` codifying the `*Controller` → `*ServiceRest[Impl]` → `rest/clients/*RestClient` triad discovered in the preflight, referencing the four in-tree examples (`ProductCatalog`, `ShoppingCart`, `Checkout`, `Pricing`). Cite the constitution's Principle I. Required by plan.md § New decisions this plan records.
- [ ] T074 [P] Append a new entry to `docs/context/gaps.md` under an "Open questions" heading: "Merchandiser SSO deferred — resolved locally for iteration 1 via `X-Merchandiser-Id` allow-list; reopens if a `react-ui` merchandiser console is scoped or `login-microservice` is scoped back in." Include a link back to [research.md § R-5](research.md#r-5-merchandiser-admin-surface--auth-fr-015-resolution).
- [ ] T075 [P] Update `docs/architecture/overview.md` service-list and ports table (if present) to include `pricing-microservice` on port `8083` and describe the checkout → pricing peer call. Do not restate design details already in this feature's plan.
- [ ] T076 Update `docs/context/index.yaml` to add the two new decision files (T017), the pattern doc (T073), and the plan/spec/tasks paths for this feature, and to flip stale entries the plan noticed (e.g., `.specify/memory/constitution.md` status field). Sanity-check the YAML with `python3 -c "import yaml; yaml.safe_load(open('docs/context/index.yaml'))"`.
- [ ] T077 Cross-reference cleanup in `docs/product/glossary.md`: after T016 lands the new terms, add reciprocal links to and from each term (Effective Price ↔ List Price ↔ Price Rule ↔ Promotion ↔ Merchandiser). No definitional changes.
- [ ] T078 [P] Run the targeted focused run to verify no whole-suite coverage gate silently fires: `./mvnw -pl pricing-microservice -Dtest=PriceRuleResolverTests test`. Record the observed output in a task-close comment.
- [ ] T079 Run the module-scoped focused suite: `./mvnw -pl pricing-microservice -am test` and `./mvnw -pl checkout-microservice -am test` and `./mvnw -pl api-gateway-microservice -am test`. All three must pass.
- [ ] T080 Run the CI-equivalent whole reactor tests: `./mvnw -B test`. All must pass.
- [ ] T081 Run the broadest suite (final authority): `./mvnw -B verify`. This is the release-build equivalent and is the merge gate for this feature.

**Checkpoint**: `./mvnw -B verify` green; every quickstart story validates through the local `docker-run.sh` stack; the five glossary terms and two decision files are searchable in `docs/`.

---

## Dependencies & Execution Order

### Phase dependencies

- **Phase 1 (Setup)** — no external dependencies; T007 (`resources/schema.cql`) is [P] because it touches a file no other setup task touches.
- **Phase 2 (Foundational)** — depends on Phase 1. **Blocks all user-story phases.** T010–T015 and T017 are [P] with each other (distinct files); T008 must precede T009 (application class before config).
- **Phase 3 (US1)** — depends on Phase 2. Independently testable checkpoint delivers MVP.
- **Phase 4 (US2)** — depends on Phase 2 for entities and Phase 3 for the gateway triad (T032). Otherwise independent of US3, US4, US5.
- **Phase 5 (US3)** — depends on Phase 2 for entities and Phase 3 for the pricing service to call. Independent of US2 and US4 (does not require batch reads or degradation).
- **Phase 6 (US4)** — depends on Phase 3 (pricing service exists) and Phase 5 (checkout's `PricingRestClient` exists in T049) for T060/T062.
- **Phase 7 (US5)** — depends on Phase 3 (rule writes exist and produce history entries via T067).
- **Phase 8 (Polish)** — depends on all preceding phases the team commits to shipping.

### Within-phase dependencies

- Within US1: T023/T024 (repositories) → T025 (resolver) → T026 (service) → T030/T031 (controllers) → T032 (gateway triad).
- Within US2: T035 → T036 (batch controller); T041/T042 (gateway wiring) depend on T032 from US1.
- Within US3: T047 (DDL) → T048 (entity fields) → T051 (checkout service change); T049/T050 can start in parallel with T047/T048.
- Within US4: T059 → T061 (contributor reads the client's mode); T060 → T062.
- Within US5: T067 (write path emits history) enables T068 (query service) enables T069 (controller) enables T070 (gateway wiring).

### Parallel opportunities

- Phase 2 [P] tasks: T010, T011, T012, T013, T014, T015, T017 — seven parallel workers possible.
- Phase 3 tests (T018–T022) all [P]. Repositories T023/T024 [P] with each other.
- Phase 4 ProductMetadata edits (T037–T040) are on four distinct files — fully parallel.
- Phase 5 tests (T045/T046) [P]. T049/T050 [P] with T047.
- Phase 6 tests (T057/T058) [P] with each other; contributors (T061/T062) [P] with each other.
- Phase 7 tests (T065/T066) [P].
- Phase 8 doc tasks (T073/T074/T075/T078) [P] — different files.

Once Phase 2 completes, US1 → US2/US3 can proceed in parallel by different developers because they touch different modules (US2 fans out into gateway + UI; US3 is checkout-focused). US4 requires US3 for T060/T062 but its cache/actuator work in the gateway (T059/T061) can start earlier if a mocked checkout client is stubbed.

---

## Parallel example: Phase 2 foundational

```
T010 (test resources application-test.yml)
T011 (domain enums)
T012 (PriceRule)
T013 (PriceRuleByScope)
T014 (history entities)
T015 (EffectivePrice DTO)
T017 (two decision files)
```

All seven can be picked up by up to seven contributors concurrently — they land in distinct files, none references another.

## Parallel example: Phase 4 ProductMetadata carrier updates

```
T037 (products ProductMetadata.effectivePrice)
T038 (checkout ProductMetadata.effectivePrice)
T039 (gateway ProductMetadata.effectivePrice)
T040 (react-ui ProductMetadata.effectivePrice)
```

Four independent module files. One PR per file if preferred.

---

## Implementation strategy

### MVP first (User Story 1 only)

1. Phase 1 (Setup) — reactor and schema land, nothing behavioral yet.
2. Phase 2 (Foundational) — module boots, glossary + decision docs merged.
3. Phase 3 (US1) — merchandiser CRUD + effective-price read, verified through the quickstart Story 1 walk.
4. **STOP. Demo.** MVP delivered: pricing changes without redeploy.

### Incremental delivery (recommended)

1. MVP as above.
2. Add US2 (Phase 4) → parity across surfaces demoed via quickstart Story 2.
3. Add US3 (Phase 5) → order-line snapshot demoed via quickstart Story 3. Now the Principle II invariants are behaviorally covered.
4. Add US4 (Phase 6) → graceful degradation demoed via quickstart Story 4 (`docker stop pricing-microservice`).
5. Add US5 (Phase 7) → history query demoed via quickstart Story 5.
6. Phase 8 (Polish) → broadest suite green, docs current.

### Parallel team strategy

With three developers after Phase 2:

- Dev A: US1 (Phase 3) → US4 gateway pieces (T059, T061, T063).
- Dev B: US2 (Phase 4) starting once T032 lands.
- Dev C: US3 (Phase 5) → US4 checkout pieces (T060, T062, T063).

Then whichever developer finishes first picks up US5 (Phase 7) and Polish.

---

## Notes

- [P] tasks touch distinct files and have no dependencies on any incomplete task.
- [Story] label maps back to spec.md user stories US1–US5.
- Every user story is independently testable via its own quickstart section.
- Behavioral tests are required (Principle V, [research.md § R-8](research.md#r-8-testing-shape)). The one context-load smoke test in `pricing-microservice` (created implicitly by `@SpringBootTest` in T022) is not sufficient by itself for new behavior — it must be paired with the resolver/service tests.
- Do not add a JaCoCo `check` goal; per [research.md § R-8](research.md#r-8-testing-shape), coverage floors belong to `specs/003-ci-test-pipeline/`.
- Do not touch `cronos.orders` or `cronos.product_inventory` except for the two additive columns in T047; any other change violates Principle II.
- Commit after each task or logical group. Task T081 (`./mvnw -B verify`) is the merge gate.
