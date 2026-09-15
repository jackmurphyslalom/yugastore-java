# Contract: `rabbit-architecture-assessment-tier` skill

This is a skill-invocation contract (inputs/outputs of an agent skill), not a network API.

## Input

- **Target tier** (required): a string, exactly one of the 7 recognized Application Tier values
  (see `../data-model.md`).

## Preconditions / Validation

- MUST reject any target not in the fixed 7-tier enumeration, including paths under `.agents/`,
  `.specify/`, `.github/`, and MUST report that the target is out of scope (FR-002). No file is
  written in this case.

## Execution model

- The 16-factor table MUST be produced by dispatching one parallel subagent per factor (16
  total per tier run), each subagent independently researching and scoring exactly one factor
  (Score 1-5 or `N/A`, plus Explanation) against this tier's evidence. The invoking skill
  collects all 16 results and assembles them into the single ordered table before writing the
  file — subagents never write the output file themselves.
- Factors XIII-XVI subagents still run (to produce the required `N/A` + one-line reason) even
  though today's answer is always `N/A` for all 7 tiers.

## Output (on success)

- Writes exactly one file: `meta/architecture-assessment/{tier-name}.md` (FR-003), where
  `{tier-name}` is the exact target value.
- File MUST contain:
  - A `## Context` section, a `## Findings` section, and a `## Recommendation` section, each
    specific to the tier (FR-004).
  - The `## Findings` section MUST note the tier's load/performance-testing tooling and status
    (existing tooling in use, gaps, and an agent-derived initial load estimate where applicable),
    or explicitly state "none identified" (FR-022).
  - The `## Recommendation` section MUST include an explicit rationale (why, not just what), a
    T-shirt size (`S`/`M`/`L`/`XL`), a risk category (flagging when an alternative would amount
    to a wholesale refactor), and both a human and an agent time-on-task estimate (FR-020,
    FR-021).
  - A 16-factor scoring table covering all 16 factors, grounded in
    `docs/context/sources/2026-09-14-twelve-to-sixteen-factor-app.md` (FR-005); each row includes
    a Score (1-5 or `N/A`), an Explanation (FR-005), a `Gap to 5` value (`5 − Score`, or `N/A`
    when Score is `N/A`) (FR-018), and a `Quick Fix` suggestion for any factor scored below 5
    (FR-019).
  - Factors XIII-XVI marked `N/A` when the tier has no AI/LLM component (FR-006) — currently true
    for all 7 tiers.
  - For `login-microservice` only: an explicit WIP/unwired finding sourced from
    `docs/architecture/overview.md` (FR-007).
- If the target file already exists, it is fully overwritten (FR-016) — never merged or
  appended.

## Error reporting

- On an out-of-scope target: report which target was rejected and that it is outside the 7
  recognized application tiers. No side effects.

## Idempotency

- Re-running with the same target always produces a full fresh overwrite of that tier's file
  (not additive).
