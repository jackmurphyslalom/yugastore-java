# Testing Conventions (Java Modules)

**Status**: Established
**Last Updated**: 2026-09-15

## Overview

Every Java module in this repo (`api-gateway-microservice`, `cart-microservice`,
`checkout-microservice`, `products-microservice`, `eureka-server-local`, `login-microservice`, and
`react-ui`'s Spring Boot backend under `react-ui/src`) uses the same standardized test toolchain:

- **Test framework**: JUnit 5 (via `spring-boot-starter-test`, test scope)
- **Mocking**: Mockito (`mockito-core`, test scope)
- **Assertions**: AssertJ (`assertj-core`, test scope)
- **Coverage**: JaCoCo (`org.jacoco:jacoco-maven-plugin` `0.8.11`)

`react-ui/frontend` (the Create React App / Jest JavaScript frontend) is a separate toolchain and is
not covered by these conventions.

## Running tests with coverage

From any in-scope module's directory:

```sh
./mvnw test
```

This runs the module's test suite and produces a JaCoCo coverage report at
`target/site/jacoco/index.html` (open directly in a browser), with a machine-readable summary at
`target/site/jacoco/jacoco.csv` and `target/site/jacoco/jacoco.xml`.

## Adding the standard block to a new/other module

```xml
<dependency>
  <groupId>org.mockito</groupId>
  <artifactId>mockito-core</artifactId>
  <scope>test</scope>
</dependency>
<dependency>
  <groupId>org.assertj</groupId>
  <artifactId>assertj-core</artifactId>
  <scope>test</scope>
</dependency>
```

```xml
<plugin>
  <groupId>org.jacoco</groupId>
  <artifactId>jacoco-maven-plugin</artifactId>
  <version>0.8.11</version>
  <executions>
    <execution>
      <id>prepare-agent</id>
      <goals><goal>prepare-agent</goal></goals>
    </execution>
    <execution>
      <id>report</id>
      <phase>test</phase>
      <goals><goal>report</goal></goals>
    </execution>
  </executions>
</plugin>
```

No explicit `<version>` is declared for `mockito-core`/`assertj-core` — every module inherits from
`spring-boot-starter-parent` `2.6.3`, whose dependency-management BOM already pins compatible
versions.

## Scope note: no Testcontainers / integration infrastructure

This convention is unit-test scope only. It does not include Testcontainers or any containerized
database (Cassandra/YugabyteDB) test infrastructure. Adding integration-test infrastructure is a
separate, future decision.

## Package convention (important)

`@SpringBootTest` only scans the test class's own package and its sub-packages for a
`@SpringBootConfiguration`/`@SpringBootApplication` class — it does **not** scan parent packages.
Always place a module's Spring Boot test classes in the same package as (or a sub-package of) that
module's `@SpringBootApplication` class. Several modules previously had generated smoke tests placed
in a mismatched package (e.g. a leftover `com.example.demo` package copied from a template), which
caused `./mvnw test` to fail with `IllegalStateException: Unable to find a @SpringBootConfiguration`
even though the test itself was trivially empty.

## Related

- [Before/After Testing Assessment](../../specs/002-testing-framework-alignment/context/before-after-testing-assessment.md)
