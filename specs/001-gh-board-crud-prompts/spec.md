# Feature Specification: gh-agent-board CRUD, Change-Owner, and Reassign Prompts

**Feature Branch**: `001-gh-board-crud-prompts`

**Created**: 2026-09-15

**Status**: Draft

**Input**: User description: "You have access to gh-agent-board. First create a new issue using these tools, with the content to create a set of CRUD prompts, change owner prompt, and reassign prompt that accept a ticket number as input."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Look up a ticket by number (Priority: P1)

An agent or teammate has a ticket number and wants to see its current details (title, status,
priority, assignee, linked artifacts) without leaving the chat/agent surface.

**Why this priority**: Every other prompt in this suite (update, change owner, reassign) needs a
reliable way to confirm the ticket exists and show its current state before and after a change.
Without a working "read" prompt, none of the write prompts can be verified.

**Independent Test**: Can be fully tested by running the lookup prompt with a valid ticket number
and confirming it returns the ticket's current title, status, priority, and assignee(s), sourced
from the live GitHub Issue and board fields.

**Acceptance Scenarios**:

1. **Given** a ticket number that exists on the board, **When** the lookup prompt is run with that
   number, **Then** it displays the Issue title, Status, Priority, and current assignee(s).
2. **Given** a ticket number that does not exist in the repository, **When** the lookup prompt is
   run with that number, **Then** it reports that no matching Issue was found and takes no write
   action.

---

### User Story 2 - Create a new ticket (Priority: P1)

A teammate or agent wants to open a new tracked ticket on the board directly from a short prompt,
without hand-typing `gh` commands.

**Why this priority**: Ticket creation is the entry point for all other prompts in this suite; a
ticket number cannot be read, updated, reassigned, or have its owner changed until it exists.

**Independent Test**: Can be fully tested by running the create prompt with a title (and optional
body/priority), then confirming a new GitHub Issue is opened, added to the board, and the new
ticket number is returned to the caller.

**Acceptance Scenarios**:

1. **Given** a title and optional description, **When** the create prompt is run, **Then** a new
   Issue is opened, added to the board, and its ticket number is returned.
2. **Given** a title only (no description or priority supplied), **When** the create prompt is
   run, **Then** the ticket is still created with Status defaulted to "Todo" and Priority left unset,
   and the prompt states that these defaults were applied.

---

### User Story 3 - Update an existing ticket's tracked fields (Priority: P1)

An agent or teammate has a ticket number and wants to update its Status and/or Priority as work
progresses, without remembering exact field names or option values.

**Why this priority**: Keeping Status/Priority current is the main day-to-day use of the board;
this is the most frequently repeated action after creation.

**Independent Test**: Can be fully tested by running the update prompt with a ticket number and a
new Status or Priority value, then confirming the board field changed and the prior value is
reported for comparison.

**Acceptance Scenarios**:

1. **Given** a valid ticket number and a supported Status value, **When** the update prompt is run,
   **Then** the ticket's Status changes to the requested value and the previous value is shown.
2. **Given** a valid ticket number and an unsupported Status or Priority value, **When** the update
   prompt is run, **Then** it rejects the request, lists the supported values, and makes no change.
3. **Given** a ticket number that does not exist, **When** the update prompt is run, **Then** it
   reports the ticket was not found and makes no change.

---

### User Story 4 - Change a ticket's owner / reassign it (Priority: P2)

An agent or teammate wants to hand a ticket off to a different person or agent to do the work,
given only the ticket number and the new owner (assignee).

**Why this priority**: Ownership/assignment changes happen less often than status/priority
updates, but are important for accountability once a ticket has multiple candidate drivers.

**Independent Test**: Can be fully tested by running the change-owner (or reassign) prompt with a
ticket number and a new owner, then confirming the ticket's assignee reflects the new value and
the previous assignee is reported.

**Acceptance Scenarios**:

1. **Given** a valid ticket number and a valid new owner, **When** the change-owner prompt is run,
   **Then** the ticket's assignee is updated to the new owner and the previous assignee is shown
   for confirmation.
2. **Given** a ticket number that does not exist, **When** the change-owner prompt is run, **Then**
   it reports the ticket was not found and makes no change.
3. **Given** a new owner who is not a valid collaborator on the repository, **When** the
   change-owner prompt is run, **Then** it rejects the request and makes no change.

---

### User Story 5 - Retire a ticket without closing it (Priority: P3)

An agent or teammate wants to mark a ticket as done or abandoned ("won't fix") using only the
ticket number, without directly closing the underlying GitHub Issue.

**Why this priority**: This is the least-used action in the suite and depends on the other prompts
already working; actually closing the Issue stays a human-only action.

**Independent Test**: Can be fully tested by running the retire prompt with a ticket number and a
target state (done or won't-fix), then confirming the ticket's Status field changes and the
underlying Issue remains open.

**Acceptance Scenarios**:

1. **Given** a valid ticket number, **When** the retire prompt is run with "done", **Then** the
   ticket's Status changes to "Done" and the Issue itself is not closed.
2. **Given** a valid ticket number, **When** the retire prompt is run with "won't fix", **Then** the
   ticket's Status reflects that outcome and the prompt reminds the caller that a human must run
   `gh issue close` to actually close it. **Known limitation**: this outcome currently fails with a
   configuration error until a human adds a matching "Won't Fix" Status option to the board (tracked
   in `docs/context/gaps.md`); the "done" outcome in Scenario 1 is unaffected and works today.
3. **Given** a ticket number that does not exist, **When** the retire prompt is run, **Then** it
   reports the ticket was not found and makes no change.

---

### Edge Cases

- What happens when the same ticket number is passed to two different prompts (e.g., update and
  reassign) back to back? Each prompt must independently re-check the ticket still exists and
  report the state it observed, rather than assuming a prior prompt's result is still valid.
- How does the system handle a ticket number that is syntactically invalid (non-numeric, blank, or
  negative)? Prompts must reject the input before attempting any board or Issue lookup.
- How does the system handle a transient failure calling the underlying board tooling (e.g.,
  network or authentication error)? Prompts must report the failure clearly and make no partial
  change, consistent with the existing audit-logging behavior of gh-agent-board scripts.
- What happens if a prompt is run by someone without permission to modify the repository or
  project board? The prompt must surface the permission error and make no change.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST provide a prompt that creates a new ticket (GitHub Issue added to the
  board) from a supplied title and optional description, and returns the new ticket number.
- **FR-002**: The system MUST provide a prompt that, given a ticket number, displays that ticket's
  current title, Status, Priority, and assignee(s).
- **FR-003**: The system MUST provide a prompt that, given a ticket number and a new Status or
  Priority value, updates that field on the ticket and reports the previous value.
- **FR-004**: The system MUST provide a "change owner" prompt that, given a ticket number and a new
  owner, updates the ticket's assignee to that owner and reports the previous assignee. "Owner" is
  the GitHub Issue assignee — confirmed 2026-09-15; there is no separate owner field.
- **FR-005**: The system MUST provide a "reassign" prompt that is functionally the same action as
  the change-owner prompt (FR-004): given a ticket number and a new assignee, it updates the
  ticket's assignee and reports the previous assignee. The two prompts may share one underlying
  script/implementation.
- **FR-006**: Every prompt in this suite MUST validate that the supplied ticket number refers to an
  existing Issue before attempting any change, and MUST report a clear not-found message and make
  no change when it does not.
- **FR-007**: Every prompt in this suite MUST use the existing `gh` CLI-based gh-agent-board
  scripts (or new scripts added under the same tooling) rather than calling GitHub REST/GraphQL or
  Actions/webhooks directly, consistent with the project's existing `gh`-only constraint.
- **FR-008**: Every write action performed by these prompts MUST produce the same kind of audit log
  entry (`docs/context/audit/agent-actions.jsonl`) that existing gh-agent-board scripts produce, so
  prompt-driven changes remain traceable.
- **FR-009**: The system MUST provide a "retire" prompt standing in for "Delete" that, given a
  ticket number and a target outcome (done or won't-fix), sets the ticket's Status field only
  (e.g., via `set-field.sh`). It MUST NOT call `gh issue close` directly — confirmed 2026-09-15 that
  actually closing the Issue remains a human-only action, consistent with the existing
  gh-agent-board rule (no `close-issue.sh`). The prompt MUST tell the caller that a human still
  needs to close the Issue.
- **FR-010**: Each prompt in this suite MUST be a new agent-invocable prompt file (following this
  repo's existing `.github/prompts/*.prompt.md` convention, e.g. alongside the `speckit.*` prompts)
  that accepts a ticket number (and any other required input) and calls the matching gh-agent-board
  script under `tools/gh-agent-board/scripts/` — confirmed 2026-09-15. New scripts (e.g. for
  change-owner/reassign and retire) MUST be added under `tools/gh-agent-board/scripts/` following
  the existing `--agent-id`/`--session-id`/audit-log contract, with one prompt file per script.

### Key Entities

- **Ticket**: A GitHub Issue tracked on the project board; identified by its ticket (Issue) number;
  has a title, description, Status, Priority, and assignee(s). Referenced throughout this feature by
  ticket number.
- **Owner** / **Assignee**: The GitHub user or agent identity currently assigned to work a ticket;
  "owner" and "assignee" are the same concept in this feature, changed by the change-owner and
  reassign prompts.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can create a new ticket, look it up, change its status/priority, change
  its owner/assignee, and retire it (done or won't-fix) — each via a single prompt invocation with
  a ticket number — without needing to run any raw `gh` command manually, except the final human
  close.
- **SC-002**: 100% of ticket-number inputs that do not correspond to an existing Issue are rejected
  with a clear not-found message, with no partial or silent change to the board.
- **SC-003**: Every successful write action performed by these prompts has a corresponding entry in
  the audit log, matching the existing gh-agent-board audit guarantee.
- **SC-004**: A teammate unfamiliar with the underlying `gh` CLI can perform a status update, an
  owner change, and a reassignment correctly on the first attempt using only the prompt and a
  ticket number.

## Assumptions

- The "ticket number" referenced throughout is the GitHub Issue number already used by the existing
  gh-agent-board tooling (`specs/copilot-agent-issue-board/`), not a separate identifier scheme.
- These prompts operate on tickets already added to the existing configured project board
  (`tools/gh-agent-board/config/board.json`); onboarding a different board is out of scope.
- Read/update/reassign prompts reuse the existing `create-issue.sh` / `set-field.sh` scripts and
  underlying `gh` CLI + audit-log conventions rather than introducing a new access pattern; any new
  script needed (e.g., for owner or reassignment) follows the same `--agent-id`/`--session-id`/audit
  contract documented in `specs/copilot-agent-issue-board/contracts/scripts.md`.
- Closing a ticket (`gh issue close`) remains a human-only action per the existing gh-agent-board
  rule; the "retire" prompt only changes the Status field and reminds the caller to close it.
- [Dependency on existing system/service, e.g., "Requires access to the existing user profile API"]
