# Quickstart: Validating the Rabbit Wiki Lifecycle

This is a validation guide, not an implementation guide. Run these scenarios after the five
`.agents/skills/rabbit-*` skills exist to confirm each User Story's Acceptance Scenarios pass.
See [data-model.md](data-model.md) for entity shapes and [contracts/skills.md](contracts/skills.md)
for each skill's invocation contract.

## Prerequisites

- The five skills exist: `.agents/skills/rabbit-ingest/SKILL.md`,
  `.agents/skills/rabbit-analyze/SKILL.md`, `.agents/skills/rabbit-query/SKILL.md`,
  `.agents/skills/rabbit-lint/SKILL.md`, `.agents/skills/rabbit-session-close/SKILL.md`.
- The existing `.agents/skills/rabbit-archive-to-markdown/SKILL.md` is unmodified.
- A sample text/markdown file is available to use as a test source asset.

## Scenario 1 — Ingest (User Story 1, P1)

1. Place a sample file (e.g. `sample-notes.md`) into `pending_imports/` (create the folder if it
   does not exist).
2. Invoke `/rabbit-ingest` referencing that file.
3. **Verify**: `meta/rabbit-wiki/sources/{YYYY-MM-DD}-sample-notes/` exists with `original.md`,
   `transformed.md`, and `raw.md`; the assigned slug is reported back.
4. Repeat step 1–2 with a second file that would derive the same slug (same day, same title).
5. **Verify**: the second run produces a `-2`-suffixed slug instead of overwriting the first
   folder (FR-003, Acceptance Scenario 2).
6. **Verify**: the original file content in `pending_imports/` is untouched/not deleted by the
   skill's own action (FR-002, Acceptance Scenario 3).

## Scenario 2 — Analyze (User Story 2, P2)

1. Using the slug from Scenario 1, invoke `/rabbit-analyze` for that asset.
2. **Verify**: `meta/rabbit-wiki/wiki/{slug}.md` exists containing Term/Concept, Definition,
   ontology links, a Source anchor to `meta/rabbit-wiki/sources/{slug}/`, and a Related entries
   section (FR-007).
3. **Verify**: the entry begins with a frontmatter block containing all four required fields
   (`type`, `authored_by`, `confidence`, `last_verified`) (FR-007a).
4. **Verify**: `meta/rabbit-wiki/ontology.yaml` gained at least one new concept/relation entry,
   and `docs/product/glossary.md` is unchanged (FR-005, Acceptance Scenario 2).
5. Re-run `/rabbit-analyze` for the same slug.
6. **Verify**: the existing `wiki/{slug}.md` was updated in place — no duplicate page was created
   (FR-017), and `last_verified` was refreshed to the current date.
7. Attempt `/rabbit-analyze` against a slug folder missing `transformed.md`.
8. **Verify**: the skill reports the missing prerequisite instead of fabricating a wiki entry
   (Edge Cases).

## Scenario 3 — Query (User Story 3, P3)

1. Invoke `/rabbit-query` with a question covered by an existing wiki entry from Scenario 2.
2. **Verify**: the answer cites the specific `wiki/*.md` entry (and source asset, where relevant).
3. Invoke `/rabbit-query` with a question no wiki entry covers.
4. **Verify**: the assistant explicitly states no existing entry answers it, rather than
   fabricating a citation (FR-013).
5. Invoke `/rabbit-query` with a question whose synthesized answer is genuinely new and
   worth retaining.
6. **Verify**: a new `meta/rabbit-wiki/wiki/*.md` page is filed for that answer (FR-012).

## Scenario 4 — Lint (User Story 4, P4)

1. Manually introduce one known issue into the wiki directory (e.g., add a page with no inbound
   links, or two pages making contradictory claims about the same concept).
2. Invoke `/rabbit-lint`.
3. **Verify**: the report flags the introduced issue in the correct category (orphan page /
   contradiction / etc.), naming the specific page(s) (FR-014).
4. **Verify**: no wiki file, source file, or `ontology.yaml` was modified by the lint run, and no
   web search was performed for any reported data gap (FR-015).
5. Introduce an entry missing the `confidence` frontmatter field.
6. **Verify**: `/rabbit-lint` reports a Frontmatter gap finding naming that page (FR-007a).

## Scenario 5 — Session Close (User Story 5, P5)

1. During a working session, draft a wiki/ontology change conversationally (without persisting
   it via `/rabbit-analyze`).
2. Invoke `/rabbit-session-close`.
3. **Verify**: `meta/rabbit-wiki/ontology.yaml` and the relevant `wiki/*.md` entries reflect
   exactly the drafted material — no new research was performed (FR-010).
4. In a fresh session with no drafted changes, invoke `/rabbit-session-close`.
5. **Verify**: the system reports nothing to close and makes no file changes (Acceptance
   Scenario 2).
6. **Verify** (by inspection of the other four skills' `SKILL.md` files): none of them invoke or
   reference `/rabbit-session-close` automatically (FR-009).

## Success Criteria Mapping

| Scenario | Success Criteria covered |
|---|---|
| 1 | SC-001 |
| 2 | SC-002, SC-006 |
| 3 | SC-003 |
| 4 | SC-004 |
| 5 | SC-005 |
