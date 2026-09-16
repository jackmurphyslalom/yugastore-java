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
- Load/performance-testing status: no load-testing or simulation tooling was observed; none
  identified. Cart reads/writes are likely lower-traffic than catalog browsing, but no benchmark
  exists to confirm this assumption.

## Recommendation

Is the YSQL-for-cart / YCQL-for-everything-else split a deliberate, durable architecture choice,
or an artifact of this being a smaller demo app where consistency wasn't prioritized? Record as
observed fact only — `resources/schema.sql` (YSQL) vs. `resources/schema.cql` (YCQL) confirms the
split is real and intentional at the schema level; no evidence in this pass suggests it's
accidental. No consolidation action recommended without a concrete driver for it.

**Size**: S — documenting the YSQL/YCQL split as intentional, or S-M if session-affinity
guarantees are added.

**Risk**: Low. Purely additive/documentation for the split; any session-affinity work would be
scoped to this one service.

**Human time-on-task**: ~0.5 developer-day to document the split rationale; ~1-2 developer-days
if session-affinity hardening is pursued.

**Agent time-on-task**: ~30 minutes for documentation; ~1-2 hours to scaffold session-affinity
hardening if pursued.

## 16-Factor Assessment

| # | Name | Score | Explanation | Gap to 5 | Quick Fix |
|---|---|---|---|---|---|
| I | Codebase | 3 | Own Maven module and `pom.xml`, tracked in VCS, supports independent builds; sharing one monorepo with 6 other tiers is a deviation from the strict 12-factor "one isolated codebase per repository" ideal. | 2 | Consider a dedicated repo/module boundary for independent versioning. |
| II | Dependencies | 5 | Dependencies declared via `pom.xml` with strict version pinning (Spring Boot 2.6.3, Java 17, Postgres/YSQL driver) via the Spring Boot BOM; no system-classpath reliance. | 0 | — |
| III | Config | 4 | Eureka discovery URI is environment-variable-driven with fallback defaults; `SecurityConfiguration` cleanly separates security beans from business logic; full runtime config scope (DB, logging) not independently confirmed. | 1 | Externalize any remaining implicit config defaults. |
| IV | Backing services | 4 | YugabyteDB YSQL accessed exclusively through `ShoppingCartRepository`, treated as a swappable attached resource rather than embedded connection logic; YSQL-over-YCQL rationale is not centrally documented. | 1 | Document the YSQL-vs-YCQL rationale so it's not mistaken for an oversight. |
| V | Build, release, run | 4 | Standard Maven build/release/run separation consistent with the rest of the fleet. | 1 | Automate release/run via CI/CD. |
| VI | Processes | 5 | Fully stateless Spring Boot process; cart state is entirely externalized to YugabyteDB YSQL, avoiding the temptation to hold session-like cart data in process memory. | 0 | — |
| VII | Port binding | 5 | Self-contained, explicitly binds to port 8083, documented and independently deployable. | 0 | — |
| VIII | Concurrency | 3 | Stateless horizontal scaling via Eureka exists, but carts are conceptually session-scoped with no session-affinity guarantee — viable only because cart state lives entirely in the database, not confirmed to be fully resolved. | 2 | Confirm cart consistency behavior under concurrent writes with a targeted test. |
| IX | Disposability | 3 | Standard Spring Boot start/stop only; no custom graceful-shutdown hooks observed for cleanup/resource draining. | 2 | Add graceful-shutdown hooks for in-flight request draining. |
| X | Dev/prod parity | 4 | Single unified `application.yml`/`Dockerfile`/`manifest.yml` path with no per-environment profile split — one source of truth across environments, consistent with products/checkout. | 1 | Monitor for drift; add a per-env profile only if requirements diverge. |
| XI | Logs | 3 | Logs to stdout via Spring Boot defaults; no structured logging, correlation IDs, or centralized log collection observed. | 2 | Add structured logging with correlation IDs. |
| XII | Admin Processes | 2 | No dedicated admin/one-off task classes observed; a real compliance gap relative to the 12-factor admin-process model. | 3 | Add a dedicated admin/one-off task class for cart maintenance/cleanup. |
| XIII | Prompts as code | N/A | Traditional shopping-cart REST microservice with no AI/LLM component observed. | N/A | — |
| XIV | State as a service | N/A | Conventional relational (YSQL) state; no AI/LLM conversational or context-window concern. | N/A | — |
| XV | Observability for non-determinism | N/A | Deterministic shopping-cart CRUD logic with no AI/LLM model output. | N/A | — |
| XVI | Trust & safety by design | N/A | No AI/LLM component or generative-content surface observed in this tier. | N/A | — |
