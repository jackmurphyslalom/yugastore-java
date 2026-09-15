# Research: CI Test Pipeline

**Feature**: 003-ci-test-pipeline
**Date**: 2026-09-15
**Purpose**: Resolve every technical unknown surfaced by the plan's Technical Context so `data-model.md`, `contracts/`, and `quickstart.md` can be written against concrete choices.

All unknowns are treated as research tasks with a Decision / Rationale / Alternatives-considered format, per the Spec Kit plan workflow.

---

## Decision 1 — Java coverage tool: JaCoCo Maven plugin

**Decision**: Use the JaCoCo Maven plugin (`org.jacoco:jacoco-maven-plugin`, latest 0.8.x compatible with Java 17) to collect Java coverage. Attach the JaCoCo agent to Surefire via `prepare-agent` in each module. Aggregate cross-module results with a new dedicated Maven module `jacoco-report/` using JaCoCo's `report-aggregate` goal, producing `jacoco-report/target/site/jacoco-aggregate/index.html` (HTML for humans, FR-009) and `jacoco-report/target/site/jacoco-aggregate/jacoco.xml` (machine-readable XML, FR-009).

**Rationale**:
- JaCoCo is the de facto standard for Java + Maven + Spring Boot coverage. It ships bytecode instrumentation that works transparently with Surefire's forked JVM via `prepare-agent`, requires no code changes, and produces both HTML and XML in one run — exactly what FR-009 demands.
- Compatible with Java 17 (this repo's declared version — `pom.xml` line 22 and every module POM's `<java.version>17</java.version>`) and Spring Boot 2.6.3's test starter (JUnit 5, Mockito, AssertJ).
- The `report-aggregate` goal is designed exactly for multi-module reactors like this one; the aggregator module depends on every module we want in the total, and JaCoCo sums their exec files at report time. No external service is required, satisfying spec Clarification Q4 / FR-013.
- The aggregator module keeps the added complexity contained: no changes to how `mvn test` is invoked; the aggregator's `report-aggregate` is bound to the `verify` phase and runs after Surefire finishes across the reactor.

**Alternatives considered**:
- **Cobertura** — abandoned upstream; no Java 17 support.
- **OpenClover** — active but heavier configuration burden; no ecosystem parity with Spring Boot's Surefire defaults; no reason to prefer it over JaCoCo.
- **Aggregate via per-module HTML only (no aggregator module)** — reviewers would have to open six separate reports; FR-011 (per-file line coverage across the reactor) is easier to consume from a single aggregate.
- **External services (Codecov / Coveralls)** — explicitly excluded by spec Clarification Q4 (no external coverage service, no secrets).

---

## Decision 2 — React coverage tool: `react-scripts test --coverage` (built-in, no upgrade)

**Decision**: Use `react-scripts test --coverage --watchAll=false --ci` as the React UI test-and-coverage command. It emits `react-ui/frontend/coverage/lcov-report/index.html` (HTML for humans, FR-010) and `react-ui/frontend/coverage/lcov.info` (LCOV, machine-readable, FR-010). Do not upgrade `react-scripts` from `1.1.1` in this feature; keep the assumption from spec Assumptions intact.

**Rationale**:
- `react-scripts test` uses Jest + Istanbul under the hood; `--coverage` is a built-in flag that produces both HTML and LCOV without any additional dependency or code change. No external service, no additional secrets — satisfies spec Clarification Q4.
- `--watchAll=false` and `--ci` make Jest terminate after a single run (default in `react-scripts` is watch mode), which is required for a non-interactive CI runner.
- Node 16.13.2 and npm 8.0.0 are already declared by `frontend-maven-plugin` in [react-ui/pom.xml](../../react-ui/pom.xml) (lines ~55-70). CI uses the same versions via `actions/setup-node@v4` to match local behavior and to keep the reactor's `frontend-maven-plugin` build in agreement with the workflow's direct `npm` invocations.

**Alternatives considered**:
- **Upgrade `react-scripts` to a modern version (5.x)** — spec Assumptions punt this to a separately-scoped decision. Doing it here would expand scope beyond CI and coverage; skipped.
- **Migrate to Vitest** — larger refactor, requires build-config changes to CRA; not justified for a first pass.
- **Add Istanbul as a separate dependency** — redundant with `react-scripts`'s built-in Istanbul integration.

**Open question** (recorded, non-blocking): `react-scripts 1.1.1` ships with Jest 22.x. Jest 22 predates official Node 16 support. If `--coverage` fails on Node 16.13.2 in practice, the fallback is:
1. First, try pinning Node to a lower version *in CI only* (e.g., Node 12 or 14 via `actions/setup-node@v4`) while leaving `frontend-maven-plugin`'s Node 16.13.2 unchanged — this keeps the CI test surface working without touching the reactor build.
2. If that also fails, upgrading `react-scripts` becomes a separately-scoped decision (spec Assumption line). This plan does not commit to the upgrade; it explicitly reserves the fallback path.

This open question is written into [docs/context/gaps.md](../../docs/context/gaps.md) only if the fallback is triggered during implementation (per Principle IV), not preemptively.

---

## Decision 3 — DB-backed integration test exclusion: Surefire (`*Test.java`) vs. Failsafe (`*IT.java`) naming convention

**Decision**: Adopt the standard Maven Surefire/Failsafe naming convention. Surefire (bound to the `test` phase) runs `**/*Test.java` — these are the unit / in-process tests CI runs on every push. Failsafe (bound to the `verify` phase) would run `**/*IT.java` — any future DB-backed integration test MUST be named this way and MUST NOT run in CI. The CI workflow invokes `./mvnw -B -ntp test` (Surefire only), never `verify`.

**Rationale**:
- Zero-config: this is the default Surefire/Failsafe include pattern. No JUnit tag registration, no filter class, no `application-test.yml` toggle. Reviewers reading the workflow see the mechanism immediately (`mvn test` vs. `mvn verify`).
- Satisfies FR-014 (no DB-backed integration tests in CI): the mechanism is enforced by build-lifecycle contract, not by an in-code annotation that could be forgotten.
- No existing `*IT.java` files exist anywhere in the repo today (checked via file search) — so this convention has zero collision risk on introduction and becomes the going-forward pattern for any future YCQL/YSQL-touching test.
- Compatible with the spec's rising-floor intent (Principle V): as new DB-backed integration tests are eventually added (in a follow-up feature), they land as `*IT.java` and CI stays green until that follow-up feature also adds a Failsafe/DB-container job.

**Alternatives considered**:
- **JUnit 5 `@Tag("integration")` + Surefire `excludeTags`** — works, but requires every author to remember to add the tag; the naming convention is enforceable via file names alone.
- **Maven profile `-P integration-tests`** — off-by-default profiles are fragile: forgetting to activate the profile silently drops tests. Naming-based exclusion is more visible.
- **`@EnabledIfSystemProperty(named = "integration.tests", matches = "true")`** — same fragility as tags; requires per-test annotations.
- **Custom Surefire `<excludes>` list** — brittle; every new file has to be added to the exclude list.

---

## Decision 4 — Fork-safe artifact publishing: `pull_request` trigger + `actions/upload-artifact@v4`

**Decision**: The workflow uses `on: [push, pull_request]` (not `pull_request_target`). Coverage artifacts are uploaded via `actions/upload-artifact@v4` using only the auto-provisioned `GITHUB_TOKEN`. No repository secrets are referenced by the workflow. No `pull_request_target` (which would run the workflow with base-branch code and elevated tokens) is used, per GitHub's security guidance for untrusted fork code.

**Rationale**:
- Satisfies FR-012 (fork PRs must be able to run the build/tests and publish coverage artifacts without secrets they cannot access). `actions/upload-artifact@v4` works on fork PRs; artifacts are attached to the workflow run and viewable from the PR.
- Avoids the well-known "`pull_request_target` + checkout fork code" foot-gun (running untrusted code with a token that can write to the base repo). Since this feature only builds/tests and never publishes, `pull_request` is the correct trigger.
- No repository secrets are needed at all (Decisions 1, 2, and 3 all avoid external services), so the "fork PRs can't access secrets" concern does not apply — this is the strongest fork-safety posture available.

**Alternatives considered**:
- **`pull_request_target`** — allows secrets but runs base-branch code by default; would need explicit checkout of the fork's ref, which is the exact anti-pattern GitHub warns against. Not needed here because we don't publish externally.
- **External artifact host (S3, Codecov artifact upload)** — requires secrets a fork PR can't access; explicitly excluded by spec Clarification Q4.
- **`workflow_run` chain to a second privileged workflow** — added complexity with no benefit given no secrets are required.

---

## Decision 5 — Reactor invocation: single `./mvnw -B -ntp test` reactor build, not per-module matrix

**Decision**: The Java job runs the reactor as a single Maven invocation: `./mvnw -B -ntp -DskipTests=false test`. The JaCoCo aggregator runs as a follow-on invocation: `./mvnw -B -ntp -pl jacoco-report -am verify`. No `matrix` over modules.

**Rationale**:
- Preserves the existing dev experience: `mvn test` from the repo root is the same command a developer runs locally, so CI green means "reproduces on your laptop". This is what [docs/architecture/overview.md](../../docs/architecture/overview.md) already documents as the build/test convention.
- Fewer moving parts on a first pass. The seven-module reactor is small; per-module wall-clock savings from parallelism don't outweigh the added workflow complexity for a first-slice.
- Aggregation is trivial: `report-aggregate` (Decision 1) needs all modules' exec files in the same workspace, which a single reactor invocation naturally provides. A matrix build would require artifact hand-off between jobs.
- Spec `SC-001`/`SC-002` are met by a single job; splitting into a matrix is not required for any success criterion.

**Alternatives considered**:
- **Per-module job matrix** — better parallelism at the cost of workflow complexity and cross-job artifact plumbing. Justified only if wall-clock time becomes a problem later; explicitly out of scope for this feature.
- **Two separate jobs (Java, React) running in parallel** — the plan *does* use two parallel jobs at the top level (`java-reactor` and `react-ui`); "single reactor invocation" refers to the internal invocation *within* the Java job, not to serializing the whole workflow.

---

## Decision 6 — React test file location and setup: colocated `*.test.js` files under `react-ui/frontend/src/**`

**Decision**: React tests live colocated with the component they test, using the `*.test.js` suffix that `react-scripts test` discovers by default (Jest's default `testMatch`). A shared `react-ui/frontend/src/setupTests.js` file is added (also a `react-scripts` convention — auto-loaded before every test) for any cross-suite setup (e.g., jsdom polyfills, `console.error` failure filtering).

**Rationale**:
- Zero-config: `react-scripts` already discovers `*.test.js` and auto-loads `src/setupTests.js`; no configuration changes.
- Colocated tests keep the "add a UI change → add its test" flow trivial (SC-007) and put the test next to the code it exercises.
- Compatible with `react-scripts 1.1.1`'s Jest configuration (which predates the modern `__tests__/` folder convention as the recommended default anyway).

**Alternatives considered**:
- **`__tests__/` folders** — supported but adds a directory-per-component; colocated is simpler.
- **Separate `react-ui/frontend/tests/` root** — breaks with `react-scripts` defaults; adds config surface.

---

## Decision 7 — Behavior-test surface for the Java rising floor (Principle V realization)

**Decision**: The first-slice behavior tests target `api-gateway-microservice` because it is the single external surface for the storefront (Principle I) and every user-relevant flow passes through it. Three initial `MockMvc`-based test classes are added:

1. `ProductCatalogControllerTest` (US4/AC-1): drives `ProductCatalogController` through `MockMvc`, mocks the `ProductCatalogRestClient`, asserts the controller returns the expected product payload and calls the client once — would fail on handler removal or contract change.
2. `ShoppingCartControllerTest` (US4/AC-1): drives `ShoppingCartController` through `MockMvc`, mocks the `ShoppingCartRestClient`, asserts add-to-cart and get-cart round-trips — would fail on handler removal or contract change.
3. `CheckoutFlowGatewayTest` (US4/AC-3, gateway-side): drives the gateway's checkout entry point through `MockMvc`, mocks the checkout `RestClient`, asserts the gateway routes the request correctly. The service-layer stock-verification contract (`NotEnoughProductsInStockException`) is verified separately in `CheckoutServiceImplTest` (on `checkout-microservice`) using mocked `ProductInventoryRepo` — since FR-014 excludes live YCQL, the persisted-effect side asserts on the mocked repository's `verify` interactions.

**Rationale**:
- Directly realizes FR-008 and SC-005: each new handler ships with a behavior test that would fail on removal.
- Honors Principle II by explicitly testing the `NotEnoughProductsInStockException` path at the layer where the stock-verification decision actually lives (`CheckoutServiceImpl`), while respecting FR-014's exclusion of live YCQL.
- Establishes the rising-floor convention: future new handlers on any microservice follow the same `MockMvc` + `@MockBean(<downstream client or repo>)` pattern.

**Alternatives considered**:
- **Start with checkout instead of gateway** — the gateway is the correct starting point per Principle I (single external surface). Checkout gets one test (via `CheckoutServiceImplTest`) for Principle II coverage but is not the primary focus.
- **Full `@SpringBootTest` (context-wide) tests** — heavier, slower, and would drag in Eureka discovery attempts unless carefully sliced. `@WebMvcTest` (or `@SpringBootTest` with `webEnvironment = MOCK`) + `@MockBean` keeps tests fast and hermetic.
- **Also add behavior tests to `login-microservice`** — explicitly excluded by FR-017.

---

## Decision 8 — React initial suite composition (US2 / FR-007 / SC-003)

**Decision**: Three initial test files that map 1:1 to the three FR-007 categories:

1. `src/components/App/App.test.js` — top-level app-shell render test: renders `<App />` inside `MemoryRouter` and asserts a stable landmark element (e.g., the header or router outlet) appears.
2. `src/components/Products/Products.test.js` — `api-gateway`-consuming component test: mocks `axios` (already in `react-ui/frontend/package.json`), renders `<Products />`, asserts it dispatches the expected `api-gateway` GET request path (e.g., `/products` — the exact path is confirmed from the component during implementation) and renders the returned items.
3. `src/components/ShowProduct/ShowProduct.test.js` — `ASIN`-rendering test: renders `<ShowProduct product={{ asin: 'B00EXAMPLE', ... }} />` and asserts the rendered output contains the `ASIN` string.

**Rationale**:
- Each test maps directly to one of the three FR-007 mandated categories and one SC-003 area, making the SC easy to verify.
- Colocated with the components under `src/components/App/`, `src/components/Products/`, `src/components/ShowProduct/` (which already exist per the current directory listing).
- Uses only libraries already in `react-ui/frontend/package.json` (`react`, `react-dom`, `react-router-dom`, `axios`); no new dependencies required to run the initial suite. If `react-testing-library` or `@testing-library/react` is ultimately required for maintainable assertions, that is an isolated, small addition tracked in tasks.

**Alternatives considered**:
- **Snapshot tests** — brittle at this stage; behavior assertions are more durable.
- **End-to-end tests (Cypress/Playwright)** — out of scope for the first slice.

---

## Consolidated open items (deferred, non-blocking)

- Whether `react-scripts 1.1.1` + Node 16.13.2 produces a usable coverage report in practice (Decision 2). Fallback path is written into research; the plan does not gate on it.
- Whether `@testing-library/react` needs to be added when the initial React tests are written (Decision 8). If yes, the tasks phase adds it as a single `devDependency` in `react-ui/frontend/package.json`; if no, it stays out.

Neither open item resolves a `NEEDS CLARIFICATION` from the spec; both are execution-detail contingencies to be resolved by `/speckit.implement`. If either fallback triggers, the outcome is recorded in [docs/context/gaps.md](../../docs/context/gaps.md) via `/speckit.aisdlc.promote` after implement.
