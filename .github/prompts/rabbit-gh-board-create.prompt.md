---
description: Create a new gh-agent-board ticket (GitHub Issue) from a title and optional body/priority.
---

## Create Request

```text
$ARGUMENTS
```

Parse a title and optional body/priority from the request above. Run
`tools/gh-agent-board/scripts/create-issue.sh --title <title> [--body <body>] --agent-id
<agent-id> --session-id <session-id>` unchanged, from the repository root (FR-001).

- If a `--priority` was supplied by the caller, follow up with
  `tools/gh-agent-board/scripts/update-ticket.sh --issue <returned-issue-number> --field Priority
  --value <priority> --agent-id <agent-id> --session-id <session-id>`.
- If no priority was supplied, state clearly that no Priority default was applied, and that one can
  be set later via `rabbit-gh-board-update`.
- Return the new ticket number to the caller.
