---
description: Change a gh-agent-board ticket's owner (sole assignee).
---

## Change-Owner Request

```text
$ARGUMENTS
```

Parse a ticket number and a new owner (GitHub login) from the request above. Run
`tools/gh-agent-board/scripts/change-owner.sh --issue <ticket-number> --new-owner <login>
--agent-id <agent-id> --session-id <session-id>` from the repository root (FR-004).

- On success, report the previous assignee(s) and the new owner.
- On a not-found ticket (exit `1`), relay the not-found message.
- On a rejected owner (e.g. not a repository collaborator, exit `1`), relay the underlying `gh`
  error; no assignee change is made.
