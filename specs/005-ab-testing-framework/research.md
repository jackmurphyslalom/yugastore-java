# Research: A/B Testing / Experimentation Framework

**Input**: [plan.md](plan.md) Technical Context, [spec.md](spec.md) FR-001–FR-013

## R-1: Config backend choice

- **Decision**: Spring Cloud Config Server running with the **native (filesystem) profile**, backed by a local `config-repo/` directory inside the new `config-server-microservice` module — not the git-backed default, not HashiCorp Vault.
- **Rationale**: The native profile re-reads its backing files on every client request (no server restart needed for a value change to become visible), which directly satisfies FR-003 (propagation without redeploy/restart) and FR-008 (retirement within the same propagation window). It requires zero new infrastructure (no git remote, no Vault instance) — consistent with the localhost-only deployment target ([ADR-0001](../../docs/architecture/adr/0001-deployment-target-localhost.md)) and with FR-009's resolution that toggle writes are "API/config-file-only," not a new authenticated admin product.
- **Alternatives considered**:
  - *Git-backed Config Server* (Spring Cloud Config's default): rejected for this iteration — it would require a git remote (even a local bare repo) and a git-commit-per-change workflow, adding operational ceremony with no behavioral benefit at this scale (a handful of global toggles), though it remains a natural upgrade path if audit-grade change history is later required.
  - *HashiCorp Vault backend*: rejected — introduces a new dependency family and a new operational surface (Vault server, unseal, ACLs) for a capability (toggle read/write) that has no confidentiality requirement; toggle values are not secrets.
  - *A database table (YCQL/YSQL)*: rejected — would require new schema and would blur this feature's boundary with `cronos.orders`/`cronos.product_inventory` (Principle II); toggles are configuration, not transactional business data.

## R-2: Propagation mechanism

- **Decision**: Each Spring Boot consumer (`products-microservice`, `checkout-microservice`) runs a `@Scheduled` bean that calls Spring Cloud's `ContextRefresher.refresh()` on a fixed interval (documented default: 30 seconds), wrapped in try/catch so a failed refresh attempt is logged and skipped rather than propagated as an error.
- **Rationale**: `spring-cloud-starter-config` (already resolvable from the existing `spring-cloud-dependencies` BOM) ships `ContextRefresher` out of the box; a scheduled poll is the simplest mechanism that meets FR-003's propagation-window requirement (SC-001's 5-minute budget is generous relative to a 30-second poll) without adding a new dependency family. Failures are inherently safe: `ContextRefresher.refresh()` only replaces `Environment` property sources on success, so a failed attempt leaves the last-successfully-applied values in place — this is also the mechanism behind FR-007's last-known-good behavior (see R-4).
- **Alternatives considered**:
  - *Spring Cloud Bus* (RabbitMQ/Kafka-backed `/actuator/busrefresh` fan-out): rejected for this iteration — push-based refresh is faster and avoids polling, but it requires standing up a message broker, a new dependency family this repo does not otherwise use. Documented as a candidate upgrade if the propagation window ever needs to shrink below the poll interval.
  - *Client re-reads config on every request* (no caching): rejected — defeats the purpose of a config client cache, adds Config Source load proportional to shopper traffic, and reintroduces the single-point-of-failure risk FR-007/Story 4 explicitly guards against.

## R-3: Toggle validation ownership (FR-004)

- **Decision**: Value-shape validation lives entirely in `config-server-microservice`'s internal write endpoint (`ExperimentToggleAdminController` + `ToggleAllowList`), which checks a submitted key/value pair against a documented per-key allow-list (e.g., `experiment.ranking-strategy` ∈ {`default`, `price-desc`, `newest-first`}) before writing to `config-repo/application.yml`. Consuming tiers trust values already validated at write time and do not re-validate.
- **Rationale**: Centralizing validation avoids duplicating an allow-list in three consumers (`products-microservice`, `checkout-microservice`, `api-gateway-microservice`) and matches FR-004's requirement that invalid values are rejected "at submission time," not discovered later by a consumer at read time.
- **Alternatives considered**: *Consumer-side validation* (each tier validates what it reads and ignores invalid values): rejected as the sole mechanism — it would let an invalid value be written and silently ignored per-consumer rather than rejected with a clear reason at the moment of change, which is what FR-004 and User Story 1's Acceptance Scenario 3 require.

## R-4: Last-known-good fallback mechanics (FR-007)

- **Decision**: No custom caching layer is built. `ContextRefresher.refresh()`'s existing success/failure semantics are the fallback mechanism: a successful poll replaces the active property values; a failed poll (Config Source down or slow) leaves the previously-applied values serving, because `Environment` property sources are only swapped on success. A tier that has never successfully fetched (fresh deploy during a Config Source outage) falls back to a built-in default declared directly in that tier's own `application.yml` (e.g., `experiment.ranking-strategy: default`), which Spring's property resolution already prefers only when no higher-precedence config-server value has been applied yet.
- **Rationale**: Reuses a mechanism already provided by the Spring Cloud Config Client dependency this feature is introducing anyway — no bespoke cache, no new failure-handling code path to test beyond "the scheduled poller doesn't crash the app on failure."
- **Alternatives considered**: *Explicit local cache file per consumer* (write last-known-good value to disk on every successful read): rejected as unnecessary — in-memory `Environment` state already provides this for the lifetime of the running process, which is the only lifetime FR-007/Story 4 care about (a full process restart during an outage is an edge case already covered by the "documented built-in default" behavior).
