# Implementation Plan: Architecture Assessment

**Branch**: `003-architecture-assessment` | **Date**: 2026-09-15 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/003-architecture-assessment/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command; its definition describes the execution workflow.

## Summary

Add two new agent skills (prompt/documentation-generation tooling, not application code): a
per-tier assessment skill that writes `meta/architecture-assessment/{tier-name}.md`
(Context/Findings/Recommendation sections + a 16-factor table with Score, Explanation, Gap to 5,
and Quick Fix columns, grounded in
`docs/context/sources/2026-09-14-twelve-to-sixteen-factor-app.md`) for one of the 7 recognized
application tiers, and a separate rollup skill that hard-gates on all 7 tier files existing and
valid before writing `meta/architecture-assessment/README.md` with C1/C2/C3 Mermaid diagrams
plus a cross-tier foundational posture score section.
Both skills follow this repo's `rabbit-` naming convention for custom (non-framework) additions
and are pure Markdown-writing workflows executed by an agent — there is no compiled artifact,
runtime service, or automated test suite to add. A tracked spike task compares the dedicated
tier skill against a generic prompt for one tier (skill-tailoring A/B comparison), recorded in
`research.md`.

## Technical Context

**Language/Version**: N/A (Markdown skill definitions consumed by an agent; no compiled/interpreted runtime code is added)

**Primary Dependencies**: Existing repo tooling only — `read_file`/`list_dir`/`create_file` style agent tools, `mermaid-diagram-validator`/`mermaid-diagram-preview` for Mermaid syntax checking; no new libraries or packages

**Storage**: Flat Markdown files under a new top-level `meta/architecture-assessment/` folder (reused if another feature already created top-level `meta/`)

**Testing**: No automated test suite (documentation-generation skills, not code); validation is manual per `quickstart.md` — run each skill and inspect the generated Markdown/Mermaid output

**Target Platform**: Repository-local agent skills (`.agents/skills/`) invoked via prompts (`.github/prompts/`) inside VS Code / other agent surfaces already used in this repo

**Project Type**: Single project — prompt/skill tooling only, no frontend/backend split

**Performance Goals**: N/A (human-in-the-loop, one invocation at a time; no throughput target)

**Constraints**: Rollup MUST hard-gate (zero partial/silent `README.md` writes) when any of the 7 tier files is missing or structurally invalid; per-tier skill MUST refuse any target outside the 7 recognized tiers; no application source code under the 7 microservice/react-ui modules may be modified

**Scale/Scope**: Exactly 7 tier assessment files + 1 rollup `README.md`; 2 new skills (+ 2 companion prompt files) total

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. Gateway-Only Service Boundary**: N/A — this feature adds documentation-generation skills
  only; it does not add or change any service-to-service call path.
- **II. Consistency-Sensitive Data Paths**: N/A — no code touching `cronos.orders` /
  `cronos.product_inventory` is added or modified.
- **III. Canonical Terminology**: PASS — tier names, YCQL/YSQL, and other terms used in
  generated assessments MUST match `docs/product/glossary.md`; the 7 tier directory names are
  used verbatim (FR-001, FR-003).
- **IV. Context-Grounded Change**: PASS — the 16-factor model is explicitly grounded in
  `docs/context/sources/2026-09-14-twelve-to-sixteen-factor-app.md` (FR-005); per-tier facts
  must cite `docs/architecture/overview.md` and observed source, consistent with this
  principle's evidence requirement.
- **V. Incremental Test Hardening**: N/A — no new/changed application behavior is shipped;
  these are documentation-generation skills with a manual quickstart validation instead of an
  automated test suite (recorded explicitly rather than silently skipped).

No violations requiring justification. `docs/architecture/overview.md` gains a one-line
cross-reference (FR-015), which is documentation-only and does not touch the constitution's
scope boundaries (deployment target, `login-microservice` wiring remain untouched — the
assessment only *records* `login-microservice`'s WIP status, per FR-007, it does not complete
or wire it).

## Project Structure

### Documentation (this feature)

```text
specs/003-architecture-assessment/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command) — skill invocation contracts
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
.agents/skills/
├── rabbit-architecture-assessment-tier/
│   └── SKILL.md              # Per-tier assessment skill (FR-001..FR-007, FR-016)
└── rabbit-architecture-assessment-rollup/
    └── SKILL.md              # Rollup skill (FR-008..FR-013, FR-017)

.github/prompts/
├── rabbit-architecture-assessment-tier.prompt.md
└── rabbit-architecture-assessment-rollup.prompt.md

meta/architecture-assessment/        # Generated output (created by running the skills, not by this plan)
├── eureka-server-local.md
├── products-microservice.md
├── checkout-microservice.md
├── cart-microservice.md
├── api-gateway-microservice.md
├── login-microservice.md
├── react-ui.md
└── README.md                        # Rollup: C1/C2/C3 Mermaid diagrams + index

docs/architecture/overview.md        # +1 line cross-reference to meta/architecture-assessment/README.md (FR-015)
```

**Structure Decision**: This is prompt/skill tooling, not an application module — there is no
`src/`/`backend`/`frontend` split to choose between. Two new skills live under
`.agents/skills/` (each with a companion prompt under `.github/prompts/`), following the
`rabbit-` prefix convention already used for this repo's non-framework custom additions (see
`rabbit-archive-to-markdown` as the precedent). Skill execution writes plain Markdown into a new
top-level `meta/architecture-assessment/` folder, kept structurally separate from AI-SDLC's
`docs/` durable-context tree per the spec's Assumptions. No existing microservice or `react-ui`
source directory is touched; only `docs/architecture/overview.md` gains a one-line
cross-reference.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No Constitution Check violations — this section is intentionally empty.

## Iteration Note (2026-09-15: actionable scoring + posture score)

No new tech stack. Both skills' existing steps now produce additional derived columns/sections
from the same per-tier data already gathered — no new data sources:

- Tier skill Step 4 (16-factor table): each per-factor subagent additionally derives `Gap to 5`
  (`5 − Score`, or `N/A`) and, for factors scored below 5, a `Quick Fix` suggestion.
- Tier skill Step 3 (`## Recommendation`): strengthened to require an explicit rationale, a
  T-shirt size (S/M/L/XL), a risk category, and human-vs-agent time-on-task estimates.
- Tier skill Step 3 (`## Findings`): gains a load/performance-testing tooling-status note.
- Rollup skill: gains a new aggregation step producing a cross-tier foundational posture score
  section, gated on all 7 tier files carrying the new columns/fields.
- A skill-tailoring A/B comparison spike (dedicated skill vs. generic prompt, one tier) is
  tracked in `research.md` and `tasks.md`, not dropped.
