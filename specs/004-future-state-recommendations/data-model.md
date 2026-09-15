# Phase 1 Data Model: Future-State Recommendations

This feature has no application data model (no database, no API payloads). This document
captures the structure of the Markdown entities it produces, per the spec's Key Entities section.

## Entity: Client need

- **Fields**:
  - `id`: one of `experimentation` | `graceful-degradation` | `pricing-agility`
  - `verbatim_text`: the exact client requirement wording (FR-004), copied without
    reinterpretation
- **Source of truth**: `specs/intake/2026-09-14-client-requirements-interview.md` and
  `docs/decisions/2026-09-14-1758-immersion-kickoff-decisions.md` (spec Assumptions)
- **Relationship**: exactly one Client need maps to exactly one Recommendation document
  (1:1, fixed set of 3 — no additions or removals permitted by this feature)

## Entity: Current-state finding

- **Fields**:
  - `citation`: a specific, real reference into `meta/architecture-assessment/` (file + section
    or statement), not a generic/assumed claim (FR-005)
  - `absence_note` (conditional): required instead of `citation` when no directly relevant
    finding exists for a client need, per the spec's Edge Cases — MUST explicitly state the
    absence rather than fabricate a finding
- **Source of truth**: `meta/architecture-assessment/` — produced externally by Feature 003;
  this feature only reads from it, never writes to it
- **Availability gate**: does not exist until Feature 003's two skills are implemented and
  executed against this repo (confirmed absent at plan time, see `research.md`)

## Entity: Options considered

- **Fields**:
  - `options`: an ordered list of at least 2 labeled alternatives (`A`, `B`, `C`, ...) (FR-006),
    each a real, distinct approach — not filler entries

## Entity: Recommendation

- **Fields**:
  - `chosen_option`: exactly one label from Options considered (FR-007)
  - `tradeoff_rationale`: explicit explanation of why the chosen option won over the others —
    MUST state the rationale, not just name the chosen option (FR-007, FR-016)
  - `future_cycle_note`: fixed statement that adoption requires a future `/speckit.specify` cycle
    before implementation begins (FR-011)
  - `size`: T-shirt size for the recommended option — one of `S` | `M` | `L` | `XL` (FR-013)
  - `risk`: risk category for the recommended option, explicitly calling out when an
    alternative would amount to a wholesale refactor (FR-014)
  - `human_time_on_task`: estimated time-on-task for a human implementer (FR-015)
  - `agent_time_on_task`: estimated time-on-task for an agent implementer (FR-015)

## Entity: Alternatives considered

- **Fields**:
  - `rejected_options`: every option from Options considered except `chosen_option`, each paired
    with a brief reason it was not selected (FR-008)

## Entity: Recommendation document

- **Fields**: `client_need`, `current_state_finding`, `options_considered`, `recommendation`,
  `alternatives_considered` — one instance per file, in this fixed section order (FR-003)
- **Instances** (exactly 3, per FR-002):
  - `meta/future-state/experimentation.md`
  - `meta/future-state/graceful-degradation.md`
  - `meta/future-state/pricing-agility.md`
- **State**: each instance is either `scaffolded` (headings/sections present, content sections
  empty/placeholder) or `content-complete` (all sections populated per FR-005..FR-008); a
  `scaffolded` file MUST NOT be mistaken for `content-complete` — the index must reflect this
  distinction (see Future-state index, and User Story 2 Acceptance Scenario 2)

## Entity: Future-state index (`README.md`)

- **Fields**:
  - `entries`: exactly 3, one per Client need, each with a relative link to its Recommendation
    document (FR-001)
  - `content_status`: per-entry indicator of whether the linked file is `scaffolded` (pending
    content) or `content-complete`, so a reader never assumes completeness (spec Edge Cases,
    User Story 2 Acceptance Scenario 2)

## Validation rules (from Functional Requirements)

- Exactly 4 files total: `README.md` + 3 recommendation documents (FR-001, FR-002) — no more, no
  fewer.
- Section order within each recommendation document is fixed: Client need → Current-state
  finding → Options considered → Recommendation → Alternatives considered (FR-003).
- Client need text is verbatim and file-specific (FR-004) — not paraphrased.
- No ADR files are created anywhere as a side effect of this feature (FR-009).
- No file under `*-microservice/src` or `react-ui/frontend` is modified (FR-010).
- Content-authoring for Current-state finding / Options considered / Recommendation /
  Alternatives considered is blocked (state remains `scaffolded`) until
  `meta/architecture-assessment/` exists with real content (FR-012).
- Each Recommendation instance MUST state `size`, `risk`, `human_time_on_task`, and
  `agent_time_on_task`, and `tradeoff_rationale` MUST be a genuine rationale rather than a bare
  restatement of `chosen_option` (FR-013, FR-014, FR-015, FR-016).
