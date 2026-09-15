---

description: "Task list for Copilot Agent Issue Board"
---

# Tasks: Copilot Agent Issue Board

**Input**: Design documents from `/specs/copilot-agent-issue-board/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/scripts.md, quickstart.md

**Tests**: Included. research.md and the plan's Testing section mandate `bats-core` with a stubbed `gh`
as the primary automated check for this tooling, and spec User Story 2's Independent Test explicitly
requires "a separate test confirms no agent script can close an Issue" — so contract-level bats tests
are part of this feature's own acceptance bar, not an optional extra.

**Organization**: Tasks are grouped by user story (P1–P3, per spec.md) to enable independent
implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1–US5)
- Paths are relative to the repository root

## Path Conventions

Single-project CLI tooling layout (per plan.md):

- `tools/gh-agent-board/lib/` — shared `gh` wrapper + audit-log writer
- `tools/gh-agent-board/scripts/` — one entry-point script per functional requirement
- `tools/gh-agent-board/config/board.json` — project/field/option ID + allowed-value config
- `tools/gh-agent-board/tests/` — bats-core tests + stubbed `gh` fixture
- `docs/context/audit/agent-actions.jsonl` — durable, repo-tracked audit log

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project scaffolding for the tooling tree

- [X] T001 Create `tools/gh-agent-board/` directory structure (`lib/`, `scripts/`, `config/`,
      `tests/fixtures/`) per plan.md's Project Structure section
- [X] T002 [P] Create `docs/context/audit/` directory with an empty, git-tracked
      `agent-actions.jsonl` placeholder file per FR-017 (repo-tracked, indefinite retention)
- [X] T003 [P] Create `tools/gh-agent-board/tests/fixtures/gh-stub` fake `gh` executable that records
      the arguments it is invoked with and returns canned JSON, per research.md's testing decision

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Cross-cutting infrastructure every script depends on (gh invocation wrapper, audit
logging, and shared config) — every write action must be able to produce an audit entry, so this
phase blocks all user stories.

**⚠️ CRITICAL**: No user story script may be implemented until this phase is complete

- [X] T004 Implement `lib/gh-common.sh` shared `gh`-invocation wrapper (run + capture exit
      code/stderr) in `tools/gh-agent-board/lib/gh-common.sh`
- [X] T005 Implement `lib/audit-log.sh` exposing `audit_log_write --action <action> --target
      <target> --result <succeeded|failed> [--reason "<text>"] [--details '<json>']` per the
      Audit Log Entry contract in data-model.md and contracts/scripts.md, writing one JSON line to
      `docs/context/audit/agent-actions.jsonl` in `tools/gh-agent-board/lib/audit-log.sh`
- [X] T006 [P] Create `config/board.json` holding `project_id`, Status/Priority field IDs and
      single-select option IDs, and the canonical allowed-value lists (Status:
      Todo/In Progress/In Review/Done; Priority: P0–P3) per data-model.md in
      `tools/gh-agent-board/config/board.json`
- [X] T007 [P] Write bats test for `lib/audit-log.sh` covering: entry written before the caller's
      exit code is returned, `agent_id`/`session_id` sourced from flags, then `AGENT_SESSION_ID` env
      var, then literal `unknown`, and a failed log write itself treated as a hard (non-zero) failure
      in `tools/gh-agent-board/tests/audit-log.bats`
- [X] T008 [P] Write bats test for `lib/gh-common.sh` verifying it captures and surfaces `gh`'s exit
      code and stderr to callers in `tools/gh-agent-board/tests/gh-common.bats`

**Checkpoint**: Foundation ready — user story scripts can now be implemented

---

## Phase 3: User Story 1 - Agent files and tracks a new body of work (Priority: P1) 🎯 MVP

**Goal**: An agent can create an Issue, add it to the project board, set its Status/Priority fields,
and link it to the feature's `specs/{feature}/` artifacts, with no human performing manual setup.

**Independent Test**: Create a new Issue via `create-issue.sh`, confirm it is added to the board via
`gh project item-list`, set Status/Priority via `set-field.sh`, and link `spec.md`/`plan.md`/`tasks.md`
via `link-artifacts.sh` — all without a human touching the board.

### Tests for User Story 1 ⚠️

- [X] T009 [P] [US1] bats test for `create-issue.sh`: missing/empty `--title` exits `2` before any
      `gh` call with no audit entry written; successful `gh issue create` + `gh project item-add`
      prints `{"issue_number": N, "item_id": "..."}` and logs one succeeded audit entry; partial
      failure (Issue created but `item-add` fails) exits `1` and logs a failed entry referencing the
      created issue number, in `tools/gh-agent-board/tests/create-issue.bats`
- [X] T010 [P] [US1] bats test for `set-field.sh`: valid Status/Priority value writes succeed; an
      invalid field/value combination exits `2` with no `gh` call and no audit entry; a field/option
      ID missing from `config/board.json` fails with `reason: "field not configured"`, in
      `tools/gh-agent-board/tests/set-field.bats`
- [X] T011 [P] [US1] bats test for `link-artifacts.sh`: an existing path posts a comment and logs a
      succeeded `link_artifact` audit entry; a missing path exits `1`, posts no comment, and logs a
      failed entry with `reason: "artifact path not found"`, in
      `tools/gh-agent-board/tests/link-artifacts.bats`

### Implementation for User Story 1

- [X] T012 [US1] Implement `scripts/create-issue.sh` per contracts/scripts.md: `gh issue create` →
      `gh project item-add` → `audit_log_write action=create_issue` in
      `tools/gh-agent-board/scripts/create-issue.sh` (depends on T004, T005, T006)
- [X] T013 [US1] Implement `scripts/set-field.sh` per contracts/scripts.md: validate `--field`/
      `--value` against `config/board.json`, resolve field/option IDs, run `gh project item-edit`,
      `audit_log_write action=set_field` in `tools/gh-agent-board/scripts/set-field.sh` (depends on
      T004, T005, T006)
- [X] T014 [US1] Implement `scripts/link-artifacts.sh` per contracts/scripts.md for `spec`/`plan`/
      `tasks` kinds: verify `--path` exists, post an issue/PR comment referencing it, `audit_log_write
      action=link_artifact` in `tools/gh-agent-board/scripts/link-artifacts.sh` (depends on T004, T005)

**Checkpoint**: User Story 1 is fully functional and independently testable

---

## Phase 4: User Story 2 - Agent advances work through its lifecycle (Priority: P1)

**Goal**: An agent can move a board item through Status transitions and update Priority, and reopen
an Issue it resumes work on — but no agent script can close an Issue (closing stays human-only).

**Independent Test**: Move one board item's Status across at least three distinct values via
`set-field.sh`, confirm the board's final state matches the last update via `gh project item-list`,
and confirm no script in `tools/gh-agent-board/` can close an Issue.

### Tests for User Story 2 ⚠️

- [X] T015 [P] [US2] bats test asserting `set-field.sh` can move Status across
      Todo → In Progress → In Review → Done (and backward) without unintentionally resetting
      Priority, and that setting Status to `Done` never invokes `gh issue close` as a side effect, in
      `tools/gh-agent-board/tests/set-field-lifecycle.bats`
- [X] T016 [P] [US2] bats test for `reopen-issue.sh`: successful reopen logs a succeeded
      `reopen_issue` audit entry; reopening an already-open Issue (idempotent `gh` no-op) is still
      treated as success; a nonexistent Issue fails with a failed audit entry, in
      `tools/gh-agent-board/tests/reopen-issue.bats`
- [X] T017 [P] [US2] bats test confirming `tools/gh-agent-board/scripts/` contains no close-Issue
      script or action, and that `lib/audit-log.sh`'s action enum has no `close_issue` value, in
      `tools/gh-agent-board/tests/no-close-action.bats`

### Implementation for User Story 2

- [X] T018 [US2] Implement `scripts/reopen-issue.sh` per contracts/scripts.md: `gh issue reopen
      <number>`, `audit_log_write action=reopen_issue` in
      `tools/gh-agent-board/scripts/reopen-issue.sh` (depends on T004, T005). No `close-issue.sh`
      script exists — closing an Issue is a human-only action outside this tooling (FR-004).
- [X] T019 [US2] Confirm `set-field.sh` keeps the Status field and the Issue's open/closed state
      fully independent (no implicit `gh issue close`/`reopen` call from any Status value) in
      `tools/gh-agent-board/scripts/set-field.sh` (depends on T013)

**Checkpoint**: User Stories 1 and 2 both work independently

---

## Phase 5: User Story 3 - Agent opens a linked pull request (Priority: P1)

**Goal**: An agent can open a PR that references an originating Issue via a closing keyword, so the
Issue/board item reflects the PR's existence and eventual merge/close state.

**Independent Test**: Open a PR via `open-pr.sh` referencing a specific Issue number with a closing
keyword and confirm the Issue/board item shows the linked PR.

### Tests for User Story 3 ⚠️

- [X] T020 [P] [US3] bats test for `open-pr.sh`: constructed PR body contains `Closes #<issue-number>`;
      successful `gh pr create` logs a succeeded `open_pr` audit entry with `details.linked_issue`;
      a protected-branch/permission failure from `gh pr create` exits `1` and logs a failed entry
      whose `reason` includes the `gh` stderr, in `tools/gh-agent-board/tests/open-pr.bats`

### Implementation for User Story 3

- [X] T021 [US3] Implement `scripts/open-pr.sh` per contracts/scripts.md: construct a body with
      `Closes #<issue-number>` plus any `--body` text, run `gh pr create`, `audit_log_write
      action=open_pr` in `tools/gh-agent-board/scripts/open-pr.sh` (depends on T004, T005)

**Checkpoint**: User Stories 1–3 all work independently

---

## Phase 6: User Story 4 - Human reviews the audit trail of agent activity (Priority: P2)

**Goal**: A human can retrieve a durable, attributable record of agent-driven writes across Issues,
board fields, and PRs, without relying on GitHub's native UI activity feed.

**Independent Test**: For any agent-created/modified Issue/item/PR in a time range, retrieve a
record showing the action, timestamp, and agent/session identity from `agent-actions.jsonl` alone.

### Tests for User Story 4 ⚠️

- [X] T022 [P] [US4] bats test asserting two different `--agent-id`/`--session-id` pairs invoking the
      same script produce distinguishable audit entries (FR-012/FR-018 session attribution) in
      `tools/gh-agent-board/tests/audit-attribution.bats`
- [X] T023 [P] [US4] bats test reconstructing a chronological multi-action sequence
      (`create_issue` → `set_field` → `open_pr`) filtered by `session_id` from
      `docs/context/audit/agent-actions.jsonl` via `jq`, matching quickstart.md's Step 6 review
      flow, in `tools/gh-agent-board/tests/audit-trail-review.bats`

### Implementation for User Story 4

- [X] T024 [US4] Document `jq`-based audit query examples (filter by `session_id`, reconstruct
      chronological order) in `tools/gh-agent-board/README.md`, referencing quickstart.md's Step 6
      review flow (depends on T005)

**Checkpoint**: Audit-trail reviewability (SC-002, SC-003) is validated end-to-end

---

## Phase 7: User Story 5 - Agent manages the broader artifact taxonomy (Priority: P3)

**Goal**: An agent can assign Issues to a shared milestone and reference checklist/ADR files from an
Issue or PR, extending coverage to the full Spec Kit artifact taxonomy.

**Independent Test**: Assign a milestone to a group of related Issues via `set-milestone.sh`, and
reference a checklist or ADR document from an Issue/PR via `link-artifacts.sh`.

### Tests for User Story 5 ⚠️

- [X] T025 [P] [US5] bats test for `set-milestone.sh`: successful assignment logs a succeeded
      `set_milestone` audit entry; a nonexistent milestone title causes a `gh` failure that exits `1`
      with a failed audit entry, in `tools/gh-agent-board/tests/set-milestone.bats`
- [X] T026 [P] [US5] bats test extending `link-artifacts.sh` coverage to `kind=checklist` and
      `kind=adr` paths (`specs/{feature}/checklists/*.md`, `docs/architecture/adr/*.md`), in
      `tools/gh-agent-board/tests/link-artifacts-taxonomy.bats`

### Implementation for User Story 5

- [X] T027 [US5] Implement `scripts/set-milestone.sh` per contracts/scripts.md: `gh issue edit
      <number> --milestone "<title>"`, `audit_log_write action=set_milestone` in
      `tools/gh-agent-board/scripts/set-milestone.sh` (depends on T004, T005)

**Checkpoint**: All five user stories are independently functional

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Documentation, real-world config population, and final validation across all stories

- [X] T028 [P] Document the one-time `config/board.json` population procedure (looking up
      `project_id`/field IDs/option IDs via `gh project field-list <number> --owner <owner> --format
      json`) in `tools/gh-agent-board/README.md`
- [X] T029 [P] Write `tools/gh-agent-board/README.md` covering prerequisites, script usage, and
      invocation examples for every `scripts/*.sh` entry point
- [X] T030 Review all scripts in `tools/gh-agent-board/scripts/` and `tools/gh-agent-board/lib/` to
      confirm none echo `gh` credentials/tokens to stdout or write them into
      `docs/context/audit/agent-actions.jsonl`
- [X] T031 Run quickstart.md's manual end-to-end smoke test against a disposable sandbox Issue,
      confirming every step (including the human-only close step and the agent
      `reopen-issue.sh` step) logs the expected audit entries
      **Completed live** against `jackmurphyslalom/yugastore-java` project 1 (Issue #12, PR #13,
      a throwaway milestone, and a throwaway branch, all cleaned up afterward). Exercised
      `create-issue.sh`, `set-field.sh` (Status + Priority), `link-artifacts.sh`, `set-milestone.sh`,
      `open-pr.sh`, and `reopen-issue.sh`; closing Issue #12 was done manually via `gh issue close`,
      never by a script. Found and fixed 2 real bugs not caught by the stubbed bats suite:
      `gh issue create` and `gh pr create` do not support `--json` (both scripts parsed the
      plain-text URL output instead), and documented a config quirk (`owner` must be `@me` for
      personal/non-org projects). Full bats suite (33 tests) re-verified green after both fixes.

---

## Phase 9: Convergence

**Purpose**: Close gaps found by `/speckit.converge` between spec/plan/tasks intent and the
implemented code, after T001-T031 were completed and validated (33 bats tests + a live smoke test).

- [X] T032 Document, in `tools/gh-agent-board/README.md`, the known limitation that a process
      killed between a successful `gh` write and its `audit_log_write` call leaves that write
      unrecorded in the audit trail per FR-010 (partial)
- [X] T033 Add a bats test in `tools/gh-agent-board/tests/` confirming no script under
      `tools/gh-agent-board/scripts/` reads interactive input or contains a confirmation/approval
      prompt, mirroring the `no-close-action.bats` pattern per FR-009 (partial)
- [X] T034 Update the `create-issue.sh` contract in `specs/copilot-agent-issue-board/contracts/scripts.md`
      to match the actual working invocation confirmed by the live smoke test: `gh issue create` has
      no `--json` flag (parse the plain-text issue URL instead), and `gh project item-add` takes
      `<project_number> --owner <owner>`, not `<project_id>` per FR-001 (contradicts)
- [X] T035 Update the `open-pr.sh` contract in `specs/copilot-agent-issue-board/contracts/scripts.md`
      to match the actual working invocation confirmed by the live smoke test: `gh pr create` has no
      `--json` flag (parse the plain-text PR URL instead) per FR-005 (contradicts)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Setup — BLOCKS all user stories (every script needs
  `lib/gh-common.sh`, `lib/audit-log.sh`, and `config/board.json`)
- **User Stories (Phase 3–7)**: All depend on Foundational completion; may then proceed in parallel
  or in priority order (US1 → US2 → US3 → US4 → US5)
- **Polish (Phase 8)**: Depends on all desired user stories being complete

### User Story Dependencies

- **US1 (P1)**: No dependency on other stories; introduces `create-issue.sh`, `set-field.sh`,
  `link-artifacts.sh` (spec/plan/tasks kinds)
- **US2 (P1)**: Reuses `set-field.sh` from US1 (T013) for lifecycle transitions; adds
  `reopen-issue.sh`; independently testable via Status transitions + the no-close-script assertion
- **US3 (P1)**: No dependency on other stories beyond Foundational; adds `open-pr.sh`
- **US4 (P2)**: Depends on audit entries produced by US1–US3 scripts existing to review, but its own
  task (T024, documentation) has no code dependency beyond Foundational T005
- **US5 (P3)**: Reuses `link-artifacts.sh` from US1 (T014) for checklist/ADR kinds; adds
  `set-milestone.sh`

### Within Each User Story

- Tests MUST be written and FAIL before implementation
- `lib/` foundations before any `scripts/*.sh`
- Story complete before moving to the next priority

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel (T002, T003)
- Foundational config/test tasks marked [P] can run in parallel (T006, T007, T008) once T004/T005
  are underway
- All tests within a user story marked [P] can run in parallel
- Once Foundational completes, US1/US2/US3/US4/US5 implementation can proceed in parallel by
  different contributors, keeping in mind US2 depends on US1's T013 and US5 depends on US1's T014

---

## Parallel Example: User Story 1

```bash
# Launch all tests for User Story 1 together:
Task: "bats test for create-issue.sh in tools/gh-agent-board/tests/create-issue.bats"
Task: "bats test for set-field.sh in tools/gh-agent-board/tests/set-field.bats"
Task: "bats test for link-artifacts.sh in tools/gh-agent-board/tests/link-artifacts.bats"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL — blocks all stories)
3. Complete Phase 3: User Story 1 (create-issue.sh, set-field.sh, link-artifacts.sh)
4. **STOP and VALIDATE**: run `bats tests/` and the quickstart.md steps for US1 independently

### Incremental Delivery

1. Setup + Foundational → foundation ready
2. Add US1 → validate independently → MVP
3. Add US2 (reuses US1's `set-field.sh`, adds `reopen-issue.sh`) → validate independently
4. Add US3 (`open-pr.sh`) → validate independently
5. Add US4 (audit-trail documentation/review tests) → validate independently
6. Add US5 (`set-milestone.sh`, checklist/ADR linking) → validate independently
7. Each story adds value without breaking previous stories

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- No `close-issue.sh` script exists anywhere in this task list — closing an Issue is a human-only
  action per FR-004; only `reopen-issue.sh` is scripted (T018, US2)
- Verify tests fail before implementing
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
