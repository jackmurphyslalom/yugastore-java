# Implementation Plan: CI Test Pipeline

**Branch**: `003-ci-test-pipeline` | **Date**: 2026-09-15 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from [specs/003-ci-test-pipeline/spec.md](spec.md)

## Summary

Deliver a GitHub Actions workflow (`.github/workflows/ci.yml`) that, on every push to any branch and every pull request against `master`, runs the full Maven reactor unit test suite, runs a new React UI test suite under `react-ui/frontend/`, and publishes Java and React code coverage reports as workflow artifacts in both HTML and machine-readable form. The plan raises the test floor per Constitution Principle V by adding meaningful behavior tests for the existing `api-gateway-microservice` controllers alongside the workflow, seeds an initial React UI test suite (currently zero test files), and adopts JaCoCo (Java) + `react-scripts`-built-in coverage (React) as the coverage tools. YugabyteDB-backed integration tests are excluded from CI (spec Clarification Q2); no deploy-adjacent CI is added (spec Clarification Q3); no external coverage service is used (spec Clarification Q4).

## Technical Context

**Language/Version**: Java 17 (reactor `pom.xml` line 22); JavaScript / Node 16.13.2 with npm 8.0.0 (already declared via `frontend-maven-plugin` in [react-ui/pom.xml](../../react-ui/pom.xml)); GitHub Actions workflow YAML.

**Primary Dependencies**: Spring Boot 2.6.3, Spring Cloud 2021.0.0 (reactor + module POMs); `spring-boot-starter-test` (already declared in every module POM — brings JUnit 5, Spring Test, Mockito, AssertJ); `react-scripts` 1.1.1 (`react-ui/frontend/package.json`); JaCoCo Maven plugin (new — added to reactor `pom.xml`); GitHub Actions core actions (`actions/checkout@v4`, `actions/setup-java@v4`, `actions/setup-node@v4`, `actions/upload-artifact@v4`).

**Storage**: N/A for the CI feature itself. Existing storage (`YCQL` for products/checkout/orders/inventory; `YSQL` for cart) is not exercised by CI — FR-014 excludes DB-backed integration tests from CI, so Java tests use mocked repositories.

**Testing**: JUnit 5 + Spring Boot Test (`MockMvc`, `@WebMvcTest`, `@MockBean`) for the Java reactor; `react-scripts test` (Jest + jsdom under the hood) for the React UI. Naming convention: Surefire runs `*Test.java` (unit / in-process only) in `mvn test`; any future DB-backed integration test MUST be named `*IT.java` so it stays out of Surefire and out of CI.

**Target Platform**: GitHub-hosted Linux runners (`ubuntu-latest`) for the CI workflow. Runtime targets of the code under test are unchanged (Java 17 JVM, browser for the React UI).

**Project Type**: Web application (frontend + backend). Backend = the seven-module Maven reactor at the repository root. Frontend = `react-ui/frontend/`.

**Performance Goals**: The workflow SHOULD complete in under ~15 minutes wall-clock on a `ubuntu-latest` runner for the P1 slice (reactor build + reactor unit tests + React UI test + coverage upload). This is a soft target, not a spec requirement.

**Constraints**:
- Must run on fork PRs without any repo secrets (FR-012); `actions/upload-artifact@v4` works with the auto-provisioned `GITHUB_TOKEN`, so no additional configuration is required.
- Must not gate merges on coverage (spec Clarification Q1) — coverage is report-only.
- Must not introduce deployment-adjacent jobs, extension points, or stubs (spec Clarification Q3 / FR-015).
- Must not add or change behavior in `login-microservice` (FR-017); its module builds and existing tests run as-is.
- Must use canonical terminology from [docs/product/glossary.md](../../docs/product/glossary.md) in workflow display names, job labels, and artifact names (FR-016 / Principle III): `api-gateway`, `Eureka`, `YCQL`, `YSQL`, `ASIN`. `Cronos` allowed only in code/package/keyspace references.

**Scale/Scope**:
- 7 Maven modules to build; 6 modules have existing `contextLoads()` smoke tests (`eureka-server-local`, `products-microservice`, `cart-microservice`, `checkout-microservice`, `api-gateway-microservice`, `react-ui`); `login-microservice` has no tests.
- ~1 React UI application under `react-ui/frontend/`, currently 0 test files.
- 1 new GitHub Actions workflow file.
- Java behavior test surface added by this feature: at least 3 new behavior tests on `api-gateway-microservice` (one per US4 acceptance scenario 1, satisfying SC-005), plus at least one behavior test per additional Java handler this feature explicitly touches.
- React UI test surface added by this feature: at least 3 test files (top-level app shell; one `api-gateway`-consuming component; one `ASIN`-rendering component — per FR-007 / SC-003).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-checked after Phase 1 design (see bottom of this section).*

Gates evaluated against [.specify/memory/constitution.md](../../.specify/memory/constitution.md) v1.0.0:

- **I. Gateway-Only Service Boundary** — PASS. New Java behavior tests target `api-gateway-microservice` controllers via `MockMvc` and do not call downstream microservices' REST endpoints directly from anything the UI or another microservice would call. The React UI test suite consumes only the `api-gateway` surface (or mocks of it), matching how the running UI behaves.
- **II. Consistency-Sensitive Data Paths** — PASS with a documented constraint. Because FR-014 excludes DB-backed integration tests from CI, the plan verifies the `cronos.orders` / `cronos.product_inventory` / `NotEnoughProductsInStockException` contract at the *service layer* using mocked `ProductInventoryRepo` and mocked `ShoppingCartRestClient` / `ProductCatalogRestClient`. The persisted-effect side of US4/AC-3 is asserted against the mock repository interactions; the real distributed-transaction guarantee remains covered by local/manual tests. This constraint is recorded in `research.md` and reproduced in `data-model.md`.
- **III. Canonical Terminology** — PASS. Workflow display name: `CI`. Jobs: `java-reactor`, `react-ui`, `java-coverage-report`, `react-coverage-report`. Artifact names: `jacoco-report`, `react-ui-coverage`. All human-facing text uses `api-gateway`, `Eureka`, `YCQL`, `YSQL`, `ASIN`. `Cronos` appears only in module/package/keyspace references (`checkout-microservice`'s package `cronoscheckoutapi`, keyspace `cronos.*`).
- **IV. Context-Grounded Change** — PASS. Every design choice below cites concrete file evidence (POMs, `application.yml`, `frontend-maven-plugin` version, existing test files). Newly discovered unknowns that this plan does not resolve (e.g., whether `react-scripts 1.1.1` produces usable coverage on Node 16.13.2 in practice) are recorded as an open question in [research.md](research.md) with a fallback path documented, and will be re-recorded in [docs/context/gaps.md](../../docs/context/gaps.md) via `/speckit.aisdlc.promote` after implementation if the fallback is triggered.
- **V. Incremental Test Hardening** — PASS. FR-008 and SC-005 are directly encoded in this plan: new `api-gateway-microservice` behavior tests (US4/AC-1), new React UI tests (US2), and any handler touched during this feature ship with a corresponding behavior test that would fail on handler removal. Existing `contextLoads()` smoke tests remain untouched (they may run, but they do not count).
- **Deployment & Scope Boundaries** — PASS. No deploy job, no extension point, no stub, no placeholder (spec Clarification Q3). `login-microservice` module builds and its (currently absent) tests are not authored (FR-017); its Spring Boot main class is compiled by the reactor build only.
- **Development Workflow** — PASS. Durable choices in this plan (JaCoCo for Java coverage; `react-scripts` built-in coverage for React; Surefire/Failsafe naming convention as the DB-test exclusion mechanism; `pull_request` + `push` triggers; `actions/upload-artifact@v4` for coverage delivery) are ADR/pattern candidates and will be routed to `docs/architecture/adr/` and `docs/patterns/` via `/speckit.aisdlc.promote` after implement.

No principle violations; no Complexity Tracking entries required.

**Post-Phase-1 re-check** (after `research.md`, `data-model.md`, `contracts/`, `quickstart.md` were written): all seven gates still PASS with the same reasoning. No design choice made in Phase 1 introduced a bypass of Principle I, a hidden dependency on live YCQL/YSQL in CI, a non-canonical term in a user-facing surface, or a scope creep into `login-microservice` or deploy-adjacent CI.

## Project Structure

### Documentation (this feature)

```text
specs/003-ci-test-pipeline/
├── plan.md              # This file (/speckit.plan output)
├── spec.md              # /speckit.specify output; clarified 2026-09-15
├── research.md          # Phase 0 output (/speckit.plan)
├── data-model.md        # Phase 1 output (/speckit.plan)
├── quickstart.md        # Phase 1 output (/speckit.plan)
├── contracts/           # Phase 1 output (/speckit.plan)
│   ├── ci-workflow.md
│   ├── coverage-artifacts.md
│   └── test-conventions.md
├── checklists/
│   └── requirements.md  # Spec quality checklist (12/12 passing)
└── tasks.md             # Phase 2 output (/speckit.tasks — NOT created by /speckit.plan)
```

### Source Code (repository root)

Web application layout — no restructuring; this feature adds files only, at these locations:

```text
.github/
└── workflows/
    └── ci.yml                                            # NEW — GitHub Actions workflow (FR-001..FR-006)

pom.xml                                                   # MODIFIED — add JaCoCo plugin management + report-aggregate config
api-gateway-microservice/
├── pom.xml                                               # MODIFIED — enable JaCoCo agent for test JVM
└── src/test/java/com/yugabyte/app/yugastore/controller/  # NEW test package for behavior tests
    ├── ProductCatalogControllerTest.java                 # NEW — US4/AC-1 behavior test for products fan-out (FR-008)
    ├── ShoppingCartControllerTest.java                   # NEW — US4/AC-1 behavior test for cart fan-out (FR-008)
    └── CheckoutFlowGatewayTest.java                      # NEW — US4/AC-3 behavior test for checkout via gateway (FR-008; mocks downstream)
checkout-microservice/
├── pom.xml                                               # MODIFIED — enable JaCoCo agent for test JVM
└── src/test/java/com/yugabyte/app/yugastore/cronoscheckoutapi/service/
    └── CheckoutServiceImplTest.java                      # NEW — US4/AC-3 service-layer test for NotEnoughProductsInStockException (Principle II)
products-microservice/pom.xml                             # MODIFIED — enable JaCoCo agent
cart-microservice/pom.xml                                 # MODIFIED — enable JaCoCo agent
eureka-server-local/pom.xml                               # MODIFIED — enable JaCoCo agent
react-ui/pom.xml                                          # MODIFIED — enable JaCoCo agent
login-microservice/pom.xml                                # MODIFIED — enable JaCoCo agent (build only; no new tests per FR-017)

jacoco-report/                                            # NEW aggregator module
├── pom.xml                                               # NEW — report-aggregate module (added to reactor <modules>)
                                                          #        depends on the six tested modules; produces target/site/jacoco-aggregate/{index.html,jacoco.xml}

react-ui/frontend/
├── package.json                                          # MODIFIED — add "test:ci" script; do NOT bump react-scripts in this feature
└── src/
    ├── setupTests.js                                     # NEW — shared React test setup (Jest globals, jsdom polyfills as needed)
    └── components/
        ├── App/
        │   └── App.test.js                               # NEW — top-level app-shell render test (FR-007, SC-003)
        ├── Products/
        │   └── Products.test.js                          # NEW — api-gateway-consuming component test (FR-007, SC-003)
        └── ShowProduct/
            └── ShowProduct.test.js                       # NEW — ASIN-rendering component test (FR-007, SC-003)
```

**Structure Decision**: Keep the existing web-application layout — the seven-module Maven reactor (backend) plus `react-ui/frontend/` (React app) as documented in [docs/architecture/overview.md](../../docs/architecture/overview.md). This feature adds files only: one workflow file, a small JaCoCo aggregator module, JaCoCo plugin declarations in each module POM, three new test packages for behavior tests, and an initial React UI test suite (setup + three test files). No file is moved or deleted; no module is added to the reactor besides the `jacoco-report` aggregator.

## Complexity Tracking

Constitution Check has no violations; no entries required.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |
