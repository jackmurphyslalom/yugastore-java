---
name: rabbit-future-state-recommendation
description: Reanalyze and regenerate a meta/future-state/ recommendation document in outcome-first form — Outcome, Client need, Solution, a ranked top-10 solution list, and a SWOT / Buy-vs-Build-vs-Partner / TCO comparative analysis of the top 6 — grounded in meta/architecture-assessment/ findings, per the recommendation-document-format contract. Use when the user wants to widen or reanalyze the possibility space for experimentation.md, graceful-degradation.md, or pricing-agility.md, or when architecture-assessment findings have changed and a recommendation should be refreshed. Not for creating new client-need documents or editing application code.
license: MIT
---

# Future-State Recommendation: Reanalyze

Regenerate one existing `meta/future-state/` recommendation document for exactly one of the 3
recognized client needs. This skill never invents a new client need and never touches
application source — it only reanalyzes and rewrites within the recommendation-document
contract: `specs/004-future-state-recommendations/contracts/recommendation-document-format.md`.

## Recognized Targets (fixed enumeration)

Exactly these 3 values are valid targets, each mapping to one file under `meta/future-state/`:

- `experimentation` -> `meta/future-state/experimentation.md`
- `graceful-degradation` -> `meta/future-state/graceful-degradation.md`
- `pricing-agility` -> `meta/future-state/pricing-agility.md`

## Execution Model: one subagent per document

- Each future-state recommendation document's reanalysis (Steps 1-7 below) MUST be conducted by
  its own dedicated subagent — never inline by the invoking/orchestrating agent itself.
- **Single-target request** (one of the 3 values above): dispatch exactly one subagent, give it
  the target and this skill's Steps 1-7, and let it read evidence, rank solutions, run the
  comparative analysis, and write the one output file itself.
- **Multi-target request** ("reanalyze all three", "reanalyze the possibility space", or no
  specific target named): dispatch one subagent per target, in parallel (up to 3 total, one per
  recognized target), each independently running Steps 1-7 for its single document. Subagents
  never coordinate with each other and never write to any file but their own target.
- The invoking/orchestrating agent's own job is limited to: validating the requested target(s)
  against the fixed enumeration, dispatching the subagent(s), collecting each subagent's
  Completion Report, and then performing Step 8 (index sync) itself exactly once after all
  dispatched subagents have finished — never before, and never delegated to a subagent, since
  concurrent subagents editing the shared `README.md` would race.

## Step 1: Validate the target and precondition

- The target MUST be exactly one of the 3 values above. Reject anything else, report the
  rejected target and the 3 valid values, and write no file.
- The target file MUST already exist under `meta/future-state/` (this skill reanalyzes, it does
  not scaffold new client-need documents).
- Re-verify `meta/architecture-assessment/` exists with real tier content (not empty/missing).
  If it does not exist, stop and report the precondition as unmet — do not fabricate findings.

## Step 2: Gather grounding evidence

- Read every file under `meta/architecture-assessment/` (all 7 tier files plus `README.md`) —
  do not rely on memory of prior runs, findings may have changed since the doc was last written.
- Read the target file's current content in full so the reanalysis builds on (rather than
  silently drops) prior grounded reasoning.

## Step 3: Rank the top 10 solutions

- Brainstorm and rank up to 10 distinct, real solution candidates that answer the client need,
  each grounded in a real gap, constraint, or existing dependency found in
  `meta/architecture-assessment/` — never a generic best-practices filler with no cited evidence.
  If fewer than 10 genuinely distinct, evidence-grounded candidates exist, list only that many
  and state why the space is smaller than 10 rather than padding with filler entries.
- Rank most to least viable. Ranking is a judgment call balancing fit to the evidence, cost, and
  risk — state the ranking basis briefly if it isn't obvious from the one-line descriptions.
- Do not merely restate a prior run's list verbatim: re-derive the ranking from the evidence
  gathered in Step 2, since findings may have changed and better-fitting options may now exist.

## Step 4: Comparative analysis of the top 6

For each of the top 6 ranked solutions (in rank order), write a comparative analysis using
exactly these three frameworks, each grounded in the evidence from Step 2 — never generic
statements that would apply to any tier:

1. **SWOT** — run first; it sets the strategic foundation. Strengths/Weaknesses assessed against
   this repo's actual technology capabilities (e.g., existing Spring Cloud stack, YugabyteDB,
   Eureka); Opportunities/Threats assessed against the client need and the current-state gap.
2. **Buy vs. Build vs. Partner** — the decision engine once SWOT has identified a gap or
   opportunity. Classify the solution as `Buy`, `Build`, or `Partner` and justify using cost,
   speed, strategic fit, and control.
3. **TCO** — the discipline that prevents a good-looking sticker price from hiding real cost.
   Cover integration cost, operations cost, migration cost, and retirement cost, and give an
   overall `Low`/`Medium`/`High` cost signal. State explicitly when TCO reverses the initial
   SWOT/Buy-Build-Partner preference.

Do not run this three-framework analysis on solutions ranked 7-10 — they are noted only in
`## Alternatives considered` (Step 6).

## Step 5: Choose and rewrite the recommendation

Per the contract's `## Recommendation` template, rewrite naming exactly one of the top 6 with:

- An explicit rationale for why it beats the *other 5 analyzed* solutions, referencing the SWOT /
  Buy-Build-Partner / TCO findings from Step 4 (not just a restatement of the chosen option).
- **Size** (S/M/L/XL), **Risk** (explicitly flag any alternative that would amount to a wholesale
  refactor), **Human time-on-task**, and **Agent time-on-task** — all re-derived from the current
  evidence, not copied forward unexamined.
- The fixed future-cycle note: "Adopting this recommendation requires a future
  `/speckit.specify` cycle before any implementation begins — this document does not authorize
  implementation."

## Step 6: Rewrite alternatives considered

Rewrite `## Alternatives considered` with:

- One bullet per non-chosen solution among the analyzed top 6, each with a brief, specific
  reason it was not selected (may reference its SWOT/Buy-Build-Partner/TCO result instead of
  repeating it).
- One bullet per solution ranked 7-10, each with a brief one-line reason it ranked below the top
  6 (no full three-framework analysis required for these).

## Step 7: Write the file

- Overwrite exactly one file: `meta/future-state/{target}.md`, following the contract's required
  section order: `## Outcome` (with the ranked top-10 list), `## Client need`, `## Solution`,
  `## Comparative Analysis (Top 6)`, `## Recommendation`, `## Alternatives considered`.
- Never modify any other file under `meta/future-state/` except `README.md` (Step 8 — performed
  by the orchestrating agent, not this subagent), and never touch `*-microservice/src`,
  `react-ui/`, or `docs/architecture/adr/`.
- Return your Completion Report to the orchestrating agent; do not attempt Step 8 yourself.

## Step 8: Sync the index

- If the rewritten `## Recommendation`'s Size or Risk differs from the corresponding row in
  `meta/future-state/README.md`, update that row. Keep the `Status` column's existing semantics
  (`Content complete` / `Scaffolded — pending Feature 003`) unchanged unless content status
  itself changed.

## Completion Report

Report: the validated target, the output file path, how many solutions are in the ranked top-10
list (and how many are new versus the prior version), which 6 got full comparative analysis, the
chosen option, and whether `README.md` was updated.

