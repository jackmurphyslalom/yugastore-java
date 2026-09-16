# Tasks: A/B Testing / Experimentation Framework

**Input**: Design documents from [specs/005-ab-testing-framework/](.)

**Prerequisites**: [plan.md](plan.md) (required), [spec.md](spec.md) (required for user stories), [research.md](research.md), [data-model.md](data-model.md), [contracts/](contracts/), [quickstart.md](quickstart.md)

**Tests**: Included. Constitution Principle V ("Incremental Test Hardening") requires new/changed behavior to ship with tests that exercise the actual behavior change, so behavioral test tasks are mandatory here, not optional — they are listed alongside (not strictly before) their implementation task since the spec did not request a TDD-first sequencing.

**Organization**: Tasks are grouped by user story (spec.md P1/P1/P2/P2) to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Which user story this task belongs to (US1–US4)
- File paths below follow [plan.md](plan.md)'s Project Structure section exactly.

## Path Conventions

Single JVM microservice reactor (existing repo layout) — one new module
(`config-server-microservice/`) plus targeted additions to `products-microservice/`,
`checkout-microservice/`, `api-gateway-microservice/`, and `react-ui/frontend/src/`. No
`backend/`/`frontend/` split is introduced beyond what already exists in this repo.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Scaffold the new module and its config-repo backing store.

- [ ] T001 Create `config-server-microservice/pom.xml` (inherits root parent, adds
  `spring-cloud-config-server` + `spring-cloud-starter-netflix-eureka-client`, matching the
  `spring-cloud.version` property pattern used in [products-microservice/pom.xml](../../products-microservice/pom.xml))
- [ ] T002 [P] Create `config-server-microservice/Dockerfile` (mirror an existing module's Dockerfile, e.g. [products-microservice/Dockerfile](../../products-microservice/Dockerfile))
- [ ] T003 [P] Create `config-server-microservice/application.yml` (server port e.g. 8888, `spring.cloud.config.server.native.searchLocations=config-repo`, `spring.profiles.active=native`, Eureka client registration)
- [ ] T004 [P] Create `config-server-microservice/config-repo/application.yml` with initial documented defaults per [contracts/config-repo-format.md](contracts/config-repo-format.md) (`experiment.ranking-strategy: default`, `experiment.ux-variant: control`)
- [ ] T005 [P] Create `config-server-microservice/config-repo/toggle-history.json` as an empty JSON array
- [ ] T006 Add `<module>config-server-microservice</module>` to root [pom.xml](../../pom.xml)
- [ ] T007 Add a `config-server-microservice` start stanza to [docker-run.sh](../../docker-run.sh), ordered to start after `eureka-server-local` and before `products-microservice`/`checkout-microservice`

**Checkpoint**: New module builds (`./mvnw -pl config-server-microservice -am compile`) and its config-repo defaults exist.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core plumbing every user story depends on — the config server application itself, its validation source-of-truth, and the two Spring Boot consumers' ability to read from it.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [ ] T008 Implement `config-server-microservice/src/main/java/com/yugabyte/app/yugastore/configserver/ConfigServerApplication.java` (`@EnableConfigServer` + `@EnableEurekaClient`) (depends on T001, T003)
- [ ] T009 [P] Implement `config-server-microservice/src/main/java/com/yugabyte/app/yugastore/configserver/admin/ToggleAllowList.java` defining the per-key allow-list (`experiment.ranking-strategy` ∈ `{default, price-desc, newest-first}`, `experiment.ux-variant` ∈ `{control, variant-a}`) per [research.md R-3](research.md#r-3-toggle-validation-ownership-fr-004)
- [ ] T010 [P] Add `spring-cloud-starter-config` to `products-microservice/pom.xml`; add `spring.config.import=optional:configserver:http://localhost:8888` and a documented built-in `experiment.ranking-strategy: default` to `products-microservice/application.yml` (FR-007 fresh-deploy fallback)
- [ ] T011 [P] Add `spring-cloud-starter-config` to `checkout-microservice/pom.xml`; add `spring.config.import=optional:configserver:http://localhost:8888` and a documented built-in default to `checkout-microservice/application.yml`
- [ ] T012 Verify `config-server-microservice` registers in `eureka-server-local` (`http://localhost:8761`) and that `products-microservice`/`checkout-microservice` resolve config successfully at startup (manual check per [quickstart.md](quickstart.md) Prerequisites) (depends on T008, T010, T011)

**Checkpoint**: Foundation ready — user story implementation can begin.

---

## Phase 3: User Story 1 - Experiment owner changes ranking/UX behavior without an engineering release (Priority: P1) 🎯 MVP

**Goal**: An experiment owner can change or retire a ranking/UX toggle through the config surface, with no rebuild/redeploy/restart of any tier.

**Independent Test**: Change a ranking-order toggle value through the config surface; reload the product list and verify the new ordering is served within the propagation window, with no rebuild or redeploy of any tier.

### Tests for User Story 1

- [ ] T013 [P] [US1] Behavioral test in `config-server-microservice/src/test/java/com/yugabyte/app/yugastore/configserver/admin/ExperimentToggleAdminControllerTests.java`: accept a valid write, reject an invalid value with a specific reason (previous value still served), per [contracts/experiment-toggle-admin.openapi.yaml](contracts/experiment-toggle-admin.openapi.yaml)
- [ ] T014 [P] [US1] Behavioral test in `config-server-microservice/src/test/java/com/yugabyte/app/yugastore/configserver/admin/ToggleHistoryStoreTests.java`: exactly one history entry appended per accepted write, zero for a rejected write
- [ ] T015 [P] [US1] Behavioral test in `products-microservice/src/test/java/com/yugabyte/app/yugastore/service/impl/ProductRankingServiceImplTests.java`: `getProductsByCategory` ordering changes when `experiment.ranking-strategy` changes
- [ ] T016 [P] [US1] Contract test in `api-gateway-microservice/src/test/java/com/yugabyte/app/yugastore/controller/ExperimentToggleControllerWebMvcTests.java`: `GET /gateway/experiments/toggles` returns the fanned-out values per [contracts/experiment-toggle-gateway.openapi.yaml](contracts/experiment-toggle-gateway.openapi.yaml)

### Implementation for User Story 1

- [ ] T017 [US1] Implement `config-server-microservice/src/main/java/com/yugabyte/app/yugastore/configserver/admin/ToggleHistoryStore.java` (read/append `config-repo/toggle-history.json`) (depends on T005)
- [ ] T018 [US1] Implement `config-server-microservice/src/main/java/com/yugabyte/app/yugastore/configserver/admin/ExperimentToggleAdminController.java`: `GET /admin/toggles`, `PUT /admin/toggles/{key}` validating against `ToggleAllowList` and writing `config-repo/application.yml` (depends on T009, T017, T013)
- [ ] T019 [US1] Implement `config-server-microservice/src/main/java/com/yugabyte/app/yugastore/configserver/web/ToggleValidationException.java` + `@ControllerAdvice` handler returning the `ValidationError` body (HTTP 400) per [contracts/experiment-toggle-admin.openapi.yaml](contracts/experiment-toggle-admin.openapi.yaml) (depends on T018)
- [ ] T020 [P] [US1] Implement `products-microservice/src/main/java/com/yugabyte/app/yugastore/config/ExperimentTogglePoller.java` (`@Scheduled` `ContextRefresher.refresh()`, try/catch log-and-skip on failure) (depends on T010)
- [ ] T021 [US1] Apply `experiment.ranking-strategy` in `products-microservice/src/main/java/com/yugabyte/app/yugastore/service/impl/ProductRankingServiceImpl.java`'s `getProductsByCategory` (depends on T020, T015)
- [ ] T022 [P] [US1] Implement `checkout-microservice/src/main/java/com/yugabyte/app/yugastore/cronoscheckoutapi/config/ExperimentTogglePoller.java` mirroring T020 (depends on T011)
- [ ] T023 [US1] Implement `api-gateway-microservice/src/main/java/com/yugabyte/app/yugastore/rest/clients/ExperimentToggleRestClient.java` (Eureka-discovered call to `config-server-microservice`'s `GET /admin/toggles`) (depends on T018)
- [ ] T024 [US1] Implement `api-gateway-microservice/src/main/java/com/yugabyte/app/yugastore/service/ExperimentToggleServiceRest.java` + `ExperimentToggleServiceRestImpl.java` (depends on T023)
- [ ] T025 [US1] Implement `api-gateway-microservice/src/main/java/com/yugabyte/app/yugastore/controller/ExperimentToggleController.java`: `GET /gateway/experiments/toggles` per [contracts/experiment-toggle-gateway.openapi.yaml](contracts/experiment-toggle-gateway.openapi.yaml) (depends on T024, T016)
- [ ] T026 [US1] Wire `react-ui/frontend/src`'s existing fetch layer to call the gateway's `/gateway/experiments/toggles` on the relevant page load and apply `experiment.ux-variant` (depends on T025)
- [ ] T027 [US1] Run [quickstart.md](quickstart.md) Story 1 validation end-to-end (change, invalid-value rejection, retirement) (depends on T019, T021, T022, T026)

**Checkpoint**: User Story 1 fully functional and independently testable — this is the MVP slice.

---

## Phase 4: User Story 2 - Shoppers experience one consistent variant per experiment, not a flicker (Priority: P1)

**Goal**: No shopper ever sees a mixed-generation response combining an old value from one tier with a new value from another.

**Independent Test**: Change a ranking toggle value mid-session; verify in-flight page loads either consistently show the old value or consistently show the new value once propagated — never an unlabeled mix.

### Tests for User Story 2

- [ ] T028 [P] [US2] Behavioral test in `products-microservice/src/test/java/com/yugabyte/app/yugastore/config/ExperimentTogglePollerAtomicityTests.java`: a single scheduled refresh tick applies all changed properties as one atomic swap, never a partially-applied mix

### Implementation for User Story 2

- [ ] T029 [US2] Verify/adjust `products-microservice/src/main/java/com/yugabyte/app/yugastore/config/ExperimentTogglePoller.java` so each tick is exactly one `ContextRefresher.refresh()` call (no partial or concurrent overlapping refresh) (depends on T020, T028)
- [ ] T030 [US2] Run [quickstart.md](quickstart.md) Story 2 validation (repeat product-list calls during the propagation window; confirm no mixed-generation response) (depends on T029)

**Checkpoint**: User Stories 1 and 2 both work independently.

---

## Phase 5: User Story 3 - Experiment owner and engineering can see which configuration is currently active (Priority: P2)

**Goal**: Currently active toggle values, since-when, and cross-tier traceability are queryable without code access or redeploy.

**Independent Test**: Change a toggle value, then query the config surface for currently active values; verify the queried value matches what was just set and requires no code access or redeploy.

### Tests for User Story 3

- [ ] T031 [P] [US3] Behavioral test in `config-server-microservice/src/test/java/com/yugabyte/app/yugastore/configserver/admin/ExperimentToggleAdminControllerTests.java`: `GET /admin/toggles/history?key=...` returns entries most-recent-first (extends T013's test class)
- [ ] T032 [P] [US3] Behavioral test verifying `products-microservice`, `checkout-microservice`, and the gateway report the same currently active value once the propagation window has elapsed (backs SC-002 cross-tier parity)

### Implementation for User Story 3

- [ ] T033 [US3] Implement `GET /admin/toggles/history` in `config-server-microservice/src/main/java/com/yugabyte/app/yugastore/configserver/admin/ExperimentToggleAdminController.java` per [contracts/experiment-toggle-admin.openapi.yaml](contracts/experiment-toggle-admin.openapi.yaml) (depends on T017, T031)
- [ ] T034 [P] [US3] Implement `products-microservice/src/main/java/com/yugabyte/app/yugastore/controller/ExperimentStatusController.java`: `GET /products-microservice/experiments/active` exposing currently bound `experiment.*` values (depends on T021)
- [ ] T035 [P] [US3] Implement `checkout-microservice/src/main/java/com/yugabyte/app/yugastore/cronoscheckoutapi/controller/ExperimentStatusController.java` mirroring T034 (depends on T022)
- [ ] T036 [US3] Run [quickstart.md](quickstart.md) Story 3 validation (`GET /admin/toggles`, `/admin/toggles/history`, cross-tier diff) (depends on T032, T033, T034, T035)

**Checkpoint**: User Stories 1–3 all work independently.

---

## Phase 6: User Story 4 - Experimentation configuration remains available when a consuming tier is degraded (Priority: P2)

**Goal**: A slow/unavailable Config Source never produces a shopper-visible error; consuming tiers keep serving last-known-good or documented default values.

**Independent Test**: Simulate the config server being unresponsive; verify `products-microservice`, `checkout-microservice`, and `react-ui` continue serving their last successfully retrieved toggle values rather than raising a shopper-visible error.

### Tests for User Story 4

- [ ] T037 [P] [US4] Behavioral test in `products-microservice/src/test/java/com/yugabyte/app/yugastore/config/ExperimentTogglePollerFallbackTests.java`: a failed refresh attempt (simulated Config Source outage) leaves the previously-applied value serving
- [ ] T038 [P] [US4] Behavioral test (same file as T037): a tier with no cached value yet (fresh start during an outage) falls back to its documented built-in default
- [ ] T039 [P] [US4] Behavioral test in `api-gateway-microservice/src/test/java/com/yugabyte/app/yugastore/rest/clients/ExperimentToggleRestClientTests.java`: gateway serves last-known-good on a downstream failure, and returns the documented 503 only when it has never successfully fetched

### Implementation for User Story 4

- [ ] T040 [US4] Implement fallback handling in `api-gateway-microservice/src/main/java/com/yugabyte/app/yugastore/rest/clients/ExperimentToggleRestClient.java`: on a Config Source read failure, return the last-known-good cached response, or the documented 503 only if never fetched, per [contracts/experiment-toggle-gateway.openapi.yaml](contracts/experiment-toggle-gateway.openapi.yaml) (depends on T023, T039)
- [ ] T041 [US4] Confirm `products-microservice`/`checkout-microservice`'s `ExperimentTogglePoller` (T020/T022) already satisfies T037/T038 as-is per [research.md R-4](research.md#r-4-last-known-good-fallback-mechanics-fr-007); add explicit failure-path logging if missing (depends on T020, T022, T037, T038)
- [ ] T042 [US4] Run [quickstart.md](quickstart.md) Story 4 validation (stop `config-server-microservice`, confirm no shopper-visible error; restart, confirm resumed reads with no manual restart) (depends on T040, T041)

**Checkpoint**: All four user stories are independently functional.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Documentation, decision records, and full-suite verification.

- [ ] T043 [P] Add **Experiment Toggle, Config Source, Experiment Owner, Propagation Window** to `docs/product/glossary.md` (FR-012, Principle III)
- [ ] T044 [P] Record `docs/decisions/2026-09-16-experiment-config-backend-choice.md` (native filesystem vs. git-backed vs. Vault) per [research.md R-1](research.md#r-1-config-backend-choice)
- [ ] T045 [P] Record `docs/decisions/2026-09-16-experiment-propagation-mechanism.md` (scheduled poll vs. Spring Cloud Bus) per [research.md R-2](research.md#r-2-propagation-mechanism)
- [ ] T046 Update `docs/context/gaps.md`: mark the existing "Rapid experimentation / A/B testing" gap resolved by this feature; add a distinct new gap entry noting per-shopper randomized bucketing (as opposed to global toggles) remains unscoped (FR-011, Principle IV)
- [ ] T047 [P] Targeted verification: `./mvnw -pl config-server-microservice -am test` (focused run of the new module's tests)
- [ ] T048 [P] Targeted verification: `./mvnw -pl products-microservice -am test` and `./mvnw -pl checkout-microservice -am test` (focused run of modified consuming tiers)
- [ ] T049 CI-equivalent verification: `./mvnw -B test` (whole reactor, tests only)
- [ ] T050 Broadest — final authority: `./mvnw -B verify` (full reactor build + tests + package; per plan.md Technical Context, no module wraps this with a coverage `check` goal, so nothing here is silently gated beyond what's documented)

---

## Dependencies & Execution Order

- **Setup (Phase 1)** has no dependencies — start immediately.
- **Foundational (Phase 2)** depends on Setup completing; **blocks all user stories**.
- **User Story 1 (Phase 3)** depends only on Foundational. It is the MVP and should be completed first.
- **User Story 2 (Phase 4)** depends on User Story 1's `ExperimentTogglePoller` (T020) existing — it hardens a property of that same component.
- **User Story 3 (Phase 5)** depends on User Story 1's admin controller (T017/T018) and consuming-tier read path (T021/T022) existing, so there is something to query.
- **User Story 4 (Phase 6)** depends on User Story 1's poller (T020/T022) and gateway client (T023) existing, so there is a read path whose failure mode can be tested.
- **Polish (Phase 7)** depends on all four user stories being complete.

Within this feature, user stories are **not** fully parallel-independent after Phase 3, because Stories 2–4 each hardens or extends behavior User Story 1 introduces (this mirrors the spec's own priority ordering: US1 must exist before US2/US3/US4 have anything to harden, query, or fail over).

## Parallel Execution Examples

- **Phase 1 (Setup)**: T002, T003, T004, T005 can all run in parallel once T001 exists (different files).
- **Phase 2 (Foundational)**: T009, T010, T011 can run in parallel (different files); T012 waits on all three.
- **Phase 3 (US1) tests**: T013, T014, T015, T016 can all be written in parallel (different files/modules) before their corresponding implementation tasks.
- **Phase 3 (US1) implementation**: T020 and T022 can run in parallel (different modules); T017 must precede T018.
- **Phase 7 (Polish)**: T043, T044, T045, T047, T048 can all run in parallel; T046, T049, T050 are sequential gates at the end.

## Implementation Strategy

- **MVP first**: Complete Phase 1 → Phase 2 → Phase 3 (User Story 1) only. This alone delivers the spec's stated core value — an experiment owner changing ranking/UX behavior without an engineering release — and is independently testable via [quickstart.md](quickstart.md) Story 1.
- **Incremental delivery**: Add Phase 4 (US2) next since it hardens a correctness property of the same MVP surface with no new components. Phases 5 and 6 (US3, US4) can be delivered in either order after that — both are P2 and depend only on Phase 3's artifacts, not on each other.
- **Polish last**: Glossary/decision-record/gap updates and full-suite verification (Phase 7) close out delivery once all four stories are independently validated.
