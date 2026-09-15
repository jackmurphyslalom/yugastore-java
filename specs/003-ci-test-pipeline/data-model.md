# Data Model: CI Test Pipeline

**Feature**: 003-ci-test-pipeline
**Date**: 2026-09-15
**Purpose**: Describe the durable "shapes" this feature adds. The feature ships automation, not application data, so the entities below describe CI-artifact shapes and code-side test conventions rather than persisted domain data.

---

## Entity 1 — CI Workflow Run

Represents a single execution of the CI workflow triggered by a `push` or `pull_request` event.

**Attributes**:

| Attribute | Type | Notes |
|---|---|---|
| `run_id` | number | GitHub-assigned run identifier |
| `run_url` | URL | Human-viewable run page |
| `trigger_event` | enum(`push`, `pull_request`) | Which event started the run |
| `commit_sha` | string (40) | The exact commit tested |
| `ref` | string | Branch or PR ref (e.g., `refs/heads/master`, `refs/pull/42/merge`) |
| `status` | enum(`queued`, `in_progress`, `success`, `failure`, `cancelled`) | Terminal states drive the PR status check |
| `jobs` | list<Job> | See Entity 2 |
| `artifacts` | list<Artifact> | See Entity 3 |
| `started_at` | timestamp | |
| `completed_at` | timestamp | Null while running |

**Relationships**:
- 1 CI Workflow Run → N Jobs (Entity 2). Jobs run in parallel where their `needs:` clause allows.
- 1 CI Workflow Run → N Artifacts (Entity 3). Every successful run produces at least two artifacts (Java coverage + React coverage, per FR-009/FR-010).

**Lifecycle / state transitions**:
`queued` → `in_progress` → { `success` | `failure` | `cancelled` }. Only terminal states are reported as the PR status check.

**Validation rules**:
- Every run MUST report a terminal status (FR-005). Runs stuck in `in_progress` past the runner timeout are auto-cancelled by GitHub.
- A `success` status MUST NOT be reported if any child Job's status is `failure` (see Entity 2 validation).

---

## Entity 2 — Job

A named unit of work inside a CI Workflow Run.

**Attributes**:

| Attribute | Type | Notes |
|---|---|---|
| `name` | string | Uses canonical glossary terms only (Principle III / FR-016): `java-reactor`, `react-ui`, `java-coverage-report`, `react-coverage-report`. `Cronos` is NOT permitted here. |
| `status` | enum(`queued`, `in_progress`, `success`, `failure`, `cancelled`, `skipped`) | |
| `steps` | list<Step> | Ordered; log output is per-step |
| `needs` | list<string> | Names of jobs that MUST complete `success` first; `[]` for parallel top-level jobs |
| `runs_on` | string | `ubuntu-latest` for every job in this feature |
| `permissions` | map | Explicit `contents: read` only (fork-safety); no `write` permissions requested (Research Decision 4) |

**Job set defined by this feature**:

| Name | Purpose | `needs:` |
|---|---|---|
| `java-reactor` | `./mvnw -B -ntp test` for the entire reactor; JaCoCo agent attached to Surefire; per-module exec files land under each module's `target/jacoco.exec` (Research Decision 1) | `[]` |
| `react-ui` | `npm ci` then `npm test -- --coverage --watchAll=false --ci` under `react-ui/frontend/` (Research Decision 2); LCOV + HTML land under `react-ui/frontend/coverage/` | `[]` |
| `java-coverage-report` | `./mvnw -B -ntp -pl jacoco-report -am verify` to produce the aggregated JaCoCo report; uploads `jacoco-aggregate` HTML + `jacoco.xml` via `actions/upload-artifact@v4` | `[java-reactor]` |
| `react-coverage-report` | Uploads `react-ui/frontend/coverage/lcov-report/` HTML + `coverage/lcov.info` via `actions/upload-artifact@v4` | `[react-ui]` |

**Validation rules**:
- If any job in `[java-reactor, react-ui]` reports `failure`, the workflow run is `failure` (FR-005).
- Both sides' logs MUST remain accessible even when one side short-circuits early (Edge Case: "Java passes but React fails or vice versa"). The parallel `needs: []` layout of the two primary jobs satisfies this — neither depends on the other.
- Coverage report jobs MAY be `skipped` if their upstream test job is `cancelled`. If the upstream job is `failure` but a partial coverage report exists (e.g., JaCoCo agent still wrote exec files for the modules that ran), the report job SHOULD still attempt to publish the partial artifact.
- Every job name MUST use canonical terminology (FR-016); `Cronos` MUST NOT appear in any job name or display label.

---

## Entity 3 — Coverage Report Artifact

A downloadable/inspectable output of a CI Workflow Run.

**Attributes**:

| Attribute | Type | Notes |
|---|---|---|
| `name` | string | Uploaded artifact name; canonical terms only: `jacoco-report`, `react-ui-coverage` |
| `scope` | enum(`java-reactor`, `react-ui`) | Which side of the codebase the report covers |
| `human_form` | file(s) | HTML report tree (FR-009/FR-010 human-readable form) |
| `machine_form` | file | Machine-readable form: XML (JaCoCo) or LCOV (React) |
| `per_file_line_coverage` | boolean | MUST be `true` (FR-011) |
| `retention_days` | number | Uses GitHub Actions default (90 days) unless the org overrides |

**Concrete artifact contents produced by this feature**:

| Artifact name | Files inside |
|---|---|
| `jacoco-report` | `jacoco-aggregate/index.html` and the full aggregate HTML tree (`jacoco-aggregate/**/*.html`); `jacoco.xml` |
| `react-ui-coverage` | `lcov-report/index.html` and the full HTML tree (`lcov-report/**/*.html`); `lcov.info` |

**Validation rules**:
- Every successful (and best-effort every failed) run MUST publish both artifacts (FR-009, FR-010, SC-004).
- Each artifact MUST include per-file line-coverage (FR-011). JaCoCo's `report-aggregate` naturally emits per-file. LCOV / `react-scripts` coverage naturally emits per-file.
- If either coverage report cannot be produced (Edge Case: "coverage tool cannot produce a report"), the workflow MUST NOT silently omit the artifact. The corresponding coverage-report job MUST either fail explicitly or upload a small textual artifact stating "no coverage produced this run: <reason>". Implementation preference: fail explicitly (loud > silent).

---

## Entity 4 — Test-file Naming Convention (Java side)

A durable *code-side* rule, not a persisted entity, but recorded here so `data-model.md` fully captures the shapes this feature introduces.

**Rule**: In every Maven module in this reactor:
- `**/*Test.java` — unit / in-process tests. Discovered and executed by the Maven Surefire plugin during `mvn test`. Run on every CI push and PR.
- `**/*IT.java` — integration tests. Discovered and executed by the Maven Failsafe plugin during `mvn verify`. NOT run in CI by this feature (FR-014). Introducing them into CI is a separately-scoped follow-up feature.

**Rationale**: Standard Maven Surefire/Failsafe convention; enforces FR-014 via build-lifecycle contract without requiring per-test annotations. See Research Decision 3.

**Validation rules**:
- Any new Java test file added to the repo during this feature MUST end in `Test.java`.
- Any future Java test requiring live YCQL / YSQL MUST end in `IT.java` (out of scope for this feature; documented for the follow-up).
- CI MUST invoke `mvn test`, not `mvn verify`.

---

## Entity 5 — Test-file Naming Convention (React side)

**Rule**: Under `react-ui/frontend/src/**`:
- `**/*.test.js` — Jest test files. Discovered by `react-scripts test` via its default `testMatch` pattern (Research Decision 6).
- `src/setupTests.js` — Shared setup, auto-loaded by `react-scripts` before every test.
- Tests are colocated with the component they test (e.g., `src/components/Products/Products.test.js` next to `src/components/Products/Products.jsx`).

**Validation rules**:
- Any new React test added by this feature MUST end in `.test.js` and MUST be located under `react-ui/frontend/src/**`.
- `setupTests.js` MUST NOT contain assertions; only shared configuration.

---

## Entity 6 — JaCoCo Aggregator Module

A durable Maven module added to the reactor.

**Location**: `jacoco-report/` at repository root; added to `pom.xml`'s `<modules>` list.

**Purpose**: Depend on the six modules whose coverage rolls up (`eureka-server-local`, `products-microservice`, `checkout-microservice`, `cart-microservice`, `api-gateway-microservice`, `react-ui`, `login-microservice` — all seven, actually; the aggregator depends on everything the reactor tests) and bind `jacoco-maven-plugin:report-aggregate` to the `verify` phase to produce the aggregated HTML + XML report.

**Attributes**:

| Attribute | Value |
|---|---|
| `groupId` | `com.yugabyte.app.yugastore` (matches reactor) |
| `artifactId` | `jacoco-report` |
| `packaging` | `pom` (no code, only aggregation) |
| `dependencies` | Every other reactor module, `<scope>test</scope>` — dependency is only for JaCoCo's aggregation resolution, not for build fan-out |
| `output paths` | `target/site/jacoco-aggregate/index.html` (HTML), `target/site/jacoco-aggregate/jacoco.xml` (XML) |

**Validation rules**:
- The aggregator module MUST NOT be a runtime dependency of any other module; it is only reachable via `mvn -pl jacoco-report -am verify`.
- The aggregator MUST NOT produce a Spring Boot fat JAR or any deployable artifact.
