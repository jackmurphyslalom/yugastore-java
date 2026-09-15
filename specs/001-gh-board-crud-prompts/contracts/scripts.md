# Contracts: New/Extended gh-agent-board Scripts

These contracts extend `specs/copilot-agent-issue-board/contracts/scripts.md`, which remains
authoritative for `create-issue.sh`, `set-field.sh`, `reopen-issue.sh`, `open-pr.sh`,
`link-artifacts.sh`, and `set-milestone.sh` (all unmodified by this feature).

## Contract: `tools/gh-agent-board/lib/board-item.sh` (shared, not directly invoked by agents)

Sourced by `view-ticket.sh`, `update-ticket.sh`, and `retire-ticket.sh`. Exposes one function:

```sh
board_item_resolve --issue <number>
```

### Behavior

1. Validates `--issue` is a positive integer; if not, returns `2` before any `gh` call (FR-006 edge
   case: syntactically invalid ticket number).
2. Runs `gh issue view <number> --json number,title,assignees` to confirm the Issue exists and
   capture `title`/`assignees`. If `gh` reports the Issue does not exist, sets
   `BOARD_ITEM_NOT_FOUND=1` and returns `1` — no further `gh` calls are made.
3. Runs `gh project item-list <project_number> --owner <owner> --format json` (project
   number/owner from `config/board.json`, same as existing scripts) and filters for the item whose
   wrapped content number equals `<number>`, extracting `item_id` and current Status/Priority
   option display names.
4. On success, exports `BOARD_ITEM_ID`, `BOARD_ITEM_TITLE`, `BOARD_ITEM_ASSIGNEES` (JSON array
   string), `BOARD_ITEM_STATUS` (or empty if unset), `BOARD_ITEM_PRIORITY` (or empty if unset), and
   returns `0`.

### Error handling

- A transient `gh` failure (auth/network) is distinguished from "not found": `gh issue view`
  succeeding but `gh project item-list` failing (or the Issue not appearing as a board item) is
  reported by the caller as a failure, not a not-found result, so scripts can log the correct
  `reason`.

---

## Contract: `tools/gh-agent-board/scripts/view-ticket.sh`

Read-only lookup (FR-002). Writes no audit entry — not a write action.

### Invocation

```sh
view-ticket.sh --issue <number>
```

### Behavior

1. Calls `board_item_resolve --issue <number>`.
2. On success, prints `{"issue_number": <int>, "title": "<string>", "status": <string|null>,
   "priority": <string|null>, "assignees": [<string>, ...]}` to stdout and exits `0`.

### Error handling

- Invalid ticket number shape: exit `2`, prints usage error to stderr, no `gh` call.
- Not found: exit `1`, prints a clear "ticket not found" message to stderr, no partial output.
- Underlying `gh` failure: exit `1`, prints the `gh` error to stderr.

---

## Contract: `tools/gh-agent-board/scripts/update-ticket.sh`

Wraps `set-field.sh` with ticket-number resolution (FR-003).

### Invocation

```sh
update-ticket.sh --issue <number> --field <Status|Priority> --value <value> [--agent-id <id>] [--session-id <id>]
```

### Behavior

1. Calls `board_item_resolve --issue <number>`; not found -> exit `1`, no `gh` mutation, no audit
   entry (the resolve step itself is read-only).
2. Records the previous value of `--field` from the resolved item (`BOARD_ITEM_STATUS` or
   `BOARD_ITEM_PRIORITY`).
3. Invokes the existing `set-field.sh --item-id <resolved-id> --field <field> --value <value>
   --agent-id <agent-id> --session-id <session-id>` as a subprocess — all field/value validation
   and the `set_field` audit entry are `set-field.sh`'s existing responsibility, unchanged.
4. On `set-field.sh` success, prints `{"issue_number": <int>, "field": "<field>", "previous_value":
   <string|null>, "new_value": "<value>"}` and exits `0`.

### Error handling

- Invalid ticket number shape: exit `2`, no `gh` call.
- Not found: exit `1`, clear not-found message, no `gh` mutation attempted.
- `set-field.sh` failure (including "field not configured" or unsupported value): propagates its
  exit code and stderr; `update-ticket.sh` writes no additional audit entry (avoids a duplicate).

---

## Contract: `tools/gh-agent-board/scripts/change-owner.sh`

Shared by the change-owner and reassign prompts (FR-004, FR-005).

### Invocation

```sh
change-owner.sh --issue <number> --new-owner <login> [--agent-id <id>] [--session-id <id>]
```

### Behavior

1. Validates `--issue` shape and `--new-owner` is non-empty; invalid -> exit `2`, no `gh` call, no
   audit entry.
2. Runs `gh issue view <number> --json number,assignees` to confirm the Issue exists and capture
   current assignee logins. Not found -> exit `1`, failed audit entry with
   `action: "change_owner"`, `reason: "ticket not found"`.
3. Runs `gh issue edit <number> --add-assignee <new-owner> --remove-assignee <comma-joined
   previous-assignees>` (omitting `--remove-assignee` if there were no previous assignees).
4. On success, appends an audit entry with `action: "change_owner"`, `target: "<issue_number>"`,
   `result: "succeeded"`, `details: {"previous_assignees": [...], "new_owner": "<login>"}`, then
   prints `{"issue_number": <int>, "previous_assignees": [...], "new_owner": "<login>"}`.

### Error handling

- `gh issue edit` failure (e.g., `new-owner` is not a valid collaborator, per spec Acceptance
  Scenario 3): exit `1`; audit entry `result: "failed"`, `reason` including the `gh` stderr; no
  assignee change is left partially applied since `gh issue edit` itself is a single atomic call.

---

## Contract: `tools/gh-agent-board/scripts/retire-ticket.sh`

Wraps `set-field.sh` for the retire prompt (FR-009). Never calls `gh issue close`.

### Invocation

```sh
retire-ticket.sh --issue <number> --outcome <done|wont-fix> [--agent-id <id>] [--session-id <id>]
```

### Behavior

1. Calls `board_item_resolve --issue <number>`; not found -> exit `1`, no `gh` mutation, no audit
   entry.
2. Maps `--outcome` to a Status value: `done` -> `Done`; `wont-fix` -> `Won't Fix`.
3. Invokes the existing `set-field.sh --item-id <resolved-id> --field Status --value <mapped-value>
   --agent-id <agent-id> --session-id <session-id>`.
4. On success, prints the reminder text: a human must still run `gh issue close <issue_number>` to
   actually close the ticket, plus `{"issue_number": <int>, "status": "<mapped-value>"}`.

### Error handling

- Invalid ticket number shape or unsupported `--outcome` value (anything other than `done`/
  `wont-fix`): exit `2`, no `gh` call.
- Not found: exit `1`, clear not-found message.
- `wont-fix` today fails with `set-field.sh`'s existing "field not configured" error (exit `2` from
  `set-field.sh`) until a human adds the `Won't Fix` Status option to the live board and
  `config/board.json` — see `research.md` and `docs/context/gaps.md`. `retire-ticket.sh` surfaces
  this error as-is rather than masking it.
