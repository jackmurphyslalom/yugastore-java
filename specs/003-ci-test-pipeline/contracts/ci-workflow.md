# Contract: CI Workflow

**Feature**: 003-ci-test-pipeline
**Applies to**: `.github/workflows/ci.yml` (new)
**Purpose**: Define the observable behavior of the GitHub Actions workflow this feature ships, in terms that reviewers can verify without reading YAML.

---

## Triggers

The workflow MUST be triggered by both of:

- `push` to any branch (`branches-ignore: []`, i.e., no branch filter — matches FR-001).
- `pull_request` targeting the repository's default branch, `master`.

The workflow MUST NOT use `pull_request_target` (Research Decision 4 — fork safety).

## Workflow-level configuration

| Field | Value | Rationale |
|---|---|---|
| `name` | `CI` | Canonical, terse (Principle III) |
| `permissions.contents` | `read` | Minimum; no write is needed anywhere |
| `permissions` (all others) | omitted / default | No write permissions requested |
| `concurrency.group` | `ci-${{ github.ref }}` | New pushes to the same branch cancel in-progress runs |
| `concurrency.cancel-in-progress` | `true` | Prevents redundant runs on rapid push sequences |

## Job graph

The workflow declares four jobs:

```
┌────────────────┐          ┌────────────────┐
│  java-reactor  │          │    react-ui    │
└───────┬────────┘          └────────┬───────┘
        │                            │
        v                            v
┌────────────────────┐   ┌───────────────────────┐
│ java-coverage-     │   │ react-coverage-       │
│ report             │   │ report                │
└────────────────────┘   └───────────────────────┘
```

- `java-reactor` and `react-ui` MUST have `needs: []` (run in parallel).
- `java-coverage-report` MUST have `needs: [java-reactor]`.
- `react-coverage-report` MUST have `needs: [react-ui]`.
- Every job MUST use `runs-on: ubuntu-latest`.
- Every job MUST use `if: always()` on coverage-report jobs if a partial-report best-effort upload is chosen; otherwise the default `if: success()` applies.

## `java-reactor` job

| Step | Action | Notes |
|---|---|---|
| 1 | `actions/checkout@v4` | Default depth |
| 2 | `actions/setup-java@v4` | `distribution: temurin`, `java-version: 17`, `cache: maven` |
| 3 | `./mvnw -B -ntp -DskipTests=false test` | Reactor unit tests (Surefire only). Skips `*IT.java` (data-model Entity 4). JaCoCo agent is attached via reactor `pom.xml` (Research Decision 1) |
| 4 | `actions/upload-artifact@v4` (`if: always()`) | Name: `surefire-reports`. Contents: `**/target/surefire-reports/**` (test XML for debugging failures) |

Contract:

- The job MUST fail if `mvnw test` exits non-zero (FR-002, FR-003).
- The job MUST NOT run `mvn verify`.
- The job MUST NOT start any container database service.

## `react-ui` job

| Step | Action | Notes |
|---|---|---|
| 1 | `actions/checkout@v4` | Default depth |
| 2 | `actions/setup-node@v4` | `node-version: 16.13.2`, `cache: npm`, `cache-dependency-path: react-ui/frontend/package-lock.json` (matches `frontend-maven-plugin` — Research Decision 2) |
| 3 | `npm ci` (working-directory: `react-ui/frontend`) | Deterministic install from `package-lock.json` |
| 4 | `npm test -- --coverage --watchAll=false --ci` (working-directory: `react-ui/frontend`) | CI mode; produces `coverage/lcov.info` and `coverage/lcov-report/` (Research Decision 2) |

Contract:

- The job MUST fail if either `npm ci` or `npm test` exits non-zero (FR-004).
- Node version MUST match the `frontend-maven-plugin` version declared in [react-ui/pom.xml](../../../react-ui/pom.xml).
- The job MUST NOT `git push`, MUST NOT publish to npm, MUST NOT touch external services.

## `java-coverage-report` job

| Step | Action | Notes |
|---|---|---|
| 1 | `actions/checkout@v4` | |
| 2 | `actions/setup-java@v4` | Same as `java-reactor` |
| 3 | Re-run reactor tests OR restore exec files | Simplest: `./mvnw -B -ntp -DskipTests=false test` then `./mvnw -B -ntp -pl jacoco-report -am verify -DskipTests`. Alternative: hand off `**/target/*.exec` from `java-reactor` via `actions/upload-artifact` + `actions/download-artifact`. Implementation may choose either; the contract is only on the artifact output. |
| 4 | `actions/upload-artifact@v4` | Name: `jacoco-report`. Path: `jacoco-report/target/site/jacoco-aggregate/**` and `jacoco-report/target/site/jacoco-aggregate/jacoco.xml`. Retention: default. |

Contract:

- The published artifact MUST include HTML with per-file line coverage and the machine-readable `jacoco.xml` (FR-009, FR-011).
- The artifact MUST be named `jacoco-report` (canonical, Principle III).

## `react-coverage-report` job

| Step | Action | Notes |
|---|---|---|
| 1 | `actions/checkout@v4` | |
| 2 | `actions/setup-node@v4` | Same as `react-ui` |
| 3 | Re-run tests OR restore coverage dir | Simplest: `npm ci && npm test -- --coverage --watchAll=false --ci` (short, ~1-2 min). Alternative: hand off `coverage/` via `actions/upload-artifact` + `actions/download-artifact`. Implementation may choose either; the contract is only on the artifact output. |
| 4 | `actions/upload-artifact@v4` | Name: `react-ui-coverage`. Path: `react-ui/frontend/coverage/lcov-report/**` and `react-ui/frontend/coverage/lcov.info`. |

Contract:

- The published artifact MUST include HTML with per-file line coverage and `lcov.info` (FR-010, FR-011).
- The artifact MUST be named `react-ui-coverage`.

## Fork-PR contract

- The workflow MUST run to completion on pull requests opened from forks (FR-012).
- The workflow MUST NOT reference any repository secret (Research Decision 4). This is enforced by the choices in Decisions 1-4: no external coverage service, no publish target that needs a token, `GITHUB_TOKEN` alone suffices for `actions/upload-artifact@v4`.

## Explicit non-behaviors (spec deferrals)

The workflow MUST NOT include, even as a disabled or commented stub:

- Any deploy-adjacent job (image publish, cloud upload, release tagging, environment promotion) — spec Clarification Q3 / FR-015.
- Any external coverage-service upload (Codecov, Coveralls, etc.) — spec Clarification Q4.
- Any PR-comment bot writing coverage summaries — spec Clarification Q4.
- Any GitHub Pages / `gh-pages` publish step — spec Clarification Q4.
- Any live YugabyteDB service container (YCQL / YSQL) — spec Clarification Q2 / FR-014.
- Any coverage threshold check / merge gate — spec Clarification Q1 / FR-013.
- Any `login-microservice`-specific test authoring or wiring beyond the module building — FR-017.

## Consumer contract (reviewer)

A reviewer looking at a PR sees:
- A single top-level `CI` status check (aggregating all four jobs).
- Four job entries in the Actions run page: `java-reactor`, `react-ui`, `java-coverage-report`, `react-coverage-report`.
- Two artifacts on the run page: `jacoco-report`, `react-ui-coverage` (plus `surefire-reports` on failed Java runs).
- No coverage-threshold status check (report-only per spec Clarification Q1).
