# Phase 0 Research: Future-State Recommendations

No `NEEDS CLARIFICATION` markers remain in the Technical Context (this is a documentation-only
feature with no runtime stack to select). This file records the decisions behind that Technical
Context and the blocking-precondition handling, per `speckit-aisdlc-grilling` decisions recorded
in [specs/intake/2026-09-15-future-state-recommendations.md](../intake/2026-09-15-future-state-recommendations.md).

## Decision: No new skill or prompt tooling for this feature

- **Decision**: Unlike Feature 003 (which builds two reusable `rabbit-`-prefixed skills), this
  feature does not introduce any new skill, prompt, or agent file. The three recommendation
  documents are one-off, hand-authored content, not a repeatable generation workflow.
- **Rationale**: The spec's Key Entities and FR-001..FR-011 describe fixed, one-time output
  (exactly 4 files); there is no indication this document set needs to be regenerated on demand
  the way Feature 003's per-tier/rollup skills do.
- **Alternatives considered**: Building a `rabbit-future-state-recommendation` skill to generate
  each file from a template. Rejected because the spec requires each recommendation to reflect
  human judgment about tradeoffs (FR-007, FR-008), not a mechanically regenerable output — a
  skill would risk producing a generic, unsupported claim, which FR-005 explicitly forbids.

## Decision: `meta/future-state/` is a standalone namespace, not nested under `meta/architecture-assessment/`

- **Decision**: `meta/future-state/` sits parallel to `meta/architecture-assessment/` and
  `meta/rabbit-wiki/` at the repository root, per the spec's Assumptions.
- **Rationale**: Confirmed via `aisdlc-grilling`; keeps the recommendations deliverable
  independently discoverable and lets Feature 003 be implemented, re-run, or restructured without
  moving this feature's files.
- **Alternatives considered**: Nesting under `meta/architecture-assessment/future-state/` to make
  the dependency visually explicit. Rejected — conflates two independently-scoped features'
  ownership and output, and the spec's Assumptions section already settles this.

## Decision: Blocking precondition is enforced by task ordering, not by tooling

- **Decision**: The precondition ("`meta/architecture-assessment/` must exist with real content
  before content-authoring tasks start") is enforced procedurally — by splitting `tasks.md` into a
  scaffolding group (buildable now) and a content-authoring group (blocked), with an explicit
  re-verification step before any content task starts — rather than by building an automated
  gate/check script.
- **Rationale**: This is a two-feature, human-coordinated dependency inside a single repo, not a
  runtime system needing an automated enforcement mechanism; FR-012 only requires that content
  tasks "remain blocked," which a task-list ordering and explicit precondition note satisfies.
- **Alternatives considered**: A pre-commit hook or CI check verifying `meta/architecture-assessment/`
  exists before allowing edits under `meta/future-state/`. Rejected as disproportionate tooling for
  a one-time documentation deliverable with no CI pipeline for the application itself (per
  `docs/architecture/overview.md`, no `.github/workflows/` exists for application build/test).

## Decision: Format contract is one shared five-section Markdown structure

- **Decision**: All three recommendation files share one fixed section order: "Client need",
  "Current-state finding", "Options considered", "Recommendation", "Alternatives considered"
  (FR-003). This is documented once as a contract (see `contracts/`) rather than duplicated per
  file.
- **Rationale**: FR-003 mandates identical structure across all three files; a single shared
  contract avoids drift between the three documents' formats.
- **Alternatives considered**: Letting each file's structure vary slightly based on content
  needs. Rejected — the spec requires a fixed, comparable structure across all three (FR-003,
  Acceptance Scenario 2 for graceful-degradation explicitly says "follows the same format").

## Verified at plan time

- `meta/` does not exist anywhere in this repository (confirmed via directory listing at plan
  time, 2026-09-15). This directly confirms the spec's stated precondition is still active: no
  content-authoring task may start yet.
- `specs/003-architecture-assessment/` has `spec.md`, `plan.md`, `research.md`, `data-model.md`,
  `quickstart.md`, `contracts/`, and `tasks.md`, but no implemented skill files exist yet under
  `.agents/skills/rabbit-architecture-assessment-tier/` or
  `.agents/skills/rabbit-architecture-assessment-rollup/` — consistent with the spec's framing
  that Feature 003 is "specified but not yet implemented."
