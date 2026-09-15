# Quickstart: gh-agent-board CRUD, Change-Owner, and Reassign Prompts

Validation guide for the new `tools/gh-agent-board/` scripts and `.github/prompts/rabbit-gh-board-*`
prompt files added by this feature. Assumes the same prerequisites as
`specs/copilot-agent-issue-board/quickstart.md` (board provisioned, `gh auth login` done as the
shared bot account, `config/board.json` populated).

## Prerequisites

- Everything in `specs/copilot-agent-issue-board/quickstart.md`'s Prerequisites section.
- For the "won't-fix" retire path specifically: a `Won't Fix` Status option added to the live
  GitHub Project field and to `config/board.json`'s `fields.Status.options` (see `research.md` —
  not required for the "done" retire path or any other prompt in this suite).

## Run the automated test suite (no live GitHub calls)

```sh
cd tools/gh-agent-board
bats tests/
```

Expected outcome: every `*.bats` file passes, including the new `board-item.bats`,
`view-ticket.bats`, `update-ticket.bats`, `change-owner.bats`, and `retire-ticket.bats`, using the
existing stubbed `gh` in `tests/fixtures/gh-stub` — no network access occurs.

## Manual end-to-end smoke test (live GitHub, run against a disposable/sandbox Issue)

1. **Create a ticket** (User Story 2 / FR-001, existing script, unchanged):
   ```sh
   ./scripts/create-issue.sh --title "Smoke test ticket" --agent-id smoke-test --session-id local-1
   ```
   Expected: prints `{"issue_number": N, "item_id": "..."}`.

2. **Look up the ticket** (User Story 1 / FR-002):
   ```sh
   ./scripts/view-ticket.sh --issue <issue_number>
   ```
   Expected: prints the title, `status`/`priority` (likely `null` until step 3), and an empty
   `assignees` array; no new audit-log line is written (read-only).

3. **Update Status and Priority** (User Story 3 / FR-003):
   ```sh
   ./scripts/update-ticket.sh --issue <issue_number> --field Status --value "In Progress" --agent-id smoke-test --session-id local-1
   ./scripts/update-ticket.sh --issue <issue_number> --field Priority --value P1 --agent-id smoke-test --session-id local-1
   ```
   Expected: each call prints the previous and new value; `docs/context/audit/agent-actions.jsonl`
   gains two new `action: "set_field"` entries (written by the reused `set-field.sh`).

4. **Change owner, then reassign** (User Story 4 / FR-004, FR-005):
   ```sh
   ./scripts/change-owner.sh --issue <issue_number> --new-owner <collaborator-login> --agent-id smoke-test --session-id local-1
   ./scripts/change-owner.sh --issue <issue_number> --new-owner <another-collaborator-login> --agent-id smoke-test --session-id local-1
   ```
   Expected: each call prints `previous_assignees` and `new_owner`; two new `action:
   "change_owner"` audit entries are logged. Re-running `view-ticket.sh --issue <issue_number>`
   shows the updated `assignees`.

5. **Retire the ticket as "done"** (User Story 5 / FR-009):
   ```sh
   ./scripts/retire-ticket.sh --issue <issue_number> --outcome done --agent-id smoke-test --session-id local-1
   ```
   Expected: Status becomes `Done`; the Issue itself remains open (verify with `gh issue view
   <issue_number> --json state`); a reminder is printed that a human must still close it.

6. **(Optional, only after adding the `Won't Fix` option) retire as "won't-fix"**:
   ```sh
   ./scripts/retire-ticket.sh --issue <issue_number> --outcome wont-fix --agent-id smoke-test --session-id local-1
   ```
   Expected (before the option is configured): fails with a "field not configured" error and no
   Status change — this is the documented current limitation, not a bug.

7. **Human close (out of scope for all scripts)**:
   ```sh
   gh issue close <issue_number>
   ```

8. **Review the audit trail**:
   ```sh
   jq 'select(.session_id == "local-1")' docs/context/audit/agent-actions.jsonl
   ```
   Expected: one entry per write step above (`create_issue`, two `set_field`, two `change_owner`,
   one `set_field` from the "done" retire) — no entry for the read-only `view-ticket.sh` calls.
   This is the acceptance check for SC-002/SC-003 as applied to this feature's new prompts.

## Cleanup

Close/delete the disposable smoke-test Issue in the sandbox repo; audit log entries are
intentionally left in place (indefinite retention, same as the existing tooling).
