---
description: Retire a gh-agent-board ticket by setting Status only; never closes the Issue.
---

## Retire Request

```text
$ARGUMENTS
```

Parse a ticket number and an outcome (`done` or `wont-fix`) from the request above. Run
`tools/gh-agent-board/scripts/retire-ticket.sh --issue <ticket-number> --outcome <outcome>
--agent-id <agent-id> --session-id <session-id>` from the repository root (FR-009). This script
never calls `gh issue close` — closing the Issue remains a human-only action.

- On success, surface the printed close reminder, then tell the caller they may close the Issue
  themselves with `gh issue close <ticket-number>` if that is the intended next step.
- For `--outcome wont-fix`: today this fails with a "field not configured" error, because no
  `Won't Fix` Status option is configured on the board yet (tracked in `docs/context/gaps.md`).
  Surface this limitation clearly to the caller rather than treating it as an unexpected error —
  a human with board-admin access must add the option first.
- On a not-found ticket (exit `1`), relay the not-found message and make no change.
- **Known limitation** for `--outcome done`: if the live Project has a built-in "close issue when
  Status set to Done" workflow enabled, the Issue will be closed by that Project automation as a
  side effect, even though this script itself never calls `gh issue close`. Tell the caller to
  check the Issue's state afterward and, if closed unexpectedly, that a board admin should disable
  that Project workflow if the "never closes the Issue" guarantee must hold (tracked in
  `docs/context/gaps.md`).

**Auth note**: this script resolves the ticket via `gh project item-list`, which needs the
`project` (or `read:project`) token scope. If `gh auth status` shows that scope missing, run the
script with `GH_TOKEN` set from this repo's `.env` file instead of the default session, e.g.:
`GH_TOKEN="$(grep '^GH_CLASSIC_KEY=' .env | cut -d= -f2-)" tools/gh-agent-board/scripts/retire-ticket.sh ...`.
Never print, log, or echo the token value itself.
