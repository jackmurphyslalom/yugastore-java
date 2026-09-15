# Architecture Assessment: `products-microservice`

**Tier**: `products-microservice` | **Port**: 8082 | **Assessed**: 2026-09-15

## SCQA Overview

**Situation**: `products-microservice` owns the product catalog and rankings for the storefront.
It exposes REST endpoints via `ProductCatalogController`, backed by `ProductServiceImpl`,
`ProductRankingServiceImpl`, and `ProductInventoryServiceImpl`, and persists to YugabyteDB's
YCQL (Cassandra-compatible) API through `ProductMetadataRepo`, `ProductRankingRepository`, and
`ProductInventoryRepository`. It registers with `eureka-server-local` and is called only by
`api-gateway-microservice`, never directly by `react-ui`.

**Complication**: The service defines its own copies of shared domain classes (`Order`,
`ProductMetadata`, `ProductRanking`, `ProductInventory`, `ProductRankingKey`, `CheckoutStatus`,
`ImageInfo`) that are structurally duplicated in `checkout-microservice` and
`api-gateway-microservice` rather than shared through a common library — any schema change must
be applied identically in at least three places by hand.

**Question**: Should the duplicated domain model be extracted into a shared module, or is
per-service duplication an intentional microservice-isolation boundary here?

**Answer/recommendation**: Given the small size of this codebase and the absence of any existing
shared-library module in the Maven reactor (`pom.xml` lists only the 7 top-level modules), keep
duplication for now, but flag it in `docs/context/gaps.md` if a real schema-drift incident occurs;
introducing a shared library is a bigger structural change than this assessment's scope.

## 16-Factor Assessment

| # | Name | Assessment |
|---|---|---|
| I | Codebase | Single Maven module (`products-microservice/`) in the shared multi-module reactor, own `pom.xml`, tracked in the same repo/VCS as all other tiers. |
| II | Dependencies | Declared explicitly in `pom.xml` (Spring Boot 2.6.3 starters, Java 17); no system-level dependency assumed. |
| III | Config | `application.yml` sets only `spring.application.name`; YCQL connection details live in `YugabyteYCQLConfig`, allowing environment-specific values outside the code (though some connection defaults may still be code-level — verify against `YugabyteYCQLConfig` before assuming full externalization). |
| IV | Backing services | YugabyteDB YCQL is an attached, swappable resource accessed via Spring Data repositories (`ProductMetadataRepo`, `ProductRankingRepository`, `ProductInventoryRepository`). |
| V | Build, release, run | Maven build (`mvn -DskipTests package`) produces a runnable jar; release/run separation is manual (README-documented `mvn spring-boot:run` steps or `Dockerfile`/`docker-run.sh`). |
| VI | Processes | Runs as a stateless Spring Boot process; catalog/ranking state lives in YugabyteDB, not in-process memory. |
| VII | Port binding | Self-contained; binds to port 8082 per `docs/architecture/overview.md`'s module table. |
| VIII | Concurrency | Scaling model is running more copies of this stateless process behind Eureka service discovery; no in-process session affinity observed. |
| IX | Disposability | Spring Boot supports fast startup/shutdown; no custom graceful-shutdown hooks were observed in source, so default Spring Boot behavior applies. |
| X | Dev/prod parity | Single `application.yml` plus a Docker/`manifest.yml` path exist, but no dedicated per-environment profile files were observed in this module — parity depends on environment variables at deploy time. |
| XI | Logs | No custom log-routing/config was found; relies on Spring Boot's default stdout logging, consistent with treating logs as an event stream. |
| XII | Admin Processes | No dedicated admin/one-off-task classes were observed in this module; any admin actions would run as ad hoc Spring Boot commands today. |
| XIII | Prompts as code | N/A — no AI/LLM component observed in this tier. |
| XIV | State as a service | N/A — no AI/LLM component observed in this tier. |
| XV | Observability for non-determinism | N/A — no AI/LLM component observed in this tier. |
| XVI | Trust & safety by design | N/A — no AI/LLM component observed in this tier. |
