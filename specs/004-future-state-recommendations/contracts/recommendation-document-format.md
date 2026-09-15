# Contract: Recommendation Document Format

This feature has no API/service contract — its only "interface" is the fixed Markdown document
format each of the three recommendation files must follow, and the index format that links to
them. This file is the single shared contract referenced by all three documents (per
`research.md`'s decision to avoid per-file duplication).

## Recommendation document contract

Applies to `meta/future-state/experimentation.md`, `meta/future-state/graceful-degradation.md`,
and `meta/future-state/pricing-agility.md`.

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

**Chosen: Option {A|B|C}.** {short tradeoff rationale for why this option was chosen over the
others — FR-007}

> Adopting this recommendation requires a future `/speckit.specify` cycle before any
> implementation begins — this document does not authorize implementation. (FR-011)

## Alternatives considered

- **{other option label}**: {brief reason it was not selected — FR-008}
- **{other option label}**: {brief reason it was not selected — FR-008}
```

**Verbatim client need text per file** (FR-004 — copy exactly, do not paraphrase):

| File | Client need (verbatim) |
|---|---|
| `experimentation.md` | "run constant experiments (pricing, UX, recommendations) without engineering becoming a bottleneck." |
| `graceful-degradation.md` | "when any service slows down or goes down, the storefront must degrade gracefully." |
| `pricing-agility.md` | "pricing rules change weekly; engineers shouldn't need to redeploy everything." |

**Content-authoring gate** (FR-012): The "Current-state finding", "Options considered",
"Recommendation", and "Alternatives considered" sections MUST NOT be filled in until
`meta/architecture-assessment/` exists with real, generated content from Feature 003's
implemented and executed skills. Until then, these sections MUST contain only their heading plus
a placeholder note such as `_Blocked: pending meta/architecture-assessment/ (Feature 003)._` —
never a guessed or generic statement.

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
