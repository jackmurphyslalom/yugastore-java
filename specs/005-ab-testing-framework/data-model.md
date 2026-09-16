# Data Model: A/B Testing / Experimentation Framework

**Input**: [spec.md](spec.md) Key Entities, [research.md](research.md)

## Experiment Toggle

A named, externally-editable configuration value read at runtime by one or more consuming tiers.

| Field | Type | Notes |
|---|---|---|
| `key` | string | Dotted property name, e.g. `experiment.ranking-strategy`. Must appear in `ToggleAllowList` (R-3) to be writable. |
| `value` | string | Current active value. Must be one of the allow-listed values for `key`. |
| `updatedAt` | ISO-8601 timestamp | When this value was last successfully written. Answers FR-006 "since when." |
| `updatedBy` | string (optional) | Free-text identifier of the experiment owner/engineer who made the change, if supplied on write. Not an authenticated identity (FR-009 resolution — infrastructure-layer auth, not a login system). |

**Storage**: one YAML key per `Experiment Toggle` inside `config-server-microservice/config-repo/application.yml` (the shared config profile Spring Cloud Config Server serves to every registered client application by default).

**Validation rule**: a write is rejected, with a specific human-readable reason, if `key` is not in `ToggleAllowList` or `value` is not one of that key's allowed values (FR-004). A rejected write does not change `config-repo/application.yml` and does not append a history entry.

## Config Source

The Spring Cloud Config Server instance (`config-server-microservice`) that stores and serves current toggle values.

| Field | Type | Notes |
|---|---|---|
| `applicationName` | string | Eureka service ID, `config-server-microservice`. |
| `profile` | string | Fixed to `native` for this iteration (R-1). |
| `configRepoPath` | path | `config-server-microservice/config-repo/` — the filesystem location the native profile reads from. |

Not a persisted domain row — this entity is the module/service itself, documented here because the spec's Key Entities section calls it out explicitly.

## Propagation Window

The documented maximum time between a toggle change being committed and all consuming tiers serving the new value.

| Field | Type | Notes |
|---|---|---|
| `pollIntervalSeconds` | integer | Default 30s (R-2), configurable per consumer via `application.yml`. |
| `documentedMaxSeconds` | integer | Communicated value used in SC-001/SC-004 verification — set to a value comfortably inside the 5-minute (300s) SC-001 budget, e.g. 60s, to leave margin for scheduler jitter and Config Source read latency. |

Not a persisted entity — a documented constant plus the two consumers' `@Scheduled` intervals.

## Last-Known-Good Value

The most recent successfully retrieved toggle value a consuming tier caches locally, served when the Config Source is unavailable (FR-007).

| Field | Type | Notes |
|---|---|---|
| (implicit) | Spring `Environment` property source | No explicit field/table — this is the in-memory property value Spring's `ContextRefresher` last successfully applied (R-4). Cleared only by process restart, at which point the tier's own `application.yml` built-in default takes over until the next successful fetch. |

## Experiment Owner *(actor, not a persisted domain object)*

The primary human actor changing toggle values, subject to the FR-009 resolution: authorized via infrastructure-layer access to the internal write endpoint (network/deployment-topology control), not an authenticated user record. No `User`/`Role` entity is introduced by this feature; `login-microservice` remains untouched.

## Toggle Change Event

A record of a toggle change, appended on every successful write — needed to answer "which experiment produced this outcome" (Story 3) and to support FR-006.

| Field | Type | Notes |
|---|---|---|
| `key` | string | Which toggle changed. |
| `previousValue` | string | Value before this change (empty/`null` if this is the toggle's first-ever write). |
| `newValue` | string | Value after this change. |
| `changedAt` | ISO-8601 timestamp | When the write was accepted. |
| `changedBy` | string (optional) | Free-text identifier, if supplied. |

**Storage**: appended as one JSON object per line (or one array entry) in `config-server-microservice/config-repo/toggle-history.json`. Read-only for consumers; written only by `ExperimentToggleAdminController` on a successful validated write. No rejected/invalid write attempt is recorded here (rejections are returned synchronously to the caller with a reason, per FR-004, and are not part of the durable history).

## Relationships and invariants

- Exactly one **Config Source** exists per deployment (single `config-server-microservice` instance, matching every other module's single-instance local-run pattern).
- Every **Experiment Toggle** currently being read by a consumer MUST have a documented built-in default in that consumer's own `application.yml` (invariant enforced by code review / `/speckit.tasks` acceptance, not by a runtime check) — this is what makes FR-007's "fall back to a documented built-in default" possible for a tier with no cached value yet.
- A **Toggle Change Event** is append-only; history is never edited or deleted by this feature (no requirement in spec.md calls for history mutation or retention limits — out of scope for this iteration).
- `key` values are shared, global, single-active-value settings (FR-011) — there is no per-shopper variant of an `Experiment Toggle` in this iteration's data model.
