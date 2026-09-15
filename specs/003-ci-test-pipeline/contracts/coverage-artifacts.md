# Contract: Coverage Artifacts

**Feature**: 003-ci-test-pipeline
**Applies to**: The two coverage artifacts published by every CI run — `jacoco-report` and `react-ui-coverage`.
**Purpose**: Define, from a reviewer's perspective, exactly what each coverage artifact contains and how to consume it, independent of the tool that produces it.

---

## Common contract (both artifacts)

Every CI Workflow Run MUST publish two artifacts, both viewable from the run page without authentication beyond the reviewer's normal repo access:

| Property | Value |
|---|---|
| Delivery mechanism | GitHub Actions workflow artifact (via `actions/upload-artifact@v4`) |
| External service required? | No |
| Repository secret required? | No |
| Available on fork PRs? | Yes (FR-012) |
| Retention | GitHub Actions default (90 days) unless the repository or org overrides |
| Aggregated across the reactor / UI? | Yes — one artifact per side, aggregated |
| Per-file line-coverage included? | Yes (FR-011) |

The artifacts MUST NOT gate merges (FR-013 / spec Clarification Q1). They are report-only.

---

## `jacoco-report` artifact

**Name**: `jacoco-report` (canonical, Principle III; not "cronos-coverage", not "yugastore-jacoco-html")

**Scope**: Java reactor — every reactor module Surefire executes (`api-gateway-microservice`, `products-microservice`, `checkout-microservice`, `cart-microservice`, `eureka-server-local`, `react-ui`, `login-microservice`).

**Contents**:

| File | Purpose |
|---|---|
| `index.html` | Landing page; per-package roll-up |
| `**/*.html` | Full HTML tree; drill-down to per-class, per-method, per-line coverage |
| `jacoco.xml` | Machine-readable form; per-file line/branch counts |
| `jacoco.csv` (optional) | Machine-readable alternative form; JaCoCo emits by default |

**Producer**: JaCoCo Maven plugin `report-aggregate` goal, bound to `verify` phase of the new `jacoco-report/` module (Research Decision 1 / data-model Entity 6).

**Reviewer usage**:
1. Open the CI run page from the PR's status check.
2. Scroll to Artifacts; download `jacoco-report`.
3. Open `index.html` in a browser to explore per-file coverage.
4. Alternative: parse `jacoco.xml` for automation.

**SC evidence**:
- `SC-004` (per-file line coverage) satisfied by JaCoCo's default report format.
- `SC-006` (fork PRs still publish) satisfied by using only `actions/upload-artifact@v4` + `GITHUB_TOKEN`.

---

## `react-ui-coverage` artifact

**Name**: `react-ui-coverage` (canonical, Principle III)

**Scope**: React UI — `react-ui/frontend/src/**` files exercised by `react-scripts test --coverage`.

**Contents**:

| File | Purpose |
|---|---|
| `lcov-report/index.html` | Landing page; per-directory roll-up |
| `lcov-report/**/*.html` | Full HTML tree; drill-down to per-file, per-line coverage |
| `lcov.info` | LCOV machine-readable form |

**Producer**: `react-scripts test --coverage --watchAll=false --ci` (Research Decision 2). Output default landing: `react-ui/frontend/coverage/`.

**Reviewer usage**:
1. Open the CI run page from the PR's status check.
2. Scroll to Artifacts; download `react-ui-coverage`.
3. Open `lcov-report/index.html` in a browser to explore per-file coverage.
4. Alternative: parse `lcov.info` for automation.

**SC evidence**:
- `SC-004` (per-file line coverage) satisfied by `react-scripts` / Istanbul default report format.
- `SC-003` (initial suite covers three FR-007 areas) verifiable by seeing >0 covered lines in `App`, `Products`, `ShowProduct` folders of the report.
- `SC-006` (fork PRs still publish) satisfied by using only `actions/upload-artifact@v4` + `GITHUB_TOKEN`.

---

## Failure-mode contract

If either coverage report cannot be produced (e.g., zero tests executed on one side, `--coverage` flag fails, aggregator module fails to resolve exec files):

- The workflow MUST NOT silently omit the artifact and report `success` (Edge Case: "coverage tool cannot produce a report").
- The corresponding coverage-report job MUST report `failure` OR upload a single-file explanatory artifact (`README-no-coverage.txt`) with the reason. Implementation preference: report `failure` and let the reviewer investigate.
- The workflow MUST NOT report 0% coverage as if it were a real measurement when in fact no coverage was collected.
