# gh-agent-board

Bash scripts that let Copilot agents create and track GitHub Issues on a Projects (v2) board,
using the `gh` CLI only (no raw REST/GraphQL, no Actions/webhooks — FR-013). See
`specs/copilot-agent-issue-board/` for the full spec, plan, and contracts.

## Prerequisites

- `gh` CLI installed and authenticated as the shared bot/service account (repo + project scopes).
- `jq` installed.
- `config/board.json` populated with this repo's real `project_id`, field IDs, and Status/Priority
  option IDs (see "Populating config/board.json" below).
- `bats-core` installed to run the test suite (`brew install bats-core` or equivalent).

## Populating `config/board.json`

Look up the project and field/option IDs once, then paste them into `config/board.json`:

```sh
gh project list --owner <owner> --format json                # find project_number / project_id
gh project field-list <project_number> --owner <owner> --format json   # find field_id + option ids
```

Replace every `REPLACE_WITH_*` placeholder in `config/board.json` with the real values. The
`options` maps must use the exact display names (`Todo`, `In Progress`, `In Review`, `Done` for
Status; `P0`-`P3` for Priority) as keys, per FR-016.

**`owner` value quirk**: for a personal (non-org) project, `gh project` subcommands reject the
literal username with `unknown owner type` — set `"owner": "@me"` instead. For an org-owned
project, use the org's literal login (e.g. `"my-org"`).

**Auth scope quirk**: `gh project` subcommands need the `project` (or `read:project`) token
scope, which the default `gh auth login` session may not have. Check with `gh auth status`. If
missing, either run `gh auth refresh -s read:project` (interactive), or, for this repo, point at
the PAT in the git-ignored `.env` file's `GH_CLASSIC_KEY` for a single invocation:
`GH_TOKEN="$(grep '^GH_CLASSIC_KEY=' .env | cut -d= -f2-)" ./scripts/<script>.sh ...`. Never print,
log, or commit the token value; `.env` is already in `.gitignore`.

**Known limitation — Project automation can close an Issue behind this tooling's back**: none of
these scripts ever call `gh issue close`, but if the live Project has a built-in "close issue when
Status set to Done" workflow enabled, setting Status to a Done-mapped option (e.g. via
`retire-ticket.sh --outcome done`) closes the underlying Issue as a side effect of that Project
automation. Disable that workflow in the Project's own Workflows settings (not exposed via `gh
project` CLI subcommands) if the "never closes the Issue" guarantee must hold. See
`docs/context/gaps.md` for details.

## Scripts

| Script | Purpose | FR |
|---|---|---|
| `scripts/create-issue.sh` | Create an Issue for a feature and add it to the board | FR-001 |
| `scripts/set-field.sh` | Set the Status or Priority field on a board item | FR-002/003 |
| `scripts/reopen-issue.sh` | Reopen an Issue (closing is human-only — no close script exists) | FR-004 |
| `scripts/open-pr.sh` | Open a PR linked to an originating Issue via a closing keyword | FR-005 |
| `scripts/link-artifacts.sh` | Reference a spec/plan/tasks/checklist/ADR path from an Issue/PR | FR-006/008 |
| `scripts/set-milestone.sh` | Assign an Issue to an existing milestone | FR-007 |

Every script accepts `--agent-id <id>` and `--session-id <id>` (falling back to the
`AGENT_SESSION_ID` env var, then the literal `unknown`), and writes exactly one audit entry to
`docs/context/audit/agent-actions.jsonl` before exiting, on both success and failure. See
`specs/copilot-agent-issue-board/contracts/scripts.md` for full per-script invocation contracts.

### Example usage

```sh
./scripts/create-issue.sh --title "Add checkout retry logic" --agent-id copilot --session-id run-123
./scripts/set-field.sh --item-id ITEM_1 --field Status --value "In Progress" --agent-id copilot --session-id run-123
./scripts/link-artifacts.sh --target-type issue --target 42 --kind plan --path specs/checkout-retry/plan.md --agent-id copilot --session-id run-123
./scripts/open-pr.sh --issue 42 --title "Add checkout retry logic" --base main --head checkout-retry --agent-id copilot --session-id run-123
./scripts/reopen-issue.sh --issue 42 --agent-id copilot --session-id run-123
./scripts/set-milestone.sh --issue 42 --milestone "v1.0" --agent-id copilot --session-id run-123
```

Closing an Issue is a human-only action (`gh issue close <number>`), performed outside this
tooling — there is no `close-issue.sh` script.

## Running tests

```sh
bats tests/
```

Tests run against a stubbed `gh` executable (`tests/fixtures/gh-stub`) — no network access or
real GitHub credentials are used.

## Known limitation: mid-action process kill

Every script runs its `gh` write first, then calls `audit_log_write`. If the agent process is
killed (e.g. `SIGKILL`) between those two steps, the write completes on GitHub with no
corresponding audit entry — the audit trail is not crash-atomic with the underlying `gh` call.
This does not affect ordinary failures (a `gh` error, or a failure writing the log itself, are
both caught and logged as `result: "failed"`); it only applies to an abrupt process kill mid-script.

## Reviewing the audit trail

Every write is logged as one JSON line in `docs/context/audit/agent-actions.jsonl`. Example
queries with `jq`:

```sh
# All actions from one agent session, in order
jq 'select(.session_id == "run-123")' docs/context/audit/agent-actions.jsonl

# All failed writes across all sessions
jq 'select(.result == "failed")' docs/context/audit/agent-actions.jsonl
```
