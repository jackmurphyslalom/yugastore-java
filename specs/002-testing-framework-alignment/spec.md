# Feature Specification: Testing Framework Alignment

**Feature Branch**: `002-testing-framework-alignment`

**Created**: 2026-09-15

**Status**: Draft

**Input**: User description: "Align on a single testing framework/toolchain for the current codebase, replacing ad-hoc/inconsistent test tooling."

**GitHub Issue**: [jackmurphyslalom/yugastore-java#25](https://github.com/jackmurphyslalom/yugastore-java/issues/25) — "Align on a testing framework for current state"

## Current State (Background)

A prior assessment of the repository's Java modules found the following. This is recorded as
context for the standardization work below, not as requirements in itself.

- `api-gateway-microservice`, `cart-microservice`, `checkout-microservice`, `products-microservice`,
  `eureka-server-local`, and the `react-ui` Spring Boot backend (`react-ui/src`) each depend on
  `spring-boot-starter-test` (which pulls in JUnit 5 transitively) and each has exactly one
  auto-generated, empty `contextLoads()` smoke test. No real unit or integration tests of business
  logic exist in any of these modules today.
- `login-microservice` has zero test infrastructure: no test dependency is declared in its
  `pom.xml`, and it has no `src/test` directory at all.
- No module uses a code coverage tool (no JaCoCo or equivalent) anywhere in the repository.
- No module has an explicit or consistent convention for Mockito or AssertJ usage, even though both
  libraries are already transitively available via `spring-boot-starter-test`.
- `react-ui/frontend` (the Create React App / Jest JavaScript frontend) has Jest wired up via
  `react-scripts` but has zero test files. This part of the codebase is explicitly **out of scope**
  for this feature.
- A prior client requirements interview
  (`docs/context/sources/2026-09-14-client-requirements-interview.md`) mentioned an informal ~85%
  code coverage target. That figure is recorded here as an aspirational future reference point only
  — this feature does not attempt to reach it, since it does not add new business-logic tests.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Standardized, runnable test tooling across every in-scope module (Priority: P1)

As a developer or contributor working in any of the seven in-scope Java modules
(`api-gateway-microservice`, `cart-microservice`, `checkout-microservice`, `products-microservice`,
`eureka-server-local`, `login-microservice`, and `react-ui`'s Spring Boot backend), I need every
module to declare the same test framework and coverage tooling, so that I can run tests and see
coverage the same way no matter which module I'm working in.

**Why this priority**: This is the core ask of the linked issue and the foundation everything else
depends on — without a single, consistent toolchain, coverage cannot be measured consistently and
future test-authoring work has no shared convention to follow.

**Independent Test**: Can be fully tested by opening the `pom.xml` of each in-scope module and
confirming it declares the same standardized test dependencies (JUnit 5, Mockito, AssertJ) and the
same JaCoCo plugin configuration, then running the existing test suite in each module and confirming
it completes successfully and produces a JaCoCo coverage report.

**Acceptance Scenarios**:

1. **Given** any in-scope Java module's `pom.xml`, **When** a contributor inspects its test-related
   dependencies and plugins, **Then** they see the same JUnit 5, Mockito, AssertJ, and JaCoCo
   configuration used in every other in-scope module.
2. **Given** an in-scope module with its existing (even minimal) test suite, **When** a contributor
   runs that module's test command, **Then** the existing tests execute successfully and a JaCoCo
   coverage report is generated for that module.
3. **Given** the full set of seven in-scope modules, **When** a contributor runs the same test
   command pattern across each of them in turn, **Then** every module behaves consistently (same
   command shape, same report location/format), with no module requiring different tooling or a
   different invocation style.

---

### User Story 2 - `login-microservice` brought to test-infrastructure parity (Priority: P2)

As a developer working on `login-microservice`, I need it to have the same minimal test
infrastructure and smoke test convention already used by the other six in-scope modules, so that it
is no longer the one module with zero test setup.

**Why this priority**: `login-microservice` is the single clearest gap identified in the baseline
assessment (no test dependency, no `src/test` directory at all) and blocks it from participating in
the standardized, measurable test/coverage setup that User Story 1 establishes everywhere else.

**Independent Test**: Can be fully tested by inspecting `login-microservice/pom.xml` for the
standardized test dependencies and JaCoCo plugin, confirming a `src/test` directory now exists with
a minimal smoke test matching the convention already used in the other modules (e.g., an equivalent
of `contextLoads()`), and running that module's test command to confirm it passes and produces a
coverage report.

**Acceptance Scenarios**:

1. **Given** `login-microservice` before this feature (no test dependency, no `src/test`),
   **When** the standardization work is applied, **Then** its `pom.xml` gains the same standardized
   test dependencies and JaCoCo plugin as the other six in-scope modules.
2. **Given** the updated `login-microservice`, **When** a contributor looks under `src/test`,
   **Then** they find a minimal smoke test that follows the same convention as the auto-generated
   `contextLoads()` tests already present in the other modules.
3. **Given** the updated `login-microservice`, **When** a contributor runs its test command,
   **Then** the smoke test passes and a JaCoCo coverage report is produced for that module, matching
   the behavior of every other in-scope module.

---

### User Story 3 - Documented before/after assessment and contributor testing conventions (Priority: P3)

As a technical lead or future contributor, I need a documented comparison of the testing setup
before and after this change, plus a short conventions note, so that I can see what changed at a
glance and know how to write tests consistently with the rest of the codebase going forward.

**Why this priority**: This makes the standardization durable and legible — without it, the
improved-but-still-low test coverage state could be mistaken for insufficient progress, and future
contributors would have no written guidance on the agreed conventions.

**Independent Test**: Can be fully tested by locating the before/after assessment report and the
testing-conventions note in the repository and confirming the report lists, per module: framework/
dependencies present, test count, whether the suite runs, and whether coverage is measurable — both
before and after this feature's changes.

**Acceptance Scenarios**:

1. **Given** the completed standardization work, **When** a reader opens the before/after
   assessment report, **Then** they see a module-by-module comparison (all seven in-scope modules)
   covering test framework/dependencies present, test count, whether the suite runs, and whether
   coverage is measurable, for both the "before" and "after" states.
2. **Given** the before/after report, **When** a reader looks for the ~85% coverage figure from the
   prior client requirements interview, **Then** it is referenced only as an aspirational future
   target/gap, not as a bar this feature claims to have met.
3. **Given** a new contributor, **When** they read the testing-conventions note, **Then** they can
   determine which test framework, mocking library, assertion library, and coverage tool to use for
   any in-scope Java module without needing to reverse-engineer it from `pom.xml` files.

---

### Edge Cases

- What happens if an in-scope module's existing `contextLoads()` test conflicts with a newly added
  JaCoCo/test dependency version (e.g., a transitive version clash with `spring-boot-starter-test`)?
  The standardized configuration must resolve to a single consistent version across all modules
  without breaking the existing smoke test.
- How is `login-microservice`'s minimal smoke test scoped when the module currently has no
  Spring Boot application context test to model at all versus modules that already have one?
  It must match the convention already used in the other six modules as closely as the module's
  existing structure allows.
- What happens to `react-ui/frontend`'s Jest setup? It is explicitly untouched — no dependency,
  configuration, or test file changes are made there under this feature.
- What happens if a module's test suite currently "passes" only because it contains no real
  assertions (the empty `contextLoads()` case)? It must continue to run and pass unchanged; this
  feature does not add or change assertions, only tooling and reporting.
- How is the aspirational ~85% coverage figure presented so it isn't mistaken for a target this
  feature achieves? It must appear only as a labeled future reference point in the before/after
  report, alongside the actual (low) measured coverage after this feature's changes.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Every in-scope Java module (`api-gateway-microservice`, `cart-microservice`,
  `checkout-microservice`, `products-microservice`, `eureka-server-local`, `login-microservice`, and
  `react-ui`'s Spring Boot backend under `react-ui/src`) MUST declare the same standardized set of
  test dependencies: JUnit 5, Mockito, and AssertJ, at unit-test scope only (no Testcontainers or
  other integration-test infrastructure).
- **FR-002**: Every in-scope Java module MUST have the same standardized JaCoCo code-coverage plugin
  configuration applied, so that running that module's test command also produces a JaCoCo coverage
  report.
- **FR-003**: Every in-scope module's existing test suite MUST be executable via a consistent,
  repeatable command pattern that is the same shape across all seven modules.
- **FR-004**: `login-microservice` MUST be brought to parity with the other six in-scope modules:
  it MUST gain the standardized test dependencies and JaCoCo plugin (FR-001, FR-002) and a `src/test`
  directory containing a minimal smoke test that follows the same convention as the auto-generated
  `contextLoads()` tests already present in the other modules.
- **FR-005**: This feature MUST NOT include authoring new unit, integration, or business-logic
  tests in any module. The scope is limited to test tooling, configuration, and the
  `login-microservice` parity smoke test described in FR-004.
- **FR-006**: `react-ui/frontend` (the Create React App / Jest JavaScript test setup) MUST remain
  entirely untouched by this feature — no dependency, configuration, or test file changes.
- **FR-007**: A documented before/after testing-assessment comparison MUST be checked into the
  repository, covering all seven in-scope modules, showing for each module and for both the
  "before" and "after" states: test framework/dependencies present, test count, whether the suite
  runs, and whether coverage is measurable.
- **FR-008**: A short testing-conventions note for contributors MUST be checked into the repository,
  documenting the standardized framework choice (JUnit 5 + Mockito + AssertJ + JaCoCo) and how to run
  tests with coverage in an in-scope module.
- **FR-009**: The before/after assessment report MUST reference the informal ~85% code coverage
  figure from the prior client requirements interview only as a known future target/gap, not as a
  bar this feature claims to meet.
- **FR-010**: This feature's spec artifacts MUST be linked to
  [jackmurphyslalom/yugastore-java#25](https://github.com/jackmurphyslalom/yugastore-java/issues/25)
  for traceability.

### Key Entities *(include if feature involves data)*

- **In-Scope Module**: One of the seven Java modules covered by this feature. Tracked attributes:
  module name, test dependencies present (before/after), coverage tool presence (before/after), test
  count, whether its test suite runs successfully, and whether coverage is measurable.
- **Before/After Testing Assessment Report**: The checked-in document comparing each in-scope
  module's testing state prior to and after this feature's changes, including the referenced
  aspirational ~85% coverage figure.
- **Testing Conventions Note**: The checked-in, short contributor-facing document describing the
  standardized framework/toolchain and how to run tests with coverage.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: All seven in-scope modules have an identical, standardized test-dependency and
  coverage-tooling setup — a reviewer comparing any two in-scope modules' test configuration finds
  no differences beyond the module's own name/package.
- **SC-002**: Every in-scope module's test suite can be executed via the same consistent command
  pattern and completes successfully, with zero in-scope modules failing to run their tests.
- **SC-003**: Every in-scope module produces a coverage report as a result of running its test
  suite, where previously zero modules did.
- **SC-004**: `login-microservice` is no longer missing test infrastructure — it has a runnable test
  suite and a measurable coverage report, matching the other six in-scope modules.
- **SC-005**: A before/after comparison report exists in the repository and clearly shows the state
  change from ad hoc/inconsistent testing tooling to standardized and measurable, for all seven
  in-scope modules.
- **SC-006**: A contributor unfamiliar with the prior ad hoc setup can determine the required test
  framework, mocking library, assertion library, and coverage tool for any in-scope module solely
  from the checked-in testing-conventions note, without inspecting `pom.xml` files individually.

## Assumptions

- The test framework, mocking library, assertion library, and coverage tool choices (JUnit 5,
  Mockito, AssertJ, JaCoCo) were confirmed directly by the stakeholder for this feature and are
  treated as settled scope, not open questions.
- "Unit-level only, no Testcontainers" means this feature does not introduce integration-test
  infrastructure (e.g., containerized YugabyteDB/Cassandra instances) for any module; that remains a
  separate future concern if pursued.
- The minimal smoke test added to `login-microservice` is expected to be a Spring Boot context-load
  style test (mirroring the other six modules' `contextLoads()` pattern), scoped to whatever
  application context `login-microservice` already exposes — it is not a new business-logic test.
- `react-ui/frontend`'s Jest/CRA setup, including its current lack of test files, is intentionally
  left exactly as-is; any future alignment of that JavaScript tooling is a separate, later effort.
- The ~85% coverage figure remains an aspirational reference only; actual measured coverage after
  this feature will still be low, since no new business-logic tests are authored here.
- "Consistent command pattern" refers to each module using the same build-tool invocation shape
  (e.g., the same Maven goal/profile) to run tests and generate a coverage report, not a single
  cross-module aggregate command.
