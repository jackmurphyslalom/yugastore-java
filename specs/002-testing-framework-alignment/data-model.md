# Phase 1 Data Model: Testing Framework Alignment

This feature has no application data/schema changes. The entities below are the documentation/
tracking entities from the spec's Key Entities section, modeled here as the structured records each
checked-in document must contain.

## In-Scope Module

One row per module, tracked in the before/after assessment report
(`specs/002-testing-framework-alignment/context/before-after-testing-assessment.md`).

| Field | Type | Notes |
|---|---|---|
| `module_name` | enum | One of: `api-gateway-microservice`, `cart-microservice`, `checkout-microservice`, `products-microservice`, `eureka-server-local`, `login-microservice`, `react-ui` |
| `test_dependencies_before` | text | e.g., "spring-boot-starter-test only" or "none" (login-microservice) |
| `test_dependencies_after` | text | Always "spring-boot-starter-test + mockito-core + assertj-core" once this feature is applied |
| `coverage_tool_before` | boolean | Always `false` per spec Current State |
| `coverage_tool_after` | boolean | Always `true` (JaCoCo) once this feature is applied |
| `test_count_before` | integer | Existing test method count (0 for `login-microservice`, 1 for the other 6) |
| `test_count_after` | integer | Same as before for the 6 existing modules; 1 for `login-microservice` |
| `suite_runs_before` | boolean | Whether `./mvnw test` succeeds before changes (false for `login-microservice`: no test sources) |
| `suite_runs_after` | boolean | Whether `./mvnw test` succeeds after changes |
| `coverage_measurable_before` | boolean | Always `false` |
| `coverage_measurable_after` | boolean | Whether a JaCoCo report was produced after changes |
| `coverage_percent_after` | number \| N/A | Overall instruction/line coverage % from the JaCoCo report, when produced |

**Validation rules**: `coverage_percent_after` MUST be reported alongside the ~85% aspirational
figure only as a comparison reference (FR-009), never presented as a target this feature claims to
meet.

## Before/After Testing Assessment Report

**Location**: `specs/002-testing-framework-alignment/context/before-after-testing-assessment.md`

| Field | Type | Notes |
|---|---|---|
| `modules` | list of In-Scope Module rows | All 7, both before and after states |
| `aspirational_coverage_reference` | text | The ~85% figure from `docs/context/sources/2026-09-14-client-requirements-interview.md`, labeled explicitly as aspirational/future, per FR-009 |
| `generated_date` | date | Date the report was produced |

## Testing Conventions Note

**Location**: `docs/patterns/testing-conventions.md`

| Field | Type | Notes |
|---|---|---|
| `status` | enum | `Established` (per `docs/patterns/README.md`'s pattern-status legend) |
| `framework` | text | JUnit 5 |
| `mocking_library` | text | Mockito |
| `assertion_library` | text | AssertJ |
| `coverage_tool` | text | JaCoCo (`jacoco-maven-plugin`) |
| `run_command` | text | `./mvnw test` (per in-scope module directory) |
| `report_location` | text | `target/site/jacoco/index.html` |
| `scope_note` | text | Explicitly states no Testcontainers/integration infra is included (per spec Assumptions) |
