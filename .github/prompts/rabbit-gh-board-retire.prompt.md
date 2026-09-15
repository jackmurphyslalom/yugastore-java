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
