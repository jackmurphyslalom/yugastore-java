# Implementation Plan: Externalized Dynamic Pricing

**Branch**: `001-externalized-dynamic-pricing` (recommended; see Local Freshness below) | **Date**: 2026-09-15 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from [specs/001-externalized-dynamic-pricing/spec.md](spec.md)

## Summary

Externalize product pricing from the catalog into a new **`pricing-microservice`** so a merchandiser can change the effective price of a product or category — including scheduled promotions — and have that change take effect across storefront, cart, and checkout within minutes, with no engineering redeploy. The new service registers with Eureka, sits behind `api-gateway-microservice`, computes the **effective price** at read time from a `list_price` baseline + applicable `price_rule` rows in a new YCQL table under the existing `cronos` keyspace, and preserves order-line historical integrity by having checkout snapshot the resolved unit price onto each order line at commit time.

Approach (validated in [research.md](research.md)):

1. **New Spring Boot 2.6.3 module** (`pricing-microservice`) using the same parent POM and `YugabyteYCQLConfig` pattern that `products-microservice` uses today.
2. **New YCQL tables** `cronos.price_rules` and `cronos.price_rule_history` with `transactions = 'false'` (matching `cronos.products`), added additively to [resources/schema.cql](../../resources/schema.cql). No changes to `cronos.orders` or `cronos.product_inventory`.
3. **Gateway fan-out extension**: a fourth triad (`PricingController` → `PricingServiceRest[Impl]` → `PricingRestClient`) in `api-gateway-microservice`, mirroring the three existing pairs (`ProductCatalog`, `ShoppingCart`, `Checkout`). Merchandiser writes and shopper effective-price reads both go through this triad.
4. **Checkout integration**: at order placement, `checkout-microservice` calls the pricing service through `ProductCatalogRestClient`'s peer boundary (add a sibling `PricingRestClient` inside checkout, discovered via Eureka just like the existing catalog client) to resolve unit price, then snapshots that value onto the order line — leaving the transactional stock-check + order-write path unchanged. See research decision R-2 for the exact insertion point in `CheckoutServiceImpl` (the spec's Assumptions section refers to `calculatePrice()`, which does not exist; the actual method is `getTotal(Map<String, Integer>)` invoked from `checkout(String userId)`).
5. **Graceful degradation** (Story 4) is realized as: an in-service resolver cache of last-known effective prices per ASIN + a "list-price fallback" when the pricing dependency times out, plus an operator-visible `/actuator/info` flag surfacing "serving from pricing source | serving from fallback." No new resilience infrastructure — this stays coordinated with `specs/002-graceful-degradation-resilience` rather than duplicating it.
6. **Merchandiser surface** is API-only for this iteration through the gateway (`POST /pricing/rules`, `PUT /pricing/rules/{id}`, `DELETE /pricing/rules/{id}`, `GET /pricing/rules/history?asin=...`), guarded by a documented local-only `X-Merchandiser-Id` header + allow-list. No `react-ui` admin UI in this iteration; no `login-microservice` dependency. This resolves FR-015 with the escalation criteria captured in research decision R-5.
7. **A/B experimentation is out of scope** for this iteration but the rule-resolver design leaves a single interposition point (`PriceRuleResolver`) where a variant-selector can be inserted later without redesign. This resolves FR-016 with the escalation criteria captured in research decision R-6.

## Technical Context

**Language/Version**: Java 17 (per [Brewfile](../../Brewfile) `openjdk@17` and root [pom.xml](../../pom.xml) `<java.version>17</java.version>`).

**Primary Dependencies**: Spring Boot 2.6.3 (pinned in root pom), Spring Cloud 2021.0.0 (Netflix Eureka client, OpenFeign for peer calls or `RestTemplate` matching current pattern), `spring-boot-starter-data-cassandra`, `spring-cloud-starter-netflix-eureka-client` — matching what `products-microservice` uses today. No new dependency families introduced.

**Storage**: YCQL under the existing `cronos` keyspace on the same local Yugabyte instance the rest of the reactor uses. Two new tables — `cronos.price_rules` and `cronos.price_rule_history` — both with `WITH transactions = { 'enabled' : 'false' }` matching `cronos.products`. **No changes** to `cronos.orders` or `cronos.product_inventory` (both stay transactional). See [research.md R-3](research.md#r-3-pricing-store-choice) for evidence and alternatives.

**Testing**: JUnit 5 + Spring Boot Test (already on classpath in every module). Coverage is measured by `jacoco-maven-plugin` bound to `prepare-agent` + `report` in every module's `pom.xml` — no `check` goal is configured today, so **the Maven wrapper imposes no module-wide coverage floor** and is safe as a focused runner. Per Principle V, new work ships **behavioral** tests, not context-load smokes.

Test placement and naming (carry-forward from existing modules):

- Placement: `<module>/src/test/java/**` (standard Surefire layout).
- Naming: `*Tests.java` suffix (Surefire default; matches every existing test class).
- Test-profile config: mirror [products-microservice/src/test/resources/application-test.yml](../../products-microservice/src/test/resources/application-test.yml) which bypasses the `@Profile("local")` YCQL config for unit-style tests.

Commands (final authority as the broadest suite is the full reactor):

- **Targeted (single test class)**: `./mvnw -pl pricing-microservice -Dtest=<ClassName> test`
- **Focused (module only, all its tests)**: `./mvnw -pl pricing-microservice -am test`
- **CI-equivalent (whole reactor, tests only)**: `./mvnw -B test`
- **Broadest — final authority (full reactor build + tests + package)**: `./mvnw -B verify` (equivalent to what a release build runs; keeps all modules' behavior tests as gates).

None of these wraps its inner runner with a coverage `check` goal; they can be run independently without silently importing whole-suite gates from a wrapper script.

**Target Platform**: Localhost only, per ratified [ADR-0001](../../docs/architecture/adr/0001-deployment-target-localhost.md). Runnable via [docker-run.sh](../../docker-run.sh) (which will need a new stanza for `pricing-microservice`) or per-service `mvn spring-boot:run`.

**Project Type**: JVM microservice reactor (`pom.xml` at repo root with `<packaging>pom</packaging>` and a `<modules>` list). Adding one new module.

**Performance Goals**: SC-001 ("under 5 minutes end-to-end propagation"), SC-004 (">= 99% availability of storefront product list during a simulated 5-minute pricing outage via fallback"), and SC-005 ("<1 minute for change-history entry visibility"). Rule resolution itself has no hard latency budget in the spec; plan target is p95 < 50 ms for `GET /pricing/effective?asin=<asin>` on the shopper-read path, based on a single YCQL point lookup + in-memory rule evaluation.

**Constraints**:

- Localhost-only (no cloud services).
- Must not touch `cronos.orders` or `cronos.product_inventory` (Principle II).
- Must not add a direct microservice-to-microservice REST bypass of the gateway (Principle I). Peer-to-peer discovery via Eureka between `checkout-microservice` and `pricing-microservice` is permitted (mirroring the existing `checkout → products` peer call), because it is an internal-reactor call — the gateway remains the only external surface for shopper/merchandiser traffic.
- Must add durable glossary entries for Effective Price, List Price, Price Rule, Promotion, Merchandiser (Principle III / FR-012).
- Must record a decision file under `docs/decisions/` for the pricing-store choice (Principle IV).

**Scale/Scope**: Catalog scale is the existing product set (see [resources/products.json](../../resources/products.json) — thousands of ASINs, single-digit categories). Merchandiser change rate: unbounded in principle, but the spec's SC-001 ("under 5 minutes") is generous enough to permit a synchronous write + eventual read-side cache warm-up. Not a high-frequency trading system; solutioning assumes tens of writes/minute peak, hundreds of shopper reads/second peak.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Evaluated against [constitution v1.0.1](../../.specify/memory/constitution.md), ratified 2026-09-15.

| Principle | Applies? | Assessment | Evidence |
|---|---|---|---|
| **I — Gateway-Only Service Boundary** | Yes | ✅ Pass. All external merchandiser and shopper access is via `api-gateway-microservice` (new `PricingController` in the gateway plus `PricingRestClient`). `pricing-microservice` registers with `eureka-server-local` like every other module. The only microservice-to-microservice call is `checkout-microservice → pricing-microservice`, which is an internal-reactor peer call via Eureka discovery — the same pattern `checkout-microservice → products-microservice` already uses today via its own `ProductCatalogRestClient`. No `react-ui → pricing-microservice` direct call is introduced. | Existing pattern: [api-gateway-microservice/.../rest/clients/](../../api-gateway-microservice/src/main/java/com/yugabyte/app/yugastore/rest/clients/); checkout's existing peer client: [checkout-microservice/.../rest/clients/ProductCatalogRestClient.java](../../checkout-microservice/src/main/java/com/yugabyte/app/yugastore/cronoscheckoutapi/rest/clients/ProductCatalogRestClient.java). |
| **II — Consistency-Sensitive Data Paths** | Yes | ✅ Pass. Zero DDL or DML changes to `cronos.orders` or `cronos.product_inventory`. Stock check and `NotEnoughProductsInStockException` remain in the same place in `CheckoutServiceImpl.checkout(String userId)`. The **only** checkout-side change is that `getTotal(Map<String,Integer>)` (and/or its callers) resolves unit price through `PricingRestClient` before writing the order line, and the resolved value is **snapshotted onto the order line** (an additive column on the existing order table, or an additive column on the order-line side of the order write). See [research.md R-4](research.md#r-4-order-line-price-snapshot). | Method actually named `checkout` and `getTotal`, not `calculatePrice`: [checkout-microservice/.../service/CheckoutServiceImpl.java](../../checkout-microservice/src/main/java/com/yugabyte/app/yugastore/cronoscheckoutapi/service/CheckoutServiceImpl.java). |
| **III — Canonical Terminology** | Yes | ✅ Pass (delivery-gated). Plan explicitly requires adding **Effective Price, List Price, Price Rule, Promotion, Merchandiser** to [docs/product/glossary.md](../../docs/product/glossary.md) as part of implementation (see tasks generated by `/speckit.tasks`). `Cronos` remains an internal package/keyspace-only term; user-facing REST paths use `/pricing/*`, and merchandiser-facing entity names use "Price Rule" / "Promotion." No user-facing use of "Cronos." | Constitution Principle III; existing glossary at [docs/product/glossary.md](../../docs/product/glossary.md). |
| **IV — Context-Grounded Change** | Yes | ✅ Pass. This plan and [research.md](research.md) cite concrete evidence (schema.cql, ADR-0001, existing service classes, per-module POMs) for every decision. Two open questions in-repo relevant to this feature were checked: [docs/context/gaps.md](../../docs/context/gaps.md) is consulted, and one **new** unresolved question surfaces below and MUST be recorded in `docs/context/gaps.md` as part of tasks. Two ADR-worthy decisions are recorded as separate decision files (see below). | Constitution Principle IV; [docs/context/gaps.md](../../docs/context/gaps.md). |
| **V — Incremental Test Hardening** | Yes | ✅ Pass (delivery-gated). Plan mandates **behavioral** tests for the new module — resolver unit tests (no Spring context), WebMvc slice tests for `PricingController`, and a `@SpringBootTest` end-to-end test that changes a rule and asserts that a follow-up effective-price read reflects the change. No new context-load smoke test is added. Existing modules' smoke tests are left intact per Principle V's grandfather clause. | Constitution Principle V; existing test surface described in [docs/architecture/overview.md](../../docs/architecture/overview.md). |
| **Deployment scope — localhost only** | Yes | ✅ Pass. No cloud services, no SaaS feature flags. New module ships a `Dockerfile`, is added to [docker-run.sh](../../docker-run.sh), and runs via `mvn spring-boot:run` locally. Dormant `manifest.yml` is **not** added to the new module (no reason to reintroduce cloud manifests). | [ADR-0001](../../docs/architecture/adr/0001-deployment-target-localhost.md). |
| **`login-microservice` scope** | Yes | ✅ Pass. Plan does not require `login-microservice`. Merchandiser identification uses a documented local-only mechanism (see FR-015 resolution in [research.md R-5](research.md#r-5-merchandiser-admin-surface--auth-fr-015-resolution)). If merchandiser SSO is ever wanted, that is a separate `/speckit.specify` cycle for `login-microservice`, per Deployment & Scope Boundaries. | Constitution deployment/scope section. |

**Gate result**: PASS. No principle is violated; no entries in the Complexity Tracking table are required.

### New decisions this plan records

Per Principle IV, durable decisions land as decision files (not only in this plan). The following will be added by `/speckit.tasks`:

- `docs/decisions/2026-09-15-pricing-store-choice.md` — YCQL under `cronos` keyspace; two new tables with `transactions = 'false'`. See [research.md R-3](research.md#r-3-pricing-store-choice).
- `docs/decisions/2026-09-15-pricing-service-boundary.md` — new microservice + gateway triad; checkout snapshot-on-place preserves Principle II. See [research.md R-1](research.md#r-1-service-boundary--integration-shape) and [R-4](research.md#r-4-order-line-price-snapshot).
- A new entry in `docs/context/gaps.md`: "Merchandiser SSO — deferred; resolved locally for iteration 1, reopens when a `react-ui` merchandiser console is scoped."

## Project Structure

### Documentation (this feature)

```text
specs/001-externalized-dynamic-pricing/
├── plan.md              # This file
├── research.md          # Phase 0 — resolutions for FR-015, FR-016, FR-017 + pattern reuse
├── data-model.md        # Phase 1 — entities, invariants, tables, precedence rules
├── contracts/           # Phase 1
│   ├── pricing-rest.openapi.yaml   # Gateway REST surface (public)
│   ├── pricing-peer.openapi.yaml   # Checkout↔pricing internal REST surface (Eureka-discovered)
│   └── ycql-schema.md              # DDL for cronos.price_rules and cronos.price_rule_history
├── quickstart.md        # Phase 1 — how to run + validate the 5 stories locally
├── checklists/
│   └── requirements.md  # From /speckit.specify
└── tasks.md             # NOT created here — output of /speckit.tasks
```

### Source Code (repository root)

Concrete additions to the existing reactor. Nothing existing is removed.

```text
yugastore-java/
├── pom.xml                                                                  # + <module>pricing-microservice</module>
├── docker-run.sh                                                            # + start block for pricing-microservice
├── resources/
│   └── schema.cql                                                           # + cronos.price_rules, cronos.price_rule_history (additive)
├── docs/
│   ├── product/glossary.md                                                  # + Effective Price, List Price, Price Rule, Promotion, Merchandiser
│   ├── decisions/
│   │   ├── 2026-09-15-pricing-store-choice.md                               # new
│   │   └── 2026-09-15-pricing-service-boundary.md                           # new
│   ├── patterns/gateway-fanout.md                                           # new — codifies the *Controller/*ServiceRest[Impl]/*RestClient triad
│   └── context/gaps.md                                                      # + entry: "Merchandiser SSO deferred"
│
├── pricing-microservice/                                                    # NEW MODULE
│   ├── pom.xml                                                              # inherits root; same deps profile as products-microservice
│   ├── Dockerfile
│   ├── application.yml
│   └── src/
│       ├── main/java/com/yugabyte/app/yugastore/pricing/
│       │   ├── PricingServiceApplication.java                               # @SpringBootApplication + @EnableEurekaClient
│       │   ├── config/
│       │   │   └── YugabyteYCQLConfig.java                                  # mirrors products-microservice
│       │   ├── controller/
│       │   │   ├── PricingReadController.java                               # GET /pricing/effective, /pricing/effective/batch
│       │   │   ├── PricingRulesAdminController.java                         # POST/PUT/DELETE /pricing/rules
│       │   │   └── PricingHistoryController.java                            # GET /pricing/rules/history
│       │   ├── domain/
│       │   │   ├── PriceRule.java                                           # Entity (YCQL row)
│       │   │   ├── PriceRuleScope.java                                      # ASIN | CATEGORY
│       │   │   ├── PriceRuleKind.java                                       # LIST_PRICE_OVERRIDE | PROMOTION
│       │   │   ├── PriceRuleHistoryEntry.java
│       │   │   └── EffectivePrice.java                                      # DTO: asin, unit_price, source_rule_id or LIST_PRICE, resolved_at
│       │   ├── repository/
│       │   │   ├── PriceRuleRepository.java                                 # Spring Data Cassandra
│       │   │   └── PriceRuleHistoryRepository.java
│       │   ├── service/
│       │   │   ├── PriceRuleResolver.java                                   # PURE — no I/O, no Spring; testable without context
│       │   │   ├── EffectivePriceService.java                               # orchestrates: repo → resolver → EffectivePrice
│       │   │   ├── PriceRuleWriteService.java                               # validates + writes rule + history entry
│       │   │   └── MerchandiserAuthorizer.java                              # X-Merchandiser-Id + allow-list check
│       │   └── web/
│       │       └── ProblemDetailAdvice.java                                 # RFC 7807-style error bodies for merchandiser writes
│       └── test/java/com/yugabyte/app/yugastore/pricing/
│           ├── service/PriceRuleResolverTests.java                          # BEHAVIORAL — precedence, overlap, window boundaries (no Spring)
│           ├── service/EffectivePriceServiceTests.java                      # Repo mocked; asserts resolver call + DTO shape
│           ├── controller/PricingReadControllerWebMvcTests.java             # @WebMvcTest slice
│           ├── controller/PricingRulesAdminControllerWebMvcTests.java       # @WebMvcTest slice + validation
│           └── e2e/PricingEndToEndTests.java                                # @SpringBootTest — change rule then read reflects it
│
├── api-gateway-microservice/src/main/java/com/yugabyte/app/yugastore/
│   ├── controller/PricingController.java                                    # NEW: gateway REST surface for merchandiser + shopper
│   ├── service/{PricingServiceRest.java,impl/PricingServiceRestImpl.java}   # NEW: gateway service abstraction
│   ├── rest/clients/PricingRestClient.java                                  # NEW: fourth client (Ribbon/Eureka-discovered)
│   └── domain/ProductMetadata.java                                          # + effectivePrice: Double (nullable; falls back to list price)
│
├── checkout-microservice/src/main/java/com/yugabyte/app/yugastore/cronoscheckoutapi/
│   ├── rest/clients/PricingRestClient.java                                  # NEW: peer client, mirrors ProductCatalogRestClient shape
│   ├── service/CheckoutServiceImpl.java                                     # MODIFY: resolve unit price via PricingRestClient before order write
│   ├── domain/OrderLine.java                                                # MODIFY: add unit_price_at_order (immutable snapshot)
│   └── domain/ProductMetadata.java                                          # + effectivePrice: Double
│
├── products-microservice/                                                   # UNCHANGED — remains catalog source of truth; `price` stays as list price
│
├── cart-microservice/                                                       # UNCHANGED — cart holds ASIN + qty; effective price comes from gateway on render
│
└── react-ui/src/main/java/com/yugabyte/yugastore/ui/model/
    └── ProductMetadata.java                                                 # + effectivePrice: Double (nullable; used by React frontend for display)
```

**Structure Decision**: **Extend the existing multi-module Maven reactor** by adding a single new module, `pricing-microservice`, and by making surgical additions to `api-gateway-microservice`, `checkout-microservice`, and the four `ProductMetadata` copies. This is the only structure compatible with Principle I (all shopper/merchandiser traffic through `api-gateway-microservice`) and with the localhost-only deployment target (module boots via `mvn spring-boot:run` and via a new `docker-run.sh` stanza). No new top-level source tree is introduced — the "single project" / "web application" / "mobile + API" placeholder options from the template do not apply to this reactor.

The four `ProductMetadata` copies are a known duplication described in the preflight briefing and in [docs/architecture/overview.md](../../docs/architecture/overview.md); this plan does **not** consolidate them (that is a separate refactor with its own spec). It only adds a nullable `effectivePrice: Double` field to each copy, kept nullable so that consumers can degrade to `price` (list price) when the pricing service is unavailable — see FR-010.

## Local Freshness

- Preflight reports the working branch as `master` with `spec.md` + `checklists/requirements.md` staged. The other feature specs in this repo use `NNN-<short-name>` branches. **Recommended user action before `/speckit.tasks`**:

  ```zsh
  git switch -c 001-externalized-dynamic-pricing
  ```

  Session start is the sole owner of branch switches; the plan does not perform it automatically.

- Remote freshness relative to `origin/HEAD` is **unknown** — this plan is written from local tracking refs only, per the read-only preflight contract.

## Anchor mismatch noted for tasks.md

The spec's Assumptions block names `CheckoutServiceImpl.calculatePrice()`. That method does not exist in the current codebase. The actual entry points are `checkout(String userId)` and `getTotal(Map<String, Integer>)`. `/speckit.tasks` MUST retarget the "change the checkout unit-price source" work to `checkout(String userId)` (where `productCatalogRestClient.getProductDetails(asin)` is called) and to `getTotal(...)`; it MUST NOT create a `calculatePrice()` method just to match the spec. A spec-side follow-up task will correct the Assumptions bullet.

## Complexity Tracking

No constitution violations were identified. This table is intentionally empty.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| (none)    | (n/a)      | (n/a)                                |
