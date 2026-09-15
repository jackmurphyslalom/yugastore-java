# Tasks: gh-agent-board CRUD, Change-Owner, and Reassign Prompts

**Input**: Design documents from `/specs/001-gh-board-crud-prompts/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md,
data-model.md, contracts/scripts.md, quickstart.md

**Tests**: Included. `plan.md`'s Constitution Check (Principle V) requires `bats-core` tests for
every new script's successful path, not-found path, and `gh` failure path, matching the existing
`tools/gh-agent-board/tests/*.bats` pattern.

**Organization**: Tasks are grouped by user story (spec.md priorities P1/P1/P1/P2/P3) to enable
independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1-US5)
- Include exact file paths in descriptions

## Path Conventions

All paths are relative to the repository root (`/Users/jack/projects/yugastore-java`):

- Scripts/lib: `tools/gh-agent-board/scripts/`, `tools/gh-agent-board/lib/`
- Tests: `tools/gh-agent-board/tests/`
- Prompts: `.github/prompts/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Confirm the existing tooling/test harness this feature extends is ready; no new
languages, package managers, or scaffolding are introduced (bash + `gh` + `jq` + `bats-core`
already used throughout `tools/gh-agent-board/`).

- [X] T001 Confirm `bats-core` and `jq` are on `PATH` and `bats tests/` passes cleanly today from
      `tools/gh-agent-board/` (baseline before adding new tests)

**Checkpoint**: Existing test suite is green; safe to add new lib/scripts on top.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shared ticket-resolution helper required by User Story 1 (lookup), User Story 3
(update), and User Story 5 (retire) before any of those scripts can be written.

**⚠️ CRITICAL**: No US1/US3/US5 work can begin until this phase is complete. US2 (create, reuses
`create-issue.sh` unchanged) and US4 (`change-owner.sh`, which resolves the Issue itself per its
own contract) do not depend on this phase and may proceed in parallel with it.

- [X] T002 Add `tests/fixtures/gh-stub` response coverage/queue entries needed for
      `gh project item-list` (JSON array of items with `content.number`, `fieldValues`) in
      `tools/gh-agent-board/tests/fixtures/gh-stub`, if not already supported by the existing stub
      (verify first; extend only if the stub cannot already return arbitrary queued JSON)
- [X] T003 Implement `board_item_resolve --issue <number>` in
      `tools/gh-agent-board/lib/board-item.sh` per contracts/scripts.md: validates positive-integer
      `--issue` (exit `2` before any `gh` call on invalid shape), runs
      `gh issue view <number> --json number,title,assignees`, sets `BOARD_ITEM_NOT_FOUND=1`/returns
      `1` on not-found, else runs `gh project item-list <project_number> --owner <owner> --format
      json` (reading `project_number`/`owner` from `config/board.json` like the existing scripts),
      filters for the matching `content.number`, and exports `BOARD_ITEM_ID`, `BOARD_ITEM_TITLE`,
      `BOARD_ITEM_ASSIGNEES`, `BOARD_ITEM_STATUS`, `BOARD_ITEM_PRIORITY` on success (return `0`)
- [X] T004 [P] Write `tools/gh-agent-board/tests/board-item.bats` covering: valid ticket resolves
      all exported vars; invalid (non-numeric/blank/negative) `--issue` exits `2` with no `gh` call
      (`$GH_STUB_LOG` empty); Issue not found sets `BOARD_ITEM_NOT_FOUND=1` and returns `1`;
      `gh issue view` succeeds but `gh project item-list` fails or has no matching item is reported
      distinctly from not-found (per contracts/scripts.md Error handling)

**Checkpoint**: `board_item_resolve` is implemented and tested — User Stories 1, 3, and 5 can now
proceed (in parallel with each other and with US2/US4).

---

## Phase 3: User Story 1 - Look up a ticket by number (Priority: P1) 🎯 MVP

**Goal**: Given a ticket number, display its title, Status, Priority, and assignee(s), or a clear
not-found message, with no write/audit action taken (FR-002, FR-006).

**Independent Test**: Run `view-ticket.sh --issue <number>` for a ticket that exists on the board
and confirm it prints title/status/priority/assignees; run it again for a non-existent number and
confirm a not-found message with no audit-log entry written.

### Tests for User Story 1 ⚠️

> Write these tests FIRST, ensure they FAIL before implementation

- [X] T005 [P] [US1] Write `tools/gh-agent-board/tests/view-ticket.bats` covering: existing ticket
      prints the documented JSON shape (`issue_number`, `title`, `status`, `priority`,
      `assignees`) and exits `0`; ticket with unset Status/Priority prints `null` for those fields;
      not-found ticket exits `1` with a clear stderr message and no output JSON; invalid `--issue`
      shape exits `2` with no `gh` call; confirm no audit-log entry is written for any case (per
      data-model.md, `view-ticket.sh` is read-only)

### Implementation for User Story 1

- [X] T006 [US1] Implement `tools/gh-agent-board/scripts/view-ticket.sh` per contracts/scripts.md:
      sources `lib/board-item.sh`, calls `board_item_resolve --issue <number>`, on success prints
      `{"issue_number": <int>, "title": "<string>", "status": <string|null>, "priority":
      <string|null>, "assignees": [<string>, ...]}` and exits `0`; on invalid shape exits `2`; on
      not-found exits `1` with a clear message; on other `board_item_resolve` failure exits `1`
      with the underlying `gh` error — writes no audit entry (depends on T003)
- [X] T007 [US1] Run `tools/gh-agent-board/tests/view-ticket.bats` and fix `view-ticket.sh` until
      all cases from T005 pass
- [X] T008 [US1] Create `.github/prompts/rabbit-gh-board-view.prompt.md` (FR-002, FR-010): accepts a
      ticket number, invokes `tools/gh-agent-board/scripts/view-ticket.sh --issue <number>`, and
      presents the returned title/Status/Priority/assignees (or the not-found message) to the
      caller

**Checkpoint**: User Story 1 (lookup) is fully functional and independently testable.

---

## Phase 4: User Story 2 - Create a new ticket (Priority: P1)

**Goal**: Open a new tracked ticket (Issue + board item) from a title (and optional
body/priority), returning the new ticket number, reusing the existing `create-issue.sh` unchanged
(FR-001).

**Independent Test**: Run the create prompt with a title only, confirm a new Issue is opened,
added to the board, and its ticket number is returned; confirm reasonable defaults are stated when
body/priority are omitted.

### Implementation for User Story 2

- [X] T009 [P] [US2] Create `.github/prompts/rabbit-gh-board-create.prompt.md` (FR-001, FR-010): accepts a
      title and optional body/priority, invokes the existing
      `tools/gh-agent-board/scripts/create-issue.sh --title <title> [--body <body>] --agent-id
      <agent-id> --session-id <session-id>` unchanged, and — when `--priority` is supplied by the
      caller — follows up with `tools/gh-agent-board/scripts/update-ticket.sh --issue
      <returned-issue-number> --field Priority --value <priority>` (available after Phase 5); if no
      priority is supplied, states in its response that no Priority default was applied and one may
      be set later via the update prompt; returns the new ticket number to the caller

**Checkpoint**: User Story 2 (create) is functional using only the existing, unmodified
`create-issue.sh`. No new script or test file is needed for this story.

---

## Phase 5: User Story 3 - Update an existing ticket's tracked fields (Priority: P1)

**Goal**: Given a ticket number and a new Status or Priority value, update that field and report
the previous value, rejecting unsupported values without any change (FR-003).

**Independent Test**: Run the update prompt with a valid ticket number and a supported Status
value, confirm the field changes and the previous value is reported; run it with an unsupported
value and confirm rejection with no change; run it with a non-existent ticket number and confirm a
not-found message with no change.

### Tests for User Story 3 ⚠️

> Write these tests FIRST, ensure they FAIL before implementation

- [X] T010 [P] [US3] Write `tools/gh-agent-board/tests/update-ticket.bats` covering: valid ticket +
      supported Status/Priority value succeeds, prints `{"issue_number", "field", "previous_value",
      "new_value"}`, and delegates the audit entry to `set-field.sh` (one `set_field` entry, not a
      duplicate); unsupported field/value propagates `set-field.sh`'s exit `2` and "field not
      configured" reason with no additional audit entry from `update-ticket.sh` itself; not-found
      ticket exits `1` with no `gh` mutation attempted and no audit entry from the resolve step;
      invalid `--issue` shape exits `2` with no `gh` call

### Implementation for User Story 3

- [X] T011 [US3] Implement `tools/gh-agent-board/scripts/update-ticket.sh` per
      contracts/scripts.md: sources `lib/board-item.sh`, calls `board_item_resolve --issue
      <number>` (not-found -> exit `1`, no mutation), records the previous value of `--field` from
      `BOARD_ITEM_STATUS`/`BOARD_ITEM_PRIORITY`, invokes
      `tools/gh-agent-board/scripts/set-field.sh --item-id <resolved-id> --field <field> --value
      <value> --agent-id <agent-id> --session-id <session-id>` as a subprocess, and on success
      prints `{"issue_number": <int>, "field": "<field>", "previous_value": <string|null>,
      "new_value": "<value>"}` — depends on T003
- [X] T012 [US3] Run `tools/gh-agent-board/tests/update-ticket.bats` and fix `update-ticket.sh`
      until all cases from T010 pass
- [X] T013 [US3] Create `.github/prompts/rabbit-gh-board-update.prompt.md` (FR-003, FR-010): accepts a
      ticket number, a field (Status or Priority), and a value; invokes
      `tools/gh-agent-board/scripts/update-ticket.sh --issue <number> --field <field> --value
      <value> --agent-id <agent-id> --session-id <session-id>`; on rejection, lists the supported
      values for that field from `config/board.json`

**Checkpoint**: User Stories 1, 2, and 3 (all P1) are independently functional.

---

## Phase 6: User Story 4 - Change a ticket's owner / reassign it (Priority: P2)

**Goal**: Given a ticket number and a new owner, update the ticket's sole assignee and report the
previous assignee(s); reject an invalid collaborator with no change (FR-004, FR-005).

**Independent Test**: Run the change-owner prompt with a valid ticket number and a valid new
owner, confirm the assignee updates and the previous assignee is reported; run the reassign prompt
the same way and confirm identical behavior (same underlying script); run with a non-collaborator
owner and confirm rejection with no change; run with a non-existent ticket number and confirm a
not-found message with no change.

### Tests for User Story 4 ⚠️

> Write these tests FIRST, ensure they FAIL before implementation

- [X] T014 [P] [US4] Write `tools/gh-agent-board/tests/change-owner.bats` covering: valid ticket +
      valid new owner succeeds, prints `{"issue_number", "previous_assignees", "new_owner"}`, and
      logs one `action: "change_owner"` audit entry with `result: "succeeded"` and matching
      `details`; ticket with no previous assignees omits `--remove-assignee`; not-found ticket
      exits `1` with a failed `change_owner` audit entry (`reason: "ticket not found"`); `gh issue
      edit` failure (e.g., invalid collaborator) exits `1` with a failed `change_owner` audit entry
      and no partial assignee change; invalid `--issue` shape or empty `--new-owner` exits `2` with
      no `gh` call and no audit entry

### Implementation for User Story 4

- [X] T015 [US4] Implement `tools/gh-agent-board/scripts/change-owner.sh` per
      contracts/scripts.md: validates `--issue` shape and non-empty `--new-owner` (exit `2` on
      invalid, no `gh` call, no audit entry); runs `gh issue view <number> --json
      number,assignees` (not-found -> exit `1`, failed `change_owner` audit entry); runs `gh issue
      edit <number> --add-assignee <new-owner> --remove-assignee <comma-joined
      previous-assignees>` (omitting `--remove-assignee` when there were none); on success, appends
      an audit entry (`action: "change_owner"`, `target: "<issue_number>"`, `result: "succeeded"`,
      `details: {"previous_assignees": [...], "new_owner": "<login>"}`) and prints
      `{"issue_number": <int>, "previous_assignees": [...], "new_owner": "<login>"}`; on `gh issue
      edit` failure, appends a failed `change_owner` audit entry and exits `1`
- [X] T016 [US4] Run `tools/gh-agent-board/tests/change-owner.bats` and fix `change-owner.sh` until
      all cases from T014 pass
- [X] T017 [P] [US4] Create `.github/prompts/rabbit-gh-board-change-owner.prompt.md` (FR-004, FR-010):
      accepts a ticket number and a new owner, invokes
      `tools/gh-agent-board/scripts/change-owner.sh --issue <number> --new-owner <login>
      --agent-id <agent-id> --session-id <session-id>`, and reports the previous assignee(s) and
      new owner (or the not-found/rejection message)
- [X] T018 [P] [US4] Create `.github/prompts/rabbit-gh-board-reassign.prompt.md` (FR-005, FR-010):
      functionally identical to `rabbit-gh-board-change-owner.prompt.md` — accepts a ticket number and a
      new assignee, invokes the same `tools/gh-agent-board/scripts/change-owner.sh`, and reports
      the previous assignee(s) and new owner

**Checkpoint**: User Story 4 (change owner / reassign) is independently functional; audit log
gains the new `change_owner` action value (data-model.md).

---

## Phase 7: User Story 5 - Retire a ticket without closing it (Priority: P3)

**Goal**: Given a ticket number and an outcome (done or won't-fix), set the ticket's Status field
only, never call `gh issue close`, and remind the caller that closing remains a human action
(FR-009).

**Independent Test**: Run the retire prompt with `--outcome done` on a valid ticket, confirm Status
becomes `Done`, the Issue itself stays open, and a close reminder is printed; run with
`--outcome wont-fix` and confirm the documented current-limitation failure ("field not configured")
until a human adds the `Won't Fix` Status option (tracked in `docs/context/gaps.md`); run with a
non-existent ticket number and confirm a not-found message with no change.

### Tests for User Story 5 ⚠️

> Write these tests FIRST, ensure they FAIL before implementation

- [X] T019 [P] [US5] Write `tools/gh-agent-board/tests/retire-ticket.bats` covering: valid ticket +
      `--outcome done` succeeds, maps to Status `Done`, delegates to `set-field.sh` (one
      `set_field` audit entry), and prints the close-reminder text plus `{"issue_number",
      "status"}`; `--outcome wont-fix` against today's `config/board.json` (no `Won't Fix` option)
      propagates `set-field.sh`'s exit `2` "field not configured" failure unchanged; not-found
      ticket exits `1` with no mutation; invalid `--issue` shape or an `--outcome` value other than
      `done`/`wont-fix` exits `2` with no `gh` call

### Implementation for User Story 5

- [X] T020 [US5] Implement `tools/gh-agent-board/scripts/retire-ticket.sh` per
      contracts/scripts.md: sources `lib/board-item.sh`, validates `--outcome` is `done` or
      `wont-fix` (exit `2` on any other value or invalid `--issue` shape, no `gh` call), calls
      `board_item_resolve --issue <number>` (not-found -> exit `1`, no mutation), maps `done` ->
      `Done` / `wont-fix` -> `Won't Fix`, invokes
      `tools/gh-agent-board/scripts/set-field.sh --item-id <resolved-id> --field Status --value
      <mapped-value> --agent-id <agent-id> --session-id <session-id>`, and on success prints the
      human-close reminder plus `{"issue_number": <int>, "status": "<mapped-value>"}` — never calls
      `gh issue close` — depends on T003
- [X] T021 [US5] Run `tools/gh-agent-board/tests/retire-ticket.bats` and fix `retire-ticket.sh`
      until all cases from T019 pass
- [X] T022 [US5] Create `.github/prompts/rabbit-gh-board-retire.prompt.md` (FR-009, FR-010): accepts a
      ticket number and an outcome (`done` or `wont-fix`), invokes
      `tools/gh-agent-board/scripts/retire-ticket.sh --issue <number> --outcome <outcome>
      --agent-id <agent-id> --session-id <session-id>`, surfaces the human-close reminder on
      success, and surfaces the "field not configured" limitation clearly for `wont-fix` today

**Checkpoint**: All five user stories are independently functional.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Repo-wide consistency and validation across all five stories.

- [X] T023 [P] Run `shellcheck` (or the repo's existing lint convention, if any, for
      `tools/gh-agent-board/*.sh`) across `lib/board-item.sh`,
      `scripts/{view-ticket,update-ticket,change-owner,retire-ticket}.sh` and fix any warnings
- [X] T024 Run the full suite from `tools/gh-agent-board/`: `bats tests/` and confirm every
      `*.bats` file passes, including the five new files added in Phases 2-7
- [ ] T025 Execute the manual smoke test in
      [quickstart.md](/Users/jack/projects/yugastore-java/specs/001-gh-board-crud-prompts/quickstart.md)
      against a disposable/sandbox Issue (steps 1-8) and confirm the audit trail matches the
      expected entries (SC-002/SC-003)
- [ ] T026 [P] Promote the new "Ticket" and "Owner"/"Assignee" terminology into
      `docs/product/glossary.md` per plan.md's Constitution Check (Principle III), via
      `/speckit.aisdlc.promote`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup - BLOCKS User Stories 1, 3, and 5 only
- **User Story 2 (Phase 4)** and **User Story 4 (Phase 6)**: Depend only on Setup (Phase 1); do
  NOT depend on Foundational (Phase 2) — may start in parallel with it
- **User Stories 1, 3, 5 (Phases 3, 5, 7)**: Depend on Foundational (Phase 2) completion
- **Polish (Phase 8)**: Depends on all five user stories being complete

### User Story Dependencies

- **User Story 1 (P1, lookup)**: Needs Foundational (`board-item.sh`) - no dependency on other
  stories
- **User Story 2 (P1, create)**: No dependency on Foundational or other stories (reuses
  `create-issue.sh` unchanged); its prompt's optional priority-default follow-up references
  User Story 3's `update-ticket.sh`, available once Phase 5 completes
- **User Story 3 (P1, update)**: Needs Foundational (`board-item.sh`) - no dependency on other
  stories
- **User Story 4 (P2, change owner/reassign)**: No dependency on Foundational or other stories
  (`change-owner.sh` resolves the Issue itself)
- **User Story 5 (P3, retire)**: Needs Foundational (`board-item.sh`) and reuses `set-field.sh`
  (unchanged, pre-existing) - no dependency on other new stories

### Within Each User Story

- Tests MUST be written and FAIL before implementation
- `board_item_resolve`/lib work before any script that sources it
- Script implementation before its `.bats` tests are run to green
- Script before its prompt file (prompt just wraps the script)

### Parallel Opportunities

- Setup task T001 has no parallel siblings
- T004 (board-item.bats) can be written in parallel with drafting T003, but must fail against it
  before implementation is considered complete
- Once Foundational (Phase 2) completes: User Stories 1, 3, and 5 can proceed in parallel; User
  Stories 2 and 4 can proceed in parallel with Foundational itself and with each other
- Within US4: T017 and T018 (the two prompt files) are `[P]` since they are different files with
  no dependency on each other
- T023 and T026 in Polish are `[P]`

---

## Parallel Example: Foundational + User Stories 2 and 4

```bash
# Once Setup (T001) is done, these three tracks can run in parallel:
Track A (Foundational, blocks US1/US3/US5): T002 -> T003 -> T004
Track B (US2): T009
Track C (US4): T014 -> T015 -> T016 -> [T017, T018 in parallel]
```

## Parallel Example: User Story 4 prompt files

```bash
Task: "Create .github/prompts/rabbit-gh-board-change-owner.prompt.md"
Task: "Create .github/prompts/rabbit-gh-board-reassign.prompt.md"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (`board-item.sh`) - CRITICAL, blocks US1/US3/US5
3. Complete Phase 3: User Story 1 (lookup)
4. **STOP and VALIDATE**: Run `view-ticket.sh` against a real ticket and a non-existent one
5. Demo the lookup prompt

### Incremental Delivery

1. Setup + Foundational -> Foundation ready for US1/US3/US5
2. Add User Story 1 (lookup) -> validate independently -> demo (MVP!)
3. Add User Story 2 (create, parallel-eligible from the start) -> validate -> demo
4. Add User Story 3 (update) -> validate -> demo
5. Add User Story 4 (change owner/reassign, parallel-eligible from the start) -> validate -> demo
6. Add User Story 5 (retire) -> validate (done path only, until `Won't Fix` is configured) -> demo
7. Polish: lint, full suite, quickstart smoke test, glossary promotion

### Parallel Team Strategy

With multiple developers:

1. One developer starts Setup + Foundational (`board-item.sh`)
2. In parallel, a second developer starts User Story 2 (create prompt) and a third starts User
   Story 4 (`change-owner.sh`) — neither needs Foundational
3. Once Foundational completes, remaining developers pick up User Stories 1, 3, and 5 in parallel
4. All five stories integrate independently; Polish phase runs last

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- `create-issue.sh` and `set-field.sh` are reused unmodified — no tasks alter them
- Verify tests fail before implementing (bats-core, stubbed `gh` per `tests/fixtures/gh-stub`)
- Commit after each task or logical group
- Stop at any checkpoint to validate a story independently
- These prompts use the `rabbit-gh-board-*` prefix per this repo's naming convention for new
  custom prompts (see `.agents/skills/rabbit-archive-to-markdown` for the established pattern)
