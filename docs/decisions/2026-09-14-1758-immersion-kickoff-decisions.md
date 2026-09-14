# AI Immersion Kickoff Decisions (Team Rabbit Mode)

## Date
2026-09-14 17:58 (session start time, per recording title; session ran ~2h14m)

## Context
Kickoff meeting for a 3-day AI immersion exercise. The team (internally "Team Rabbit Mode",
session/team number 518) chose `yugastore-java` as their working project over the alternative
starter option (a .NET AdventureWorks repo) and began setting up tooling before any code work.
Source: Microsoft Teams meeting recording/transcript, "AI Immersion Meeting-20260914_105842",
converted from `.docx` to Markdown for ingestion. Timestamps below are the transcript's own
mm:ss markers, used as stable anchors.

## Decisions

- **Working project**: use this repo (`yugastore-java`) as the immersion project ("the Yugo
  store approach"). *(anchor 0:54)*
- **Team name**: "Rabbit Mode" (GitHub project created as "Rabbit Mode Project"). *(anchor
  47:14–47:38, 1:32:23–1:32:57)*
- **Target cloud provider**: AWS, chosen because it was the only provider a team member had
  working credentials for; explicitly a reversible/tentative pick. *(anchor 47:44–48:08)*
- **Primary LLM/agent tool**: GitHub Copilot, since it's the tool available to the whole team
  under existing licensing; team members separately have Claude/Cursor experience from prior
  projects but are standardizing on Copilot for this engagement. *(anchor 3:10–3:44)*
- **Knowledge-base strategy**: bootstrap the AI-SDLC framework's `docs/` structure already in
  this repo rather than building a separate documentation system from scratch, given the 3-day
  timebox. The team discussed Andrej Karpathy's "wiki" concept (structured Markdown +
  tagging/ontology, searchable by LLMs without a vector store, inspired by Obsidian-style
  linking) as a longer-term aspiration — e.g., a CI/CD step that renders a human-readable wiki —
  but treated it as inspiration rather than an immediate build target. *(anchor 1:09:53–1:20:12)*
- **Project management**: use GitHub Projects (Kanban board) instead of standing up JIRA, since
  the repo already exists on GitHub. The team also began experimenting with a GitHub MCP server
  to auto-generate issues/tickets by comparing GitHub Project requirements against the current
  code. *(anchor 1:20:50–1:31:11)*
- **Planned exercise**: ingest this meeting's own transcript into the project's knowledge base
  as an early test of the ingestion workflow. *(anchor 1:37:05–1:37:12)*

## Rationale
Options were picked for expediency within a short, fixed timebox (cloud provider by available
credentials, PM tool by what already existed, knowledge base by reusing the framework already
present in the repo) rather than by deep evaluation of alternatives.

## Consequences
- Cloud and PM tooling choices are provisional and may need revisiting once real client
  problems and access constraints (e.g., inability to fork into the org account, GitHub Issues
  being disabled by default) are resolved.
- The Karpathy-style wiki idea was not adopted as the primary knowledge base for this
  engagement; if raised again later it should be evaluated as a possible addition on top of
  `docs/`, not a replacement.

## Related
- Open product/architecture questions from the same meeting: see `specs/intake/2026-09-14-ai-immersion-open-questions.md`.
