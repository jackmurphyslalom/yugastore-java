# Research: GitHub Issue vs. Spec Kit Feature Spec Boundary

No `[NEEDS CLARIFICATION]` markers remain in [spec.md](spec.md) after the `/speckit.clarify`
session — all open decisions were resolved there. This file records the resulting decisions in
the standard research format for traceability.

## Decision: Documentation location

- **Decision**: New page at `docs/process/user-stories-vs-specs.md`, linked from
  `docs/process/README.md` and `specs/README.md`.
- **Rationale**: `docs/process/` already holds cross-feature, evidence-based process guidance
  (`pr-process.md`, `mcp-servers.md`); this topic is exactly that shape. `docs/decisions/` was
  rejected because it's for narrower implementation decisions, not durable cross-feature process.
- **Alternatives considered**: `docs/decisions/` (too narrow/dated-record shaped),
  `specs/README.md` in place (would conflate a per-feature-folder README with durable
  cross-feature process guidance).

## Decision: Promotion rule shape

- **Decision**: A concrete, testable rule (journey count, cross-service touch, or need for a
  `plan.md`/`tasks.md` breakdown) rather than examples-only guidance.
- **Rationale**: Examples alone ("was #19 an Issue-only case?") don't generalize to new,
  unprecedented Issues; a testable condition does.
- **Alternatives considered**: Examples + judgment only — rejected because SC-004 requires the
  rule be applicable without consulting a worked example first.

## Decision: Glossary terms

- **Decision**: Do not add `docs/product/glossary.md` entries as part of this feature; recommend
  them as a follow-up via `/speckit.aisdlc.promote`.
- **Rationale**: Keeps this feature's scope to the boundary documentation itself; glossary
  additions are Constitution Principle III's concern and better reviewed once the new page's
  terminology is stable.
- **Alternatives considered**: Adding glossary entries now — rejected per explicit clarification.

## Decision: specs/README.md cross-link

- **Decision**: Add a short pointer from `specs/README.md` to the new `docs/process/` page.
- **Rationale**: A reader starting from either README should be able to find the boundary
  documentation in one click (spec SC-003).
- **Alternatives considered**: Leaving `specs/README.md` untouched — rejected per explicit
  clarification.

**Output**: All `NEEDS CLARIFICATION` items resolved (none existed post-clarify); no further
research required before Phase 1.
