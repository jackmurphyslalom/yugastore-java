# Phase 0 Research: Rabbit Wiki Ingestion Lifecycle

All Technical Context items were resolvable from the spec (itself pre-confirmed via the
2026-09-15 grilling session) and the existing `rabbit-archive-to-markdown` skill. No
`NEEDS CLARIFICATION` markers remain.

## Decision: Reuse `rabbit-archive-to-markdown`'s conversion step, fork the destination logic

- **Decision**: `rabbit-ingest`'s `SKILL.md` explicitly delegates format conversion (steps 1–2 of
  `rabbit-archive-to-markdown`: resolve input reference, convert to Markdown) to that existing
  skill's mechanics, but replaces its destination/frontmatter/naming steps (3–7) with new logic
  targeting `meta/rabbit-wiki/sources/{slug}/`.
- **Rationale**: FR-001 and the spec's Assumptions both require reusing conversion mechanics
  without reimplementing them; `rabbit-archive-to-markdown` already resolves file/URL inputs and
  performs the actual Markdown conversion. Duplicating that logic would create two divergent
  copies of the same conversion behavior.
- **Alternatives considered**: Modify `rabbit-archive-to-markdown` in place to support both
  destinations — rejected because that skill's own description/contract (archive to
  `docs/context/sources/`, no ontology/slug involvement) is a distinct, independently useful
  capability the spec does not ask us to change, and doing so would risk regressing its existing
  callers (`aisdlc-knowledge-ingestion`).

## Decision: Slug format and collision handling

- **Decision**: `{YYYY-MM-DD}-{kebab-title}`, with a numeric suffix (`-2`, `-3`, ...) appended
  only on collision against existing `meta/rabbit-wiki/sources/` folder names — identical in
  shape to `rabbit-archive-to-markdown`'s existing `docs/context/sources/{YYYY-MM-DD}-{slug}.md`
  convention, extended from a filename to a folder name.
- **Rationale**: FR-003, Acceptance Scenario 2 of User Story 1, and the Edge Cases section all
  specify this exact rule; reusing the same date-prefix + kebab-title + numeric-suffix shape as
  the existing skill keeps the two skills' collision semantics consistent and avoids inventing a
  second scheme in the same repo.
- **Alternatives considered**: UUID-based slugs — rejected; the spec requires human-readable,
  date-and-title-derived slugs for both source folders and their corresponding wiki entries
  (FR-003, Key Entities: Slug).

## Decision: Ontology stored as a single `ontology.yaml`, not per-concept files

- **Decision**: One `meta/rabbit-wiki/ontology.yaml` file holds all concepts, categories, and
  typed relations, grown incrementally by `rabbit-analyze` and `rabbit-session-close`.
- **Rationale**: FR-005 specifies a single structured ontology file; Karpathy's source pattern
  (cited in the spec's Input) treats the ontology as one evolving graph, not a file-per-concept
  store. A single file is also the simplest structure that still lets `rabbit-lint` and
  `rabbit-query` read the whole ontology in one pass.
- **Alternatives considered**: One YAML file per concept under `meta/rabbit-wiki/ontology/` —
  rejected as unnecessary ceremony for a project-scale ontology; the spec's Key Entities section
  describes a single ontology artifact, not a directory of them.

## Decision: No automated test suite for the new skills

- **Decision**: Validation is scenario-based (spec Acceptance Scenarios exercised manually per
  `quickstart.md`), matching the existing `rabbit-archive-to-markdown` skill, which also has no
  `.bats`/JUnit/pytest coverage.
- **Rationale**: Skills are Markdown instruction files interpreted by the agent at runtime, not
  compiled/interpreted application code; there is no existing test harness in this repo for
  `.agents/skills/*` content (confirmed by inspecting `rabbit-archive-to-markdown/` and every
  other skill directory, none of which contain a `tests/` folder). Constitution Principle V
  ("Incremental Test Hardening") targets code behavior changes; it does not mandate inventing a
  new test framework for prompt/skill content where none exists in the codebase today.
- **Alternatives considered**: Building a harness that feeds fixture files through each skill and
  asserts on output file contents — rejected as disproportionate scope for this feature; no such
  harness exists for the closest analogous skill, and the spec does not request one.

## Decision: `pending_imports/` and `meta/` are new repo-root folders, created on first use

- **Decision**: `rabbit-ingest`'s `SKILL.md` creates `pending_imports/` and `meta/rabbit-wiki/`
  (and their subfolders) if they do not already exist, rather than requiring pre-provisioning.
- **Rationale**: The spec's Assumptions state both folders are "created on first use if not
  already present" — this matches `rabbit-archive-to-markdown`'s existing precedent of creating
  `docs/context/sources/` on demand (step 3 of its `SKILL.md`).
- **Alternatives considered**: Requiring the user to manually create these folders before first
  use — rejected; the spec explicitly rules this out.
