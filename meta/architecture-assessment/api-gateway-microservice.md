# Architecture Assessment: `api-gateway-microservice`

**Tier**: `api-gateway-microservice` | **Port**: 8081 | **Assessed**: 2026-09-15

## SCQA Overview

**Situation**: `api-gateway-microservice` is the system's single external API surface. Its
`*Controller` classes (`ProductCatalogController`, `ShoppingCartController`) delegate to
`*ServiceRest` implementations (`ProductCatalogServiceRestImpl`, `ShoppingCartServiceRestImpl`,
`CheckoutServiceRestImpl`), which fan out via `rest/clients/*RestClient`
(`ProductCatalogRestClient`, `ShoppingCartRestClient`, `CheckoutRestClient`) to the downstream
microservices, resolved through Eureka. `react-ui` talks only to this tier.

**Complication**: No fallback/circuit-breaker code was found in any `*RestClient` — per
`docs/architecture/overview.md`, a downstream outage (e.g. `checkout-microservice` down) is not
currently handled gracefully by observed code; a caller would see a raw failure rather than a
degraded response. There is also no REST client for `login-microservice` (see that tier's WIP
finding).

**Question**: Should graceful degradation (timeouts, circuit breakers, fallback responses) be
added to these REST clients, and is that in scope for the current engagement?

**Answer/recommendation**: Treat as unresolved per `docs/context/gaps.md`'s existing "Graceful
degradation when a dependent service is down" entry — this assessment only records the absence of
such logic; it does not add resilience code (out of scope for a documentation-generation skill and
this feature's plan.md constraints).

## 16-Factor Assessment

| # | Name | Assessment |
|---|---|---|
| I | Codebase | Single Maven module (`api-gateway-microservice/`) in the shared reactor, its own `pom.xml`. |
| II | Dependencies | Declared explicitly via `pom.xml` (Spring Boot 2.6.3, Java 17, Eureka client, REST client dependencies). |
| III | Config | `application.yml` plus `CustomRestMvcConfiguration`/`SecurityConfiguration` hold environment-facing settings outside core business code. |
| IV | Backing services | Treats `products-microservice`, `cart-microservice`, and `checkout-microservice` as swappable attached resources via Eureka-resolved REST clients — no direct datastore access of its own. |
| V | Build, release, run | Same Maven build/release/run separation as the rest of the fleet. |
| VI | Processes | Stateless Spring Boot process; it holds no durable session/cart state itself, delegating entirely downstream. |
| VII | Port binding | Self-contained; binds to port 8081 per `docs/architecture/overview.md`, the single port `react-ui` proxies to. |
| VIII | Concurrency | Same stateless horizontal-scaling model as other tiers; as the single external entry point, it is also the fleet's most concurrency-sensitive tier under real load. |
| IX | Disposability | Standard Spring Boot start/stop; the missing circuit-breaker logic (Complication above) means an in-flight request during a downstream outage may fail slowly rather than fail fast. |
| X | Dev/prod parity | Single `application.yml`/`Dockerfile`/`manifest.yml` path, consistent with most other tiers. |
| XI | Logs | Relies on Spring Boot default stdout logging. |
| XII | Admin Processes | No dedicated admin/one-off task classes observed. |
| XIII | Prompts as code | N/A — no AI/LLM component observed in this tier. |
| XIV | State as a service | N/A — no AI/LLM component observed in this tier. |
| XV | Observability for non-determinism | N/A — no AI/LLM component observed in this tier. |
| XVI | Trust & safety by design | N/A — no AI/LLM component observed in this tier; conventional `SecurityConfiguration` is present but distinct from AI-specific trust & safety concerns. |
