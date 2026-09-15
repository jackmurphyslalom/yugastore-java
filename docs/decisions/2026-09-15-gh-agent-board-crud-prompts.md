# gh-agent-board CRUD/change-owner/reassign prompts reuse existing scripts and extend the audit vocabulary

## Date
2026-09-15

## Context
`specs/001-gh-board-crud-prompts/` added six agent-invocable prompts (lookup, create, update,
change-owner, reassign, retire) on top of the existing `tools/gh-agent-board/` tooling
(`specs/copilot-agent-issue-board/`). Every prompt accepts only a ticket (Issue) number, but the
existing `set-field.sh` takes a Projects v2 item id, not an Issue number.

## Decision
- Added a shared `tools/gh-agent-board/lib/board-item.sh` (`board_item_resolve`) that resolves a
  ticket number to its item id, current Status/Priority/assignees, or a not-found result. Every new
  script that needs ticket-number lookup (`view-ticket.sh`, `update-ticket.sh`, `retire-ticket.sh`)
  calls this helper instead of duplicating the `gh issue view` + `gh project item-list` lookup.
- `update-ticket.sh` and `retire-ticket.sh` resolve the item id and then invoke the existing
  `set-field.sh` as a subprocess rather than re-implementing field validation or the audit write.
- `change-owner.sh` is one script shared by both the change-owner and reassign prompts (same
  action), and it introduces a new audit action value, `change_owner`, with
  `details: {"previous_assignees": [...], "new_owner": "<login>"}` — extending the audit vocabulary
  documented in `specs/copilot-agent-issue-board/data-model.md`.
- `view-ticket.sh` is read-only and intentionally writes no audit-log entry, consistent with the
  existing "audit only write actions" contract.

## Rationale
Centralizing ticket resolution and reusing `set-field.sh` keeps not-found handling, field
validation, and audit-entry format consistent across all gh-agent-board scripts instead of letting
each new script drift independently.

## Consequences
Future gh-agent-board scripts that need "given a ticket number, do X" should call
`board_item_resolve` and reuse `set-field.sh` (or the equivalent existing script) rather than
re-implementing lookup/mutation logic. Any consumer of `docs/context/audit/agent-actions.jsonl`
must now also handle the `change_owner` action.

## Related
- `specs/001-gh-board-crud-prompts/plan.md`, `research.md`, `contracts/scripts.md`
- `specs/copilot-agent-issue-board/data-model.md` (original audit action vocabulary)
- `tools/gh-agent-board/lib/board-item.sh`, `tools/gh-agent-board/scripts/change-owner.sh`
