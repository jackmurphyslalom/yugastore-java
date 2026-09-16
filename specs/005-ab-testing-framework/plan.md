# Implementation Plan: A/B Testing / Experimentation Framework

**Branch**: `005-ab-testing-framework` | **Date**: 2026-09-16 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from [specs/005-ab-testing-framework/spec.md](spec.md)

## Summary

Externalize ranking and UX experiment behavior into a new **`config-server-microservice`** (Spring Cloud Config Server, native/filesystem-backed) so an experiment owner can change or retire a global runtime toggle — with `products-microservice`, `checkout-microservice`, and `react-ui` (via `api-gateway-microservice`) picking up the new value within a documented propagation window, with zero rebuild/redeploy/restart.

Approach (validated in [research.md](research.md)):

1. **New Spring Boot 2.6.3 module** (`config-server-microservice`) using `spring-cloud-config-server` + `spring-cloud-starter-netflix-eureka-client` — both already managed by the existing `spring-cloud.version` (`2021.0.0`) BOM every module imports today, so no new dependency family is introduced (FR-001).
2. **Native (filesystem) config backend**: a `config-repo/application.yml` under the new module holds the shared toggle namespace (`experiment.ranking-strategy`, `experiment.ux-variant`, …) served to every client via Spring Cloud Config's built-in `/{application}/{profile}` endpoint. The native profile re-reads the file on every request, so edits are visible immediately — no config-server restart needed for a value to become current (supports FR-003, FR-008).
3. **Small internal-only write surface** on `config-server-microservice` itself (`ExperimentToggleAdminController`): validates a submitted key/value against a documented per-key allow-list before writing it into `config-repo/application.yml`, rejecting invalid values with a specific reason and leaving the previous value in effect (FR-004). This endpoint is reachable only inside the Docker/localhost network — never through `api-gateway-microservice` — satisfying FR-009 (API/config-file-only, infrastructure-layer authorization) and FR-010 (config source is internal-only). It also appends a `{key, previousValue, newValue, changedAt}` entry to `config-repo/toggle-history.json`, giving FR-006 ("since when did this take effect") and Story 3 traceability without a database.
4. **Consumer read path**:
   - `products-microservice` and `checkout-microservice` add `spring-cloud-starter-config` and `spring.config.import=optional:configserver:` (Spring Boot 2.4+/Spring Cloud 2021.0.0 import mechanism, no new bootstrap mechanism), plus a small `@Scheduled` poller that calls `ContextRefresher.refresh()` on a fixed interval — this is the documented propagation mechanism for FR-003 (see [research.md R-2](research.md#r-2-propagation-mechanism)).
   - `react-ui` has no Spring context, so it cannot read Config Source directly; per Principle I (Gateway-Only Service Boundary) it must not call `config-server-microservice` directly anyway. `api-gateway-microservice` gets a new fan-out triad — `ExperimentToggleController` → `ExperimentToggleServiceRest[Impl]` → `ExperimentToggleRestClient` — mirroring the existing `ProductCatalog`/`ShoppingCart`/`Checkout` triads, so `react-ui` fetches current UX-toggle values from the gateway on page load like it fetches everything else.
5. **Last-known-good fallback (FR-007, Story 4)**: Spring Cloud Config Client's default behavior already keeps the last successfully applied `Environment` property set when a later refresh attempt fails — the scheduled poller only calls `ContextRefresher.refresh()` inside a try/catch that logs and skips on failure, so a slow/unavailable Config Source never clears already-applied values. A tier with **no** cached value yet (fresh deploy, Config Source down) falls back to a documented built-in default declared in that tier's own `application.yml`, consistent with the existing pattern of local `application.yml` defaults.
6. **Toggle validation ownership**: value-shape validation for FR-004 lives in `config-server-microservice`'s write endpoint (one documented allow-list per toggle key), not scattered across each consumer — consumers trust values already validated at write time, keeping `products-microservice`/`checkout-microservice`/gateway changes minimal.
7. **Glossary and decision records**: per FR-012, add **Experiment Toggle, Config Source, Experiment Owner, Propagation Window** to `docs/product/glossary.md`; per Principle IV, record a decision file for the config-backend choice (native filesystem vs. git-backed vs. Vault) and one for the propagation mechanism (scheduled poll vs. Spring Cloud Bus).

## Technical Context

**Language/Version**: Java 17 (root [pom.xml](../../pom.xml) `<java.version>17</java.version>`), matching every existing module.

**Primary Dependencies**: Spring Boot 2.6.3, Spring Cloud 2021.0.0 (`spring-cloud-config-server`, `spring-cloud-starter-config`, `spring-cloud-starter-netflix-eureka-client`) — all resolved from the `spring-cloud-dependencies` BOM already imported by every module (e.g. [products-microservice/pom.xml](../../products-microservice/pom.xml)). No new dependency family.

**Storage**: None for read-side toggle values (native/filesystem Config Server backend — a YAML file under `config-server-microservice/config-repo/`, not a database). A local `config-repo/toggle-history.json` file (append-only) is used for change history (FR-006 "since when"), not YugabyteDB — this feature does not touch `cronos.orders`, `cronos.product_inventory`, or any YCQL/YSQL table (Principle II unaffected).

**Testing**: JUnit 5 + Spring Boot Test (already on classpath in every module). Per Principle V, new work ships behavioral tests: config-read/refresh tests for the two consuming microservices, a validation-and-write test for `config-server-microservice`'s admin endpoint, and a gateway `@WebMvcTest` slice for the new `ExperimentToggleController`.

Test placement and naming (carry-forward from existing modules):

- Placement: `<module>/src/test/java/**` (standard Surefire layout).
- Naming: `*Tests.java` suffix (Surefire default; matches every existing test class).

Commands (final authority as the broadest suite is the full reactor):

- **Targeted (single test class)**: `./mvnw -pl config-server-microservice -Dtest=<ClassName> test`
- **Focused (module only, all its tests)**: `./mvnw -pl config-server-microservice -am test`
- **CI-equivalent (whole reactor, tests only)**: `./mvnw -B test`
- **Broadest — final authority (full reactor build + tests + package)**: `./mvnw -B verify`

None of these wraps its inner runner with a coverage `check` goal (no `jacoco:check` goal is bound in any module's `pom.xml` today), so they can be run independently without silently importing a whole-suite gate from a wrapper script.

**Target Platform**: Localhost only, per ratified [ADR-0001](../../docs/architecture/adr/0001-deployment-target-localhost.md). Runnable via [docker-run.sh](../../docker-run.sh) (new stanza for `config-server-microservice`) or per-service `mvn spring-boot:run`.

**Project Type**: JVM microservice reactor (`pom.xml` at repo root, `<packaging>pom</packaging>`, `<modules>` list). Adding one new module; modifying three existing ones (`products-microservice`, `checkout-microservice`, `api-gateway-microservice`) plus `react-ui` (new fetch call to the gateway).

**Performance Goals**: SC-001 (toggle change visible on storefront in under 5 minutes end-to-end, zero engineering actions). Plan target: consumer poll interval of 30–60 seconds (configurable), well inside the 5-minute SC-001 budget, and native-profile config reads with no hard latency budget beyond "fast enough to not be user-visible" since consumers cache the last-read value in memory.

**Constraints**:

- Localhost-only (no cloud config service, no SaaS feature-flag product).
- Must not touch `cronos.orders` or `cronos.product_inventory` (Principle II) — this feature is entirely additive to the read/rendering path (FR-013).
- Must not add a direct microservice-to-microservice or `react-ui`-to-`config-server-microservice` bypass of the gateway for shopper-facing paths (Principle I). `products-microservice`/`checkout-microservice` reading Config Source directly via Eureka is the same peer-discovery pattern already used elsewhere in the reactor (internal-reactor call, not a new external surface).
- Must add durable glossary entries for Experiment Toggle, Config Source, Experiment Owner, Propagation Window (Principle III / FR-012).
- Must record decision files under `docs/decisions/` for the config-backend and propagation-mechanism choices (Principle IV).
- Must not introduce a `login-microservice` dependency (constitution Deployment & Scope Boundaries; FR-009 resolution keeps authorization infrastructure-layer-only for this iteration).

**Scale/Scope**: A small, fixed set of global toggles (ranking-strategy, one or two UX variant flags) — not a growing per-shopper bucketing system (FR-011 explicitly excludes per-shopper randomized assignment). Change rate: infrequent, human-driven (experiment owners), not a high-frequency system.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Evaluated against [constitution v1.0.1](../../.specify/memory/constitution.md), ratified 2026-09-15.

| Principle | Applies? | Assessment | Evidence |
|---|---|---|---|
| **I — Gateway-Only Service Boundary** | Yes | ✅ Pass. `react-ui` reaches experiment-toggle values only through a new `api-gateway-microservice` triad (`ExperimentToggleController` → `ExperimentToggleServiceRest[Impl]` → `ExperimentToggleRestClient`), mirroring the existing three triads. `products-microservice`/`checkout-microservice` reading `config-server-microservice` directly via Eureka is an internal-reactor peer call, the same pattern `checkout-microservice → products-microservice` already uses. `config-server-microservice` itself registers with `eureka-server-local` like every other module and is never called directly by `react-ui` or an external client. | Existing pattern: [api-gateway-microservice/.../rest/clients/](../../api-gateway-microservice/src/main/java/com/yugabyte/app/yugastore/rest/clients/); [checkout-microservice's peer client](../../checkout-microservice/src/main/java/com/yugabyte/app/yugastore/cronoscheckoutapi/rest/clients/ProductCatalogRestClient.java). |
| **II — Consistency-Sensitive Data Paths** | Yes | ✅ Pass. Zero changes to `cronos.orders` or `cronos.product_inventory`, and no YCQL/YSQL schema change at all — the Config Source backend is a filesystem, not YugabyteDB. `CheckoutServiceImpl`'s stock-check/order-write path is untouched; toggle reads only affect ranking/UX rendering (FR-013). | [resources/schema.cql](../../resources/schema.cql) unchanged by this feature. |
| **III — Canonical Terminology** | Yes | ✅ Pass (delivery-gated). Plan requires adding **Experiment Toggle, Config Source, Experiment Owner, Propagation Window** to [docs/product/glossary.md](../../docs/product/glossary.md) as part of `/speckit.tasks` output. | Constitution Principle III; [docs/product/glossary.md](../../docs/product/glossary.md). |
| **IV — Context-Grounded Change** | Yes | ✅ Pass. This plan and [research.md](research.md) cite concrete evidence (root/module `pom.xml`, `application.yml`, `docs/context/gaps.md`, ADR-0001, existing gateway triad pattern) for every decision. Two decision files are recorded (config backend choice, propagation mechanism). | Constitution Principle IV; [docs/context/gaps.md](../../docs/context/gaps.md) (existing "Rapid experimentation / A/B testing" gap this feature resolves). |
| **V — Incremental Test Hardening** | Yes | ✅ Pass (delivery-gated). Plan mandates behavioral tests: a validation-and-write test for the admin endpoint (accept/reject cases), a config-refresh test per consuming microservice (value change reflected after simulated refresh), and a `@WebMvcTest` slice for the new gateway controller. No new context-load-only smoke test is added. | Constitution Principle V; [docs/architecture/overview.md](../../docs/architecture/overview.md) (existing low-signal smoke tests left intact per the grandfather clause). |
| **Deployment scope — localhost only** | Yes | ✅ Pass. No cloud config service, no SaaS feature-flag product. New module ships a `Dockerfile`, is added to [docker-run.sh](../../docker-run.sh), and runs via `mvn spring-boot:run` locally. No `manifest.yml` is added to the new module (cloud manifests are dormant repo-wide). | [ADR-0001](../../docs/architecture/adr/0001-deployment-target-localhost.md). |
| **`login-microservice` scope** | Yes | ✅ Pass. Toggle-write authorization (FR-009) is enforced at the infrastructure layer (endpoint not exposed through the gateway) rather than through `login-microservice`, per the spec's resolved Assumption. No new dependency on `login-microservice` is introduced. | Constitution Deployment & Scope Boundaries; spec.md Assumptions. |

**Gate result**: PASS. No principle is violated; no entries in the Complexity Tracking table are required.

### New decisions this plan records

Per Principle IV, durable decisions land as decision files. The following will be added by `/speckit.tasks`:

- `docs/decisions/2026-09-16-experiment-config-backend-choice.md` — native/filesystem-backed Spring Cloud Config Server (not git-backed, not Vault) for this iteration. See [research.md R-1](research.md#r-1-config-backend-choice).
- `docs/decisions/2026-09-16-experiment-propagation-mechanism.md` — scheduled client-side `ContextRefresher.refresh()` poll (not Spring Cloud Bus) as the propagation mechanism. See [research.md R-2](research.md#r-2-propagation-mechanism).
- A resolved entry in `docs/context/gaps.md`: the existing "Rapid experimentation / A/B testing" gap is marked resolved by this feature, with a note that per-shopper statistical bucketing (as opposed to global toggles) remains a distinct, unscoped future gap.

## Project Structure

### Documentation (this feature)

```text
specs/005-ab-testing-framework/
├── plan.md              # This file
├── research.md          # Phase 0 — config backend + propagation mechanism decisions
├── data-model.md        # Phase 1 — entities, invariants, file formats
├── contracts/           # Phase 1
│   ├── experiment-toggle-gateway.openapi.yaml   # Gateway REST surface (public, read-only)
│   ├── experiment-toggle-admin.openapi.yaml     # Internal-only write/query surface on config-server-microservice
│   └── config-repo-format.md                    # YAML/JSON shape of config-repo/application.yml and toggle-history.json
├── quickstart.md        # Phase 1 — how to run + validate the 4 stories locally
├── checklists/
│   └── requirements.md  # From /speckit.specify
└── tasks.md             # NOT created here — output of /speckit.tasks
```

### Source Code (repository root)

Concrete additions to the existing reactor. Nothing existing is removed.

```text
yugastore-java/
├── pom.xml                                                                        # + <module>config-server-microservice</module>
├── docker-run.sh                                                                  # + start block for config-server-microservice
├── docs/
│   ├── product/glossary.md                                                       # + Experiment Toggle, Config Source, Experiment Owner, Propagation Window
│   ├── decisions/
│   │   ├── 2026-09-16-experiment-config-backend-choice.md                        # new
│   │   └── 2026-09-16-experiment-propagation-mechanism.md                        # new
│   └── context/gaps.md                                                           # existing "Rapid experimentation" gap marked resolved
│
├── config-server-microservice/                                                    # NEW MODULE
│   ├── pom.xml                                                                    # inherits root; spring-cloud-config-server + eureka client
│   ├── Dockerfile
│   ├── application.yml                                                           # server port, eureka client, native profile, config-repo location
│   ├── config-repo/
│   │   ├── application.yml                                                       # shared toggle values (experiment.ranking-strategy, experiment.ux-variant, …)
│   │   └── toggle-history.json                                                   # append-only change log (key, previousValue, newValue, changedAt)
│   └── src/
│       ├── main/java/com/yugabyte/app/yugastore/configserver/
│       │   ├── ConfigServerApplication.java                                      # @EnableConfigServer + @EnableEurekaClient
│       │   ├── admin/
│       │   │   ├── ExperimentToggleAdminController.java                          # internal-only: GET current+history, PUT validated write
│       │   │   ├── ToggleAllowList.java                                          # per-key allowed-values definition (validation source of truth)
│       │   │   └── ToggleHistoryStore.java                                       # reads/appends config-repo/toggle-history.json
│       │   └── web/
│       │       └── ToggleValidationException.java + handler                     # human-readable rejection reason (FR-004)
│       └── test/java/com/yugabyte/app/yugastore/configserver/
│           ├── admin/ExperimentToggleAdminControllerTests.java                    # accept valid value, reject invalid value + reason, history recorded
│           └── ExperimentToggleAdminControllerWebMvcTests.java                    # slice test for the write/query endpoint
│
├── products-microservice/
│   ├── pom.xml                                                                    # + spring-cloud-starter-config
│   ├── application.yml                                                           # + spring.config.import=optional:configserver:..., + documented built-in ranking-strategy default
│   └── src/main/java/com/yugabyte/app/yugastore/
│       ├── config/ExperimentTogglePoller.java                                     # @Scheduled ContextRefresher.refresh(), swallow+log failures
│       └── service/impl/ProductRankingServiceImpl.java                            # + apply experiment.ranking-strategy to getProductsByCategory ordering
│
├── checkout-microservice/
│   ├── pom.xml                                                                    # + spring-cloud-starter-config
│   ├── application.yml                                                           # + spring.config.import=optional:configserver:..., documented default
│   └── src/main/java/com/yugabyte/app/yugastore/cronoscheckoutapi/
│       └── config/ExperimentTogglePoller.java                                     # same scheduled-refresh pattern as products-microservice
│
├── api-gateway-microservice/
│   └── src/main/java/com/yugabyte/app/yugastore/
│       ├── controller/ExperimentToggleController.java                             # GET /gateway/experiments/... (public, read-only)
│       ├── service/ExperimentToggleServiceRest.java + impl                        # orchestrates the peer call
│       └── rest/clients/ExperimentToggleRestClient.java                           # Eureka-discovered call to config-server-microservice
│
└── react-ui/frontend/src/
    └── (existing fetch layer)                                                     # + call to gateway's experiment-toggle endpoint on relevant page load
```

**Structure Decision**: Single JVM microservice reactor with one new module (`config-server-microservice`) plus targeted additions to three existing modules (`products-microservice`, `checkout-microservice`, `api-gateway-microservice`) and one new fetch call in `react-ui`. No new top-level project type — this follows the existing reactor's established `*-microservice` module + gateway-triad pattern (Option 1 "single project," reactor-style, not a generic web-app frontend/backend split, since the frontend/backend split already exists in this repo as `react-ui` + the reactor).

## Complexity Tracking

*No violations. Table intentionally empty — Constitution Check gate passed with no exceptions required.*

