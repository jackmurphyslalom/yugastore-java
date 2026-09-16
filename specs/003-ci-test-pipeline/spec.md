# Feature Specification: CI Test Pipeline

**Feature Branch**: `003-ci-test-pipeline`

**Created**: 2026-09-15

**Status**: Draft

**Input**: User description: "Establish a CI test pipeline for yugastore-java driven by GitHub Actions on push. Source intake: `specs/intake/ci-cd-tests.md`. In scope: expand Spring Boot tests across the seven-module Maven reactor beyond `contextLoads()` smoke tests; add a test setup and initial test suite to the React UI at `react-ui/frontend/`; add a GitHub Actions workflow that runs on push (and PRs) covering both the Maven reactor build/tests and the React UI tests; produce a code coverage report for both the Java and React sides."

## Clarifications

### Session 2026-09-15

- Q: Coverage threshold and merge-gating policy for this feature? → A: Report-only for now; publish Java and React coverage reports every run with no numeric merge gate; revisit gating in a follow-up feature once a real coverage baseline exists.
- Q: Do YugabyteDB-dependent integration tests run in CI? → A: Exclude DB-backed integration tests from CI for this feature; the CI workflow runs only unit and lightweight in-process tests (mocked repositories, `MockMvc`, embedded discovery). DB-backed integration tests remain local-only; adding them to CI is a follow-up feature.
- Q: How does the CI workflow interact with the unresolved deployment-target ambiguity (Cloud Foundry vs. tentative AWS)? → A: Full defer. This feature ships only build + test + coverage jobs. Any deploy-adjacent CI work (image publish, cloud upload, release tagging, environment promotion) is a separately-scoped follow-up feature after the deployment target is decided; no extension point, stub, or placeholder deploy job is added today.
- Q: How are coverage reports delivered to reviewers? → A: Workflow artifacts only. Each run uploads Java and React coverage reports as GitHub Actions workflow artifacts in both an HTML form (for humans) and a machine-readable form (e.g., XML for Java, LCOV for React). No external coverage service, no PR-summary bot, no repo-hosted HTML site, no additional secrets required.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Push-triggered CI pipeline builds and tests every change (Priority: P1)

Every push to any branch and every pull request against the default branch triggers an automated workflow that builds the seven-module Maven reactor, runs all Java tests, installs the React UI dependencies, runs the React UI tests, and reports pass/fail back to the commit and pull request. Contributors see a green or red status without having to run anything locally, and reviewers gate merges on that signal.

**Why this priority**: This is the foundational slice — until the pipeline exists at all, every downstream item (React tests, expanded Java tests, coverage) has nowhere to run. It is also the smallest independently valuable slice: even against the current smoke-only test floor, an automated build catches compile breaks, dependency drift, and reactor-level regressions that today are only found on a developer's laptop.

**Independent Test**: Push a small no-op change (e.g., a whitespace edit) on a branch and open a pull request. The workflow appears on the PR, runs to completion, and reports a status check that reflects the actual build/test outcome. Introducing a deliberate compile error on a second push flips the status to failed on the same PR.

**Acceptance Scenarios**:

1. **Given** the repository has the workflow installed, **When** a contributor pushes any commit to any branch, **Then** the workflow starts automatically and reports its result on that commit.
2. **Given** a pull request is open against the default branch, **When** any new commit is pushed to the PR branch, **Then** the workflow re-runs on that new commit and updates the PR's status check.
3. **Given** a commit compiles and every Java and React test passes, **When** the workflow completes, **Then** it reports success and its logs record which reactor modules and which React commands were exercised.
4. **Given** a commit fails one or more tests or fails to compile, **When** the workflow completes, **Then** it reports failure and its logs identify the failing module(s) and test(s) without a human having to re-run anything locally.

---

### User Story 2 - React UI has a working test setup and an initial suite (Priority: P1)

The React UI at [react-ui/frontend/](react-ui/frontend/) — which today has a `test` script wired to `react-scripts test --env=jsdom` but zero test files — has a working test runner, a documented way to add tests, and an initial suite exercising a small set of representative UI concerns: rendering the top-level app shell, at least one component that consumes the `api-gateway`, and at least one component that renders `ASIN`-keyed product data. Contributors adding UI changes have a place to add tests, and User Story 1's workflow has real React tests to run.

**Why this priority**: Without this, the CI workflow's React step is meaningless — it would run zero tests and always pass. Establishing the test setup is a prerequisite for User Story 1 to protect the UI at all, so it shares P1 priority.

**Independent Test**: A contributor runs the React UI's test command locally and sees a non-empty suite that passes. Introducing a regression in one of the covered components (e.g., breaking the app shell's render output) causes at least one test to fail locally, independent of any CI wiring.

**Acceptance Scenarios**:

1. **Given** the React UI's test tooling is set up, **When** a contributor runs the UI test command, **Then** the runner discovers and executes the initial suite and reports pass/fail for each test.
2. **Given** the initial suite is present, **When** a contributor introduces a change that breaks one of the covered components' expected behavior, **Then** at least one test fails without further test-code changes.
3. **Given** the initial suite is present, **When** a contributor adds a new UI change and writes a corresponding test, **Then** the test is discovered and executed by the same command with no additional setup.

---

### User Story 3 - Coverage reports are produced for both Java and React on every run (Priority: P2)

Every CI run produces a code coverage report for the Java side (aggregated across the Maven reactor modules) and a code coverage report for the React UI side, and publishes both as artifacts (or equivalent visible surface) on the workflow run so that reviewers can inspect trends and specific-file coverage without re-running anything locally.

**Why this priority**: Coverage reporting is an explicit intake requirement and a direct enabler for Constitution Principle V ("Incremental Test Hardening") — reviewers need visibility into whether new/changed behavior is actually being exercised. It is P2 rather than P1 because Stories 1 and 2 deliver the automated safety net on their own; coverage reporting adds a critical trend signal on top of that safety net but is not required for the pipeline to be useful.

**Independent Test**: On a completed workflow run, a reviewer can download or view a Java coverage report and a React coverage report from that run, and can identify per-file line-coverage numbers for at least one representative Java class and one representative React component.

**Acceptance Scenarios**:

1. **Given** a completed CI run, **When** a reviewer opens the run's artifacts (or equivalent visible surface), **Then** a Java coverage report and a React coverage report are present and identifiable.
2. **Given** two consecutive CI runs on the default branch, **When** a reviewer compares the reports, **Then** the reports contain enough per-file information to see which files' coverage changed between the runs.
3. **Given** a pull request adds a new code path that no test exercises, **When** the CI run completes, **Then** the coverage report for that side shows the new code path as uncovered.

---

### User Story 4 - Spring Boot tests exercise real behavior on new or changed code (Priority: P2)

For any new or changed Java behavior touched by this feature — and as a rising floor going forward — Spring Boot tests exercise real behavior (routing through the `api-gateway`, interacting with the checkout/products/cart services' contracts, verifying error and edge cases) instead of only asserting that the Spring context loads. Existing `contextLoads()`-only tests may remain as-is but do not count as coverage for any new work.

**Why this priority**: This is the direct realization of Constitution Principle V ("Incremental Test Hardening") for the Java side. It is P2 rather than P1 because Stories 1 and 2 stand up the automation independently — this story raises the *quality* of what CI runs, but CI is valuable to have running even before this story is complete. It is also unbounded by nature (the surface of "meaningful Java tests" is large), so scoping it as its own story keeps the P1 slice shippable.

**Independent Test**: For a specific representative behavior added or touched during this feature (e.g., a gateway route that fans out to `products-microservice`), a new test exists that exercises the behavior through its real code path (not just context load) and would fail if the underlying handler were removed or its return contract broken.

**Acceptance Scenarios**:

1. **Given** a new or changed handler on `api-gateway-microservice`, **When** the corresponding test runs, **Then** the test drives the handler through its actual request/response contract and asserts on the observed behavior — not merely that the Spring application starts.
2. **Given** an existing `contextLoads()`-only test on a module, **When** new behavior is added to that module during this feature, **Then** the new behavior ships with at least one test that exercises the behavior, in addition to (not replacing) the existing smoke test.
3. **Given** a critical data path (e.g., order placement writing `cronos.orders` and decrementing `cronos.product_inventory`), **When** its test runs, **Then** the test asserts on both the persisted effect and the stock-verification error path (`NotEnoughProductsInStockException`), consistent with Constitution Principle II.

---

### Edge Cases

- What happens when a contributor pushes to a fork rather than a branch on the origin repo? The workflow must still run for pull requests from forks and must not require secrets that a fork cannot access.
- What happens when the workflow itself fails to start (e.g., misconfigured YAML, unavailable runner image)? The failure must be visible as a failed status check, not a silent no-op that a PR reviewer could mistake for "no CI configured."
- What happens when the Java build passes but the React build fails (or vice versa)? The overall workflow status must be failed, and both sides' logs must remain accessible even when one side short-circuits early.
- What happens when a test is flaky? The pipeline reports the actual run result; flake mitigation (retries, quarantining) is out of scope for this feature but the design must not hide flake signal.
- What happens when the coverage tool cannot produce a report (e.g., zero tests executed on one side)? The workflow reports the situation explicitly rather than silently omitting the report or reporting 0% as if it were a real measurement.
- What happens if a workflow run is triggered on a very old commit that predates the tests? The workflow should still start; whether it passes depends on that commit's own code, not on retroactive test additions.
- What happens when `login-microservice` (currently unfinished and not wired into the `api-gateway`) is built by the reactor? Its module must compile and its existing tests must run, but this feature does not add behavior tests for it — Constitution's Deployment & Scope Boundaries keep it out of scope by default.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: A CI workflow MUST run automatically on every push to any branch and on every pull request against the default branch, without a contributor having to trigger it manually.
- **FR-002**: The CI workflow MUST build the entire Maven reactor from the repository root, exercising the same reactor build that a developer runs locally, and MUST fail the run if any module fails to build.
- **FR-003**: The CI workflow MUST run every Java test across all reactor modules and MUST fail the run if any test fails.
- **FR-004**: The CI workflow MUST install dependencies for the React UI at [react-ui/frontend/](react-ui/frontend/) and MUST run its test command, failing the run if any React test fails.
- **FR-005**: The CI workflow MUST report its final status (pass/fail) as a status check on the triggering commit and pull request, visible in the pull request UI without a reviewer having to inspect run logs.
- **FR-006**: The CI workflow MUST produce logs that identify which reactor module(s) and which React test suite(s) failed when a failure occurs, sufficient for a reviewer to locate the failing test(s) without re-running anything locally.
- **FR-007**: The React UI MUST have a working test setup — a command that discovers and runs tests, a documented location for test files, and at least one representative test file for each of: the top-level app shell, a component that consumes the `api-gateway`, and a component that renders `ASIN`-keyed product data.
- **FR-008**: New or changed Java behavior introduced by this feature (and, per Constitution Principle V, going forward on all new work) MUST ship with tests that exercise the actual behavior, not only Spring Boot `contextLoads()` smoke tests. Existing smoke tests MAY remain.
- **FR-009**: The CI workflow MUST produce a code coverage report for the Java side, aggregated across the Maven reactor's tested modules, and MUST publish it as a GitHub Actions workflow artifact on every run in both a human-readable form (HTML) and a machine-readable form (e.g., XML). No external coverage service, PR-comment bot, or repo-hosted HTML site is required in this feature.
- **FR-010**: The CI workflow MUST produce a code coverage report for the React UI side and MUST publish it as a GitHub Actions workflow artifact on every run in both a human-readable form (HTML) and a machine-readable form (e.g., LCOV). No external coverage service, PR-comment bot, or repo-hosted HTML site is required in this feature.
- **FR-011**: Coverage reports MUST include per-file line-coverage information so reviewers can identify which specific files' coverage changed between runs.
- **FR-012**: The CI workflow MUST be usable from pull requests opened from forks — it MUST NOT require secrets or permissions that a fork PR cannot access in order to run the build and tests or to publish the coverage report artifacts required by FR-009 and FR-010.
- **FR-013**: Coverage tooling choices MUST be documented (which tool for Java, which tool for React, and why), so the choice is traceable and reversible without archaeology. Coverage MUST be reported on every run but MUST NOT gate merges in this feature — no numeric coverage threshold and no blocking status check tied to coverage. Introducing merge-gating (repo-wide threshold, per-file no-regression, patch coverage, or otherwise) is a follow-up feature to be scoped once a real coverage baseline exists.
- **FR-014**: The CI workflow MUST NOT stand up or depend on a running YugabyteDB (YCQL or YSQL) cluster in this feature. Java tests that run in CI MUST use unit-level or lightweight in-process techniques (e.g., mocked repositories, `MockMvc`, embedded discovery); tests requiring a live YugabyteDB cluster remain local-only for now and MUST either be excluded from the CI run or skip themselves cleanly when no cluster is available. Adding DB-backed integration tests to CI is a separately-scoped follow-up feature.
- **FR-015**: The CI workflow MUST NOT include deployment-adjacent steps (image publish, cloud upload, release tagging, environment promotion) in this feature. The workflow MUST NOT reserve an extension point, stub, or placeholder deploy job either — deploy-adjacent CI work is a separately-scoped follow-up feature to be opened after the deployment-target ambiguity in [docs/context/gaps.md](docs/context/gaps.md) is resolved.
- **FR-016**: The CI workflow, coverage reports, and any new test scaffolding MUST use canonical terminology from [docs/product/glossary.md](docs/product/glossary.md) in human-facing text (`api-gateway`, `Eureka`, `YCQL`, `YSQL`, `ASIN`); the legacy internal name `Cronos` MAY appear only in code/package/keyspace references, not in workflow names or report titles.
- **FR-017**: This feature MUST NOT add or change behavior in `login-microservice` (its module MAY still be built and its existing tests MAY still be run by the reactor). Wiring or expanding `login-microservice` remains subject to Constitution Deployment & Scope Boundaries.

### Key Entities *(include if feature involves data)*

- **CI Workflow Run**: A single automated execution triggered by a push or pull request event. Has an identity (run URL), a trigger reference (commit SHA, branch or PR ref), a status (queued, running, success, failure, cancelled), and produces logs plus artifacts (Java coverage report, React coverage report).
- **Coverage Report**: A per-run artifact describing which lines of source files were exercised by the run's tests. Has a scope (Java reactor vs. React UI), a per-file breakdown, and a summary total. Consumed by reviewers on the pull request or run page.
- **Test Suite (per side)**: The collection of tests executed for one side of the codebase (Java reactor tests, React UI tests). Each suite has a runner command, a discovery convention (where test files live), and a pass/fail result per run.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: On any push to any branch, a CI status check appears on the corresponding commit within the platform's normal queueing time, without a contributor having to trigger it manually. Measured by: manual verification on at least three consecutive branch pushes showing an automatically-appearing status check.
- **SC-002**: When a contributor pushes a commit that breaks the reactor build or any existing test, the CI status check on that commit reports failure and the run logs identify the failing module and test. Measured by: a deliberate reproduction (e.g., a broken test introduced on a scratch branch) that produces a red status and locatable failure output.
- **SC-003**: The React UI test command discovers and executes a non-empty initial suite covering the top-level app shell, one `api-gateway`-consuming component, and one `ASIN`-rendering component, and the same command runs successfully in CI. Measured by: reviewing the run's React test output and confirming counts > 0 for all three areas.
- **SC-004**: Every CI run publishes a Java coverage report and a React coverage report as GitHub Actions workflow artifacts, each in both HTML and a machine-readable form, and each including per-file line coverage. Measured by: opening any recent run and confirming both artifact sets are present and per-file information is visible in the HTML.
- **SC-005**: New Java behavior introduced during this feature ships with at least one test per new behavior that exercises real code paths (not only `contextLoads()`), consistent with Constitution Principle V. Measured by: a code review checklist item confirming, for each new handler/service method added by this feature, that a corresponding behavior test exists and would fail on removal of the handler.
- **SC-006**: On a pull request opened from a fork, the CI workflow still runs the Java and React build/test jobs, publishes both coverage report artifacts, and reports pass/fail on the PR without requiring any secrets that a fork PR cannot access. Measured by: opening one fork PR (or simulating one) and observing that build/test status is reported and coverage artifacts are attached.
- **SC-007**: Contributors adding a new UI change alongside a new UI test can rely on the same single command (`react-ui/frontend/` test command) to run the new test locally and the same command to run it in CI. Measured by: a contributor walkthrough where a new test is added, run locally with the documented command, and then observed executing in the same CI job.

## Assumptions

- The repository will use GitHub-hosted runners for this workflow; self-hosted runners are out of scope for this feature.
- Java toolchain in CI matches the repository's declared Java version (17, per the reactor `pom.xml`), Spring Boot 2.6.3, and Spring Cloud 2021.0.0, so no reactor version bump is implied by this feature.
- React tooling is used *as it exists today* under [react-ui/frontend/](react-ui/frontend/) for the first pass (`react-scripts 1.1.1`, `test --env=jsdom`). Upgrading `react-scripts` or migrating to a different runner is a separately scopable decision and is not required by this feature; if upgrade is chosen during planning, it will be recorded as its own decision.
- Coverage tooling choice (Java: e.g., JaCoCo; React: e.g., the runner's built-in coverage) will be decided in the plan phase, not the spec. This feature commits to *producing and publishing* coverage reports, not to a specific tool.
- Integration tests that stand up services against real `Eureka` (`eureka-server-local`) discovery or that require a live YugabyteDB (`YCQL`/`YSQL`) cluster are excluded from this feature's CI scope per FR-014; the CI slice runs only unit and lightweight in-process tests. Adding DB-backed integration tests to CI is a separately-scoped follow-up.
- Reactor-level and cross-module test aggregation uses the existing root `pom.xml` reactor build; per-module CI matrices are permitted but not required.
- No existing GitHub Issue or GitHub Projects (v2) board item is assumed to already track this work. If one is discovered during planning, the plan will reference it rather than create a duplicate; verification is a plan-phase task, not a spec blocker.
- Constitution Principles I (Gateway-Only Service Boundary), II (Consistency-Sensitive Data Paths), III (Canonical Terminology), IV (Context-Grounded Change), and V (Incremental Test Hardening) apply; this feature explicitly binds itself to Principle V for its Java-side test expansion and to Principle III for terminology in workflow/report surfaces.

## Dependencies

- Repository already contains a Maven reactor at the root, seven Spring Boot modules, and a React UI at [react-ui/frontend/](react-ui/frontend/); this feature adds automation and tests around them but does not restructure them.
- Constitution [.specify/memory/constitution.md](.specify/memory/constitution.md) v1.0.0 is authoritative for test expectations (Principle V) and terminology (Principle III).
- Context gaps recorded in [docs/context/gaps.md](docs/context/gaps.md) — specifically the deployment-target ambiguity and `login-microservice` scope — are inputs to FR-015 and FR-017 respectively.

## Out of Scope

- Adding, wiring, or completing `login-microservice` behavior. This feature only requires that its module build and its existing tests run, not that its behavior be expanded or gateway-integrated.
- Deployment automation of any kind: image publishing, cloud upload (AWS, Cloud Foundry, or otherwise), release tagging, environment promotion. FR-015 explicitly defers deploy-adjacent CI work.
- Retroactively rewriting existing `contextLoads()`-only tests. Per Constitution Principle V, they may remain; the rising floor applies only to new/changed behavior.
- Choosing or migrating away from `react-scripts 1.1.1` unless planning determines it is required to satisfy FR-004 or FR-010.
- Chaos-style or performance testing (e.g., latency injection, load tests). The intake and constitution do not require them here.
- Standing up an admin/observability dashboard, uptime dashboard, or CI results dashboard beyond what GitHub Actions provides natively.
