# Data Model: gh-agent-board CRUD, Change-Owner, and Reassign Prompts

This feature adds no new persisted entity shapes beyond what
`specs/copilot-agent-issue-board/data-model.md` already defines (Issue, Project Item, Status
Field, Priority Field, Audit Log Entry). It adds one new read view and extends the Audit Log
Entry's `action` enum. Field names below map directly onto this feature's spec Key Entities
("Ticket" == Issue, "Owner"/"Assignee" == the Issue's assignee).

## Ticket View (read-only output of `view-ticket.sh`)

Not a persisted entity — the JSON shape `view-ticket.sh` prints to stdout on success, assembled
from `gh issue view` (title, assignees) and `gh project item-list` (Status, Priority), resolved via
`lib/board-item.sh`.

| Field | Type | Notes |
|---|---|---|
| `issue_number` | integer | Echoes the requested ticket number |
| `title` | string | From the Issue |
| `status` | string \| null | Current Status option display name; `null` if the item has no Status set yet |
| `priority` | string \| null | Current Priority option display name; `null` if unset |
| `assignees` | string[] | GitHub logins currently assigned; empty array if none |

**Validation rules**: Only produced when the ticket number resolves to an existing Issue that is a
board Project Item; otherwise `view-ticket.sh` exits non-zero with a not-found message and prints
no JSON (FR-002, FR-006).

## Ticket Update (input contract of `update-ticket.sh`)

| Field | Type | Notes |
|---|---|---|
| `issue_number` | integer | Ticket to update |
| `field` | enum `Status` \| `Priority` | Passed through to `set-field.sh` unchanged |
| `value` | string | Must be one of `config/board.json`'s configured options for `field` |

**Validation rules**: Same as `specs/copilot-agent-issue-board/data-model.md`'s Status/Priority
Field rules (validated against `config/board.json` before any `gh` call) — `update-ticket.sh`
resolves `issue_number` to an `item_id` first (FR-006), then delegates the field/value validation
and the actual `gh project item-edit` call to the existing `set-field.sh`.

## Owner Change (input/output contract of `change-owner.sh`)

| Field | Type | Notes |
|---|---|---|
| `issue_number` | integer | Ticket to reassign |
| `new_owner` | string | GitHub login to become the sole assignee |
| `previous_assignees` | string[] | Read from the Issue before the change; reported back to the caller and recorded in the audit entry's `details` |

**Validation rules**: `issue_number` MUST resolve to an existing Issue (FR-006). `new_owner` MUST be
accepted by `gh issue edit --add-assignee` (i.e., a valid collaborator); a `gh` rejection is
surfaced as a failed audit entry and a non-zero exit, not silently swallowed (spec Acceptance
Scenario 3 for User Story 4).

## Retire Outcome (input contract of `retire-ticket.sh`)

| Field | Type | Notes |
|---|---|---|
| `issue_number` | integer | Ticket to retire |
| `outcome` | enum `done` \| `wont-fix` | Maps to a Status value: `done` -> `Done` (configured today); `wont-fix` -> `Won't Fix` (**not yet configured** — see `research.md` and `docs/context/gaps.md`) |

**Validation rules**: `retire-ticket.sh` never calls `gh issue close` (FR-009). It resolves
`issue_number` to an `item_id` (FR-006), maps `outcome` to a Status value, then delegates to
`set-field.sh` exactly like `update-ticket.sh`. If the mapped Status value is not present in
`config/board.json` (currently true for `wont-fix`), the underlying `set-field.sh` call fails with
its existing "field not configured" error, which `retire-ticket.sh` surfaces to the caller alongside
the standard reminder that closing the Issue itself remains a human action.

## Audit Log Entry (extension)

Extends `specs/copilot-agent-issue-board/data-model.md`'s existing table; only the `action` enum
gains one new value, and `set_field` entries now may also originate from `update-ticket.sh` /
`retire-ticket.sh` (no schema change, same fields).

| Field | Type | Notes |
|---|---|---|
| `action` | enum `create_issue` \| `set_field` \| `reopen_issue` \| `open_pr` \| `link_artifact` \| `set_milestone` \| **`change_owner`** | New value `change_owner` is written only by `change-owner.sh` |

**Validation rules**: Unchanged — one entry per write invocation, written before the script's exit
code is returned, `result: "succeeded" \| "failed"` in every case. `view-ticket.sh` (a read) writes
no entry, consistent with the existing "write action" scope of this table.
