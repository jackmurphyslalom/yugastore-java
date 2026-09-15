# Implementation Plan: Testing Framework Alignment

**Branch**: `002-testing-framework-alignment` | **Date**: 2026-09-15 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/002-testing-framework-alignment/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command; its definition describes the execution workflow.

## Summary

Standardize JUnit 5 + Mockito + AssertJ + JaCoCo test tooling identically across the 7 in-scope
Java modules (`api-gateway-microservice`, `cart-microservice`, `checkout-microservice`,
`products-microservice`, `eureka-server-local`, `login-microservice`, `react-ui`), bring
`login-microservice` to test-infrastructure parity with a `spring-boot-starter-test` dependency plus
one `contextLoads()`-style smoke test, and produce a checked-in before/after assessment report plus
a short testing-conventions doc. This is tooling/config work only: no business-logic tests are
authored, and `react-ui/frontend`'s Jest setup is untouched.

## Technical Context

**Language/Version**: Java 17 on Maven. Spring Boot `2.6.3` (root `pom.xml`) — but each of the 7
in-scope modules independently declares `spring-boot-starter-parent:2.6.3` as its own `<parent>`;
the root `pom.xml` is an aggregator only (`packaging=pom`, lists the 7 `<modules>`) and is **not**
the Maven parent of any of them. There is no shared `dependencyManagement`/`pluginManagement` to
centralize test-tooling config in — each module's `pom.xml` must be edited individually.

**Primary Dependencies**: JUnit 5 (`org.junit.jupiter`, already present via `spring-boot-starter-test`
in 6 of 7 modules — verified directly in each `pom.xml`), Mockito (`mockito-core`, test scope — net
new explicit dependency, version resolved from the already-inherited `spring-boot-starter-parent`
BOM, not hardcoded), AssertJ (`assertj-core`, test scope — same BOM-resolved approach), JaCoCo
(`org.jacoco:jacoco-maven-plugin` — net new; not BOM-managed, so it needs one explicit, identical
version literal repeated in all 7 `pom.xml` files).

**Storage**: N/A — no schema, data, or repository-layer changes.

**Testing**: Maven Surefire via each module's own `./mvnw test` (existing per-module convention,
confirmed in `docs/architecture/overview.md`). This feature adds JaCoCo report generation to that
same invocation; it does not introduce a new command shape (e.g., no switch to `mvn verify`).

**Target Platform**: The 7 in-scope Java/Spring Boot backend modules (`react-ui`'s Spring Boot
backend under `react-ui/src`, not `react-ui/frontend`). `react-ui/frontend` (Create React App / Jest)
is explicitly excluded per FR-006 and is not touched by any change in this plan.

**Project Type**: Independently-parented Maven modules under one aggregator reactor `pom.xml` —
a tooling/config alignment change, not new application code or a new service boundary.

**Performance Goals**: N/A.

**Constraints**: No new business-logic/unit tests may be authored (FR-005); `login-microservice`'s
only new test is one `contextLoads()`-style smoke test (FR-004); `react-ui/frontend` must remain
byte-for-byte untouched (FR-006); the 6 modules' existing empty `contextLoads()` smoke tests must
keep passing unchanged after the JaCoCo/Mockito/AssertJ additions (spec Edge Cases).

**Scale/Scope**: 7 `pom.xml` edits (an identical JaCoCo + Mockito + AssertJ block repeated in each,
since there is no shared parent to centralize it); 1 additional `pom.xml` edit for
`login-microservice` to add `spring-boot-starter-test`; 1 new test file
(`login-microservice/src/test/java/.../YugastoreLoginServiceTests.java`); 1 before/after assessment
report; 1 testing-conventions doc.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Gate | Status |
|---|---|---|
| I. Gateway-Only Service Boundary | No microservice-to-microservice calls, gateway routing, or Eureka registration behavior is added or changed. | PASS (N/A) |
| II. Consistency-Sensitive Data Paths | No changes touch `cronos.orders`, `cronos.product_inventory`, or any transactional order/inventory code. | PASS (N/A) |
| III. Canonical Terminology | Uses only existing glossary-aligned module names; introduces no new product/domain terms requiring a glossary addition. | PASS |
| IV. Context-Grounded Change | Grounded in direct inspection of all 7 in-scope `pom.xml` files, the root aggregator `pom.xml`, and an existing `contextLoads()` test (`cart-microservice`); `docs/context/gaps.md` reviewed — the one related gap (`login-microservice` integration/completion scope) is about wiring business behavior to the gateway, which FR-005 explicitly keeps out of this feature's scope, so it does not block tooling-only parity work. | PASS |
| V. Incremental Test Hardening | This feature ships no new or changed business behavior — only test tooling/config plus one parity smoke test (FR-004/FR-005) — so the "must exercise the actual behavior change" bar does not apply; existing low-signal smoke tests intentionally remain low-signal by design (spec Edge Cases), not treated as sufficient coverage for any future behavior change. | PASS (not applicable; no behavior change is shipped) |

No violations. Complexity Tracking table is not applicable.

## Project Structure

### Documentation (this feature)

```text
specs/002-testing-framework-alignment/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── context/
│   └── before-after-testing-assessment.md  # FR-007 (feature-scoped, point-in-time)
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

No `contracts/` directory: this feature has no external API, CLI, or UI interface to contract —
it only changes build/test tooling configuration and adds one smoke test.

### Source Code (repository root)

```text
pom.xml                               # aggregator only (packaging=pom); untouched

api-gateway-microservice/pom.xml      # + jacoco-maven-plugin, mockito-core, assertj-core (test scope)
cart-microservice/pom.xml             # + jacoco-maven-plugin, mockito-core, assertj-core (test scope)
checkout-microservice/pom.xml         # + jacoco-maven-plugin, mockito-core, assertj-core (test scope)
products-microservice/pom.xml         # + jacoco-maven-plugin, mockito-core, assertj-core (test scope)
eureka-server-local/pom.xml           # + jacoco-maven-plugin, mockito-core, assertj-core (test scope)
react-ui/pom.xml                      # + jacoco-maven-plugin, mockito-core, assertj-core (test scope)

login-microservice/
├── pom.xml                           # + spring-boot-starter-test, then + jacoco/mockito/assertj block
└── src/test/java/com/yugabyte/app/yugastore/
    └── YugastoreLoginServiceTests.java   # new contextLoads()-style smoke test (FR-004)

docs/patterns/
└── testing-conventions.md            # FR-008 (durable, reusable default across in-scope modules)
```

**Structure Decision**: Every one of the 7 in-scope modules gets the identical
JaCoCo/Mockito/AssertJ block added directly to its own `pom.xml` (no shared parent exists to add it
once). `login-microservice` additionally gains `spring-boot-starter-test` (the one dependency the
other 6 already had) plus a single new smoke test file mirroring the existing
`cart-microservice`/`checkout-microservice`/etc. `contextLoads()` pattern. The durable,
forward-looking testing-conventions doc lives under `docs/patterns/` per that directory's own
stated purpose ("reusable patterns... future work should follow for consistency"); the one-off
before/after comparison snapshot lives under this feature's own `specs/.../context/` folder, since
it documents a point-in-time state change rather than a durable convention.

## Complexity Tracking

No Constitution Check violations were identified. This table is not applicable.
