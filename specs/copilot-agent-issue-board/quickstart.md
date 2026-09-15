# Quickstart: Copilot Agent Issue Board

Validation guide for `tools/gh-agent-board/`. Assumes the board's Status/Priority fields and the shared bot account's `gh auth login` are already provisioned (see spec Assumptions — provisioning itself is out of scope).

## Prerequisites

- `gh` CLI installed and authenticated (`gh auth status` shows the shared bot account with repo + project scopes).
- `jq` installed.
- `bats-core` installed for running the automated test suite (`brew install bats-core` or equivalent).
- `config/board.json` populated with this repo's `project_id`, field IDs, and the Status/Priority option IDs (looked up once via `gh project field-list <number> --owner <owner> --format json`).

## Run the automated test suite (no live GitHub calls)

```sh
cd tools/gh-agent-board
bats tests/
```

Expected outcome: every `*.bats` file passes using the stubbed `gh` in `tests/fixtures/gh-stub`; no network access occurs. This is the test suite referenced in the plan's Constitution Check / Complexity Tracking gap — it is the primary, fast-running check agents/CI should run on every change to `tools/gh-agent-board/`.

## Manual end-to-end smoke test (live GitHub, run against a disposable/sandbox Issue)

1. **Create and board an Issue** (User Story 1):
   ```sh
   ./scripts/create-issue.sh --title "Smoke test issue" --agent-id smoke-test --session-id local-1
   ```
   Expected: prints `{"issue_number": N, "item_id": "..."}`; a new line appears in `docs/context/audit/agent-actions.jsonl` with `action: "create_issue"`, `result: "succeeded"`.

2. **Advance Status/Priority** (User Story 2):
   ```sh
   ./scripts/set-field.sh --item-id <item_id> --field Status --value "In Progress" --agent-id smoke-test --session-id local-1
   ./scripts/set-field.sh --item-id <item_id> --field Priority --value P1 --agent-id smoke-test --session-id local-1
   ```
   Expected: `gh project item-list <project_number> --format json` shows the item's Status/Priority updated; two new audit entries logged.

3. **Link Spec Kit artifacts** (User Story 1/5):
   ```sh
   ./scripts/link-artifacts.sh --target-type issue --target <issue_number> --kind plan --path specs/copilot-agent-issue-board/plan.md --agent-id smoke-test --session-id local-1
   ```
   Expected: a comment referencing the plan path appears on the Issue; an audit entry with `action: "link_artifact"` is logged.

4. **Open a linked PR** (User Story 3):
   ```sh
   ./scripts/open-pr.sh --issue <issue_number> --title "Smoke test PR" --base main --head <feature-branch> --agent-id smoke-test --session-id local-1
   ```
   Expected: PR body contains `Closes #<issue_number>`; an audit entry with `action: "open_pr"` is logged.

5. **Close the Issue (human step)**:
   ```sh
   gh issue close <issue_number>
   ```
   Expected: Issue state is `closed`. This step is run directly by a human (or with a human's own `gh` session), not by any script in `tools/gh-agent-board/` — closing is out of agent scope by design; no audit entry is expected here since this is not an agent-driven write.

5a. **Optional: reopen the Issue (agent step)**:
   ```sh
   ./scripts/reopen-issue.sh --issue <issue_number> --agent-id smoke-test --session-id local-1
   ```
   Expected: Issue state is `open`; an audit entry with `action: "reopen_issue"` is logged.

6. **Review the audit trail** (User Story 4):
   ```sh
   jq 'select(.session_id == "local-1")' docs/context/audit/agent-actions.jsonl
   ```
   Expected: exactly one entry per step above, in order, each attributable to `agent_id: "smoke-test"` / `session_id: "local-1"`, reconstructing the full smoke-test scenario without consulting GitHub's native UI activity feed — this is the acceptance check for SC-002/SC-003.

## Cleanup

Close/delete the disposable smoke-test Issue and PR in the sandbox repo; the audit log entries are intentionally left in place (indefinite retention per FR-017) unless the smoke test itself is run against a genuinely disposable sandbox repo rather than this one.
