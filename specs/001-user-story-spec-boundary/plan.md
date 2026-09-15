# Implementation Plan: GitHub Issue vs. Spec Kit Feature Spec Boundary

**Branch**: `001-user-story-spec-boundary` (checked out locally as `docs/user-story-spec-boundary`) | **Date**: 2026-09-15 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/001-user-story-spec-boundary/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command; its definition describes the execution workflow.

## Summary

Document, as a new `docs/process/` page, the boundary between GitHub Issues (product-level
backlog artifact) and Spec Kit `specs/<feature>/{spec,plan,tasks}.md` (per-feature delivery
artifacts): which artifact is authoritative at each delivery stage, a concrete testable rule for
when an Issue should be promoted into a `specs/` feature, the terminology distinction between a
`spec.md` "User Story" section and a GitHub Issue, and the closure/linking convention. Link the
new page from `docs/process/README.md` and `specs/README.md`. This is a documentation-only
change — no application code, scripts, or automation are added or modified.

## Technical Context

**Language/Version**: N/A — Markdown documentation only, no code changes

**Primary Dependencies**: N/A

**Storage**: N/A

**Testing**: No automated test suite applies to Markdown docs. Validation is manual: re-check the
updated spec checklist ([checklists/requirements.md](checklists/requirements.md)) and walk through
[quickstart.md](quickstart.md)'s scenarios against the finished page.

**Target Platform**: N/A — viewed as repository documentation (GitHub web UI, VS Code, editor)

**Project Type**: Documentation (single new page + two small cross-link edits; no source tree)

**Performance Goals**: N/A

**Constraints**: Must not contradict `specs/copilot-agent-issue-board/spec.md` (the existing
worked example of an Issue promoted into a `specs/` feature); must match the terse, evidence-based
tone already used by `docs/process/pr-process.md` and `docs/process/mcp-servers.md`.

**Scale/Scope**: One new `docs/process/` page, one bullet added to `docs/process/README.md`, one
short cross-link added to `specs/README.md`.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. Gateway-Only Service Boundary** — N/A. No microservice or API code is touched.
- **II. Consistency-Sensitive Data Paths** — N/A. No `cronos.orders`/inventory code is touched.
- **III. Canonical Terminology** — PASS. New glossary entries are explicitly deferred to
  `/speckit.aisdlc.promote` (per clarify session); the new page will not introduce ad hoc
  synonyms for existing glossary terms and will not use "Cronos" in user-facing text.
- **IV. Context-Grounded Change** — PASS. `docs/context/gaps.md`, `docs/product/overview.md`,
  and `docs/architecture/overview.md` were reviewed during preflight; no open question applies.
  This plan cites `specs/copilot-agent-issue-board/` and `tools/gh-agent-board/README.md` as its
  concrete evidence for the "Issue promoted to a `specs/` feature" path.
- **V. Incremental Test Hardening** — N/A. No application behavior changes; "testing" for this
  feature is the checklist/quickstart validation described above.

**Result**: PASS — no violations to justify in Complexity Tracking.

## Project Structure

### Documentation (this feature)

```text
specs/001-user-story-spec-boundary/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md         # Phase 1 output (/speckit-plan command)
└── tasks.md              # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

No `contracts/` directory: this feature has no external interface (API, CLI schema, or UI
contract) to document — it is purely a documentation deliverable.

### Source Code (repository root)

```text
docs/process/
├── README.md                    # updated: add one bullet linking the new page
└── user-stories-vs-specs.md     # new page: the boundary documentation itself

specs/
└── README.md                    # updated: short cross-link to the new page
```

**Structure Decision**: This is a documentation-only feature — no `src/`, `tests/`, or service
code is touched. The deliverable is one new page at `docs/process/user-stories-vs-specs.md`
(matching the existing `docs/process/pr-process.md` / `mcp-servers.md` pattern), plus a one-line
link added to each of `docs/process/README.md` and `specs/README.md`.

## Complexity Tracking

*No Constitution Check violations — this section is not applicable.*

