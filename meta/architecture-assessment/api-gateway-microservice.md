# Architecture Assessment: `api-gateway-microservice`

**Tier**: `api-gateway-microservice` | **Port**: 8081 | **Assessed**: 2026-09-15

## Context

`api-gateway-microservice` is the system's single external API surface. Its `*Controller` classes
(`ProductCatalogController`, `ShoppingCartController`) delegate to `*ServiceRest`
implementations (`ProductCatalogServiceRestImpl`, `ShoppingCartServiceRestImpl`,
`CheckoutServiceRestImpl`), which fan out via `rest/clients/*RestClient`
(`ProductCatalogRestClient`, `ShoppingCartRestClient`, `CheckoutRestClient`) to the downstream
microservices, resolved through Eureka. `react-ui` talks only to this tier. Evidence consulted:
`docs/architecture/overview.md`, `api-gateway-microservice/pom.xml`, `CustomRestMvcConfiguration`,
`SecurityConfiguration`.

## Findings

- No fallback/circuit-breaker code was found in any `*RestClient` — per
  `docs/architecture/overview.md`, a downstream outage (e.g. `checkout-microservice` down) is not
  currently handled gracefully by observed code; a caller would see a raw failure rather than a
  degraded response (Concurrency, score 3; Disposability, score 2).
- There is no REST client for `login-microservice` (see that tier's WIP finding).
- Logs rely on Spring Boot defaults with no structured logging, correlation IDs, or centralized
  aggregation (Logs, score 2); no dedicated admin/one-off task classes exist (Admin Processes,
  score 2).

## Recommendation

Should graceful degradation (timeouts, circuit breakers, fallback responses) be added to these
REST clients, and is that in scope for the current engagement? Treat as unresolved per
`docs/context/gaps.md`'s existing "Graceful degradation when a dependent service is down" entry —
this assessment only records the absence of such logic; it does not add resilience code (out of
scope for a documentation-generation skill and this feature's plan.md constraints).

## 16-Factor Assessment

| # | Name | Score | Explanation |
|---|---|---|---|
| I | Codebase | 4 | Single isolated Maven module with its own `pom.xml`, independently buildable and tracked in VCS; sharing a monorepo with 6 other tiers is a mild deviation from a dedicated-repo-per-service ideal. |
| II | Dependencies | 4 | Explicit, versioned dependency declarations (Java 17, Spring Boot 2.6.3, Spring Cloud 2021.0.0) via Maven; no evidence of additional hermetic-build/dependency-verification controls. |
| III | Config | 3 | Config is separated from business code via `application.yml` and dedicated `CustomRestMvcConfiguration`/`SecurityConfiguration` classes, but no evidence of environment-variable-driven profiles or secrets externalization was reviewed. |
| IV | Backing services | 4 | `products-microservice`, `cart-microservice`, and `checkout-microservice` are cleanly abstracted as swappable attached resources via Eureka-resolved REST clients, with no direct datastore access of its own. |
| V | Build, release, run | 5 | Maven's lifecycle cleanly separates build/release/run stages, consistent with fleet-wide conventions. |
| VI | Processes | 5 | Fully stateless; holds no durable session/cart state itself, delegating entirely downstream — exemplary share-nothing design. |
| VII | Port binding | 5 | Self-contained, binds explicitly to port 8081, the single port `react-ui` proxies to; documented and independently deployable. |
| VIII | Concurrency | 3 | Stateless horizontal scaling supports concurrent load distribution, but the absence of fallback/circuit-breaker code in any `*RestClient` leaves this concurrency-sensitive entry point vulnerable to cascading failures. |
| IX | Disposability | 2 | Standard Spring Boot start/stop mechanics exist, but missing circuit-breaker logic means requests can fail slowly during a downstream outage rather than failing fast and shedding load cleanly. |
| X | Dev/prod parity | 4 | Single `application.yml`/`Dockerfile`/`manifest.yml` path across environments, consistent with most other tiers, minimizing environment-specific surprises. |
| XI | Logs | 2 | Relies on Spring Boot default stdout logging with no structured logging, log-level configuration, correlation IDs, or centralized aggregation observed. |
| XII | Admin Processes | 2 | No dedicated admin/one-off task classes observed; falls short of a formal, versioned admin-process implementation. |
| XIII | Prompts as code | N/A | Spring Cloud Gateway-style routing/request-forwarding component with no AI/LLM integration or prompt management. |
| XIV | State as a service | N/A | Stateless routing/protocol-translation layer; state management is delegated entirely to backend microservices. |
| XV | Observability for non-determinism | N/A | Deterministic routing and fan-out logic via fixed downstream REST clients, no AI/LLM model output. |
| XVI | Trust & safety by design | N/A | No AI/LLM component observed; conventional `SecurityConfiguration` (authn/authz) is present but distinct from AI-era trust & safety concerns. |
