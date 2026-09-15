# Contract: `tools/gh-agent-board/scripts/create-issue.sh`

Creates a new GitHub Issue and adds it to the Projects (v2) board (FR-001).

## Invocation

```sh
create-issue.sh --title "<title>" [--body "<body>"] [--agent-id <id>] [--session-id <id>]
```

## Preconditions

- `gh` is authenticated on `PATH` as the shared bot account with repo + project scopes.
- `config/board.json` contains a valid `project_number` and `owner` (for a personal/non-org project,
  `owner` must be the literal string `@me`, not the username — see README's owner quirk note).

## Behavior

1. Runs `gh issue create --title "<title>" --body "<body>"` (empty body allowed). `gh issue create`
   has no `--json` flag — it prints the created Issue's URL as plain text on the last line of
   stdout; the Issue number is parsed from that URL.
2. Runs `gh project item-add <project_number> --owner <owner> --url <issue_url> --format json` and
   captures the returned `item_id`. Note: `item-add` takes the project *number* + `--owner`, unlike
   `item-edit` (used by `set-field.sh`) which takes `--project-id` (the GraphQL node ID).
3. Appends one audit entry with `action: "create_issue"`, `target: "<issue_number>"`, `result: "succeeded"`, `details: {"item_id": "<item_id>"}`.

## Outputs

- stdout: JSON `{"issue_number": <int>, "item_id": "<string>"}` on success.
- Exit code `0` on success.

## Error handling

- If `--title` is missing/empty: exit `2` before any `gh` call, no audit entry written (nothing was attempted against GitHub).
- If `gh issue create` fails (non-zero exit): exit `1`; append an audit entry with `result: "failed"`, `action: "create_issue"`, `target: "unknown"`, `reason: "<gh stderr summary>"`.
- If Issue creation succeeds but `gh project item-add` fails (partial failure edge case from spec): exit `1`; append an audit entry with `result: "failed"`, `target: "<issue_number>"`, `reason` noting the Issue exists but was not added to the board, so a human/agent can retry just the board-add step.

---

# Contract: `tools/gh-agent-board/scripts/set-field.sh`

Sets the Status or Priority custom field on a Project Item (FR-002, FR-003, FR-016).

## Invocation

```sh
set-field.sh --item-id <id> --field <Status|Priority> --value <value> [--agent-id <id>] [--session-id <id>]
```

## Behavior

1. Validates `--field`/`--value` against the allowed lists in `config/board.json` (Status: Todo/In Progress/In Review/Done; Priority: P0-P3). Invalid combination → exit `2`, no `gh` call, no audit entry.
2. Resolves the field's `field_id` and the target `single-select-option-id` from `config/board.json` (pre-populated via `gh project field-list`, see research.md).
3. Runs `gh project item-edit --id <item-id> --field-id <field_id> --project-id <project_id> --single-select-option-id <option_id>`.
4. Appends one audit entry with `action: "set_field"`, `target: "<item-id>"`, `details: {"field": "<field>", "value": "<value>"}`.

## Outputs / Error handling

- Exit `0` and audit `result: "succeeded"` on success.
- Exit `1` and audit `result: "failed"` (with `reason`) if the `gh` call fails — including the "unconfigured board field" edge case (field/option ID missing from `config/board.json`), which is reported with `reason: "field not configured"` rather than a raw `gh` error.

---

# Contract: `tools/gh-agent-board/scripts/reopen-issue.sh`

Reopens an Issue an agent is resuming work on (FR-004). Closing is a human-only action and has no script in this tooling.

## Invocation

```sh
reopen-issue.sh --issue <number> [--agent-id <id>] [--session-id <id>]
```

## Behavior

Runs `gh issue reopen <number>`; appends an audit entry with `action: "reopen_issue"`.

## Error handling

Exit `1` + failed audit entry if the Issue does not exist or `gh` errors (e.g., already open — `gh` itself is idempotent/no-ops this case, treated as success).

---

# Contract: `tools/gh-agent-board/scripts/open-pr.sh`

Opens a PR linked to an originating Issue (FR-005).

## Invocation

```sh
open-pr.sh --issue <number> --title "<title>" --base <branch> --head <branch> [--body "<extra body>"] [--agent-id <id>] [--session-id <id>]
```

## Behavior

1. Constructs a PR body containing `Closes #<issue-number>` (plus any `--body` text appended after it) so GitHub auto-links the PR to the Issue.
2. Runs `gh pr create --title "<title>" --base <branch> --head <branch> --body "<constructed body>"`.
   `gh pr create` has no `--json` flag either — it prints the created PR's URL as plain text on the
   last line of stdout; the PR number is parsed from that URL.
3. Appends an audit entry with `action: "open_pr"`, `target: "<pr_number>"`, `details: {"linked_issue": <issue_number>}`.

## Error handling

- Protected-branch/permission failures from `gh pr create` (spec edge case) surface as exit `1` with a failed audit entry whose `reason` includes the `gh` stderr (e.g., branch protection message), so a human can see why the PR wasn't opened.

---

# Contract: `tools/gh-agent-board/scripts/link-artifacts.sh`

Appends Spec Kit artifact references to an Issue/PR body (FR-006, FR-008).

## Invocation

```sh
link-artifacts.sh --target-type <issue|pr> --target <number> --kind <spec|plan|tasks|checklist|adr> --path <repo-relative-path> [--agent-id <id>] [--session-id <id>]
```

## Behavior

1. Verifies `--path` exists in the working tree; if not, exit `1` with a failed audit entry (`reason: "artifact path not found"`) — no comment is posted (spec edge case: missing linked artifact).
2. Posts a comment (`gh issue comment` or `gh pr comment`) containing a single reference line, e.g. `Linked plan: specs/copilot-agent-issue-board/plan.md`.
3. Appends an audit entry with `action: "link_artifact"`, `details: {"kind": "<kind>", "path": "<path>"}`.

---

# Contract: `tools/gh-agent-board/scripts/set-milestone.sh`

Associates an Issue with an existing milestone (FR-007).

## Invocation

```sh
set-milestone.sh --issue <number> --milestone "<title>" [--agent-id <id>] [--session-id <id>]
```

## Behavior

Runs `gh issue edit <number> --milestone "<title>"`; appends an audit entry with `action: "set_milestone"`, `details: {"milestone": "<title>"}`. If the named milestone does not exist, `gh` errors and the script exits `1` with a failed audit entry (milestone creation is explicitly out of scope — see data-model.md).

---

# Contract: `tools/gh-agent-board/lib/audit-log.sh` (shared, not directly invoked by agents)

Sourced by every script above; exposes one function:

```sh
audit_log_write --action <action> --target <target> --result <succeeded|failed> [--reason "<text>"] [--details '<json>']
```

Appends one line of JSON matching the Audit Log Entry schema (see data-model.md) to `docs/context/audit/agent-actions.jsonl`, stamping `timestamp` (UTC ISO-8601) and `agent_id`/`session_id` (from `--agent-id`/`--session-id` flags passed through by the caller, defaulting to the `AGENT_SESSION_ID` env var, or the literal `unknown` if neither is set — an unattributed entry is still written per FR-010's "every write" requirement, never skipped). Returns non-zero only if the write to the log file itself fails (e.g., disk full, permissions) — callers treat that as a hard failure per data-model.md's validation rule.
