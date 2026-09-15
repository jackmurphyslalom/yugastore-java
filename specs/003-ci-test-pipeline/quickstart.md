# Quickstart: Validate the CI Test Pipeline

**Feature**: 003-ci-test-pipeline
**Purpose**: Reproduce end-to-end, on a developer laptop and on a CI run, everything the spec commits to. This is a validation/run guide, not an implementation guide — see [plan.md](plan.md), [research.md](research.md), and [contracts/](contracts/) for design details.

Everything below runs locally with the same commands CI runs, so "green on CI" and "green on your laptop" report the same thing.

---

## Prerequisites

- JDK 17 on `PATH` (`java -version` → `17.x`). Matches the reactor `pom.xml` and every module POM.
- Node 16.13.2 and npm 8.0.0 (matches `frontend-maven-plugin` in [react-ui/pom.xml](../../react-ui/pom.xml)). Use `nvm use 16.13.2` or install via your package manager.
- No YugabyteDB required — this feature's CI slice excludes DB-backed integration tests (FR-014).
- No repository secrets required.

---

## Validation 1 — Reactor build + unit tests (User Story 1, User Story 4)

Reproduce the `java-reactor` CI job locally:

```bash
./mvnw -B -ntp -DskipTests=false test
```

Expected outcome:
- Every module compiles.
- Every module's Surefire `*Test.java` classes run.
- The three new `api-gateway-microservice` behavior tests (`ProductCatalogControllerTest`, `ShoppingCartControllerTest`, `CheckoutFlowGatewayTest`) and the new `checkout-microservice` service-layer test (`CheckoutServiceImplTest`) execute and pass.
- Every module's existing `contextLoads()` smoke test still runs (unchanged, per Principle V).
- Total wall-clock: dominated by Spring Boot context initialization; expect low tens of seconds on a warm cache.

Failure investigation: read `**/target/surefire-reports/*.txt` for the failing module.

**Contract**: see [contracts/ci-workflow.md](contracts/ci-workflow.md#java-reactor-job) — `java-reactor` job.

---

## Validation 2 — React UI tests + coverage (User Story 2, User Story 3)

Reproduce the `react-ui` CI job locally:

```bash
cd react-ui/frontend
npm ci
npm test -- --coverage --watchAll=false --ci
```

Expected outcome:
- `npm ci` installs from `package-lock.json` (no `package.json` changes required for the reactor build to continue working).
- `npm test` discovers the three new colocated `.test.js` files under `src/components/App/`, `src/components/Products/`, `src/components/ShowProduct/`, plus the `src/setupTests.js` setup file.
- All three tests pass.
- `react-ui/frontend/coverage/lcov.info` and `react-ui/frontend/coverage/lcov-report/index.html` are produced.
- Open `react-ui/frontend/coverage/lcov-report/index.html` in a browser to view per-file line coverage (`SC-003` verifiable: covered lines >0 in `App`, `Products`, `ShowProduct`).

Failure investigation: `react-scripts test` prints the failing test file and assertion in-line. If `--coverage` cannot be produced (fallback path in [research.md](research.md) Decision 2), the report is missing — file the follow-up per Research Decision 2's escape plan.

**Contract**: see [contracts/ci-workflow.md](contracts/ci-workflow.md#react-ui-job) — `react-ui` job.

---

## Validation 3 — Aggregated JaCoCo report (Java coverage)

Reproduce the `java-coverage-report` CI job locally, after Validation 1 has run:

```bash
./mvnw -B -ntp -pl jacoco-report -am verify -DskipTests
```

Expected outcome:
- The `jacoco-report/` aggregator module runs `jacoco:report-aggregate`.
- `jacoco-report/target/site/jacoco-aggregate/index.html` and `jacoco-report/target/site/jacoco-aggregate/jacoco.xml` are produced.
- Open `jacoco-report/target/site/jacoco-aggregate/index.html` in a browser to view per-file line coverage across the entire reactor (SC-004 verifiable).

Note: if you skipped Validation 1, the exec files won't exist and `report-aggregate` produces an empty or partial report. Always run Validation 1 first.

**Contracts**: see [contracts/ci-workflow.md](contracts/ci-workflow.md#java-coverage-report-job) and [contracts/coverage-artifacts.md](contracts/coverage-artifacts.md#jacoco-report-artifact).

---

## Validation 4 — Push-triggered CI run (User Story 1, SC-001, SC-002)

Reproduce end-to-end on GitHub Actions:

1. Push a small no-op commit to any branch:

    ```bash
    git commit --allow-empty -m "trigger CI"
    git push
    ```

2. On the commit's page in GitHub, observe a `CI` status check appear within the platform's normal queueing time.

3. Open a pull request against `master` from the branch. Observe the same `CI` status check on the PR, running against the merge commit.

4. On a second commit to the same branch that deliberately breaks a test (for example, change an assertion in `ProductCatalogControllerTest` to fail), observe the `CI` status check turn red on that new commit, and the failing test identifiable from the run logs and the `surefire-reports` artifact.

**Contract**: see [contracts/ci-workflow.md](contracts/ci-workflow.md#triggers) — Triggers.

---

## Validation 5 — Fork PR contract (SC-006)

If you have a fork:

1. Push a change to your fork's branch.
2. Open a PR from `<your-fork>:branch` to `<upstream>:master`.
3. Observe:
   - The `CI` workflow runs on the PR without any secret-related failure.
   - `jacoco-report` and `react-ui-coverage` artifacts appear on the run page.
   - No status check is added for coverage-threshold gating (report-only, per spec Clarification Q1).

If artifacts do not appear from a fork PR, the fork-safe posture in Research Decision 4 has regressed; investigate the workflow's `permissions:` block and the presence of any `secrets.` references.

**Contract**: see [contracts/ci-workflow.md](contracts/ci-workflow.md#fork-pr-contract) — Fork-PR contract.

---

## Validation 6 — Explicit non-behaviors (spec deferrals)

Verify that the workflow does *not* do things the spec explicitly deferred:

- Grep the workflow file: `grep -E "codecov|coveralls|deploy|publish|gh-pages|pull_request_target|yugabytedb" .github/workflows/ci.yml` → should return no matches.
- Confirm no coverage-threshold status check appears on the PR.
- Confirm the `login-microservice` module compiles (its existing tests, if any, run) but no new test authoring for it has occurred (FR-017).

**Contracts**: see [contracts/ci-workflow.md](contracts/ci-workflow.md#explicit-non-behaviors-spec-deferrals) — Explicit non-behaviors.

---

## Reference

| Concern | Source of truth |
|---|---|
| Spec, requirements, user stories | [spec.md](spec.md) |
| Design decisions and rationales | [research.md](research.md) |
| Artifact / job / naming shapes | [data-model.md](data-model.md) |
| Workflow YAML behavior contract | [contracts/ci-workflow.md](contracts/ci-workflow.md) |
| Coverage artifact contract | [contracts/coverage-artifacts.md](contracts/coverage-artifacts.md) |
| Java + React test conventions | [contracts/test-conventions.md](contracts/test-conventions.md) |
| Constitution gates | [.specify/memory/constitution.md](../../.specify/memory/constitution.md) |
| Repo evidence used in planning | [docs/architecture/overview.md](../../docs/architecture/overview.md), [docs/context/gaps.md](../../docs/context/gaps.md) |
