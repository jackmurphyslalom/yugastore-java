# Architecture Assessment: `eureka-server-local`

**Tier**: `eureka-server-local` | **Port**: 8761 | **Assessed**: 2026-09-15

## SCQA Overview

**Situation**: `eureka-server-local` is a Spring Cloud Netflix Eureka service registry
(`YugastoreEurekaServer`). Every other Spring Boot tier registers with it on startup and it must
be the first service started, per `docs/architecture/overview.md`'s Startup flow. Its own
`application.yml` disables self-registration (`registerWithEureka: false`,
`fetchRegistry: false`), consistent with running as a standalone registry rather than a peer.

**Complication**: A single-instance registry is a single point of failure for service discovery;
no peer-replication config was observed, so an outage here would break inter-service discovery
for the whole fleet even though each individual downstream service might otherwise be healthy.

**Question**: Is a single, non-replicated Eureka instance an acceptable risk for this
engagement's target deployment, or does resilience scope (see `docs/context/gaps.md`'s graceful
degradation entry) require a highly-available registry?

**Answer/recommendation**: Treat as unresolved pending the same graceful-degradation scoping
decision already logged in `docs/context/gaps.md` — do not add peer replication config
speculatively; record this as a related consideration if that gap is picked up later.

## 16-Factor Assessment

| # | Name | Assessment |
|---|---|---|
| I | Codebase | Single Maven module (`eureka-server-local/`) in the shared multi-module reactor; smallest tier by source file count (one class, `YugastoreEurekaServer`). |
| II | Dependencies | Declared explicitly via `pom.xml` (Spring Cloud Netflix Eureka Server starter, Spring Boot 2.6.3, Java 17). |
| III | Config | `application.yml` externalizes port and Eureka client behavior flags outside the code. |
| IV | Backing services | None — this tier has no datastore; it is itself the backing "directory" service other tiers depend on. |
| V | Build, release, run | Same Maven build/release/run separation as the rest of the fleet. |
| VI | Processes | Single stateless-from-the-outside registry process; in-memory registry state is expected and acceptable for this role, not treated as durable application state. |
| VII | Port binding | Self-contained; binds to port 8761 per `application.yml` and `docs/architecture/overview.md`. |
| VIII | Concurrency | Not designed to be horizontally scaled by running more copies without peer-awareness config (see Complication above) — a real deviation from the 12-factor concurrency model relative to the other 6 tiers. |
| IX | Disposability | Standard Spring Boot start/stop; because every other tier depends on it at startup, its own disposability is less forgiving than a downstream tier's. |
| X | Dev/prod parity | Single `application.yml`, `Dockerfile`, and `manifest.yml` exist; no separate `application-cloud.yml`-style split was found needing reconciliation for this assessment (there is a sibling `application-cloud.yml` file, suggesting some cloud-specific override does exist). |
| XI | Logs | Relies on Spring Boot default stdout logging. |
| XII | Admin Processes | No dedicated admin/one-off task classes observed; Eureka's own dashboard is the closest thing to an admin surface but is not custom code in this tier. |
| XIII | Prompts as code | N/A — no AI/LLM component observed in this tier. |
| XIV | State as a service | N/A — no AI/LLM component observed in this tier. |
| XV | Observability for non-determinism | N/A — no AI/LLM component observed in this tier. |
| XVI | Trust & safety by design | N/A — no AI/LLM component observed in this tier. |
