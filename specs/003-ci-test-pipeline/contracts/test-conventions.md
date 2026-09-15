# Contract: Test Conventions

**Feature**: 003-ci-test-pipeline
**Applies to**: All Java and React tests added, changed, or introduced by this feature; the pattern this feature establishes for future test work per Constitution Principle V.
**Purpose**: Codify the durable test-writing rules so `/speckit.implement` and future contributors follow the same convention.

---

## Java tests

### Discovery and naming

| File suffix | Runs in | CI runs it? |
|---|---|---|
| `**/*Test.java` | Surefire (`mvn test`) | Yes, on every push and PR |
| `**/*IT.java` | Failsafe (`mvn verify`) | No (FR-014). Reserved for future DB-backed integration tests. |

Any new Java test added by this feature MUST end in `Test.java`.

### Behavior-test requirements (Constitution Principle V realization)

For any new or changed Java behavior touched by this feature, the corresponding test MUST:

1. Exercise the actual behavior (call the handler / service method / repository method under test), not merely assert that the Spring application context loads.
2. Use `MockMvc` (for `@Controller` classes) or a direct method call on an autowired bean (for `@Service` classes) — not `TestRestTemplate` against a live server (which would require Eureka + downstreams up).
3. Mock downstream collaborators with `@MockBean`: `RestClient` classes on `api-gateway-microservice`; `*Repository` interfaces on the microservice modules.
4. Assert on observable behavior (returned payload, thrown exception, mock interactions), not on internal state.
5. Would fail if the handler / service method under test were removed or its contract broken — this is the SC-005 acceptance criterion.

Existing `contextLoads()`-only tests MAY remain untouched but MUST NOT be counted as coverage for any new behavior.

### Test slice patterns

| Layer | Preferred slice | Rationale |
|---|---|---|
| `@RestController` on `api-gateway-microservice` | `@WebMvcTest(<Controller>.class)` + `@MockBean(<RestClient>)` + `MockMvc` | Fast, hermetic, gateway-boundary appropriate (Principle I) |
| `@RestController` on a microservice | `@WebMvcTest(<Controller>.class)` + `@MockBean(<Repository>)` + `MockMvc` | Fast, hermetic |
| `@Service` on any module | Direct instantiation with Mockito-mocked collaborators, OR `@SpringBootTest(webEnvironment = MOCK)` + `@MockBean(<Repository>)` | Whichever is smaller for the test in question |

### Prohibited patterns for this feature

- No test may require a live YugabyteDB YCQL or YSQL cluster to pass (FR-014).
- No test may require a live Eureka registry to pass (would violate the fork-safe CI posture and add flake surface).
- No test may hit a real network endpoint (no external HTTP dependency).
- No test may bypass the `api-gateway` from anything the running React UI represents (Principle I).
- No test may be added or changed under `login-microservice` (FR-017 — the module compiles, existing tests run; no new authoring).

### Coverage instrumentation

Every reactor module MUST have the JaCoCo agent attached to Surefire (`jacoco-maven-plugin`'s `prepare-agent` goal bound to the `initialize` phase). This is added at the reactor `pom.xml` level so no per-module change is needed beyond ensuring child POMs inherit the configuration.

---

## React tests

### Discovery and naming

| Path pattern | Runs in | CI runs it? |
|---|---|---|
| `react-ui/frontend/src/**/*.test.js` | `react-scripts test` (Jest) | Yes, on every push and PR |
| `react-ui/frontend/src/setupTests.js` | Auto-loaded by `react-scripts` before every test | N/A (setup only) |

Any new React test added by this feature MUST end in `.test.js` and live under `react-ui/frontend/src/**` (Research Decision 6).

### Colocation

Tests are colocated with the component they test:

```
src/components/Products/
├── Products.jsx        (or index.js)
└── Products.test.js    ← test for the sibling
```

### Rendering approach for the initial suite

- Use `react-dom/test-utils` OR `@testing-library/react` (if adopted during implementation) — not enzyme, not snapshot-only tests.
- Mock `axios` (already a dependency) for any component that calls the `api-gateway`.
- Assert on rendered DOM structure or dispatched network calls, not on component internal state.

### `setupTests.js` responsibilities

- Configure any global test polyfills required by `react-scripts 1.1.1` / Jest 22 on Node 16.13.2 (e.g., `TextEncoder` if any test needs it; usually none for this initial suite).
- MUST NOT contain assertions.
- MUST NOT mock modules globally in a way that individual tests cannot override.

### CI-mode invocation

CI invokes: `npm test -- --coverage --watchAll=false --ci`

- `--coverage` → produces `coverage/` output (FR-010).
- `--watchAll=false` → non-watch mode; runs once and exits (required for a non-interactive runner).
- `--ci` → CI-friendly output; disables interactive prompts; snapshot regeneration is treated as failure.

### Prohibited patterns for this feature

- No end-to-end tests requiring a running backend (out of scope; would require CI to stand up services, which FR-014 blocks).
- No test may fetch from a real `api-gateway` URL.
- No test may depend on a browser (`react-scripts test` uses jsdom; that is deliberately the boundary).
- No upgrade of `react-scripts` from `1.1.1` in this feature (spec Assumptions; Research Decision 2 fallback only if `--coverage` cannot be produced).

---

## Cross-cutting

### Terminology (Principle III)

Human-facing text in test class names, describe blocks, log messages, error messages, workflow display, and artifact names MUST use canonical terms from [docs/product/glossary.md](../../../docs/product/glossary.md):

- `api-gateway` — the module `api-gateway-microservice` and its role
- `Eureka` — service registry (`eureka-server-local`)
- `YCQL` — YugabyteDB Cassandra-compatible API
- `YSQL` — YugabyteDB Postgres-compatible API
- `ASIN` — product identifier

`Cronos` is permitted only in code identifiers: the `cronoscheckoutapi` Java package on `checkout-microservice` and the `cronos.*` YCQL/YSQL keyspace/table names. It MUST NOT appear in test class names, describe blocks, workflow display text, or artifact names.

### Failing-well requirement (SC-002 / Edge Case: "test is flaky")

Every test added by this feature MUST fail loudly and locally (assertion message with expected vs. actual) rather than swallow exceptions. Flake mitigation (retry, quarantine) is explicitly out of scope; the pipeline reports the actual run result.
