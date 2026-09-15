# Implementation Plan: Marp-Based Slide Generation for Major Repo Changes

**Branch**: `feature/48-marp-slide-generation` | **Date**: 2026-09-15 | **Spec**: [specs/004-marp-slide-generation/spec.md](./spec.md)

**Input**: Feature specification from `/specs/004-marp-slide-generation/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command; its definition describes the execution workflow.

## Summary

Add a documented, npx-only convention for turning repo history (decisions, ADRs, specs) into
Marp Markdown slide decks: a canonical `docs/slides/` location for deck sources, an authoring/export
guide (`docs/slides/README.md`), and a hand-authored sample deck (`docs/slides/ai-sdlc-bootstrap-overview.md`)
covering the 12 major themes from PRs #1–#52. No application code, `package.json`, or CI changes —
this is a docs/tooling-only feature for a Java/Maven repo, rendered/exported on demand via
`npx @marp-team/marp-cli`.

## Technical Context

**Language/Version**: N/A (Markdown docs only; no application code touched). Marp CLI itself runs on
whatever Node.js the contributor already has, invoked ad hoc via `npx` — not a repo dependency.

**Primary Dependencies**: `@marp-team/marp-cli` via `npx @marp-team/marp-cli` (no `package.json`,
no pinned/vendored version, no new Node dependency added to this Maven repo).

**Storage**: N/A — decks are plain Markdown files under `docs/slides/`; exports (PDF/HTML) are
derived, regenerable artifacts, not committed source of truth (per spec's Deck Export entity).

**Testing**: N/A (no executable code). Validation is manual: render the sample deck with the
documented `npx` command and confirm it produces a viewable deck with no errors (spec SC-001–SC-003).

**Target Platform**: Any contributor machine with Node.js/npx available (spec Assumptions); no
CI, server, or runtime target.

**Project Type**: Docs/tooling addition to an existing Java/Maven multi-module repo (single
`docs/` convention, not a new project/module).

**Performance Goals**: N/A — SC-001 (render in <5 min) is a documentation-clarity/UX goal, not a
runtime performance goal.

**Constraints**: No new `package.json`/Node dependency; no VS Code extension requirement; no
Maven plugin or CI wiring (export documented as manual/optional per FR-006).

**Scale/Scope**: One new docs subdirectory (`docs/slides/`), one README, one sample deck file
covering 12 named themes. No other repo module is touched.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Applies? | Assessment |
|---|---|---|
| I. Gateway-Only Service Boundary | No | No service/API code touched; docs-only change. |
| II. Consistency-Sensitive Data Paths | No | No `cronos.orders`/`cronos.product_inventory` code touched. |
| III. Canonical Terminology | Yes | No glossary terms are implicated; no new durable terms introduced that need adding to `docs/product/glossary.md` ("Marp deck"/"Deck export" are self-explanatory, spec-scoped terms, not repo domain terms). |
| IV. Context-Grounded Change | Yes | Plan cites `docs/decisions/`, `docs/patterns/`, `docs/architecture/overview.md` as reviewed baselines; no new gaps discovered (`docs/context/gaps.md` has none relevant). |
| V. Incremental Test Hardening | No | No behavior/code change; N/A by nature (docs/tooling feature). |

**Result**: PASS — no violations, no Complexity Tracking entries needed. This feature does not
rise to the level of an ADR (`docs/architecture/adr/`); it is a docs/tooling convention.

## Project Structure

### Documentation (this feature)

```text
specs/004-marp-slide-generation/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

No `contracts/` directory: this feature exposes no API, CLI schema, or programmatic interface —
the only "interface" is a documented `npx` command invocation, which is captured in `quickstart.md`.

### Source Code (repository root)

```text
docs/
└── slides/
    ├── README.md                          # Authoring + export conventions (FR-003, FR-006, FR-007)
    └── ai-sdlc-bootstrap-overview.md       # Sample deck: PRs #1-#52, 12 themes (FR-004, FR-005)
```

**Structure Decision**: Single new docs subdirectory, `docs/slides/`, added at the repo root
alongside the existing `docs/` tree (`docs/architecture/`, `docs/decisions/`, `docs/patterns/`,
`docs/product/`, `docs/context/`). No Maven module, `package.json`, or CI file is added or
modified — this satisfies FR-001/FR-002 (no new Node dependency, canonical location) directly.
Deck rendering/export happens via `npx @marp-team/marp-cli <deck>.md --pdf|--html`, invoked
manually per FR-006; no build/CI wiring is introduced.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No violations — table intentionally left empty.
