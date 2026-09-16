# Architecture Assessment: `checkout-microservice`

**Tier**: `checkout-microservice` | **Port**: 8086 | **Assessed**: 2026-09-15

## Context

`checkout-microservice` (package `cronoscheckoutapi`) owns checkout, inventory, and order
placement. `CheckoutController` delegates to `CheckoutServiceImpl`, which coordinates
`ProductInventoryRepo`/`ProductInventoryRepository` (YCQL) alongside REST calls to
`ShoppingCartRestClient` and `ProductCatalogRestClient`, raising
`NotEnoughProductsInStockException` when stock is insufficient. Evidence consulted:
`docs/architecture/overview.md`, `checkout-microservice/pom.xml`, its config classes.

## Findings

- This tier calls out to two other microservices directly (`ShoppingCartRestClient`,
  `ProductCatalogRestClient`) rather than only through `api-gateway-microservice`, with no
  observed circuit-breaker/timeout protection, creating a cascading-failure risk under load
  (Concurrency, score 2).
- Two parallel connection-config paths (`YugabyteLocalConfig`, `YugabyteCloudConfig`) whose
  selection logic is not obvious from the directory listing alone (Config, score 2; Dev/prod
  parity, score 2).
- No graceful-shutdown hooks or in-flight-request draining observed (Disposability, score 2).
- No dedicated admin/one-off task classes exist (Admin Processes, score 2).
- Load/performance-testing status: no load-testing or simulation tooling was observed for this
  tier; none identified. Given this tier calls two downstream services synchronously with no
  circuit breaker, an agent-derived initial concern (not a measured estimate) is that concurrent
  load could amplify latency from either downstream call into cascading timeouts — a real load
  test would be needed to quantify this.

## Recommendation

Does checkout calling other microservices directly (bypassing the gateway) violate the "single
external API surface" intent described for `api-gateway-microservice`, or is service-to-service
calling explicitly allowed for this internal orchestration case? This is an internal
(not external-facing) call path, consistent with `docs/architecture/overview.md`'s Checkout flow
description; no evidence suggests it's unintentional. Flag the dual local/cloud config classes as
worth clarifying only if a real environment-selection bug is observed — no evidence of a bug
today.

**Size**: M — adding circuit-breaker/timeout wrapping to two REST clients plus consolidating the
local/cloud config split.

**Risk**: Medium. Touches two live call paths (`ShoppingCartRestClient`,
`ProductCatalogRestClient`); a poorly-tuned timeout could introduce new failures rather than
removing them, though this is not a wholesale refactor.

**Human time-on-task**: ~2-3 developer-days to add Resilience4j wrapping and test both failure
paths.

**Agent time-on-task**: ~2-4 hours to scaffold the circuit-breaker wiring and fallback stubs.

## 16-Factor Assessment

| # | Name | Score | Explanation | Gap to 5 | Quick Fix |
|---|---|---|---|---|---|
| I | Codebase | 4 | Own Maven module and `pom.xml`, tracked in unified version control alongside other tiers, independently versionable/buildable/deployable as a distinct artifact despite the shared monorepo. | 1 | Consider a dedicated repo/module boundary if independent release cadence becomes a need. |
| II | Dependencies | 4 | Explicit, version-pinned dependency declaration via `pom.xml` (Spring Boot 2.6.3, Java 17) plus explicit REST client dependencies for cart/products calls; no dependency-conflict or security-scanning evidence reviewed. | 1 | Add dependency-vulnerability scanning to CI. |
| III | Config | 2 | Environment-varying config is selected via code (`YugabyteLocalConfig` vs `YugabyteCloudConfig`) rather than being fully externalized, which is a deviation from strict 12-factor config separation. | 3 | Consolidate the local/cloud config selection into a documented, externally-driven profile choice. |
| IV | Backing services | 4 | YugabyteDB, `cart-microservice`, and `products-microservice` are all abstracted behind repository/REST-client layers as swappable attached resources; runtime-swap behavior not independently confirmed. | 1 | Add contract tests against `ShoppingCartRestClient`/`ProductCatalogRestClient` to verify swappability. |
| V | Build, release, run | 4 | Clear Maven build / Docker+manifest.yml release / manual run separation consistent with the rest of the fleet; manual run steps stop this short of full automation. | 1 | Automate the manual run step via CI/CD. |
| VI | Processes | 5 | Fully stateless Spring Boot process; checkout/order state is externalized entirely to YugabyteDB via repository abstractions, none held in process memory. | 0 | — |
| VII | Port binding | 4 | Self-contained, binds explicitly and documented to port 8086; no external app-server dependency. | 1 | Document/verify port override via env var for deployment flexibility. |
| VIII | Concurrency | 2 | Stateless horizontal scaling exists, but synchronous calls to two downstream services with no circuit-breaker/timeout protection create cascading-failure risk under concurrent load. | 3 | Add circuit breakers/timeouts (e.g. Resilience4j) around both downstream REST clients. |
| IX | Disposability | 2 | Standard Spring Boot start/stop only; no graceful-shutdown hooks or in-flight-request draining observed for stock-exception or shutdown scenarios. | 3 | Add graceful-shutdown hooks and in-flight-request draining. |
| X | Dev/prod parity | 2 | The local/cloud config split is a deliberate parity mechanism but a real drift-risk source if the two implementations diverge beyond connection details. | 3 | Clarify and document the local/cloud config selection mechanism to reduce drift risk. |
| XI | Logs | 3 | Logs route to stdout per 12-factor convention via Spring Boot defaults, but no structured logging, correlation IDs, or custom routing observed. | 2 | Add structured logging with correlation IDs. |
| XII | Admin Processes | 2 | No dedicated admin/one-off task classes observed; maintenance/admin work would be ad hoc today. | 3 | Add a dedicated admin/one-off task class for order/inventory maintenance. |
| XIII | Prompts as code | N/A | Traditional REST-based order-orchestration microservice with no AI/LLM integration observed. | N/A | — |
| XIV | State as a service | N/A | No AI/LLM conversational state concern; order state is conventional relational/YCQL data. | N/A | — |
| XV | Observability for non-determinism | N/A | Deterministic checkout/order orchestration logic with no AI/LLM model output. | N/A | — |
| XVI | Trust & safety by design | N/A | No AI/LLM component or generative-content surface observed; this tier handles payment/order logic deterministically. | N/A | — |
