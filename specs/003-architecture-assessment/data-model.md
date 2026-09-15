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
| Findings section | Markdown section (`## Findings`) | Yes | Specific to the tier (FR-004) |
| Recommendation section | Markdown section (`## Recommendation`) | Yes | Specific to the tier (FR-004) |
| 16-factor table | Markdown table, 16 rows, columns `Factor \| Name \| Score \| Explanation` | Yes | Factors I-XII scored; XIII-XVI scored or "N/A" (FR-005, FR-006) |
| WIP/unwired finding | Explicit statement within the file | Only for `login-microservice` | Sourced from `docs/architecture/overview.md` (FR-007) |

**Validity rule** (used by the rollup skill's gate, FR-009/FR-010): a tier file is *valid* only if
it contains all of `## Context`, `## Findings`, `## Recommendation`, and `## 16-Factor
Assessment`; otherwise it is treated as missing.

**Lifecycle**: Overwritten in full on every re-run for that tier (FR-016) — not incrementally
patched or hand-preserved.

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

**Exclusion**: No C4-Code (level 4) diagram (FR-012).

**Lifecycle**: Idempotent full overwrite on every successful rollup run (FR-017); never appended
to, never written partially (FR-010).

## Relationships

```text
Application Tier (1) ──produces──> (1) Tier Assessment File
Tier Assessment File (7, all valid) ──read by (hard gate)──> Rollup Index (README.md)
```

The rollup never performs its own 16-factor scoring (FR-008); it only reads the 7 tier files and
renders the C1/C2/C3 Mermaid diagrams plus the index.
