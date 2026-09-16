---
type: concept
authored_by: rabbit-analyze
confidence: medium
last_verified: 2026-09-15
source_type: image
source_ref: meta/rabbit-wiki/sources/2026-09-15-team-rabbit-mode
tags: [team, roster, mcp, github, tooling]
related: [2026-09-15-the-team, 2026-09-15-meeting-with-young-chul-kim]
---

# Yugastore Delivery Team Roster

## Term/Concept

**Yugastore delivery team roster** — the named participants in the "Meeting with Young Chul
Kim" Teams chat, confirming the people behind the AI-SDLC bootstrap and related work on this
repo.

## Definition

Per the Teams meeting's People panel (3 members):

- **Jack Murphy** — screenshot owner; already had a local Yugastore checkout during the
  bootstrap call.
- **Michael Apfelbeck** — shared a working `mcp.json` configuring a `github-mcp` HTTP server
  (`https://api.githubcopilot.com/mcp/`) with a prompted (not hardcoded) GitHub PAT input.
- **Young Chul Kim** — meeting organizer; ran both the client requirements interview and the
  AI-SDLC bootstrap setup call.

The same chat also references a GitHub PAT shared separately via encrypted email (token value
not present in the source image) and links a related pull request,
`https://github.com/jackmurphyslalom/yugastore-java/pull/39/`, for a gh-agent-board CRUD/prompt
suite.

## Ontology links

- [yugastore-delivery-team](../ontology.yaml) (concept)
- [ai-sdlc-bootstrap-decision](../ontology.yaml) (concept, related — same people ran the
  bootstrap setup call)

## Source anchor

[meta/rabbit-wiki/sources/2026-09-15-team-rabbit-mode/](../sources/2026-09-15-team-rabbit-mode/)

## Related entries

- [2026-09-15-the-team](2026-09-15-the-team.md) — the earlier, low-confidence `rabbit-query`
  answer this roster confirms and extends (that page's own frontmatter/sources were not modified
  by this analysis; refresh it separately if you want it merged).
- [2026-09-15-meeting-with-young-chul-kim](2026-09-15-meeting-with-young-chul-kim.md) — the
  bootstrap call these same three people ran.
