# Architecture Assessment: `products-microservice`

**Tier**: `products-microservice` | **Port**: 8082 | **Assessed**: 2026-09-15

## Context

`products-microservice` owns the product catalog and rankings for the storefront. It exposes REST
endpoints via `ProductCatalogController`, backed by `ProductServiceImpl`,
`ProductRankingServiceImpl`, and `ProductInventoryServiceImpl`, and persists to YugabyteDB's YCQL
(Cassandra-compatible) API through `ProductMetadataRepo`, `ProductRankingRepository`, and
`ProductInventoryRepository`. It registers with `eureka-server-local` and is called only by
`api-gateway-microservice`, never directly by `react-ui`. Evidence consulted:
`docs/architecture/overview.md`, `products-microservice/pom.xml`, `products-microservice/application.yml`.

## Findings

- The service defines its own copies of shared domain classes (`Order`, `ProductMetadata`,
  `ProductRanking`, `ProductInventory`, `ProductRankingKey`, `CheckoutStatus`, `ImageInfo`) that
  are structurally duplicated in `checkout-microservice` and `api-gateway-microservice` rather
  than shared through a common library — any schema change must be applied identically in at
  least three places by hand.
- Sharing a single repository with all other tiers is a real deviation from the strict 12-factor
  Codebase principle (Codebase, score 2) even though the Maven module itself is independently
  buildable.
- Build/release/run stages exist but release and run are manual, README-documented steps rather
  than an automated pipeline (Build/release/run, score 3).
- No per-environment profile files were observed; parity depends on environment variables at
  deploy time only (Dev/prod parity, score 2).

## Recommendation

Should the duplicated domain model be extracted into a shared module, or is per-service
duplication an intentional microservice-isolation boundary here? Given the small size of this
codebase and the absence of any existing shared-library module in the Maven reactor (`pom.xml`
lists only the 7 top-level modules), keep duplication for now, but flag it in
`docs/context/gaps.md` if a real schema-drift incident occurs; introducing a shared library is a
bigger structural change than this assessment's scope.

## 16-Factor Assessment

| # | Name | Score | Explanation |
|---|---|---|---|
| I | Codebase | 2 | Independently buildable Maven module with its own `pom.xml`, but sharing one monorepo with all 6 other tiers is a real deviation from the strict 12-factor "one codebase, independently versioned" principle. |
| II | Dependencies | 4 | Dependencies are explicitly declared with pinned versions (Spring Boot 2.6.3, Java 17); transitive-dependency lock/CI-reproducibility was not independently audited. |
| III | Config | 3 | `application.yml` externalizes `spring.application.name`; YCQL connection details live in `YugabyteYCQLConfig`, but some connection defaults may still be code-level rather than fully externalized. |
| IV | Backing services | 4 | YugabyteDB YCQL is cleanly abstracted behind Spring Data repositories (`ProductMetadataRepo`, `ProductRankingRepository`, `ProductInventoryRepository`), treated as an attached, swappable resource. |
| V | Build, release, run | 3 | Maven build produces a clean runnable jar, but release and run are manual, README-documented steps (`mvn spring-boot:run`, `docker-run.sh`) rather than an automated pipeline. |
| VI | Processes | 5 | Fully stateless Spring Boot process; all catalog/ranking state is externalized to YugabyteDB, none held in process memory. |
| VII | Port binding | 5 | Self-contained, binds explicitly to port 8082, documented in `docs/architecture/overview.md`'s module table. |
| VIII | Concurrency | 4 | Stateless horizontal scaling via Eureka-discovered copies with no session affinity; in-process threading/request-capacity detail not independently verified. |
| IX | Disposability | 3 | Relies on Spring Boot's default startup/shutdown behavior; no custom graceful-shutdown hooks or hardened recovery paths observed. |
| X | Dev/prod parity | 2 | No per-environment (`application-{env}.yml`) profile files observed; parity depends entirely on environment variables injected at deploy time, a fragile pattern. |
| XI | Logs | 4 | Relies on Spring Boot's default stdout logging, consistent with treating logs as an event stream; no structured logging or correlation IDs observed. |
| XII | Admin Processes | 2 | No dedicated admin/one-off-task classes exist; any admin action today would run as an ad hoc Spring Boot command rather than a first-class isolated process. |
| XIII | Prompts as code | N/A | Traditional product catalog REST microservice with no AI/LLM component or prompt infrastructure observed. |
| XIV | State as a service | N/A | No AI/LLM conversational-state concern; this is a stateless product data service. |
| XV | Observability for non-determinism | N/A | Deterministic CRUD/REST microservice with no AI/LLM model inference or probabilistic output. |
| XVI | Trust & safety by design | N/A | No AI/LLM component or generative-content surface observed in this tier. |
