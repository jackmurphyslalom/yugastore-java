# Data Model: Copilot Agent Issue Board

This feature has no application database — "data" here means the shape of records the tooling reads from/writes to GitHub (via `gh` CLI JSON output) and the one repo-local persisted record type, the audit log entry. Field names below map directly onto the spec's Key Entities section.

## Issue

Represents a standard GitHub repository Issue. One Issue maps 1:1 to one Spec Kit feature (one Issue per `specs/{feature}/` directory) — agents do not open sub-Issues per task.

| Field | Type | Notes |
|---|---|---|
| `number` | integer | GitHub-assigned Issue number; primary identifier used in cross-references |
| `title` | string | Required, non-empty |
| `body` | string | May contain Linked Artifact references (see below) appended by `link-artifacts.sh` |
| `state` | enum `open` \| `closed` | Closing is a human-only action performed outside this tooling; agents MAY reopen via `reopen-issue.sh` but MUST NOT close |
| `labels` | string[] | Optional; not directly managed by this feature's scripts beyond passthrough |
| `milestone` | string \| null | Set by `set-milestone.sh`; references a Milestone by title |

**Validation rules**: `title` MUST be non-empty before `create-issue.sh` invokes `gh issue create`. `number` only exists after creation (scripts operate on it thereafter). No script exists to close an Issue.

## Project Item

The Projects (v2) board's wrapper around a linked Issue or PR.

| Field | Type | Notes |
|---|---|---|
| `item_id` | string | Projects v2 node ID, returned by `gh project item-add`/`item-list` |
| `project_id` | string | Fixed per repo; stored in `config/board.json` |
| `content_number` | integer | The wrapped Issue/PR number (FK to Issue.number or PullRequest.number) |
| `status` | Status Field | See below |
| `priority` | Priority Field | See below |

**Validation rules**: A Project Item MUST wrap a real Issue or PR (FR-014) — draft/content-less items are out of scope and never created by these scripts.

## Status Field

Single-select custom field on a Project Item.

| Allowed value | Meaning |
|---|---|
| `Todo` | Not yet started |
| `In Progress` | Actively being worked |
| `In Review` | PR open / under review |
| `Done` | Complete; Issue typically closed |

**State transitions**: No enforced linear order at the tooling layer — `set-field.sh` accepts any of the four values and validates only that the value is one of them (per `config/board.json`); the *scenario-level* expectation (per spec User Story 2) is Todo → In Progress → In Review → Done, but scripts do not reject out-of-order or backward transitions, since agents may legitimately reopen/regress work. Setting Status to `Done` never closes the Issue as a side effect — Status and the Issue's open/closed state are tracked and mutated independently; a human decides when to close.

## Priority Field

Single-select custom field on a Project Item.

| Allowed value |
|---|
| `P0` |
| `P1` |
| `P2` |
| `P3` |

**Validation rules**: Same pattern as Status — validated against `config/board.json`'s allowed list before the `gh project item-edit` call.

## Pull Request

| Field | Type | Notes |
|---|---|---|
| `number` | integer | GitHub-assigned PR number |
| `linked_issue_number` | integer | Issue referenced via a closing keyword (e.g. `Closes #123`) in the PR body, written by `open-pr.sh` |
| `state` | enum `open` \| `closed` \| `merged` | Read-only from this tooling's perspective; GitHub itself transitions PR state on merge |

## Milestone

| Field | Type | Notes |
|---|---|---|
| `title` | string | Existing GitHub milestone title; `set-milestone.sh` does not create milestones, only assigns Issues to an existing one (creating one is a manual/one-time repo-setup action per the spec's Assumptions) |

## Linked Artifact

A repo-local file path referenced from an Issue/PR body or comment — not a separate stored record, just a convention for text appended by `link-artifacts.sh`.

| Field | Type | Notes |
|---|---|---|
| `kind` | enum `spec` \| `plan` \| `tasks` \| `checklist` \| `adr` | Determines the label used in the appended reference line |
| `path` | string | Repo-relative path, e.g. `specs/copilot-agent-issue-board/plan.md` |

**Validation rules**: `link-artifacts.sh` MUST verify the path exists in the working tree before appending a reference (spec edge case: "missing linked artifact") — if missing, the script exits non-zero and logs an audit entry with `result: "failed"` and a `reason` field, rather than silently appending a dead link.

## Audit Log Entry

The one entity actually persisted by this feature, as a single line of JSON appended to `docs/context/audit/agent-actions.jsonl`.

| Field | Type | Notes |
|---|---|---|
| `timestamp` | string (ISO-8601 UTC) | Set by `lib/audit-log.sh` at write time |
| `agent_id` | string | From `AGENT_SESSION_ID` env var or an explicit `--agent-id` script flag; required, no default |
| `session_id` | string | Same source; identifies one continuous agent run — every script call made during that run shares this one value, distinguishing it from other agents' or other runs' sessions (FR-012, FR-018) |
| `action` | enum `create_issue` \| `set_field` \| `reopen_issue` \| `open_pr` \| `link_artifact` \| `set_milestone` | One value per `scripts/*.sh` entry point; no `close_issue` action exists since closing is human-only |
| `target` | string | The affected Issue/PR number or Project Item ID |
| `result` | enum `succeeded` \| `failed` | Every invocation logs exactly one entry regardless of outcome |
| `reason` | string \| null | Populated only when `result` is `failed` (e.g., `gh` exit code/stderr summary) |
| `details` | object | Action-specific extra context (e.g., `{"field": "Status", "value": "In Progress"}`) |

**Validation rules**: An entry MUST be appended before the invoking script's own exit code is returned to the caller — i.e., audit logging is not best-effort/fire-and-forget; a failure to write the audit entry itself is treated as a script failure (non-zero exit), since FR-010 makes the audit record mandatory for every write action.
