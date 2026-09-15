# Architecture Assessment: `checkout-microservice`

**Tier**: `checkout-microservice` | **Port**: 8086 | **Assessed**: 2026-09-15

## SCQA Overview

**Situation**: `checkout-microservice` (package `cronoscheckoutapi`) owns checkout, inventory, and
order placement. `CheckoutController` delegates to `CheckoutServiceImpl`, which coordinates
`ProductInventoryRepo`/`ProductInventoryRepository` (YCQL) alongside REST calls to
`ShoppingCartRestClient` and `ProductCatalogRestClient`, raising
`NotEnoughProductsInStockException` when stock is insufficient.

**Complication**: This tier calls out to two other microservices directly
(`ShoppingCartRestClient`, `ProductCatalogRestClient`) rather than only through
`api-gateway-microservice`, and it has both `YugabyteLocalConfig` and `YugabyteCloudConfig` — two
parallel connection-config paths whose selection logic is not obvious from the directory listing
alone.

**Question**: Does checkout calling other microservices directly (bypassing the gateway) violate
the "single external API surface" intent described for `api-gateway-microservice`, or is
service-to-service calling explicitly allowed for this internal orchestration case?

**Answer/recommendation**: This is an internal (not external-facing) call path, consistent with
`docs/architecture/overview.md`'s Checkout flow description; no evidence suggests it's
unintentional. Flag the dual local/cloud config classes as worth clarifying only if a real
environment-selection bug is observed — no evidence of a bug today.

## 16-Factor Assessment

| # | Name | Assessment |
|---|---|---|
| I | Codebase | Single Maven module (`checkout-microservice/`) in the shared reactor, its own `pom.xml`. |
| II | Dependencies | Declared explicitly via `pom.xml` (Spring Boot 2.6.3, Java 17, plus REST client dependencies for its two downstream calls). |
| III | Config | Two explicit config classes (`YugabyteLocalConfig`, `YugabyteCloudConfig`) suggest environment-specific config is handled in code-selected classes rather than purely `application.yml` values — a partial rather than full externalization of environment-varying config. |
| IV | Backing services | YugabyteDB (via `ProductInventoryRepo`) plus `cart-microservice` and `products-microservice` (via REST clients) are all treated as swappable attached resources. |
| V | Build, release, run | Same Maven build/release/run separation as the rest of the fleet. |
| VI | Processes | Stateless Spring Boot process; checkout/order state persists to YugabyteDB, not in-process memory. |
| VII | Port binding | Self-contained; binds to port 8086 per `docs/architecture/overview.md`. |
| VIII | Concurrency | Same stateless horizontal-scaling model as other tiers, registered via Eureka. |
| IX | Disposability | Standard Spring Boot start/stop; no custom graceful-shutdown hooks observed. |
| X | Dev/prod parity | The local/cloud config split (`YugabyteLocalConfig` vs `YugabyteCloudConfig`) is itself a deliberate parity mechanism, but also a source of drift risk if the two diverge in behavior beyond connection details. |
| XI | Logs | Relies on Spring Boot default stdout logging. |
| XII | Admin Processes | No dedicated admin/one-off task classes observed. |
| XIII | Prompts as code | N/A — no AI/LLM component observed in this tier. |
| XIV | State as a service | N/A — no AI/LLM component observed in this tier. |
| XV | Observability for non-determinism | N/A — no AI/LLM component observed in this tier. |
| XVI | Trust & safety by design | N/A — no AI/LLM component observed in this tier. |
