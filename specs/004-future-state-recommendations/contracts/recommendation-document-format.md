# Contract: Recommendation Document Format

This feature has no API/service contract — its only "interface" is the fixed Markdown document
format each of the three recommendation files must follow, and the index format that links to
them. This file is the single shared contract referenced by all three documents (per
`research.md`'s decision to avoid per-file duplication).

## Recommendation document contract (v2 — outcome-first, top-10/top-6 comparative)

Applies to `meta/future-state/experimentation.md`, `meta/future-state/graceful-degradation.md`,
and `meta/future-state/pricing-agility.md`. Supersedes the original v1 5-section format below for
any document regenerated via the `rabbit-future-state-recommendation` skill (2026-09-15 scope
expansion). v1 remains documented further down for historical reference only.

**Required section order**:

```markdown
# {Recommendation Title}

## Outcome

{2-4 sentences leading with what we recommend and the resulting business outcome, before any
 client-need restatement or analysis.}

**Top 10 solutions considered** (ranked, most to least viable):

1. {name} — {one-line description}
2. {name} — {one-line description}
...
10. {name} — {one-line description}

(List fewer than 10 only when genuinely distinct, evidence-grounded candidates run out — state
 why the space is smaller instead of padding with filler entries.)

## Client need

> {verbatim client need text — FR-004}

## Solution

{Outline of the chosen solution: what it is, how it addresses the client need, and a citation of
 a specific, real finding from meta/architecture-assessment/ — FR-005. If no directly relevant
 finding exists, explicitly state that absence instead of fabricating one — spec Edge Cases.}

## Comparative Analysis (Top 6)

### 1. {Solution name}

**SWOT**
- Strengths: ...
- Weaknesses: ...
- Opportunities: ...
- Threats: ...

**Buy vs. Build vs. Partner**
- Classification: Buy | Build | Partner
- Rationale: ...

**TCO**
- Integration cost: ...
- Operations cost: ...
- Migration cost: ...
- Retirement cost: ...
- Overall signal: Low | Medium | High

(... repeat for solutions #2-#6 in rank order ...)

## Recommendation

**Chosen: Solution #{N}, {name}.** {explicit rationale for why this beats the other 5 analyzed
solutions, referencing the SWOT / Buy-Build-Partner / TCO findings above — FR-007, FR-016}

**Size**: {S|M|L|XL} (FR-013)

**Risk**: {risk category; explicitly call out if an alternative would amount to a wholesale
refactor — FR-014}

**Human time-on-task**: {estimate} (FR-015)

**Agent time-on-task**: {estimate} (FR-015)

> Adopting this recommendation requires a future `/speckit.specify` cycle before any
> implementation begins — this document does not authorize implementation. (FR-011)

## Alternatives considered

- **Solution #{N}, {name}** (analyzed): {brief reason not selected — may reference its
  SWOT/Buy-Build-Partner/TCO result instead of repeating it — FR-008}
- ... (one bullet per non-chosen solution among the analyzed top 6)
- **Solution #{N}, {name}** (ranked 7-10, not analyzed): {brief one-line reason it ranked below
  the top 6}
- ... (one bullet per solution ranked 7-10)
```

**Comparative-analysis framework** (applies only to the top 6 ranked solutions):

1. **SWOT** sets the strategic foundation — assessed against this repo's actual technology
   capabilities before any decision is made. Run first.
2. **Buy vs. Build vs. Partner** is the decision engine once SWOT has identified a gap or
   opportunity — brings cost, speed, strategic fit, and control into a single classification.
3. **TCO** is the discipline that prevents a good-looking sticker price from hiding real cost —
   covers integration, operations, migration, and retirement cost, and may reverse the initial
   SWOT/Buy-Build-Partner preference.

**Verbatim client need text per file** (FR-004 — copy exactly, do not paraphrase):

| File | Client need (verbatim) |
|---|---|
| `experimentation.md` | "run constant experiments (pricing, UX, recommendations) without engineering becoming a bottleneck." |
| `graceful-degradation.md` | "when any service slows down or goes down, the storefront must degrade gracefully." |
| `pricing-agility.md` | "pricing rules change weekly; engineers shouldn't need to redeploy everything." |

**Content-authoring gate** (FR-012): The "Solution", "Comparative Analysis (Top 6)",
"Recommendation", and "Alternatives considered" sections MUST NOT be filled in until
`meta/architecture-assessment/` exists with real, generated content from Feature 003's
implemented and executed skills. Until then, these sections MUST contain only their heading plus
a placeholder note such as `_Blocked: pending meta/architecture-assessment/ (Feature 003)._` —
never a guessed or generic statement.

## Recommendation document contract (v1 — historical, superseded above)

**Required section order** (FR-003):

```markdown
# {Recommendation Title}

## Client need

> {verbatim client need text — FR-004}

## Current-state finding

{Citation of a specific, real finding from meta/architecture-assessment/ — FR-005.
 If no directly relevant finding exists, explicitly state that absence instead of
 fabricating one — spec Edge Cases.}

## Options considered

- **A**: {real, distinct alternative}
- **B**: {real, distinct alternative}
- **C** (optional): {real, distinct alternative}

## Recommendation

**Chosen: Option {A|B|C}.** {explicit rationale for why this option was chosen over the
others — a genuine explanation, not just the option's name — FR-007, FR-016}

**Size**: {S|M|L|XL} (FR-013)

**Risk**: {risk category; explicitly call out if an alternative would amount to a wholesale
refactor — FR-014}

**Human time-on-task**: {estimate} (FR-015)

**Agent time-on-task**: {estimate} (FR-015)

> Adopting this recommendation requires a future `/speckit.specify` cycle before any
> implementation begins — this document does not authorize implementation. (FR-011)

## Alternatives considered

- **{other option label}**: {brief reason it was not selected — FR-008}
- **{other option label}**: {brief reason it was not selected — FR-008}
```

**Content-authoring gate** (FR-012): The "Current-state finding", "Options considered",
"Recommendation", and "Alternatives considered" sections MUST NOT be filled in until
`meta/architecture-assessment/` exists with real, generated content from Feature 003's
implemented and executed skills. Until then, these sections MUST contain only their heading plus
a placeholder note such as `_Blocked: pending meta/architecture-assessment/ (Feature 003)._` —
never a guessed or generic statement.

**Sizing & risk fields** (FR-013, FR-014, FR-015, FR-016): The `## Recommendation` section MUST
always include, alongside the chosen option and rationale, a `Size` (S/M/L/XL), a `Risk`
category (calling out wholesale-refactor alternatives explicitly), a `Human time-on-task`
estimate, and an `Agent time-on-task` estimate. These four fields are subject to the same
content-authoring gate as the rest of the `## Recommendation` section — they must not be
fabricated before `meta/architecture-assessment/` exists, and once written they must reflect
genuine author judgment, not filler values.

## Future-state index contract

Applies to `meta/future-state/README.md`.

**Required content** (FR-001, spec Edge Cases, User Story 2 Acceptance Scenario 2):

```markdown
# Future-State Recommendations

| Client need | Recommendation | Status |
|---|---|---|
| Run constant experiments without engineering becoming a bottleneck | [experimentation.md](./experimentation.md) | {Scaffolded — pending Feature 003 | Content complete} |
| Storefront must degrade gracefully when a service slows or goes down | [graceful-degradation.md](./graceful-degradation.md) | {Scaffolded — pending Feature 003 | Content complete} |
| Pricing rules change weekly without engineering redeploys | [pricing-agility.md](./pricing-agility.md) | {Scaffolded — pending Feature 003 | Content complete} |
```

- All 3 rows MUST always be present, regardless of content status (FR-001).
- The `Status` column MUST truthfully reflect whether each linked file's content sections are
  still blocked (`Scaffolded — pending Feature 003`) or complete (`Content complete`) — never
  imply completeness while content-authoring remains gated (FR-012, spec Edge Cases).
