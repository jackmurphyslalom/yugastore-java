# Before/After Testing Assessment

**Feature**: [002-testing-framework-alignment](../spec.md)
**GitHub Issue**: [jackmurphyslalom/yugastore-java#25](https://github.com/jackmurphyslalom/yugastore-java/issues/25)
**Date**: 2026-09-15
**Method**: For each in-scope module, `./mvnw test` was run against the module's original
(pre-feature) `pom.xml`/test sources to capture "Before", then re-run against the standardized
`pom.xml`/test sources to capture "After". Coverage % is overall instruction coverage from
`target/site/jacoco/jacoco.csv`.

## Key finding: the baseline was worse than "trivial but passing"

Before any change, running the existing (empty) smoke test module-by-module showed that **4 of the
6 modules with a pre-existing test class actually failed to build** (`BUILD FAILURE`), not just
lacking real coverage. The cause was the same in every case: the test class's Java package did not
match (or was not a sub-package of) the package containing that module's `@SpringBootApplication`
class, so Spring Boot's `@SpringBootTest` could not locate a configuration
(`IllegalStateException: Unable to find a @SpringBootConfiguration`). This is exactly the kind of
ad-hoc/inconsistent test setup issue #25 called out. Fixing this (moving each broken test class into
the same package as its module's application class, matching the convention already used correctly
in `checkout-microservice` and `eureka-server-local`) was necessary to satisfy this feature's
requirement that every module's test suite actually run — it did not involve authoring any new test
logic; the `contextLoads()` method bodies are unchanged.

## Module-by-module comparison

| Module | Before: framework/deps | Before: test count | Before: suite runs? | Before: coverage measurable? | After: framework/deps | After: test count | After: suite runs? | After: coverage measurable? |
|---|---|---|---|---|---|---|---|---|
| `api-gateway-microservice` | JUnit 5 (via `spring-boot-starter-test`) only | 1 | **No — BUILD FAILURE** (test package `com.example.demo` didn't match app package) | No | JUnit 5 + Mockito + AssertJ + JaCoCo | 1 | Yes | Yes — 10% (67/705 instructions) |
| `cart-microservice` | JUnit 5 only | 1 | **No — BUILD FAILURE** (test package `com.yugabyte.app.yugastore` missing `.cart`) | No | JUnit 5 + Mockito + AssertJ + JaCoCo | 1 | Yes | Yes — 6% (23/374) |
| `checkout-microservice` | JUnit 5 only | 1 | Yes | No | JUnit 5 + Mockito + AssertJ + JaCoCo | 1 | Yes | Yes — 7% (54/829) |
| `products-microservice` | JUnit 5 only | 1 | **No — BUILD FAILURE** (test package `com.example.demo` didn't match app package) | No | JUnit 5 + Mockito + AssertJ + JaCoCo | 1 | Yes | Yes — 10% (72/736) |
| `eureka-server-local` | JUnit 5 only | 1 | Yes | No | JUnit 5 + Mockito + AssertJ + JaCoCo | 1 | Yes | Yes — 38% (3/8) |
| `react-ui` (Spring Boot backend) | JUnit 5 only | 1 | **No — BUILD FAILURE** (test package `com.yugabyte.yugastore.test` didn't match app package `...ui`) | No | JUnit 5 + Mockito + AssertJ + JaCoCo | 1 | Yes | Yes — 4% (18/478) |
| `login-microservice` | **None** — no test dependency, no `src/test` | 0 | No test sources to run | No | JUnit 5 + Mockito + AssertJ + JaCoCo | 1 (new smoke test, parity with other modules) | Yes | Yes — 27% (102/384) |

`react-ui/frontend` (CRA/Jest JavaScript) is unchanged — out of scope (FR-006); `git status
react-ui/frontend` shows no changes.

## The ~85% coverage reference point

A prior client requirements interview recorded an informal ~85% code-coverage target. That figure
is noted here **only as an aspirational future target**. This feature does not attempt to reach it:
no business-logic tests were authored, so the coverage percentages above reflect incidental coverage
from Spring context startup (bean construction, getters/setters invoked during autowiring, etc.),
not deliberate test coverage. Reaching 85% requires a separate, future effort to author real
unit/integration tests.

## What changed vs. what didn't

- **Changed**: every in-scope module's `pom.xml` now declares the same `mockito-core` +
  `assertj-core` (test scope) dependencies and the same `jacoco-maven-plugin` `0.8.11` configuration
  (`prepare-agent` + `report` bound to the `test` phase). `login-microservice` additionally gained
  `spring-boot-starter-test` and a new minimal `contextLoads()` smoke test. Four pre-existing broken
  test classes were moved into the correct package so they can run at all.
- **Not changed**: no assertions were added to any `contextLoads()` test; no business logic was
  tested; `react-ui/frontend` was left untouched.
