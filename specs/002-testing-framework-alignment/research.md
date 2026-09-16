# Phase 0 Research: Testing Framework Alignment

All choices below (JUnit 5, Mockito, AssertJ, JaCoCo) were already confirmed as settled scope by
the stakeholder (see spec Assumptions). This research resolves *how* to apply them consistently
given this repo's actual Maven layout, not *whether* to use them.

## Decision 1: Mockito/AssertJ version alignment via the inherited Spring Boot BOM

**Decision**: Add `mockito-core` and `assertj-core` as explicit `test`-scope dependencies to each
of the 7 in-scope `pom.xml` files **without** an explicit `<version>` element.

**Rationale**: Every in-scope module already declares `spring-boot-starter-parent:2.6.3` as its own
`<parent>` (confirmed by reading all 7 `pom.xml` files). `spring-boot-starter-parent` sets
`spring-boot-dependencies` as its own parent, which is the BOM that already manages the JUnit
Jupiter and Mockito versions pulled in transitively via `spring-boot-starter-test` (confirmed via
Spring Boot's own build sources: `spring-boot-starter-test` depends on `org.junit.jupiter:junit-jupiter`
with no version, and `spring-boot-dependencies` declares a managed `Mockito` library entry resolved
through `mockito-bom`; AssertJ is managed the same way). Adding the two dependencies without a
version means every module resolves the *same* version because they all inherit the *same* BOM —
"version-aligned" by construction, with nothing to keep in sync by hand.

**Alternatives considered**:
- Hardcode identical literal `<version>` values for `mockito-core`/`assertj-core` in all 7 files —
  rejected: adds a manual-drift risk (someone edits one file later and forgets the rest) for no
  benefit, since the shared parent already guarantees alignment.
- Introduce a new shared parent POM across the 7 modules to centralize
  `dependencyManagement`/`pluginManagement` once — rejected for this feature: it is a larger
  structural change than "align test tooling," and none of FR-001–FR-004 require it. Worth flagging
  as a future promotion candidate (see plan.md Summary note to `/speckit.aisdlc.promote`), not part
  of this feature's scope.

## Decision 2: JaCoCo Maven plugin version and phase binding

**Decision**: Add `org.jacoco:jacoco-maven-plugin` version `0.8.11` (identical literal version
repeated in each of the 7 `pom.xml` files) with two executions: the default `prepare-agent` goal
(binds to phase `initialize` by default) and a `report` execution explicitly bound to phase `test`.

```xml
<plugin>
  <groupId>org.jacoco</groupId>
  <artifactId>jacoco-maven-plugin</artifactId>
  <version>0.8.11</version>
  <executions>
    <execution>
      <goals><goal>prepare-agent</goal></goals>
    </execution>
    <execution>
      <id>jacoco-report</id>
      <phase>test</phase>
      <goals><goal>report</goal></goals>
    </execution>
  </executions>
</plugin>
```

**Rationale**: JaCoCo is not part of the Spring Boot BOM, so it needs one explicit version pinned
identically everywhere (confirmed via JaCoCo's own Maven plugin docs). Binding the `report` goal to
phase `test` (rather than its default `verify` binding) means the existing per-module command every
module already uses today — `./mvnw test` — produces the coverage report directly, satisfying
FR-002/FR-003/SC-002/SC-003 and the "consistent command pattern" assumption without asking anyone
to switch to `mvn verify`.

**Alternatives considered**:
- Leave `report` on its default `verify` binding — rejected: would require every module's habitual
  test command to change from `test` to `verify`, violating FR-003 ("no module requiring... a
  different invocation style").
- Use a version range or `LATEST` — rejected: non-reproducible builds across the 7 modules and over
  time.

## Decision 3: `login-microservice` smoke test convention

**Decision**: `login-microservice/pom.xml` first gains `spring-boot-starter-test` (test scope) —
the one dependency the other 6 modules already had — then the same JaCoCo/Mockito/AssertJ block
from Decisions 1–2. A new file,
`login-microservice/src/test/java/com/yugabyte/app/yugastore/YugastoreLoginServiceTests.java`, adds
a `@SpringBootTest`-annotated class with a single empty `contextLoads()` `@Test` method — the exact
pattern already used by every other in-scope module (verified directly against
`cart-microservice/src/test/java/com/yugabyte/app/yugastore/YugastoreCartTests.java`), package- and
class-name-aligned to `login-microservice`'s own main application class, `YugastoreLoginService`.

**Rationale**: Matches FR-004/User Story 2's explicit requirement to mirror the convention "already
present in the other modules," using an existing module's test as the verified template rather than
inventing a new style.

**Alternatives considered**: A richer test that exercises `UserServiceImpl`/`UserController` —
rejected: explicitly out of scope per FR-005 ("MUST NOT include authoring new... business-logic
tests").

## Decision 4: Before/after verification approach

**Decision**: For each of the 7 modules, run `./mvnw test` from that module's own directory (its
own Maven wrapper — the existing per-module convention, not a new root-aggregator command) once
before any `pom.xml`/test changes and once after, recording per module:

- pass/fail result of the run;
- whether a JaCoCo report was produced (`target/site/jacoco/index.html` present or not);
- the overall instruction/line coverage percentage after (read from
  `target/site/jacoco/jacoco.xml` or the HTML summary), when a report exists.

Results are captured in `specs/002-testing-framework-alignment/context/before-after-testing-assessment.md`.

**Rationale**: Directly matches this repo's already-documented per-module test convention
(`docs/architecture/overview.md`: "per-module `src/test/java`"). For `login-microservice`, the
"before" state is expected to be "no test sources to run" rather than a failing test — that
absence-of-infrastructure state *is* the documented baseline (spec Current State).

**Alternatives considered**:
- Running tests only from the root aggregator (`./mvnw test` at repo root, invoking the full
  reactor) — usable as an optional cross-check, but not the primary per-module command shape that
  FR-003 references.
- A new custom verification script — rejected: adds tooling the spec does not ask for; plain
  `./mvnw test` per module is sufficient and already the existing convention.

## Decision 5: Documentation placement

**Decision**:
- The before/after assessment report (FR-007) lives at
  `specs/002-testing-framework-alignment/context/before-after-testing-assessment.md`.
- The testing-conventions note (FR-008) lives at `docs/patterns/testing-conventions.md`, with
  pattern status `Established`.

**Rationale**: The before/after report is a point-in-time snapshot tied to this one feature — it
belongs in this feature's own `specs/*/context/` folder, consistent with this repo's existing
feature-scoped context convention (`AGENTS.md`; `docs/context/README.md`). The conventions note is a
durable, reusable-by-default guide for any future contributor writing tests in any in-scope
module — `docs/patterns/README.md` already states that is exactly what `docs/patterns/` is for
("reusable patterns... future work should follow for consistency").

**Alternatives considered**:
- Both docs under `docs/` — rejected: the before/after report is not a durable, reusable pattern,
  so it would not fit `docs/patterns/`'s stated purpose.
- Both docs under `specs/002-testing-framework-alignment/context/` — rejected: the conventions note
  needs to be discoverable by future, unrelated feature work, not buried inside one feature's
  folder.
