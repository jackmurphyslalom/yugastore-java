# Quickstart: Validating Testing Framework Alignment

This guide validates the standardized JaCoCo + Mockito + AssertJ tooling once applied. It does not
duplicate the `pom.xml`/plugin configuration itself — see [research.md](research.md) Decisions 1–2
for the exact blocks, and [data-model.md](data-model.md) for what the before/after report and
conventions doc must contain.

## Prerequisites

- Java 17 and no other local toolchain changes — every in-scope module already builds with its own
  `./mvnw` wrapper.
- Run all commands from each module's own directory (not the repo root), matching the existing
  per-module convention.

## Per-module validation (repeat for all 7 in-scope modules)

Modules: `api-gateway-microservice`, `cart-microservice`, `checkout-microservice`,
`products-microservice`, `eureka-server-local`, `login-microservice`, `react-ui`.

1. **Before capture** (once, prior to any `pom.xml`/test change):
   ```bash
   cd <module>
   ./mvnw test
   ```
   Record pass/fail and confirm `target/site/jacoco/` does not exist yet.

2. **Apply the standardized tooling** to `<module>/pom.xml` per research.md Decisions 1–2 (and, for
   `login-microservice` only, Decision 3's `spring-boot-starter-test` dependency + new
   `YugastoreLoginServiceTests.java`).

3. **After capture**:
   ```bash
   cd <module>
   ./mvnw test
   ```
   Confirm:
   - the run passes (same test count as before, plus 1 for `login-microservice`);
   - `target/site/jacoco/index.html` now exists;
   - the reported overall instruction/line coverage % is captured.

4. Record both captures as one row in
   `specs/002-testing-framework-alignment/context/before-after-testing-assessment.md`
   (see data-model.md's *In-Scope Module* fields).

## Validating `login-microservice` parity specifically

```bash
cd login-microservice
./mvnw test
```

Expected: the run now succeeds (previously there were no test sources to run at all), executing
exactly one `contextLoads()`-style test, and produces a JaCoCo report — matching the other 6
modules' behavior (spec User Story 2, Acceptance Scenarios 1–3).

## Validating `react-ui/frontend` is untouched

```bash
git status react-ui/frontend
```

Expected: no changes reported (FR-006).

## Validating the documentation deliverables

- `docs/patterns/testing-conventions.md` exists and, on its own, lets a reader identify the required
  test framework, mocking library, assertion library, and coverage tool for any in-scope module
  without opening any `pom.xml` (SC-006).
- `specs/002-testing-framework-alignment/context/before-after-testing-assessment.md` exists and
  covers all 7 modules' before/after state per data-model.md, with the ~85% figure referenced only
  as an aspirational future target (FR-009).

## Success criteria mapping

| Spec Success Criterion | Verified by |
|---|---|
| SC-001 | Diffing the added block across all 7 `pom.xml` files — identical apart from module name/package |
| SC-002 | Step 3's "after capture" passing for all 7 modules |
| SC-003 | Step 3's `target/site/jacoco/index.html` check for all 7 modules |
| SC-004 | "Validating `login-microservice` parity specifically" section |
| SC-005 | "Validating the documentation deliverables" section, before/after report |
| SC-006 | "Validating the documentation deliverables" section, conventions note |
