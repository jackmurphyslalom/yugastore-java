---

description: "Task list for Testing Framework Alignment"
---

# Tasks: Testing Framework Alignment

**Input**: Design documents from `/specs/002-testing-framework-alignment/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Tests**: No new business-logic tests are authored (FR-005). The "tests" in this feature ARE the
deliverable: per-module `mvnw test` runs are used both as **before/after verification** tasks and,
for `login-microservice`, as the one new parity smoke test.

**Organization**: Tasks are grouped by user story (US1, US2, US3) from spec.md, with a Foundational
phase that captures the "before" baseline for all 7 modules **before any `pom.xml` is touched**.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files/module directories, no dependencies)
- **[Story]**: Maps task to US1, US2, or US3
- Include exact file paths in descriptions

## In-Scope Modules (7)

`api-gateway-microservice`, `cart-microservice`, `checkout-microservice`, `products-microservice`,
`eureka-server-local`, `login-microservice`, `react-ui` (Spring Boot backend under `react-ui/src`
only — `react-ui/frontend` is out of scope, FR-006).

---

## Phase 1: Setup

**Purpose**: Confirm every in-scope module is buildable before capturing any baseline data.

- [X] T001 Verify Java 17 is active and each in-scope module's own `./mvnw` wrapper runs (`./mvnw -v`) successfully in `api-gateway-microservice/`, `cart-microservice/`, `checkout-microservice/`, `products-microservice/`, `eureka-server-local/`, `login-microservice/`, and `react-ui/`

**Checkpoint**: All 7 module directories have a working Maven wrapper; no `pom.xml` has been modified yet.

---

## Phase 2: Foundational — "Before" Baseline Capture (BLOCKS all pom.xml edits)

**Purpose**: Record the pre-change state for all 7 modules per data-model.md's *In-Scope Module*
fields (`test_dependencies_before`, `coverage_tool_before`, `test_count_before`,
`suite_runs_before`, `coverage_measurable_before`). **No `pom.xml` in any module may be edited until
every task in this phase is complete.**

**⚠️ CRITICAL**: This phase MUST run to completion before Phase 3 or Phase 4 starts.

- [X] T002 [P] Run `./mvnw test` in `api-gateway-microservice/`; record pass/fail, test count, and confirm `target/site/jacoco/` does not exist
- [X] T003 [P] Run `./mvnw test` in `cart-microservice/`; record pass/fail, test count, and confirm `target/site/jacoco/` does not exist
- [X] T004 [P] Run `./mvnw test` in `checkout-microservice/`; record pass/fail, test count, and confirm `target/site/jacoco/` does not exist
- [X] T005 [P] Run `./mvnw test` in `products-microservice/`; record pass/fail, test count, and confirm `target/site/jacoco/` does not exist
- [X] T006 [P] Run `./mvnw test` in `eureka-server-local/`; record pass/fail, test count, and confirm `target/site/jacoco/` does not exist
- [X] T007 [P] Run `./mvnw test` in `react-ui/`; record pass/fail, test count, and confirm `target/site/jacoco/` does not exist
- [X] T008 [P] Inspect `login-microservice/pom.xml` and confirm no `src/test` directory exists and no test dependency is declared; record baseline as "no test sources to run" (`suite_runs_before` = false, `test_count_before` = 0)

**Checkpoint**: Baseline ("before") state recorded for all 7 modules. Only after this checkpoint may any `pom.xml` be edited.

---

## Phase 3: User Story 1 - Standardized, runnable test tooling across every in-scope module (Priority: P1) 🎯 MVP

**Goal**: The 6 modules that already declare `spring-boot-starter-test` gain the identical
`jacoco-maven-plugin` + `mockito-core` + `assertj-core` block, and running `./mvnw test` produces a
JaCoCo report for each.

**Independent Test**: Diff the added `pom.xml` block across the 6 modules (identical apart from
module name/package); run `./mvnw test` in each and confirm it passes and produces
`target/site/jacoco/index.html`.

**Depends on**: Phase 2 (Foundational) complete for the 7 modules.

### Implementation for User Story 1

- [X] T009 [P] [US1] Add `mockito-core` + `assertj-core` (test scope, no explicit `<version>`) and the `org.jacoco:jacoco-maven-plugin` `0.8.11` block (`prepare-agent` execution + `report` execution bound to phase `test`) to `api-gateway-microservice/pom.xml`
- [X] T010 [P] [US1] Same standardized block to `cart-microservice/pom.xml`
- [X] T011 [P] [US1] Same standardized block to `checkout-microservice/pom.xml`
- [X] T012 [P] [US1] Same standardized block to `products-microservice/pom.xml`
- [X] T013 [P] [US1] Same standardized block to `eureka-server-local/pom.xml`
- [X] T014 [P] [US1] Same standardized block to `react-ui/pom.xml`
- [X] T015 [P] [US1] Run `./mvnw test` in `api-gateway-microservice/` ("after"); confirm the existing test still passes (same test count as before), `target/site/jacoco/index.html` is produced, and record the overall instruction/line coverage % from `target/site/jacoco/jacoco.xml` or the HTML summary (depends on T009)
- [X] T016 [P] [US1] Run `./mvnw test` in `cart-microservice/` ("after"); confirm the existing test still passes (same test count as before), `target/site/jacoco/index.html` is produced, and record the overall instruction/line coverage % from `target/site/jacoco/jacoco.xml` or the HTML summary (depends on T010)
- [X] T017 [P] [US1] Run `./mvnw test` in `checkout-microservice/` ("after"); confirm the existing test still passes (same test count as before), `target/site/jacoco/index.html` is produced, and record the overall instruction/line coverage % from `target/site/jacoco/jacoco.xml` or the HTML summary (depends on T011)
- [X] T018 [P] [US1] Run `./mvnw test` in `products-microservice/` ("after"); confirm the existing test still passes (same test count as before), `target/site/jacoco/index.html` is produced, and record the overall instruction/line coverage % from `target/site/jacoco/jacoco.xml` or the HTML summary (depends on T012)
- [X] T019 [P] [US1] Run `./mvnw test` in `eureka-server-local/` ("after"); confirm the existing test still passes (same test count as before), `target/site/jacoco/index.html` is produced, and record the overall instruction/line coverage % from `target/site/jacoco/jacoco.xml` or the HTML summary (depends on T013)
- [X] T020 [P] [US1] Run `./mvnw test` in `react-ui/` ("after"); confirm the existing test still passes (same test count as before), `target/site/jacoco/index.html` is produced, and record the overall instruction/line coverage % from `target/site/jacoco/jacoco.xml` or the HTML summary (depends on T014)

**Checkpoint**: 6 of 7 in-scope modules have standardized, verified test tooling.

---

## Phase 4: User Story 2 - `login-microservice` brought to test-infrastructure parity (Priority: P2)

**Goal**: `login-microservice` gains the same test dependencies, JaCoCo plugin, and a minimal
`contextLoads()`-style smoke test, matching the other 6 modules.

**Independent Test**: Inspect `login-microservice/pom.xml` for the standardized dependencies and
JaCoCo plugin, confirm `src/test` now exists with a smoke test, and run `./mvnw test` to confirm it
passes and produces a coverage report.

**Depends on**: Phase 2 (Foundational) complete, specifically T008.

### Implementation for User Story 2

- [X] T021 [US2] Add `spring-boot-starter-test` (test scope) dependency to `login-microservice/pom.xml` (depends on T008)
- [X] T022 [US2] Add the same standardized `mockito-core` + `assertj-core` + `jacoco-maven-plugin` `0.8.11` block used in Phase 3 to `login-microservice/pom.xml` (depends on T021)
- [X] T023 [US2] Create `login-microservice/src/test/java/com/yugabyte/app/yugastore/YugastoreLoginServiceTests.java`: a `@SpringBootTest`-annotated class with a single empty `contextLoads()` `@Test` method, mirroring `cart-microservice/src/test/java/com/yugabyte/app/yugastore/YugastoreCartTests.java` and targeting `YugastoreLoginService` (depends on T021)
- [X] T024 [US2] Run `./mvnw test` in `login-microservice/` ("after"); confirm the new `contextLoads()` smoke test passes (test count 1), `target/site/jacoco/index.html` is produced, and record the overall instruction/line coverage % from `target/site/jacoco/jacoco.xml` or the HTML summary (depends on T022, T023) — **result: PASS, 27% instruction coverage**

**Checkpoint**: All 7 in-scope modules now have standardized, verified test tooling; `login-microservice` is at parity.

---

## Phase 5: User Story 3 - Documented before/after assessment and contributor testing conventions (Priority: P3)

**Goal**: A checked-in before/after report and a short testing-conventions doc so the change and
the go-forward convention are both legible to future contributors.

**Independent Test**: Locate both documents and confirm the report covers all 7 modules'
before/after state (data-model.md fields) and the conventions note lets a reader identify the
required framework/tools without opening any `pom.xml`.

**Depends on**: Phase 2 (all "before" data) and Phases 3–4 (all "after" data) complete.

### Implementation for User Story 3

- [X] T025 [P] [US3] Write `specs/002-testing-framework-alignment/context/before-after-testing-assessment.md`: one row per module (all 7) per data-model.md's *In-Scope Module* fields, using the before data from T002-T008 and after data from T015-T020 and T024, referencing the ~85% figure from `docs/context/sources/2026-09-14-client-requirements-interview.md` only as an aspirational future target (FR-009)
- [X] T026 [P] [US3] Write `docs/patterns/testing-conventions.md` (status `Established`) documenting JUnit 5 + Mockito + AssertJ + JaCoCo, the `./mvnw test` run command, the `target/site/jacoco/index.html` report location, and an explicit no-Testcontainers/integration-infra scope note

**Checkpoint**: Before/after report and conventions doc are checked in and match the data-model.md schema.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final cross-module validation per quickstart.md's success-criteria mapping.

- [X] T027 Run `git status react-ui/frontend` and confirm no changes are reported (FR-006) — confirmed clean
- [X] T028 [P] Diff the added `pom.xml` block across all 7 modules and confirm it is identical apart from module name/package (SC-001) — confirmed identical (login-microservice has one extra `spring-boot-starter-test` line, as expected since it started with none)
- [X] T029 Walk through quickstart.md's "Success criteria mapping" table (SC-001–SC-006) end to end and confirm each row is satisfied — all 7 modules now `BUILD SUCCESS` with JaCoCo reports; see before-after-testing-assessment.md

> **Implementation note**: While capturing the "before" baseline (Phase 2), 4 of the 6 modules with a pre-existing test (`api-gateway-microservice`, `cart-microservice`, `products-microservice`, `react-ui`) were discovered to already be `BUILD FAILURE` — their auto-generated smoke test's Java package did not match their module's `@SpringBootApplication` package, so Spring could not locate a configuration. Fixing this (moving the existing empty test class into the correct package, no assertion/logic changes) was required to satisfy FR-003 and is documented in the before/after report.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Setup — **BLOCKS every `pom.xml` edit in Phase 3 and Phase 4**
- **User Story 1 (Phase 3)**: Depends on Phase 2 completing for all 7 modules
- **User Story 2 (Phase 4)**: Depends on Phase 2 completing (specifically T008); independent of Phase 3
- **User Story 3 (Phase 5)**: Depends on Phase 2 (before data) and Phases 3–4 (after data) all completing
- **Polish (Phase 6)**: Depends on Phases 3–5 completing

### Within Each Phase

- Phase 2: all 7 baseline-capture tasks are independent of each other ([P])
- Phase 3: the 6 pom.xml edits are independent of each other ([P]); each module's "after" verification depends only on that module's own edit task
- Phase 4: T021 → T022/T023 (parallel) → T024, strictly sequential within `login-microservice`
- Phase 5: both doc-writing tasks are independent of each other ([P]), but each depends on all upstream data being captured

### Parallel Opportunities

- All Phase 2 baseline captures (T002-T008) can run in parallel
- All Phase 3 pom.xml edits (T009-T014) can run in parallel; all Phase 3 "after" verifications (T015-T020) can run in parallel once their respective edit lands
- Phase 3 (US1) and Phase 4 (US2) can proceed in parallel once Phase 2 is complete
- Phase 5's two documentation tasks (T025, T026) can run in parallel

---

## Parallel Example: Phase 2 Foundational Baseline

```bash
# Launch all 7 "before" baseline captures together:
Task: "Run ./mvnw test in api-gateway-microservice/; record pass/fail + absence of jacoco report"
Task: "Run ./mvnw test in cart-microservice/; record pass/fail + absence of jacoco report"
Task: "Run ./mvnw test in checkout-microservice/; record pass/fail + absence of jacoco report"
Task: "Run ./mvnw test in products-microservice/; record pass/fail + absence of jacoco report"
Task: "Run ./mvnw test in eureka-server-local/; record pass/fail + absence of jacoco report"
Task: "Run ./mvnw test in react-ui/; record pass/fail + absence of jacoco report"
Task: "Inspect login-microservice/pom.xml + src/test absence"
```

## Parallel Example: User Story 1 pom.xml edits

```bash
Task: "Add jacoco/mockito/assertj block to api-gateway-microservice/pom.xml"
Task: "Add jacoco/mockito/assertj block to cart-microservice/pom.xml"
Task: "Add jacoco/mockito/assertj block to checkout-microservice/pom.xml"
Task: "Add jacoco/mockito/assertj block to products-microservice/pom.xml"
Task: "Add jacoco/mockito/assertj block to eureka-server-local/pom.xml"
Task: "Add jacoco/mockito/assertj block to react-ui/pom.xml"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational baseline capture — **do not skip or reorder this**
3. Complete Phase 3: User Story 1 (6 modules standardized)
4. **STOP and VALIDATE**: diff the 6 `pom.xml` blocks, confirm 6 passing runs + 6 JaCoCo reports

### Incremental Delivery

1. Setup + Foundational baseline → foundation ready, before-state recorded
2. User Story 1 → 6 modules standardized and verified (MVP)
3. User Story 2 → `login-microservice` at parity
4. User Story 3 → before/after report + conventions doc checked in
5. Polish → cross-module diff + `react-ui/frontend` untouched check + quickstart success-criteria walkthrough

---

## Notes

- [P] tasks = different files/module directories, no dependencies
- [Story] label maps task to US1, US2, or US3
- Baseline capture (Phase 2) MUST fully complete before any `pom.xml` edit (T009-T014, T021-T022) starts
- No business-logic tests are authored anywhere in this feature (FR-005)
- `react-ui/frontend` is never touched by any task in this file (FR-006)
