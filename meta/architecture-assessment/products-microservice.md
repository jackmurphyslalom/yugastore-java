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
- Load/performance-testing status: no load-testing or simulation tooling (e.g. Gatling, JMeter,
  k6) was observed in this tier's `pom.xml` or source; no existing load benchmarks exist — none
  identified. Given catalog/ranking reads are a high-traffic path in the request flow, an initial
  agent-derived estimate would require at minimum a smoke-level load test (e.g. a k6 script
  hitting `ProductCatalogController`) before any capacity claim could be made.

## Recommendation

Should the duplicated domain model be extracted into a shared module, or is per-service
duplication an intentional microservice-isolation boundary here? Given the small size of this
codebase and the absence of any existing shared-library module in the Maven reactor (`pom.xml`
lists only the 7 top-level modules), keep duplication for now, but flag it in
`docs/context/gaps.md` if a real schema-drift incident occurs; introducing a shared library is a
bigger structural change than this assessment's scope.

**Size**: M — extracting a shared domain-model library, or documenting duplication as accepted,
both touch build tooling/process rather than one file.

**Risk**: Low-Medium if duplication is kept as-is (status quo, no code change); Medium-High if a
shared library is introduced later since it would touch build wiring in three services at once (a
near-wholesale-refactor for that specific change).

**Human time-on-task**: ~0.5 developer-day to write up the accepted-duplication decision; ~3-5
developer-days if a shared library extraction is later chosen.

**Agent time-on-task**: ~30 minutes for the decision write-up; ~2-3 hours to scaffold a shared
library extraction if pursued.

## 16-Factor Assessment

| # | Name | Score | Explanation | Gap to 5 | Quick Fix |
|---|---|---|---|---|---|
| I | Codebase | 2 | Independently buildable Maven module with its own `pom.xml`, but sharing one monorepo with all 6 other tiers is a real deviation from the strict 12-factor "one codebase, independently versioned" principle. | 3 | Extract shared domain classes into a common library module to remove duplication risk. |
| II | Dependencies | 4 | Dependencies are explicitly declared with pinned versions (Spring Boot 2.6.3, Java 17); transitive-dependency lock/CI-reproducibility was not independently audited. | 1 | Add automated dependency-vulnerability scanning (e.g. OWASP Dependency-Check) to CI. |
| III | Config | 3 | `application.yml` externalizes `spring.application.name`; YCQL connection details live in `YugabyteYCQLConfig`, but some connection defaults may still be code-level rather than fully externalized. | 2 | Externalize remaining YCQL connection defaults from code into `application.yml`/env vars. |
| IV | Backing services | 4 | YugabyteDB YCQL is cleanly abstracted behind Spring Data repositories (`ProductMetadataRepo`, `ProductRankingRepository`, `ProductInventoryRepository`), treated as an attached, swappable resource. | 1 | Add integration tests swapping in a test double to verify true backing-service swappability. |
| V | Build, release, run | 3 | Maven build produces a clean runnable jar, but release and run are manual, README-documented steps (`mvn spring-boot:run`, `docker-run.sh`) rather than an automated pipeline. | 2 | Automate release/run via a CI/CD pipeline instead of manual README steps. |
| VI | Processes | 5 | Fully stateless Spring Boot process; all catalog/ranking state is externalized to YugabyteDB, none held in process memory. | 0 | — |
| VII | Port binding | 5 | Self-contained, binds explicitly to port 8082, documented in `docs/architecture/overview.md`'s module table. | 0 | — |
| VIII | Concurrency | 4 | Stateless horizontal scaling via Eureka-discovered copies with no session affinity; in-process threading/request-capacity detail not independently verified. | 1 | Load-test concurrent request handling to confirm scaling assumptions. |
| IX | Disposability | 3 | Relies on Spring Boot's default startup/shutdown behavior; no custom graceful-shutdown hooks or hardened recovery paths observed. | 2 | Add custom graceful-shutdown hooks (e.g. `SmartLifecycle`) for in-flight request draining. |
| X | Dev/prod parity | 2 | No per-environment (`application-{env}.yml`) profile files observed; parity depends entirely on environment variables injected at deploy time, a fragile pattern. | 3 | Add per-environment `application-{env}.yml` profiles instead of relying solely on env vars. |
| XI | Logs | 4 | Relies on Spring Boot's default stdout logging, consistent with treating logs as an event stream; no structured logging or correlation IDs observed. | 1 | Add structured (JSON) logging with correlation IDs. |
| XII | Admin Processes | 2 | No dedicated admin/one-off-task classes exist; any admin action today would run as an ad hoc Spring Boot command rather than a first-class isolated process. | 3 | Add a dedicated admin/one-off task class (e.g. a Spring Boot CLI runner) for catalog maintenance. |
| XIII | Prompts as code | N/A | Traditional product catalog REST microservice with no AI/LLM component or prompt infrastructure observed. | N/A | — |
| XIV | State as a service | N/A | No AI/LLM conversational-state concern; this is a stateless product data service. | N/A | — |
| XV | Observability for non-determinism | N/A | Deterministic CRUD/REST microservice with no AI/LLM model inference or probabilistic output. | N/A | — |
| XVI | Trust & safety by design | N/A | No AI/LLM component or generative-content surface observed in this tier. | N/A | — |
