# Implementation Plan: Future-State Recommendations

**Branch**: `004-future-state-recommendations` | **Date**: 2026-09-15 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/004-future-state-recommendations/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command; its definition describes the execution workflow.

## Summary

Produce a recommendations-only documentation set at `meta/future-state/`: three fixed-format
recommendation files (`experimentation.md`, `graceful-degradation.md`, `pricing-agility.md`) and
one index (`README.md`). Each recommendation file must, in order, contain "Client need",
"Current-state finding", "Options considered", "Recommendation", and "Alternatives considered"
sections, cite a real finding from `meta/architecture-assessment/` (Feature 003's output), and
state that adoption requires a future `/speckit.specify` cycle. No application code or ADRs are
produced.

**2026-09-15 iteration**: The recommendation-document contract gains four additional fixed
fields — T-shirt size, risk category, human time-on-task, and agent time-on-task — and the
`## Recommendation` section must state an explicit rationale, not just the chosen option's
name. No new tech stack or data source is introduced; sizing/risk/time-on-task values are
author judgment layered on top of what Feature 003 already provides.

**Hard blocking precondition (content only)**: `meta/architecture-assessment/` does not exist yet
(verified at plan time — no top-level `meta/` folder exists in this repo). Feature 003's two
skills (`rabbit-architecture-assessment-tier`, `rabbit-architecture-assessment-rollup`, per its
[plan.md](../003-architecture-assessment/plan.md)) are specified but not yet implemented, and even
once implemented they must be run to completion (all 7 tiers + rollup) before any
"Current-state finding" content can be written. This plan therefore separates **scaffolding**
tasks (buildable now) from **content-authoring** tasks (blocked on Feature 003's output existing),
per FR-012.

## Technical Context

**Language/Version**: N/A (Markdown-only deliverable; no compiled/interpreted runtime code)

**Primary Dependencies**: Existing repo tooling only — `read_file`/`list_dir`/`create_file` style
agent tools; no new libraries, packages, or skills are introduced by this feature

**Storage**: Flat Markdown files under a new top-level `meta/future-state/` folder (standalone
namespace, parallel to `meta/architecture-assessment/` and `meta/rabbit-wiki/`, per spec Assumptions)

**Testing**: No automated test suite (documentation deliverable); validation is manual per
`quickstart.md` — open each file and confirm required sections, citations, and links per FR-001..FR-011

**Target Platform**: Repository documentation tree, authored directly by the engagement team /
an agent inside VS Code; no runtime platform involved

**Project Type**: Single project — documentation only, no frontend/backend split, no new skills
or prompts required for this feature itself

**Performance Goals**: N/A

**Constraints**: Zero application source files (backend microservices, `react-ui/frontend`) may
be modified (FR-010, SC-004); zero ADRs may be created (FR-009); content-writing tasks for all
four required sections in each of the three recommendation files MUST remain blocked until
`meta/architecture-assessment/` exists with real, generated content from Feature 003's
implemented and executed skills (FR-012) — scaffolding (file creation with headings, index
construction) is explicitly exempt from this gate

**Scale/Scope**: Exactly 4 files total (1 index + 3 recommendation documents); no new skills,
prompts, or agents

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. Gateway-Only Service Boundary**: N/A — no service-to-service call path is added or changed;
  this feature writes documentation only.
- **II. Consistency-Sensitive Data Paths**: N/A — no code touching `cronos.orders` /
  `cronos.product_inventory` is added or modified.
- **III. Canonical Terminology**: PASS — the three client needs are reproduced verbatim (FR-004)
  from `specs/intake/2026-09-14-client-requirements-interview.md` /
  `docs/decisions/2026-09-14-1758-immersion-kickoff-decisions.md`; any other terminology used
  (YCQL, YSQL, api-gateway, etc.) must match `docs/product/glossary.md`.
- **IV. Context-Grounded Change**: PASS (with an explicit gate) — every "Current-state finding"
  must cite a specific, real finding from `meta/architecture-assessment/` rather than an assumed
  statement (FR-005); this principle is honored precisely by blocking content-authoring tasks
  until that grounding evidence exists, rather than allowing a plausible-sounding but unverified
  finding to be written.
- **V. Incremental Test Hardening**: N/A — no application behavior is shipped; validation is the
  manual `quickstart.md` review described above.

No violations requiring justification. This feature does not touch the constitution's open
`DEPLOYMENT_TARGET` or `LOGIN_MICROSERVICE_SCOPE` items; any future implementation of an accepted
recommendation is explicitly deferred to a separate `/speckit.specify` cycle (FR-011), not this
plan.

## Project Structure

### Documentation (this feature)

```text
specs/004-future-state-recommendations/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command) — document-format contract
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
meta/future-state/                       # New standalone namespace (this feature's entire output)
├── README.md                            # Index: lists all 3 client needs, links to each file,
│                                         #   flags content status per FR-012 (FR-001)
├── experimentation.md                   # Client need, Current-state finding, Options considered,
│                                         #   Recommendation, Alternatives considered (FR-002..FR-011)
├── graceful-degradation.md              # Same 5-section format (FR-002..FR-011)
└── pricing-agility.md                   # Same 5-section format (FR-002..FR-011)

meta/architecture-assessment/            # NOT produced by this feature — external precondition
                                          #   from Feature 003; content-authoring tasks read from
                                          #   here but this plan does not create or modify it
```

**Structure Decision**: This is a pure documentation deliverable — there is no `src/`/backend/
frontend split to choose between, and no new skill or prompt is introduced (unlike Feature 003,
this feature does not need reusable tooling since the three recommendation documents are
one-off, hand-authored content). All output lives under a new top-level `meta/future-state/`
folder, kept structurally separate from `docs/` (AI-SDLC durable context) and from
`meta/architecture-assessment/` (Feature 003's separate output), per the spec's Assumptions. No
existing microservice or `react-ui` source directory is touched, and no ADR is created.

**Phase ordering note (scaffolding vs. content)**: Phase 1 design artifacts below (data model,
quickstart) describe the fixed five-section format and file layout, which is buildable now.
`tasks.md` (produced by a later `/speckit.tasks` run) MUST split into two explicit groups:
(1) scaffolding tasks — creating the four files with correct headings/links, buildable
immediately — and (2) content-authoring tasks — filling in "Current-state finding", "Options
considered", "Recommendation", and "Alternatives considered" for each of the three files, which
remain blocked until `meta/architecture-assessment/` exists with real content from Feature 003's
implemented and executed skills (FR-012). No task in group (2) may be started before that
precondition is independently re-verified at task-start time.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No Constitution Check violations — this section is intentionally empty.
