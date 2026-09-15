---
description: Reassign a gh-agent-board ticket to a new owner (same behavior as change-owner).
---

## Reassign Request

```text
$ARGUMENTS
```

Parse a ticket number and a new assignee (GitHub login) from the request above. Run
`tools/gh-agent-board/scripts/change-owner.sh --issue <ticket-number> --new-owner <login>
--agent-id <agent-id> --session-id <session-id>` from the repository root — functionally identical
to `rabbit-gh-board-change-owner` (FR-005).

- On success, report the previous assignee(s) and the new owner.
- On a not-found ticket (exit `1`), relay the not-found message.
- On a rejected owner (e.g. not a repository collaborator, exit `1`), relay the underlying `gh`
  error; no assignee change is made.

**Auth note**: this script resolves the ticket via `gh project item-list`, which needs the
`project` (or `read:project`) token scope. If `gh auth status` shows that scope missing, run the
script with `GH_TOKEN` set from this repo's `.env` file instead of the default session, e.g.:
`GH_TOKEN="$(grep '^GH_CLASSIC_KEY=' .env | cut -d= -f2-)" tools/gh-agent-board/scripts/change-owner.sh ...`.
Never print, log, or echo the token value itself.
