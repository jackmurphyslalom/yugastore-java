---

description: "Task list for Future-State Recommendations"
---

# Tasks: Future-State Recommendations

**Input**: Design documents from `/specs/004-future-state-recommendations/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/recommendation-document-format.md, quickstart.md

**Tests**: Not applicable — this is a documentation-only deliverable with no automated test suite (per plan.md Technical Context). Validation is manual per `quickstart.md`.

**Organization**: Tasks are grouped by user story. All scaffolding tasks are immediately actionable now. All content-authoring tasks are explicitly gated on the Feature 003 (Architecture Assessment) precondition and MUST NOT be started until that precondition is independently re-verified.

## ⚠️ Content-Authoring Gate (read before starting any [CONTENT-BLOCKED] task)

Per spec.md's Blocking Precondition and plan.md's Phase ordering note (FR-012):

- **Precondition**: `meta/architecture-assessment/` must exist in this repository with real,
  generated output — i.e., `specs/003-architecture-assessment/` has been implemented (its two
  skills, `rabbit-architecture-assessment-tier` and `rabbit-architecture-assessment-rollup`,
  exist under `.agents/skills/`) **and** those skills have been run to completion against this
  repo (all tiers + rollup).
- **Verified NOT met at task-generation time** (2026-09-15): no top-level `meta/` directory
  exists in this repository.
- Any task marked **[CONTENT-BLOCKED]** below MUST re-verify this precondition (e.g., `list_dir`
  on `meta/architecture-assessment/`) immediately before starting, even if this file was
  generated earlier. Do not rely on this file's verification timestamp.
- Tasks **not** marked `[CONTENT-BLOCKED]` (scaffolding, index-building) have no such gate and
  are actionable immediately.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- **[CONTENT-BLOCKED]**: Gated on the precondition above — do not start until re-verified
- Include exact file paths in descriptions

## Path Conventions

All output is under `meta/future-state/` (new top-level namespace, per plan.md Project
Structure). No `src/`/`tests/` paths apply — this is a documentation-only feature.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create the namespace all user stories write into

- [X] T001 Create the `meta/future-state/` directory (new standalone top-level namespace,
      parallel to `meta/architecture-assessment/`, per plan.md Project Structure)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shared scaffolding all three user stories' files depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T002 Re-verify the content-authoring precondition status by checking whether
      `meta/architecture-assessment/` exists in the repository root; record the result (met /
      not met) so subsequent tasks know which group to run (per Content-Authoring Gate above)

**Checkpoint**: Foundation ready — user story scaffolding can now begin

---

## Phase 3: User Story 1 - Author the three client-need recommendation documents (Priority: P1) 🎯 MVP

**Goal**: Produce three recommendation files, one per client need, each grounded in a real
current-state finding, labeled alternatives, and one explicit recommendation.

**Independent Test**: Once the precondition is met, open each of the three files under
`meta/future-state/` and confirm each cites a specific, real finding from
`meta/architecture-assessment/`, lists at least two labeled alternatives (A, B, ...), and states
one explicit recommendation with a tradeoff rationale.

### Scaffolding for User Story 1 (actionable now)

- [X] T003 [P] [US1] Create `meta/future-state/experimentation.md` with the fixed five-section
      structure from
      [contracts/recommendation-document-format.md](./contracts/recommendation-document-format.md):
      `## Client need` (verbatim text: "run constant experiments (pricing, UX, recommendations)
      without engineering becoming a bottleneck."), followed by empty `## Current-state finding`,
      `## Options considered`, `## Recommendation`, `## Alternatives considered` headings, each
      containing only the placeholder note `_Blocked: pending meta/architecture-assessment/
      (Feature 003)._` (FR-002, FR-003, FR-004, FR-012)
- [X] T004 [P] [US1] Create `meta/future-state/graceful-degradation.md` with the same
      five-section structure, verbatim client need text: "when any service slows down or goes
      down, the storefront must degrade gracefully.", and the same blocked placeholder note in
      each of the four content sections (FR-002, FR-003, FR-004, FR-012)
- [X] T005 [P] [US1] Create `meta/future-state/pricing-agility.md` with the same five-section
      structure, verbatim client need text: "pricing rules change weekly; engineers shouldn't
      need to redeploy everything.", and the same blocked placeholder note in each of the four
      content sections (FR-002, FR-003, FR-004, FR-012)

### Content-authoring for User Story 1 (BLOCKED — see Content-Authoring Gate)

- [X] T006 [US1] [CONTENT-BLOCKED] Re-verify `meta/architecture-assessment/` exists with real
      tier + rollup content, then write the `## Current-state finding` section of
      `meta/future-state/experimentation.md`, citing a specific file/section from
      `meta/architecture-assessment/` (or explicitly noting the absence of a directly relevant
      finding per spec Edge Cases) (FR-005, depends on T003)
- [X] T007 [US1] [CONTENT-BLOCKED] Write the `## Options considered` section of
      `meta/future-state/experimentation.md` with at least two real, distinct alternatives
      labeled A, B (, C...) (FR-006, depends on T006)
- [X] T008 [US1] [CONTENT-BLOCKED] Write the `## Recommendation` section of
      `meta/future-state/experimentation.md`, naming exactly one option from T007 with a
      tradeoff rationale, and including the fixed future-cycle note (adoption requires a future
      `/speckit.specify` cycle) (FR-007, FR-011, depends on T007)
- [X] T009 [US1] [CONTENT-BLOCKED] Write the `## Alternatives considered` section of
      `meta/future-state/experimentation.md`, giving a brief reason each non-chosen option from
      T007 was not selected (FR-008, depends on T008)
- [X] T010 [US1] [CONTENT-BLOCKED] Re-verify the precondition, then write the
      `## Current-state finding` section of `meta/future-state/graceful-degradation.md` (FR-005,
      depends on T004)
- [X] T011 [US1] [CONTENT-BLOCKED] Write the `## Options considered` section of
      `meta/future-state/graceful-degradation.md` (FR-006, depends on T010)
- [X] T012 [US1] [CONTENT-BLOCKED] Write the `## Recommendation` section of
      `meta/future-state/graceful-degradation.md`, including the fixed future-cycle note
      (FR-007, FR-011, depends on T011)
- [X] T013 [US1] [CONTENT-BLOCKED] Write the `## Alternatives considered` section of
      `meta/future-state/graceful-degradation.md` (FR-008, depends on T012)
- [X] T014 [US1] [CONTENT-BLOCKED] Re-verify the precondition, then write the
      `## Current-state finding` section of `meta/future-state/pricing-agility.md` (FR-005,
      depends on T005)
- [X] T015 [US1] [CONTENT-BLOCKED] Write the `## Options considered` section of
      `meta/future-state/pricing-agility.md` (FR-006, depends on T014)
- [X] T016 [US1] [CONTENT-BLOCKED] Write the `## Recommendation` section of
      `meta/future-state/pricing-agility.md`, including the fixed future-cycle note (FR-007,
      FR-011, depends on T015)
- [X] T017 [US1] [CONTENT-BLOCKED] Write the `## Alternatives considered` section of
      `meta/future-state/pricing-agility.md` (FR-008, depends on T016)

**Checkpoint**: Scaffolding (T003-T005) is independently testable now via `quickstart.md`'s
"Scaffolding validation" section. Content tasks (T006-T017) remain blocked until Feature 003's
output exists, per FR-012.

---

## Phase 4: User Story 2 - Provide a single index into the three recommendations (Priority: P2)

**Goal**: One entry point (`README.md`) listing all three client needs with links and content
status, usable even before Story 1's content is unblocked.

**Independent Test**: Open `meta/future-state/README.md` and confirm it lists all three client
needs with working relative links, without needing the underlying recommendation content to be
finalized.

### Scaffolding for User Story 2 (actionable now)

- [X] T018 [US2] Create `meta/future-state/README.md` using the Future-state index contract from
      [contracts/recommendation-document-format.md](./contracts/recommendation-document-format.md):
      a table with columns `Client need`, `Recommendation`, `Status`, one row per client need,
      each linking to its file (`./experimentation.md`, `./graceful-degradation.md`,
      `./pricing-agility.md`) with `Status` set to `Scaffolded — pending Feature 003` (FR-001,
      depends on T003, T004, T005)

### Content-status maintenance for User Story 2 (BLOCKED — see Content-Authoring Gate)

- [X] T019 [US2] [CONTENT-BLOCKED] Update the `Status` column in
      `meta/future-state/README.md` to `Content complete` for each recommendation file whose
      four content sections have been filled in (depends on T009, T013, T017 as each
      corresponding file completes)

**Checkpoint**: T018 is independently testable now. T019 only applies once content tasks from
Phase 3 complete.

---

## Phase 5: User Story 3 - Keep recommendations out of implementation scope (Priority: P3)

**Goal**: Make it unambiguous that this feature produces recommendations only, with no
application code changes and no ADRs.

**Independent Test**: Inspect this feature's spec/plan/tasks and confirm no task instructs
writing or modifying application code, and that each recommendation document states that
adoption requires a future `/speckit.specify` cycle.

- [X] T020 [P] [US3] Confirm the future-cycle note ("Adopting this recommendation requires a
      future `/speckit.specify` cycle before any implementation begins") is present in each of
      the three recommendation files' `## Recommendation` section — verified as part of T008,
      T012, T016 above; this task is a final cross-check once all three are content-complete
      (FR-011, SC-005, depends on T008, T012, T016)
- [X] T021 [P] [US3] Confirm zero files under any `*-microservice/src` or `react-ui/frontend`
      directory were modified, and zero ADR files were created under `docs/architecture/adr/`,
      as a side effect of any task in this file (FR-009, FR-010, SC-004) — actionable at any
      point, re-run as a final check

**Checkpoint**: This story is a governance check, not new content — actionable in parallel with
the rest of the feature and again as a final gate before calling the feature done.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final validation across the whole deliverable

- [X] T022 Run the "Scaffolding validation" section of
      [quickstart.md](./quickstart.md) end-to-end (confirms T001, T003-T005, T018)
- [X] T023 [CONTENT-BLOCKED] Run the "Content validation" section of
      [quickstart.md](./quickstart.md) end-to-end once all content tasks are complete (confirms
      T006-T017, T019)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — actionable immediately
- **Foundational (Phase 2)**: Depends on Setup — BLOCKS all user story work
- **User Story 1 scaffolding (T003-T005)**: Depends on Foundational; actionable immediately;
  parallelizable (3 different files)
- **User Story 1 content (T006-T017)**: [CONTENT-BLOCKED] — depends on the corresponding
  scaffolding task per file, AND on the Feature 003 precondition being met
- **User Story 2 scaffolding (T018)**: Depends on T003, T004, T005 existing (links to all 3
  files) — actionable immediately once those exist
- **User Story 2 status update (T019)**: [CONTENT-BLOCKED] — depends on the corresponding
  content tasks per file completing
- **User Story 3 (T020, T021)**: Governance checks; T020 depends on content tasks completing,
  T021 is actionable at any point and re-run as a final gate
- **Polish (Phase 6)**: T022 actionable once Phase 3-5 scaffolding is done; T023 depends on all
  content tasks

### Content-Authoring Gate Summary

Every `[CONTENT-BLOCKED]` task (T006-T017, T019, T020, T023) MUST NOT start until
`meta/architecture-assessment/` exists with real content from Feature 003's implemented and
executed skills, re-verified at the time each task starts — not only at task-generation time.

### Parallel Opportunities

- T003, T004, T005 (scaffolding for the three recommendation files) can run in parallel
- Once unblocked, T006/T010/T014 (the three files' "Current-state finding" sections) can run in
  parallel, and similarly for each subsequent per-file content step
- T020 and T021 can run in parallel

---

## Parallel Example: User Story 1 Scaffolding

```bash
# Launch all three scaffolding tasks together (actionable now):
Task: "Create meta/future-state/experimentation.md with fixed five-section structure"
Task: "Create meta/future-state/graceful-degradation.md with fixed five-section structure"
Task: "Create meta/future-state/pricing-agility.md with fixed five-section structure"
```

---

## Implementation Strategy

### Immediately Actionable (MVP scaffolding)

1. Complete Phase 1: Setup (T001)
2. Complete Phase 2: Foundational (T002 — re-verify precondition status)
3. Complete User Story 1 scaffolding (T003-T005)
4. Complete User Story 2 scaffolding (T018)
5. Complete User Story 3 checks that don't depend on content (T021)
6. Run scaffolding validation (T022)
7. **STOP** — all remaining tasks are `[CONTENT-BLOCKED]`

### Blocked Until Feature 003 Ships

1. Confirm `meta/architecture-assessment/` exists with real content (re-verify T002's finding)
2. Complete User Story 1 content tasks (T006-T017) — can proceed per-file in parallel
3. Complete User Story 2 status update (T019)
4. Complete User Story 3 final check (T020)
5. Run content validation (T023)

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- [CONTENT-BLOCKED] label maps task to the Feature 003 precondition per FR-012 — re-verify at
  task start, not only against this file's generation-time timestamp
- No tests are generated (documentation-only feature, no automated suite per plan.md)
- No application source file or ADR may be touched by any task in this file (FR-009, FR-010)
