# AI Immersion Kickoff — Open Product/Architecture Questions

Raw intake from a team kickoff meeting, not yet a spec. Feed into `/speckit.specify` or
`/speckit.aisdlc.triage` when someone picks up one of these.

## Source
- Microsoft Teams meeting recording/transcript, "AI Immersion Meeting-20260914_105842"
  (2026-09-14, ~2h14m), converted from `.docx` to Markdown for ingestion.
- Related team-process decisions from the same meeting: see
  `docs/decisions/2026-09-14-1758-immersion-kickoff-decisions.md`.
- **Update**: all three questions below were directly answered by the client in a later
  interview; see `specs/intake/2026-09-14-client-requirements-interview.md` for the primary,
  client-confirmed requirements. The assumptions recorded below are the team's own pre-interview
  reading of the code and still need code-level verification.
- Timestamps below are the transcript's own mm:ss markers, used as stable anchors.

## Questions

- **Pricing changes require redeploy?**
  Client problem statement (paraphrased from a referenced slide): "pricing rules change weekly;
  engineers shouldn't need to redeploy everything" to change them. The team's read of the current
  code was that each product's price is stored directly on the product record and displayed in
  dollars, which was flagged as a likely mismatch with that requirement. Needs verification
  against the actual `products-microservice` code/schema, not just the meeting's assumption.
  *(anchor 54:10–56:39)*

- **Graceful degradation when a dependent service is down**
  Client problem statement: "if [a] service goes down, the storefront must degrade gracefully,"
  e.g. if checkout goes down, browsing/products should still work. The team's working idea was
  to build on Eureka (Spring Cloud Netflix service discovery, already used by
  `eureka-server-local`) to detect a downed dependency and drive a degradation strategy, but this
  was not evaluated against the actual gateway/UI code. *(anchor 42:17–52:55)*

- **Rapid experimentation / A/B testing without an engineering bottleneck**
  Client problem statement: want to run constant experiments (e.g., pricing, UX) without
  engineering becoming the bottleneck. No specific A/B testing framework or approach was chosen;
  the team noted this needs its own investigation once real client requirements are available.
  *(anchor 48:37–49:08)*

## Not Yet Resolved
- None of the three items above have been verified against the actual codebase in this pass —
  they are meeting notes/assumptions, not confirmed findings.
- The "client problem" slide deck referenced in the meeting was not available to this ingestion
  pass (it was described verbally, not attached as a source document). A later client interview
  now covers the same three topics directly — see
  `specs/intake/2026-09-14-client-requirements-interview.md`.
