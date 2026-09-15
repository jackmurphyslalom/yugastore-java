# Architecture Assessment: `cart-microservice`

**Tier**: `cart-microservice` | **Port**: 8083 | **Assessed**: 2026-09-15

## Context

`cart-microservice` owns the shopping cart. `ShoppingCartController` delegates to
`ShoppingCartImpl`, backed by `ShoppingCartRepository` against YugabyteDB's YSQL (Postgres-
compatible) API and a `shopping_cart` table — the only tier in the system using YSQL rather than
YCQL. Evidence consulted: `docs/architecture/overview.md`, `cart-microservice/pom.xml`,
`SecurityConfiguration`, `resources/schema.sql`.

## Findings

- Being the sole YSQL consumer in an otherwise YCQL-dominant fleet means any cross-cutting
  datastore change (driver upgrade, connection-pool tuning, schema-migration tooling) must
  account for two different data-access stacks instead of one.
- Carts are conceptually session-scoped, yet there is no session-affinity guarantee — cart state
  relies entirely on the database being the source of truth rather than any in-process session
  mechanism (Concurrency, score 3).
- No dedicated admin/one-off task classes exist (Admin Processes, score 2).

## Recommendation

Is the YSQL-for-cart / YCQL-for-everything-else split a deliberate, durable architecture choice,
or an artifact of this being a smaller demo app where consistency wasn't prioritized? Record as
observed fact only — `resources/schema.sql` (YSQL) vs. `resources/schema.cql` (YCQL) confirms the
split is real and intentional at the schema level; no evidence in this pass suggests it's
accidental. No consolidation action recommended without a concrete driver for it.

## 16-Factor Assessment

| # | Name | Score | Explanation |
|---|---|---|---|
| I | Codebase | 3 | Own Maven module and `pom.xml`, tracked in VCS, supports independent builds; sharing one monorepo with 6 other tiers is a deviation from the strict 12-factor "one isolated codebase per repository" ideal. |
| II | Dependencies | 5 | Dependencies declared via `pom.xml` with strict version pinning (Spring Boot 2.6.3, Java 17, Postgres/YSQL driver) via the Spring Boot BOM; no system-classpath reliance. |
| III | Config | 4 | Eureka discovery URI is environment-variable-driven with fallback defaults; `SecurityConfiguration` cleanly separates security beans from business logic; full runtime config scope (DB, logging) not independently confirmed. |
| IV | Backing services | 4 | YugabyteDB YSQL accessed exclusively through `ShoppingCartRepository`, treated as a swappable attached resource rather than embedded connection logic; YSQL-over-YCQL rationale is not centrally documented. |
| V | Build, release, run | 4 | Standard Maven build/release/run separation consistent with the rest of the fleet. |
| VI | Processes | 5 | Fully stateless Spring Boot process; cart state is entirely externalized to YugabyteDB YSQL, avoiding the temptation to hold session-like cart data in process memory. |
| VII | Port binding | 5 | Self-contained, explicitly binds to port 8083, documented and independently deployable. |
| VIII | Concurrency | 3 | Stateless horizontal scaling via Eureka exists, but carts are conceptually session-scoped with no session-affinity guarantee — viable only because cart state lives entirely in the database, not confirmed to be fully resolved. |
| IX | Disposability | 3 | Standard Spring Boot start/stop only; no custom graceful-shutdown hooks observed for cleanup/resource draining. |
| X | Dev/prod parity | 4 | Single unified `application.yml`/`Dockerfile`/`manifest.yml` path with no per-environment profile split — one source of truth across environments, consistent with products/checkout. |
| XI | Logs | 3 | Logs to stdout via Spring Boot defaults; no structured logging, correlation IDs, or centralized log collection observed. |
| XII | Admin Processes | 2 | No dedicated admin/one-off task classes observed; a real compliance gap relative to the 12-factor admin-process model. |
| XIII | Prompts as code | N/A | Traditional shopping-cart REST microservice with no AI/LLM component observed. |
| XIV | State as a service | N/A | Conventional relational (YSQL) state; no AI/LLM conversational or context-window concern. |
| XV | Observability for non-determinism | N/A | Deterministic shopping-cart CRUD logic with no AI/LLM model output. |
| XVI | Trust & safety by design | N/A | No AI/LLM component or generative-content surface observed in this tier. |
