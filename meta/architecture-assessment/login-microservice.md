# Architecture Assessment: `login-microservice`

**Tier**: `login-microservice` | **Port**: 8085 | **Assessed**: 2026-09-15

## Context

`login-microservice` implements user/role authentication (`User`, `Role`, `UserRepository`,
`RoleRepository`, `UserServiceImpl`, `SecurityServiceImpl`, `UserDetailsServiceImpl`,
`UserController`) using Spring Security and Spring Data JPA. Evidence consulted:
`docs/architecture/overview.md`, `login-microservice/pom.xml`,
`login-microservice/src/main/resources/application.yml`, module root directory listing.

## Findings

- **WIP**, no `api-gateway` REST client wired yet. Per `docs/architecture/overview.md`'s module
  table, `login-microservice` has no corresponding REST client under
  `api-gateway-microservice/src/main/java/.../rest/clients/`, unlike every other downstream tier
  (products, cart, checkout all have a matching `*RestClient`). It cannot currently be reached
  through the single external API surface the rest of the system uses (confirmed by the absence
  of a login/user-domain client class — that directory only contains `ProductCatalogRestClient`,
  `ShoppingCartRestClient`, and `CheckoutRestClient`).
- Correction from an earlier assessment pass: this tier DOES have an `application.yml`, unlike
  what was previously recorded — it lives at the standard Spring Boot location
  `src/main/resources/application.yml`, whereas all 6 sibling tiers instead keep theirs at the
  module root. It sets `server.port: 8085` and a hardcoded local Postgres datasource
  (`jdbc:postgresql://127.0.0.1:5433/postgres`, empty password) with no environment-variable
  externalization (Config, score 3; Dev/prod parity, score 2).
- No `Dockerfile` exists for this module (unlike all 6 siblings), though a `manifest.yml` does
  (Build/release/run, score 3; Dev/prod parity, score 2).
- Admin actions run through normal request paths (`UserController`/`UserValidator`), with no
  separate one-off admin-task process (Admin Processes, score 1).

## Recommendation

Is finishing and wiring `login-microservice` into `api-gateway-microservice` in scope for the
current engagement, or does it remain intentionally out of scope for now? Treat this as
unresolved per `docs/context/gaps.md`'s existing entry ("`login-microservice` completion status
and integration plan") — do not assume completion status without human confirmation of engagement
scope; this assessment only records the finding, it does not complete or wire the service (per
this feature's plan.md constraints).

## 16-Factor Assessment

| # | Name | Score | Explanation |
|---|---|---|---|
| I | Codebase | 2 | Single Maven module tracked in the same monorepo/VCS as every other tier; the shared-repository pattern is a real deviation from the strict 12-factor "one codebase, independently versioned" principle. |
| II | Dependencies | 5 | Dependencies declared explicitly in `pom.xml` with pinned versions (`spring-boot-starter-web`, `-data-jpa`, `-security`, Spring Boot 2.6.3, Java 17); no vendored or implicit dependencies observed. |
| III | Config | 3 | `application.yml` exists (at `src/main/resources/`, unlike siblings' module-root convention) and externalizes port/datasource/logging settings from code, but the datasource URL and credentials are hardcoded to a local value rather than environment-variable driven. |
| IV | Backing services | 4 | Spring Data JPA repositories (`UserRepository`, `RoleRepository`) treat the relational store as a swappable attached backing service, consistent with the rest of the system's YugabyteDB usage; no confirmation the datasource URL itself is environment-swappable without a code/config change. |
| V | Build, release, run | 3 | Same Maven build/release/run separation as other tiers (`mvn -DskipTests package`); a `manifest.yml` exists for CF-style deployment, but no `Dockerfile` exists unlike all 6 sibling modules — a real fleet-parity gap in the release stage. |
| VI | Processes | 4 | Runs as a stateless Spring Boot process; user/role state persists via JPA to the datasource, not in-process memory. |
| VII | Port binding | 4 | `application.yml` explicitly declares `server.port: 8085`, confirming `docs/architecture/overview.md`'s documented port; no environment-variable override (e.g. `${SERVER_PORT:-8085}`) observed for deployment flexibility. |
| VIII | Concurrency | 3 | Same stateless-process scaling model as the rest of the fleet in design, but with no `api-gateway` wiring it carries zero live concurrent traffic today — design compliance without operational validation. |
| IX | Disposability | 3 | Standard Spring Boot start/stop lifecycle provides baseline disposability; no custom shutdown hooks or optimized resource cleanup observed. |
| X | Dev/prod parity | 2 | The datasource URL is hardcoded to a local Postgres instance with no environment-profile split, and no `Dockerfile` exists (only `manifest.yml`) — a weaker parity story than the other 6 tiers. |
| XI | Logs | 3 | Relies on Spring Boot default stdout logging (`logging.level.root: info` in `application.yml`); no structured logging or log-level-per-environment tuning observed. |
| XII | Admin Processes | 1 | User management flows entirely through normal request paths (`UserController`/`UserValidator`); no separate one-off admin-task process infrastructure exists. |
| XIII | Prompts as code | N/A | Traditional authentication service with no AI/LLM component observed. |
| XIV | State as a service | N/A | Conventional relational (JPA) user/role state; no AI/LLM conversational-state concern. |
| XV | Observability for non-determinism | N/A | Deterministic authentication logic with no AI/LLM model output. |
| XVI | Trust & safety by design | N/A | No AI/LLM component observed; `WebSecurityConfig`/`SecurityConfig` provide conventional auth security, distinct from AI-era trust & safety concerns. |
