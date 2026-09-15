---
source: pending_imports/TeamRabbitMode.png
source_type: image
retrieved: 2026-09-15
original_filename: TeamRabbitMode.png
---

# Team roster and MCP setup chat ("Meeting with Young Chul Kim")

## Team roster

The Teams meeting "Meeting with Young Chul Kim" has 3 people:

- **Jack Murphy** — screenshot owner ("You")
- **Michael Apfelbeck**
- **Young Chul Kim** — Organizer

## MCP GitHub setup

Michael Apfelbeck shared a working `mcp.json` for a `github-mcp` server:
- Type: `http`, URL: `https://api.githubcopilot.com/mcp/`
- Auth header: `Authorization: Bearer ${input:github_token}` (templated, not a literal secret)
- Declares an `inputs` entry `github_token` (`type: promptString`) describing a GitHub personal
  access token (classic, `ghp_...`) with `repo` scope, prompted for at VS Code start rather than
  hardcoded.
- A related message notes a GitHub PAT token was shared separately via encrypted email — the
  token value itself is not present in this screenshot.

## Related work

A later chat message links a merged/opened pull request,
`https://github.com/jackmurphyslalom/yugastore-java/pull/39/`, titled "gh-agent-board: CRUD,
change-owner, ..." — a ticket-number based prompt suite for gh-agent-board (lookup, create,
update, change-owner, reassign).
