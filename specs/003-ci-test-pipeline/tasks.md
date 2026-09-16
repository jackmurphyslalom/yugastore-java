# Tasks: CI Test Pipeline

**Feature**: 003-ci-test-pipeline
**Branch**: `003-ci-test-pipeline`
**Input**: Design documents from [specs/003-ci-test-pipeline/](.)
**Prerequisites (all read)**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/](contracts/), [quickstart.md](quickstart.md), [.specify/memory/constitution.md](../../.specify/memory/constitution.md)

**Tests are NOT optional here** — this feature's entire deliverable is tests + the pipeline that runs them. Every "test file" task below is a first-class implementation task, not an add-on. Constitution Principle V (Incremental Test Hardening) binds each new Java behavior test to its handler; SC-005 makes each test a review gate.

**Organization**: One phase per user story (spec priority order: P1 → P1 → P2 → P2). Setup and Foundational phases are intentionally minimal because this feature is additive on top of a working reactor + React app.

**Format**: `- [ ] [TaskID] [P?] [Story?] Description with file path` (checkbox required, IDs sequential in execution order, `[P]` = parallelizable, `[Story]` = US-tag for user-story phase tasks only).

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Confirm working-tree context and required toolchain versions before any file is written. This feature adds files only; there is no project init.

- [ ] T001 Confirm the current Git checkout is on branch `003-ci-test-pipeline` (created by `.specify/scripts/bash/create-new-feature.sh`); if the working tree is on another branch, switch to it before authoring any new file so all additions land on the correct feature branch.
- [ ] T002 [P] Confirm local JDK 17 (`java -version`) matches `pom.xml` line 22 and `<java.version>17</java.version>` in every module POM; no code change.
- [ ] T003 [P] Confirm local Node `16.13.2` and npm `8.0.0` (`node -v`, `npm -v`) match `frontend-maven-plugin` in [react-ui/pom.xml](../../react-ui/pom.xml); no code change.

**Checkpoint**: Branch and toolchain verified — user story implementation can now begin in parallel.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Nothing in this feature is a hard prerequisite for *every* user story — US1 (workflow), US2 (React tests), US3 (coverage), and US4 (Java behavior tests) are each independently valuable and can be implemented against a working reactor without a shared prerequisite. This phase is intentionally empty and left as a placeholder for structural clarity.

*(No tasks.)*

**Checkpoint**: Foundation ready (empty by design) — proceed to user stories.

---

## Phase 3: User Story 1 — Push-triggered CI pipeline (Priority: P1) 🎯 MVP

**Goal**: Every push and PR triggers a GitHub Actions workflow that builds the Maven reactor, runs all reactor unit tests, installs React UI dependencies, runs React UI tests, and reports pass/fail as a PR status check.

**Independent Test**: A scratch commit on a branch triggers the workflow; a subsequent commit that breaks a test turns the check red. See [quickstart.md Validation 4](quickstart.md#validation-4--push-triggered-ci-run-user-story-1-sc-001-sc-002).

### Implementation for User Story 1

- [ ] T004 [US1] Create `.github/workflows/ci.yml` with workflow-level configuration per [contracts/ci-workflow.md](contracts/ci-workflow.md#workflow-level-configuration): `name: CI`, `on: [push, pull_request]` (no `pull_request_target`), `permissions.contents: read`, `concurrency` group `ci-${{ github.ref }}` with `cancel-in-progress: true`.
- [ ] T005 [US1] In `.github/workflows/ci.yml`, add the `java-reactor` job per [contracts/ci-workflow.md](contracts/ci-workflow.md#java-reactor-job): `runs-on: ubuntu-latest`, `needs: []`, steps for `actions/checkout@v4`, `actions/setup-java@v4` (`distribution: temurin`, `java-version: 17`, `cache: maven`), `./mvnw -B -ntp -DskipTests=false test`, and an `if: always()` upload of `**/target/surefire-reports/**` as artifact `surefire-reports`.
- [ ] T006 [US1] In `.github/workflows/ci.yml`, add the `react-ui` job per [contracts/ci-workflow.md](contracts/ci-workflow.md#react-ui-job): `runs-on: ubuntu-latest`, `needs: []`, `working-directory: react-ui/frontend` where applicable, steps for `actions/checkout@v4`, `actions/setup-node@v4` (`node-version: 16.13.2`, `cache: npm`, `cache-dependency-path: react-ui/frontend/package-lock.json`), `npm ci`, and `npm test -- --coverage --watchAll=false --ci`. Include `--passWithNoTests` only if User Story 2 has not yet landed at CI-integration time (remove when US2 tests exist to prevent silent zero-test success — Edge Case: "coverage tool cannot produce a report").
- [ ] T007 [US1] Push a scratch commit on branch `003-ci-test-pipeline` and confirm the `CI` status check appears on the commit within GitHub's normal queueing time (per SC-001, [quickstart.md Validation 4](quickstart.md#validation-4--push-triggered-ci-run-user-story-1-sc-001-sc-002)). Then push a second commit that deliberately breaks an existing `contextLoads()` test to confirm the check turns red (SC-002); revert the deliberate break before continuing.

**Checkpoint**: US1 delivers an automated, push-triggered CI signal — the P1 MVP is shippable. US2, US3, US4 add value on top but are not required for US1 to be useful.

---

## Phase 4: User Story 2 — React UI test setup and initial suite (Priority: P1)

**Goal**: The React UI has a working test runner and an initial suite covering the three FR-007 categories (app shell, `api-gateway`-consuming component, `ASIN`-rendering component). SC-003 verifiable by running the initial suite locally and in CI.

**Independent Test**: `cd react-ui/frontend && npm ci && npm test -- --coverage --watchAll=false --ci` runs a non-empty suite that passes; breaking a covered component fails at least one test. See [quickstart.md Validation 2](quickstart.md#validation-2--react-ui-tests--coverage-user-story-2-user-story-3).

### Implementation for User Story 2

- [ ] T008 [P] [US2] Create `react-ui/frontend/src/setupTests.js` (empty file with a top-level comment describing its purpose) so `react-scripts` auto-loads it per [contracts/test-conventions.md](contracts/test-conventions.md#setuptestsjs-responsibilities); do not add any assertions.
- [ ] T009 [P] [US2] Author `react-ui/frontend/src/components/App/App.test.js`: render `<App />` inside `MemoryRouter` (already a dependency), assert a stable landmark from the app shell renders (e.g., the top-level router container). See [research.md Decision 8](research.md#decision-8--react-initial-suite-composition-us2--fr-007--sc-003) and [contracts/test-conventions.md](contracts/test-conventions.md#rendering-approach-for-the-initial-suite).
- [ ] T010 [P] [US2] Author `react-ui/frontend/src/components/Products/Products.test.js`: mock `axios` with `jest.mock('axios')`, render `<Products />`, assert it dispatches a GET against the `api-gateway` path used by the component (confirm the exact path from the component source during authoring), and asserts the rendered output includes an item from the mocked response.
- [ ] T011 [P] [US2] Author `react-ui/frontend/src/components/ShowProduct/ShowProduct.test.js`: render `<ShowProduct product={{ asin: 'B00EXAMPLE', title: 'Example', ... }} />` (props shape confirmed from the component source during authoring), assert the rendered DOM contains the `ASIN` string. Uses canonical `ASIN` terminology in test description text (Principle III).
- [ ] T012 [US2] Run [quickstart.md Validation 2](quickstart.md#validation-2--react-ui-tests--coverage-user-story-2-user-story-3) locally and confirm all three tests pass (SC-003). If T006 in US1 was authored with `--passWithNoTests`, edit `.github/workflows/ci.yml` to remove that flag now that a non-empty suite exists.

**Checkpoint**: US1 + US2 = the P1 slice is complete. CI now runs Java tests + a meaningful React suite on every push. US3 and US4 add coverage visibility and Java rising-floor tests.

---

## Phase 5: User Story 3 — Coverage reports for Java and React (Priority: P2)

**Goal**: Every CI run publishes a `jacoco-report` artifact (Java, HTML + `jacoco.xml`) and a `react-ui-coverage` artifact (React, HTML + `lcov.info`) per [contracts/coverage-artifacts.md](contracts/coverage-artifacts.md).

**Independent Test**: On any completed run, download both artifacts and identify per-file line coverage for at least one Java class and one React component. See [quickstart.md Validation 3](quickstart.md#validation-3--aggregated-jacoco-report-java-coverage).

### Implementation for User Story 3

- [ ] T013 [US3] In root `pom.xml`, add `org.jacoco:jacoco-maven-plugin` under `<build><pluginManagement><plugins>` with an execution binding `prepare-agent` to the `initialize` phase, so every reactor module's Surefire JVM is instrumented per [research.md Decision 1](research.md#decision-1--java-coverage-tool-jacoco-maven-plugin). Use the latest 0.8.x version compatible with Java 17.
- [ ] T014 [P] [US3] Create the aggregator module `jacoco-report/pom.xml` per [data-model.md Entity 6](data-model.md#entity-6--jacoco-aggregator-module): `packaging=pom`, parent Spring Boot `2.6.3` (inherited or Spring Boot starter parent), test-scope dependencies on all seven reactor modules (`eureka-server-local`, `products-microservice`, `checkout-microservice`, `cart-microservice`, `api-gateway-microservice`, `react-ui`, `login-microservice`), and a `jacoco-maven-plugin` execution binding `report-aggregate` to the `verify` phase with `outputDirectory` = `${project.build.directory}/site/jacoco-aggregate`.
- [ ] T015 [US3] In root `pom.xml`, append `<module>jacoco-report</module>` to the `<modules>` list (depends on T014).
- [ ] T016 [US3] Locally verify [quickstart.md Validation 1](quickstart.md#validation-1--reactor-build--unit-tests-user-story-1-user-story-4) still passes (JaCoCo agent must not break Surefire), then [Validation 3](quickstart.md#validation-3--aggregated-jacoco-report-java-coverage): `./mvnw -B -ntp -pl jacoco-report -am verify -DskipTests` produces `jacoco-report/target/site/jacoco-aggregate/index.html` and `jacoco.xml` with per-file line coverage (FR-011).
- [ ] T017 [US3] In `.github/workflows/ci.yml`, add the `java-coverage-report` job per [contracts/ci-workflow.md](contracts/ci-workflow.md#java-coverage-report-job): `needs: [java-reactor]`, `runs-on: ubuntu-latest`, checkout + setup-java + reactor test invocation followed by `./mvnw -B -ntp -pl jacoco-report -am verify -DskipTests`, then `actions/upload-artifact@v4` with `name: jacoco-report` and paths `jacoco-report/target/site/jacoco-aggregate/**` and `jacoco-report/target/site/jacoco-aggregate/jacoco.xml`.
- [ ] T018 [US3] In `.github/workflows/ci.yml`, add the `react-coverage-report` job per [contracts/ci-workflow.md](contracts/ci-workflow.md#react-coverage-report-job): `needs: [react-ui]`, `runs-on: ubuntu-latest`, checkout + setup-node + `npm ci` + `npm test -- --coverage --watchAll=false --ci` (re-run for artifact isolation, per Research Decision 5 alternatives), then `actions/upload-artifact@v4` with `name: react-ui-coverage` and paths `react-ui/frontend/coverage/lcov-report/**` and `react-ui/frontend/coverage/lcov.info`.
- [ ] T019 [US3] Push a commit to the feature branch, confirm both artifacts appear on the workflow run page (SC-004), and confirm no coverage-threshold status check appears on the PR (spec Clarification Q1 verification).
- [ ] T020 [US3] If `react-scripts 1.1.1` + Node 16.13.2 fails to produce coverage in CI (Research Decision 2 fallback), pin `actions/setup-node@v4` to a lower Node version *in CI only* — do NOT bump `react-scripts` in this feature. Record the pin (and reason) in [docs/context/gaps.md](../../docs/context/gaps.md). If the pin also fails, stop and open a follow-up feature to decide the `react-scripts` upgrade.

**Checkpoint**: Coverage visible per-run for both sides; report-only (no merge gating, per spec Clarification Q1).

---

## Phase 6: User Story 4 — Meaningful Spring Boot behavior tests (Priority: P2)

**Goal**: New Java behavior tests exercise real request/response contracts on `api-gateway-microservice` and the checkout service layer, replacing the `contextLoads()`-only floor with per-behavior assertions per Constitution Principle V and SC-005.

**Independent Test**: Each of the four new tests fails on removal of the handler / service method it targets. See [quickstart.md Validation 1](quickstart.md#validation-1--reactor-build--unit-tests-user-story-1-user-story-4).

### Implementation for User Story 4

- [ ] T021 [P] [US4] Author `api-gateway-microservice/src/test/java/com/yugabyte/app/yugastore/controller/ProductCatalogControllerTest.java` per [contracts/test-conventions.md](contracts/test-conventions.md#test-slice-patterns) and [research.md Decision 7](research.md#decision-7--behavior-test-surface-for-the-java-rising-floor-principle-v-realization): `@WebMvcTest(ProductCatalogController.class)` + `@MockBean(ProductCatalogRestClient.class)` + `MockMvc`; stub the client's list-products call and assert the controller returns the payload and invokes the client once. Test class name and describe text must use canonical `api-gateway` terminology (Principle III).
- [ ] T022 [P] [US4] Author `api-gateway-microservice/src/test/java/com/yugabyte/app/yugastore/controller/ShoppingCartControllerTest.java`: `@WebMvcTest(ShoppingCartController.class)` + `@MockBean(ShoppingCartRestClient.class)` + `MockMvc`; assert add-to-cart and get-cart round-trips against the mocked client. See the `ShoppingCartController` class in [api-gateway-microservice/src/main/java/com/yugabyte/app/yugastore/controller/](../../api-gateway-microservice/src/main/java/com/yugabyte/app/yugastore/controller/).
- [ ] T023 [P] [US4] Author `api-gateway-microservice/src/test/java/com/yugabyte/app/yugastore/controller/CheckoutFlowGatewayTest.java`: `@WebMvcTest` on the gateway's checkout controller (identify the class name from the `api-gateway-microservice` controller package during authoring) + `@MockBean` on its downstream checkout `RestClient`; assert the gateway routes checkout requests correctly and returns the mocked downstream response.
- [ ] T024 [P] [US4] Author `checkout-microservice/src/test/java/com/yugabyte/app/yugastore/cronoscheckoutapi/service/CheckoutServiceImplTest.java`: Mockito mocks for `ProductInventoryRepo`, `ShoppingCartRestClient`, `ProductCatalogRestClient`; assert (a) a successful checkout path invokes inventory decrement + order write on the mocked repos, and (b) an insufficient-stock scenario raises `NotEnoughProductsInStockException` (Constitution Principle II / US4 acceptance scenario 3). Do NOT depend on a live YugabyteDB cluster (FR-014).
- [ ] T025 [US4] Run [quickstart.md Validation 1](quickstart.md#validation-1--reactor-build--unit-tests-user-story-1-user-story-4) locally and confirm the four new tests execute and pass alongside every existing `contextLoads()` test.
- [ ] T026 [US4] Verify SC-005: for each of the four new tests, temporarily remove or rename the targeted handler / service method and confirm the corresponding test fails; revert immediately. Do not commit the deliberate breakage.

**Checkpoint**: All four user stories complete. The rising Java-side floor per Principle V is established for `api-gateway-microservice` and the `checkout-microservice` critical path.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: End-to-end verification, terminology audit, and confirmation that spec deferrals are honored.

- [ ] T027 Run every quickstart validation end-to-end (Validations 1-6) and confirm each expected artifact / status appears. See [quickstart.md](quickstart.md).
- [ ] T028 [P] Terminology audit: grep `.github/workflows/ci.yml`, all new test files, and `jacoco-report/pom.xml` for the non-canonical strings `cronos`/`Cronos` in human-facing text (workflow display names, job names, artifact names, test class descriptions, log messages); confirm `Cronos` appears only in code identifiers (the `cronoscheckoutapi` package and `cronos.*` keyspace/table references) per FR-016 / Principle III.
- [ ] T029 [P] Spec-deferral audit per [quickstart.md Validation 6](quickstart.md#validation-6--explicit-non-behaviors-spec-deferrals): `grep -E "codecov|coveralls|deploy|publish|gh-pages|pull_request_target|yugabytedb|--fail-under|--coverage-threshold" .github/workflows/ci.yml` returns no matches; no coverage-threshold status check appears on any PR; `login-microservice` module builds without any new test authoring (FR-017 / spec Clarification Q3).
- [ ] T030 [P] Fork-safety audit: confirm `.github/workflows/ci.yml` references no `secrets.*` values (other than the auto-provisioned `GITHUB_TOKEN`), uses `on: pull_request` (not `pull_request_target`), and declares only `permissions.contents: read` (FR-012 / Research Decision 4). Then, if a fork is available, open a fork PR and confirm both coverage artifacts publish (SC-006).
- [ ] T031 Gaps ledger: if the Research Decision 2 or Decision 8 fallback triggered during implementation (Node pin, or adding `@testing-library/react`), record the outcome and reasoning in [docs/context/gaps.md](../../docs/context/gaps.md) per Constitution Principle IV; otherwise no change to that file.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)** — no dependencies; can start immediately.
- **Phase 2 (Foundational)** — empty by design; no wait.
- **Phase 3 (US1) — MVP** — depends on Phase 1 completion; delivers the workflow file. Once complete, the CI signal exists.
- **Phase 4 (US2)** — depends on Phase 1; **independent of US1** for authoring, but Phase 3's `react-ui` job runs meaningfully only after US2 lands (see T006's `--passWithNoTests` note and T012).
- **Phase 5 (US3)** — depends on Phase 3 (needs `.github/workflows/ci.yml` to exist to add coverage-report jobs to it) and on Phase 4 for meaningful React coverage numbers, though it can technically ship against zero-test React coverage.
- **Phase 6 (US4)** — depends on Phase 1 only; independent of US1/US2/US3 for authoring. Its four tests must be green (T025) before Phase 5's coverage jobs report anything meaningful for the Java side.
- **Phase 7 (Polish)** — depends on all desired user stories being complete.

### Within Each User Story

- Files in different paths marked `[P]` can be authored in parallel.
- Single-file phases (Phase 3, most of Phase 5) serialize because each task modifies `.github/workflows/ci.yml`.
- Verification tasks (T007, T012, T016, T019, T025, T026) depend on all authoring tasks in their phase.

### Parallel Opportunities

- **Setup** — T002 and T003 in parallel (different runtimes to check).
- **US2 (Phase 4)** — T008, T009, T010, T011 all `[P]` (four different files). T012 depends on all.
- **US3 (Phase 5)** — T014 is `[P]` alongside T013 (different files). T013+T014+T015 gate T016; T016 gates T017/T018 (workflow file edits serialize).
- **US4 (Phase 6)** — T021, T022, T023, T024 all `[P]` (four different files). T025 and T026 depend on all four.
- **Polish (Phase 7)** — T028, T029, T030 all `[P]` (independent audits).
- **Cross-story** — Once Phase 1 is done, Phase 4 (US2) and Phase 6 (US4) can proceed in parallel with Phase 3 (US1) if capacity allows, since they touch disjoint file sets.

---

## Parallel Example — User Story 2 (React initial suite)

After T007 lands (workflow exists), all four React files can be authored simultaneously by different pair members or in a single agent turn:

- T008: `react-ui/frontend/src/setupTests.js`
- T009: `react-ui/frontend/src/components/App/App.test.js`
- T010: `react-ui/frontend/src/components/Products/Products.test.js`
- T011: `react-ui/frontend/src/components/ShowProduct/ShowProduct.test.js`

Then T012 (single verification task) runs once against the completed set.

---

## Parallel Example — User Story 4 (Java behavior tests)

All four Java behavior tests target different files and different modules; they can be authored in parallel:

- T021: `api-gateway-microservice/src/test/java/com/yugabyte/app/yugastore/controller/ProductCatalogControllerTest.java`
- T022: `api-gateway-microservice/src/test/java/com/yugabyte/app/yugastore/controller/ShoppingCartControllerTest.java`
- T023: `api-gateway-microservice/src/test/java/com/yugabyte/app/yugastore/controller/CheckoutFlowGatewayTest.java`
- T024: `checkout-microservice/src/test/java/com/yugabyte/app/yugastore/cronoscheckoutapi/service/CheckoutServiceImplTest.java`

Then T025 (single `./mvnw test`) and T026 (single removal-verification pass) verify the completed set.

---

## Implementation Strategy

**MVP (deliverable independently)**: Phase 1 → Phase 3 → Phase 4. This gives a working CI pipeline that runs Java and React tests on every push and PR. Coverage reporting and the Java rising-floor tests are additive from there.

**Next increment**: Phase 5 (US3 — coverage artifacts). This is where reviewers gain trend visibility.

**Second increment**: Phase 6 (US4 — meaningful Java behavior tests). This is where Principle V begins to bite in code review.

**Final increment**: Phase 7 (Polish). End-to-end verification and terminology / spec-deferral audits.

**Sequential fallback** (single-implementer path): T001 → T002/T003 → T004 → T005 → T006 → T007 → T008 → T009 → T010 → T011 → T012 → T013 → T014 → T015 → T016 → T017 → T018 → T019 → T020 → T021 → T022 → T023 → T024 → T025 → T026 → T027 → T028 → T029 → T030 → T031.

---

## Task Count Summary

| Phase | Story | Tasks | Parallelizable |
|---|---|---|---|
| Phase 1 | Setup | 3 (T001-T003) | 2 (T002, T003) |
| Phase 2 | Foundational | 0 | 0 |
| Phase 3 | US1 (P1, MVP) | 4 (T004-T007) | 0 (single file) |
| Phase 4 | US2 (P1) | 5 (T008-T012) | 4 (T008-T011) |
| Phase 5 | US3 (P2) | 8 (T013-T020) | 1 (T014 with T013) |
| Phase 6 | US4 (P2) | 6 (T021-T026) | 4 (T021-T024) |
| Phase 7 | Polish | 5 (T027-T031) | 3 (T028-T030) |
| **Total** | | **31 tasks** | **14 `[P]`** |
