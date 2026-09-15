# Research: gh-agent-board CRUD, Change-Owner, and Reassign Prompts

Technical Context items were resolved from the spec's already-confirmed clarifications and this
repo's existing `tools/gh-agent-board/` conventions (`specs/copilot-agent-issue-board/`); no items
were left as NEEDS CLARIFICATION. This document records the supporting decisions specific to this
feature's additions.

## Decision: Add a shared `lib/board-item.sh` helper to resolve a ticket number to its Projects v2 item

- **Rationale**: The existing `set-field.sh` takes `--item-id`, not a ticket/Issue number, but
  FR-010 requires every new prompt to accept only a ticket number. `view-ticket.sh`,
  `update-ticket.sh`, and `retire-ticket.sh` all need the same two things: confirm the Issue exists
  (FR-006) and resolve its Projects v2 item id (plus current Status/Priority/assignees for
  `view-ticket.sh`'s output and `update-ticket.sh`'s "previous value" reporting). Centralizing this
  in one lib function keeps not-found handling and the `gh issue view` + `gh project item-list`
  lookup pattern consistent across all three scripts.
- **Alternatives considered**: Duplicating the lookup in each script — rejected, risks inconsistent
  not-found messages/exit codes across scripts, violating the "each prompt independently re-checks
  the ticket exists" edge case in a uniform way.

## Decision: `view-ticket.sh` is read-only and writes no audit-log entry

- **Rationale**: `specs/copilot-agent-issue-board/data-model.md`'s Audit Log Entry only enumerates
  mutating actions (`create_issue`, `set_field`, `reopen_issue`, `open_pr`, `link_artifact`,
  `set_milestone`); FR-008 only requires an audit entry for "every write action performed by these
  prompts." A lookup performs no `gh` mutation, so it stays consistent with that existing contract.
- **Alternatives considered**: Logging every invocation including reads — rejected; no FR requires
  it, and it would add audit noise not covered by any acceptance scenario.

## Decision: `update-ticket.sh` and `retire-ticket.sh` resolve the item id, then invoke the existing `set-field.sh` as a subprocess

- **Rationale**: The spec's Assumptions explicitly say read/update/reassign prompts should reuse
  `set-field.sh` rather than introduce a new access pattern. `set-field.sh` already validates
  field/value against `config/board.json` and writes the `set_field` audit entry; the new wrapper
  scripts add only ticket-number resolution (and, for retire, outcome-to-Status mapping) on top.
- **Alternatives considered**: Re-implementing the `gh project item-edit` call and audit write
  directly in the new scripts — rejected, duplicates already-tested logic and risks the two
  scripts' audit entries drifting out of format sync over time.

## Decision: `change-owner.sh` is one shared script invoked by both the change-owner and reassign prompts

- **Rationale**: FR-005 states the two prompts "may share one underlying script." The script
  resolves the Issue's current assignees via `gh issue view --json assignees`, then runs
  `gh issue edit <number> --add-assignee <new-owner> --remove-assignee <previous-assignees>` so the
  ticket ends up with exactly the new owner as sole assignee, and writes one new audit action,
  `change_owner`, with `details: {"previous_assignees": [...], "new_owner": "<login>"}`.
- **Alternatives considered**: Two near-duplicate scripts (one per prompt) — rejected as
  unnecessary duplication the spec explicitly disclaims.

## Decision: the retire prompt's "won't-fix" outcome is a new, currently unconfigured Status value

- **Rationale**: FR-009 says the retire prompt sets the ticket's Status field only, via
  `set-field.sh` (reuse, no new mutation path). `set-field.sh` validates values only against
  `config/board.json`'s configured Status options, which today are `Todo`/`In Progress`/`In
  Review`/`Done` — there is no `Won't Fix` option in either the checked-in config or (unverified)
  the live GitHub Project field. The "done" outcome maps directly to the existing `Done` value and
  works today. The "won't-fix" outcome maps to a `Won't Fix` Status value that does not yet exist;
  until a human adds that option to the live Project field and to `config/board.json` (the
  existing, documented one-time setup step in `tools/gh-agent-board/README.md`), `retire-ticket.sh`
  will surface `set-field.sh`'s existing "field not configured" failure for that outcome only. This
  is recorded as a new entry in `docs/context/gaps.md` per Constitution Principle IV rather than
  guessed silently.
- **Alternatives considered**: Silently reusing `Done` for both outcomes — rejected: it would
  misreport won't-fix tickets as completed, contradicting spec User Story 5's Acceptance Scenario 2
  ("the ticket's Status reflects that outcome"). Having `retire-ticket.sh` call
  `gh project field-create`/`item-edit` to add a brand-new option itself — rejected: out of scope
  for this feature's FRs, and changing the live board schema from a script is a bigger, unreviewed
  change than this feature's spec asks for.

## Decision: ticket-number input validation happens before any `gh` call

- **Rationale**: The spec's Edge Cases require rejecting a syntactically invalid ticket number
  (non-numeric, blank, or negative) before any board/Issue lookup. Every new/wrapping script
  validates this first and, on failure, exits `2` with no `gh` call and no audit entry — mirroring
  the existing `create-issue.sh` pattern for a missing `--title`.
- **Alternatives considered**: Letting `gh issue view`/`gh project item-list` fail naturally on a
  bad number — rejected, since `gh` may exit non-zero for reasons other than a malformed number
  (e.g., auth/network), and the spec wants a distinct, immediate rejection for shape errors.
