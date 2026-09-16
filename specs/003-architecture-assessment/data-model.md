# Phase 1 Data Model: Architecture Assessment

This feature has no database/runtime data model — its "entities" are Markdown documents and a
fixed enumeration. Documented here as the artifact schema the two skills must produce/consume.

## Application Tier (fixed enumeration)

Not user-editable data; a fixed set of 7 values used to validate skill targets (FR-001, FR-002).

| Value | Notes |
|---|---|
| `eureka-server-local` | Service registry |
| `products-microservice` | Product catalog |
| `checkout-microservice` | Checkout + orders |
| `cart-microservice` | Shopping cart |
| `api-gateway-microservice` | Single external API surface; also the C3 diagram's scope |
| `login-microservice` | WIP/unwired — still receives full treatment (FR-007) |
| `react-ui` | React storefront frontend |

Any target string outside this set (including paths under `.agents/`, `.specify/`, `.github/`)
MUST be rejected by the per-tier skill (FR-002).

## Tier Assessment File

**Path**: `meta/architecture-assessment/{tier-name}.md`, one per tier, `{tier-name}` = the exact
value from the Application Tier enumeration.

| Field | Type | Required | Notes |
|---|---|---|---|
| Context section | Markdown section (`## Context`) | Yes | Specific to the tier (FR-004) |
| Findings section | Markdown section (`## Findings`) | Yes | Specific to the tier (FR-004); MUST note load/performance-testing tooling and status (FR-022) |
| Recommendation section | Markdown section (`## Recommendation`) | Yes | Specific to the tier (FR-004); MUST include an explicit rationale, a T-shirt size (S/M/L/XL), a risk category, and human-vs-agent time-on-task estimates (FR-020, FR-021) |
| 16-factor table | Markdown table, 16 rows, columns `Factor \| Name \| Score \| Explanation \| Gap to 5 \| Quick Fix` | Yes | Factors I-XII scored; XIII-XVI scored or "N/A" (FR-005, FR-006); `Gap to 5` = `5 − Score` or `N/A` (FR-018); `Quick Fix` required for any factor scored below 5 (FR-019) |
| WIP/unwired finding | Explicit statement within the file | Only for `login-microservice` | Sourced from `docs/architecture/overview.md` (FR-007) |

**Validity rule** (used by the rollup skill's gate, FR-009/FR-010): a tier file is *valid* only if
it contains all of `## Context`, `## Findings`, `## Recommendation`, and `## 16-Factor
Assessment`; otherwise it is treated as missing.

**Lifecycle**: Overwritten in full on every re-run for that tier (FR-016) — not incrementally
patched or hand-preserved.

## Recommendation (entity detail)

| Field | Type | Required | Notes |
|---|---|---|---|
| Rationale | Prose | Yes | Explicit "why", not just "what" (FR-020) |
| Size | Enum: `S` \| `M` \| `L` \| `XL` | Yes | T-shirt size of the recommended change (FR-021) |
| Risk | Category + short reason | Yes | Explicitly flags when an alternative would amount to a wholesale refactor (FR-021) |
| Human time-on-task | Estimate | Yes | Estimated effort for a human implementer (FR-021) |
| Agent time-on-task | Estimate | Yes | Estimated effort for an agent implementer (FR-021) |

## AI 16-Factor Model (reference framework, not generated data)

Source of truth: `docs/context/sources/2026-09-14-twelve-to-sixteen-factor-app.md`. Consists of
the classic 12-factor principles (I-XII) plus 4 AI-era factors:

- XIII. Prompts as code
- XIV. State as a service
- XV. Observability for non-determinism
- XVI. Trust & safety by design

Every tier assessment scores all 16; factors XIII-XVI are marked `N/A` for tiers with no AI/LLM
component (all 7 tiers today, per spec Assumptions).

## Rollup Index (`README.md`)

**Path**: `meta/architecture-assessment/README.md` (singular, always regenerated in full).

| Field | Type | Required | Notes |
|---|---|---|---|
| Index/links | Markdown links or list | Yes | Identifies/links all 7 per-tier files (FR-013) |
| C1 diagram | ```mermaid``` block, System Context | Yes | Whole system, all 7 tiers (FR-011) |
| C2 diagram | ```mermaid``` block, Container | Yes | Whole system, all 7 tiers (FR-011) |
| C3 diagram | ```mermaid``` block, Component | Yes | `api-gateway-microservice` only (FR-011) |
| Foundational Posture Score section | Markdown section | Yes | Cross-tier sixteen-factor summary aggregating all 7 tiers (FR-023) |

**Exclusion**: No C4-Code (level 4) diagram (FR-012).

**Lifecycle**: Idempotent full overwrite on every successful rollup run (FR-017); never appended
to, never written partially (FR-010).

## Foundational Posture Score (entity)

**Location**: A section within `meta/architecture-assessment/README.md`, produced by the rollup
skill once all 7 tier files carry `Gap to 5`, `Quick Fix`, and strengthened Recommendation
fields (FR-023).

| Field | Type | Required | Notes |
|---|---|---|---|
| Per-tier score summary | Table or list, 1 row per tier | Yes | Rolls up each tier's 16-factor scores |
| Weakness | Prose, per tier | Yes | Cites the tier's concrete weak factor(s), not a restated table |
| Estimated cost | Prose/size, per tier | Yes | Derived from each tier's Recommendation `Size` fields |
| Estimated risk | Prose/category, per tier | Yes | Derived from each tier's Recommendation `Risk` fields |
| Cross-tier posture value | Single aggregate summary | Yes | One rolled-up value/summary across all 7 tiers |

## Relationships

```text
Application Tier (1) ──produces──> (1) Tier Assessment File
Tier Assessment File (7, all valid) ──read by (hard gate)──> Rollup Index (README.md)
```

The rollup never performs its own 16-factor scoring (FR-008); it only reads the 7 tier files and
renders the C1/C2/C3 Mermaid diagrams plus the index.
