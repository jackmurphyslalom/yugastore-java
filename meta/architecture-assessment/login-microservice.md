# Architecture Assessment: `login-microservice`

**Tier**: `login-microservice` | **Port**: 8085 | **Assessed**: 2026-09-15

## SCQA Overview

**Situation**: `login-microservice` implements user/role authentication (`User`, `Role`,
`UserRepository`, `RoleRepository`, `UserServiceImpl`, `SecurityServiceImpl`,
`UserDetailsServiceImpl`, `UserController`) using Spring Security and Spring Data JPA.

**Complication**: **WIP**, no `api-gateway` REST client wired yet. Per
`docs/architecture/overview.md`'s module table, `login-microservice` has no corresponding REST
client under `api-gateway-microservice/src/main/java/.../rest/clients/`, unlike every other
downstream tier (products, cart, checkout all have a matching `*RestClient`). It cannot currently
be reached through the single external API surface the rest of the system uses.

**Question**: Is finishing and wiring `login-microservice` into `api-gateway-microservice` in
scope for the current engagement, or does it remain intentionally out of scope for now?

**Answer/recommendation**: Treat this as unresolved per `docs/context/gaps.md`'s existing entry
("`login-microservice` completion status and integration plan") — do not assume completion status
without human confirmation of engagement scope; this assessment only records the finding, it does
not complete or wire the service (per this feature's plan.md constraints).

## login-microservice WIP/Unwired Finding

`login-microservice` is **WIP**, no `api-gateway` REST client wired yet — confirmed by the
absence of a `login`/`user`-domain client class under
`api-gateway-microservice/src/main/java/.../rest/clients/` (that directory only contains
`ProductCatalogRestClient`, `ShoppingCartRestClient`, and `CheckoutRestClient`).

## 16-Factor Assessment

| # | Name | Assessment |
|---|---|---|
| I | Codebase | Single Maven module (`login-microservice/`) in the shared multi-module reactor; tracked in the same VCS as every other tier. |
| II | Dependencies | Declared explicitly in `pom.xml` (`spring-boot-starter-web`, `-data-jpa`, `-security`, Spring Boot 2.6.3, Java 17). |
| III | Config | No dedicated `application.yml` was found for this module (unlike the other 6 tiers) — configuration currently relies on Spring Boot defaults/embedded settings, a gap relative to the other tiers' externalized-config pattern. |
| IV | Backing services | Spring Data JPA repositories (`UserRepository`, `RoleRepository`) treat the relational store as an attached backing service, consistent with the rest of the system's YugabyteDB usage. |
| V | Build, release, run | Same Maven build/release/run separation as other tiers (`mvn -DskipTests package`), though it lacks a `Dockerfile`/`application.yml` seen in the other 6 modules — reduces parity with the rest of the fleet's release path. |
| VI | Processes | Runs as a Spring Boot process; user/role state persists via JPA, not in-process memory. |
| VII | Port binding | Documented as port 8085 per `docs/architecture/overview.md`'s module table (not independently re-verified here since no `application.yml` exists in this module to confirm it). |
| VIII | Concurrency | Same stateless-process scaling model as the rest of the fleet, in principle — but with no `api-gateway` wiring, it is not currently part of any live concurrent request path. |
| IX | Disposability | Standard Spring Boot start/stop; no custom shutdown hooks observed. |
| X | Dev/prod parity | Weaker than the other 6 tiers: no `application.yml`, `Dockerfile`, or `manifest.yml` was found for this module, so its deployment parity story is unverified/unproven relative to its siblings. |
| XI | Logs | Relies on Spring Boot default stdout logging; no custom log config observed. |
| XII | Admin Processes | `UserController`/`UserValidator` handle user management via normal request paths; no separate one-off admin-task class observed. |
| XIII | Prompts as code | N/A — no AI/LLM component observed in this tier. |
| XIV | State as a service | N/A — no AI/LLM component observed in this tier. |
| XV | Observability for non-determinism | N/A — no AI/LLM component observed in this tier. |
| XVI | Trust & safety by design | N/A — no AI/LLM component observed in this tier; note `WebSecurityConfig`/`SecurityConfig` do provide conventional auth security, distinct from AI-specific trust & safety concerns. |
