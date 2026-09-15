---
description: Update a gh-agent-board ticket's Status or Priority field.
---

## Update Request

```text
$ARGUMENTS
```

Parse a ticket number, a field (`Status` or `Priority`), and a new value from the request above.
Run `tools/gh-agent-board/scripts/update-ticket.sh --issue <ticket-number> --field <field> --value
<value> --agent-id <agent-id> --session-id <session-id>` from the repository root (FR-003).

- On success, report the field, its previous value, and its new value.
- On rejection (unsupported field/value, exit `2`), list the supported values for that field from
  `tools/gh-agent-board/config/board.json` and make no change.
- On a not-found ticket (exit `1`), relay the not-found message and make no change.

**Auth note**: this script resolves the ticket via `gh project item-list`, which needs the
`project` (or `read:project`) token scope. If `gh auth status` shows that scope missing, run the
script with `GH_TOKEN` set from this repo's `.env` file instead of the default session, e.g.:
`GH_TOKEN="$(grep '^GH_CLASSIC_KEY=' .env | cut -d= -f2-)" tools/gh-agent-board/scripts/update-ticket.sh ...`.
Never print, log, or echo the token value itself.
