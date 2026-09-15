# Architecture Assessment: `cart-microservice`

**Tier**: `cart-microservice` | **Port**: 8083 | **Assessed**: 2026-09-15

## SCQA Overview

**Situation**: `cart-microservice` owns the shopping cart. `ShoppingCartController` delegates to
`ShoppingCartImpl`, backed by `ShoppingCartRepository` against YugabyteDB's YSQL (Postgres-
compatible) API and a `shopping_cart` table — the only tier in the system using YSQL rather than
YCQL.

**Complication**: Being the sole YSQL consumer in an otherwise YCQL-dominant fleet means any
cross-cutting datastore change (driver upgrade, connection-pool tuning, schema-migration tooling)
must account for two different data-access stacks instead of one.

**Question**: Is the YSQL-for-cart / YCQL-for-everything-else split a deliberate, durable
architecture choice, or an artifact of this being a smaller demo app where consistency wasn't
prioritized?

**Answer/recommendation**: Record as observed fact only — `resources/schema.sql` (YSQL) vs.
`resources/schema.cql` (YCQL) confirms the split is real and intentional at the schema level; no
evidence in this pass suggests it's accidental. No consolidation action recommended without a
concrete driver for it.

## 16-Factor Assessment

| # | Name | Assessment |
|---|---|---|
| I | Codebase | Single Maven module (`cart-microservice/`) in the shared reactor, its own `pom.xml`. |
| II | Dependencies | Declared explicitly via `pom.xml` (Spring Boot 2.6.3, Java 17, Postgres/YSQL driver). |
| III | Config | `application.yml` plus `SecurityConfiguration` hold environment-facing settings outside core business code. |
| IV | Backing services | YugabyteDB YSQL, accessed as an attached resource via `ShoppingCartRepository`, distinct from the YCQL path used by products/checkout. |
| V | Build, release, run | Same Maven build/release/run separation as the rest of the fleet. |
| VI | Processes | Stateless Spring Boot process; cart state persists to YugabyteDB YSQL, not in-process memory — notable since carts are inherently session-like data that could tempt in-process state, but this tier externalizes it correctly. |
| VII | Port binding | Self-contained; binds to port 8083 per `docs/architecture/overview.md`. |
| VIII | Concurrency | Same stateless horizontal-scaling model as other tiers, registered via Eureka. |
| IX | Disposability | Standard Spring Boot start/stop; no custom graceful-shutdown hooks observed. |
| X | Dev/prod parity | Single `application.yml`/`Dockerfile`/`manifest.yml` path, consistent with the products/checkout tiers' parity story. |
| XI | Logs | Relies on Spring Boot default stdout logging. |
| XII | Admin Processes | No dedicated admin/one-off task classes observed. |
| XIII | Prompts as code | N/A — no AI/LLM component observed in this tier. |
| XIV | State as a service | N/A — no AI/LLM component observed in this tier. |
| XV | Observability for non-determinism | N/A — no AI/LLM component observed in this tier. |
| XVI | Trust & safety by design | N/A — no AI/LLM component observed in this tier. |
