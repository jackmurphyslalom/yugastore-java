# Quickstart: Validate the Boundary Documentation

## Prerequisites

- `docs/process/user-stories-vs-specs.md` has been written (per [tasks.md](tasks.md)).
- `docs/process/README.md` and `specs/README.md` have been updated with the cross-links.

## Validation scenarios

Run through these after implementation — no build/test command applies (documentation-only
change), so validation is a manual read-through against [spec.md](spec.md)'s acceptance criteria.

1. **Classify three example intakes** (spec.md User Story 1):
   - A one-line config fix (e.g. issue #19 / the Brewfile PR).
   - A multi-service, multi-journey feature (e.g. `specs/copilot-agent-issue-board`).
   - An ambiguous in-between case of your choosing.
   - Expected: the new doc's promotion rule (FR-004) classifies all three without needing to ask
     a teammate.

2. **Resolve an authority conflict** (spec.md User Story 2):
   - Pick any one of the 6 delivery stages (intake, specify, plan, tasks, implement, done).
   - Expected: the doc states, without contradiction, exactly one authoritative artifact for that
     stage (FR-003).

3. **Terminology check** (spec.md User Story 3):
   - Search the new doc for "User Story".
   - Expected: an explicit statement that a `spec.md` "User Story" section is not the same
     artifact as a GitHub Issue (FR-005).

4. **Discoverability** (spec.md SC-003):
   - From `docs/README.md`, `docs/process/README.md`, and `specs/README.md`, confirm the new page
     is reachable in one click from each.

5. **Re-run the spec checklist**:
   - Re-check every item in
     [checklists/requirements.md](checklists/requirements.md) still passes against the finished
     documentation.

## Expected outcome

All five scenarios pass without needing implementation-detail knowledge — this is the
documentation-only equivalent of an end-to-end test for this feature.
