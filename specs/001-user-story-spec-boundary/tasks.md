---

description: "Task list template for feature implementation"
---

# Tasks: GitHub Issue vs. Spec Kit Feature Spec Boundary

**Input**: Design documents from `specs/001-user-story-spec-boundary/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md),
[data-model.md](data-model.md), [quickstart.md](quickstart.md)

**Tests**: Not applicable. This is a documentation-only feature (no `[NEEDS CLARIFICATION]` or
test request in spec.md); validation is the manual quickstart walkthrough in the Polish phase.

**Organization**: Tasks are grouped by user story (P1–P3, per spec.md) so each can be validated
independently against its own acceptance scenarios. All story tasks edit the same single file
(`docs/process/user-stories-vs-specs.md`), so — unlike a typical multi-file feature — story tasks
are sequential, not parallel, to avoid edit conflicts on that file.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)

## Path Conventions

Documentation-only feature — no `src/`/`tests/` tree. Paths touched:

- `docs/process/user-stories-vs-specs.md` (new)
- `docs/process/README.md` (updated)
- `specs/README.md` (updated)

---

## Phase 1: Setup

**Purpose**: Create the new page with the shared header/intro before any section is drafted

- [x] T001 Create `docs/process/user-stories-vs-specs.md` with a title, one-sentence purpose
      statement, and a link back to this feature (`specs/001-user-story-spec-boundary/spec.md`),
      matching the terse style of `docs/process/pr-process.md` and `docs/process/mcp-servers.md`
      (plan.md Constraints)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Establish the two core artifact definitions every user story section builds on

**⚠️ CRITICAL**: No user story section can be drafted until this phase is complete

- [x] T002 In `docs/process/user-stories-vs-specs.md`, add a "GitHub Issue" definition (product-
      level backlog artifact, tracked via the project board + `tools/gh-agent-board` tooling) and
      a "Spec Kit Feature (`specs/<feature>/`)" definition (per-feature `spec.md`/`plan.md`/
      `tasks.md` delivery artifacts) (FR-001, FR-002; data-model.md)
- [x] T003 In the same file, add the two worked-example references that later sections will cite:
      "Issue only" (issue #19 / PR #38, the Brewfile) and "Issue + `specs/` feature"
      (`specs/copilot-agent-issue-board/`) (FR-004 evidence; plan.md Existing Patterns)

**Checkpoint**: Definitions and worked examples exist — user story sections can now be drafted

---

## Phase 3: User Story 1 - Decide where new work should be tracked (Priority: P1) 🎯 MVP

**Goal**: A contributor can classify a new piece of work as "Issue only" or "Issue + `specs/`
feature" using a testable rule, not just examples.

**Independent Test**: quickstart.md scenario 1 — classify 3 example intakes using only the doc.

- [x] T004 [US1] In `docs/process/user-stories-vs-specs.md`, write the concrete testable
      promotion rule (journey count ≥2, touches >1 microservice/module, or needs a
      `plan.md`/`tasks.md` breakdown) (FR-004; research.md "Promotion rule shape")
- [x] T005 [US1] Apply the rule from T004 to the two worked examples from T003, showing the
      "Issue only" and "Issue + `specs/` feature" outcomes explicitly (FR-004)

**Checkpoint**: User Story 1 is fully drafted and independently testable via quickstart scenario 1

---

## Phase 4: User Story 2 - Resolve which artifact is authoritative (Priority: P2)

**Goal**: A reader can state, for each of the 6 delivery stages, which single artifact
(GitHub Issue or `specs/<feature>/`) is authoritative.

**Independent Test**: quickstart.md scenario 2 — pick any one delivery stage and confirm exactly
one authoritative artifact is stated.

- [x] T006 [US2] In `docs/process/user-stories-vs-specs.md`, add a precedence table covering all
      6 delivery stages (intake/backlog, `/speckit.specify`, `/speckit.plan`, `/speckit.tasks`,
      `/speckit.implement`, done/closed) and the single authoritative artifact at each (FR-003)

**Checkpoint**: User Story 2 is fully drafted and independently testable via quickstart scenario 2

---

## Phase 5: User Story 3 - Avoid conflating spec.md "User Story" sections with Issues (Priority: P3)

**Goal**: A reader understands that a `spec.md` "User Story" section is not itself a backlog item.

**Independent Test**: quickstart.md scenario 3 — search the doc for "User Story" and confirm the
distinction is stated explicitly.

- [x] T007 [US3] In `docs/process/user-stories-vs-specs.md`, add an explicit terminology note:
      a `spec.md` "User Story N (Priority: Px)" section is a prioritized journey *within* one
      Spec Kit feature, not a standalone backlog item or a substitute for a GitHub Issue
      (FR-005; data-model.md "User Story (spec.md section)")

**Checkpoint**: All three user stories are drafted and independently testable

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Lifecycle convention, discoverability links, and final validation

- [x] T008 In `docs/process/user-stories-vs-specs.md`, add the lifecycle/closure section: closing
      a GitHub Issue remains human-only (no `close-issue.sh` exists); a `specs/<feature>/` and its
      originating Issue are linked via `tools/gh-agent-board/scripts/link-artifacts.sh`; open/
      closed and in-progress/done state are tracked independently (FR-006)
- [x] T009 [P] Add one bullet to `docs/process/README.md` linking the new page (FR-007)
- [x] T010 [P] Add a short cross-link from `specs/README.md` to the new page (FR-008)
- [x] T011 Run all 5 `quickstart.md` validation scenarios against the finished page end to end
- [x] T012 Re-validate `specs/001-user-story-spec-boundary/checklists/requirements.md` against the
      finished page; update any checkbox whose pass/fail state changed

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 — BLOCKS all user stories
- **User Stories (Phases 3–5)**: All depend on Phase 2. Because every story task edits the same
  single file, run them **sequentially in priority order (P1 → P2 → P3)**, not in parallel,
  despite the template's usual "user stories can proceed in parallel" guidance.
- **Polish (Phase 6)**: T008 depends on Phase 2; T009/T010 depend on nothing but Phase 1 (different
  files, can run in parallel with each other and with Phases 3–5); T011 depends on T004–T010;
  T012 depends on T011.

### Within Each User Story

- No tests are requested for this feature; each story is one or two direct doc-editing tasks.
- Story complete before moving to the next priority (same-file edit ordering, not just convention).

### Parallel Opportunities

- T009 and T010 are the only tasks safe to run in parallel with each other (different files).
- All other tasks touch `docs/process/user-stories-vs-specs.md` and must run sequentially.

---

## Parallel Example: Phase 6

```bash
# Safe to run together — different files:
Task: "Add one bullet to docs/process/README.md linking the new page"
Task: "Add a short cross-link from specs/README.md to the new page"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: run quickstart.md scenario 1 independently

### Incremental Delivery

1. Setup + Foundational → page skeleton with definitions ready
2. Add User Story 1 → validate scenario 1 (promotion rule)
3. Add User Story 2 → validate scenario 2 (authority precedence)
4. Add User Story 3 → validate scenario 3 (terminology distinction)
5. Polish → lifecycle section, both cross-links, full quickstart + checklist re-validation

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Commit after each phase (or logical group) completes
- Stop at any checkpoint to validate a story independently before continuing
