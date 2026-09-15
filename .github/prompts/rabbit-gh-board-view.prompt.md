---
description: Look up a gh-agent-board ticket by number and show its title, Status, Priority, and assignees.
---

## Ticket Number

```text
$ARGUMENTS
```

Run `tools/gh-agent-board/scripts/view-ticket.sh --issue <ticket-number>` from the repository
root, using the ticket number above. This is a read-only lookup — no board or Issue state changes
and no audit-log entry is written (FR-002).

- On success, present the returned `title`, `status`, `priority`, and `assignees` to the caller.
- On a not-found result (exit `1`), relay the "ticket not found" message as-is.
- On an invalid ticket number (exit `2`), ask the caller for a valid positive integer ticket
  number.
