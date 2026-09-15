# Phase 1 Contracts: Rabbit Wiki Skill Interfaces

This feature exposes no HTTP/CLI API. Its "interface contract" is the invocation contract each
skill presents to the agent/user — inputs expected, outputs produced, and side effects permitted.
This mirrors the existing `rabbit-archive-to-markdown` skill's contract shape (steps + a
Completion Report).

## `/rabbit-ingest`

- **Trigger**: User asks to ingest a file already placed in `pending_imports/` (or references a
  file/URL directly, consistent with `rabbit-archive-to-markdown`'s input resolution).
- **Inputs**: A file reference (path within `pending_imports/`, absolute path, or URL).
- **Preconditions**: None — creates `pending_imports/` and `meta/rabbit-wiki/` on first use.
- **Side effects**: Writes exactly one new `meta/rabbit-wiki/sources/{slug}/` folder containing
  `original.{ext}`, `transformed.md`, `raw.md`. MUST NOT delete or mutate the original input file
  outside of retaining a copy under the new folder (FR-002).
- **Outputs**: The assigned slug, reported back to the user (Acceptance Scenario 1, User Story 1).
- **Forbidden**: Overwriting an existing slug's folder; deleting the user's original file content.

## `/rabbit-analyze`

- **Trigger**: User asks to analyze an ingested asset (by slug or by description resolvable to
  one).
- **Inputs**: A slug (or enough context to resolve one) identifying a folder under
  `meta/rabbit-wiki/sources/`.
- **Preconditions**: `meta/rabbit-wiki/sources/{slug}/transformed.md` MUST exist; if missing, the
  skill MUST report the missing prerequisite rather than fabricate a wiki entry (Edge Cases).
- **Side effects**: Writes or updates exactly one `meta/rabbit-wiki/wiki/{slug}.md`; adds new
  concepts/categories/relations to `meta/rabbit-wiki/ontology.yaml` (never removes existing ones);
  MUST NOT write to `docs/product/glossary.md`. Writes/refreshes the entry's YAML frontmatter
  (`type`, `authored_by: rabbit-analyze`, `confidence`, `last_verified`) on every write or
  in-place update.
- **Outputs**: Confirmation of the wiki entry path and a summary of ontology additions.
- **Forbidden**: Creating a duplicate wiki entry for an already-analyzed slug (FR-017); modifying
  the glossary.

## `/rabbit-query`

- **Trigger**: User asks a question intended to be answered from the wiki.
- **Inputs**: A natural-language question.
- **Preconditions**: None (an empty/sparse wiki is a valid state — see Outputs).
- **Side effects**: MAY write exactly one new `meta/rabbit-wiki/wiki/{slug}.md` page, only when
  the answer is genuinely new and not already captured (FR-012). MUST NOT modify any existing
  wiki page or the ontology as a side effect of answering.
- **Outputs**: An answer citing the specific `wiki/*.md` entries (and source assets, where
  relevant) used, OR an explicit statement that no existing entry answers the question (FR-013).
  If multiple entries conflict, the conflict itself is surfaced rather than resolved silently
  (Edge Cases).
- **Forbidden**: Fabricating a citation to a non-existent or unused wiki entry.

## `/rabbit-lint`

- **Trigger**: User asks for a wiki health check.
- **Inputs**: None required (operates over the whole `meta/rabbit-wiki/wiki/` + `ontology.yaml`).
- **Preconditions**: None.
- **Side effects**: None — read-only. MUST NOT perform web searches for gaps it identifies
  (FR-015); MUST NOT edit any wiki page, source, or the ontology. Reports a Frontmatter gap
  finding for any `wiki/*.md` entry missing one or more of the four required frontmatter fields.
- **Outputs**: A findings report, each finding naming the specific page(s) and category
  (contradiction, stale claim, orphan page, missing page candidate, missing cross-reference, data
  gap, Frontmatter gap) per FR-014.
- **Forbidden**: Auto-fixing findings; performing the web searches it flags.

## `/rabbit-session-close`

- **Trigger**: Explicit, standalone user invocation only — never triggered automatically by any
  other `/rabbit-*` skill or workflow (FR-009).
- **Inputs**: None beyond the current conversation's already-drafted session material.
- **Preconditions**: None; a session with no drafted changes is a valid, no-op input (Acceptance
  Scenario 2, User Story 5).
- **Side effects**: Updates `meta/rabbit-wiki/ontology.yaml` and affected `meta/rabbit-wiki/wiki/`
  entries using only material already drafted in-session. MUST NOT perform new research, web
  lookups, or fresh source ingestion (FR-010).
- **Outputs**: A summary of what was persisted, or an explicit "nothing to close" report when no
  drafted material exists.
- **Forbidden**: Running without explicit invocation; introducing any content not already drafted
  earlier in the same session (SC-005).
