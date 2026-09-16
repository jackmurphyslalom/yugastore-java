# Phase 1 Data Model: Rabbit Wiki Ingestion Lifecycle

All entities are plain files (Markdown/YAML) under `meta/rabbit-wiki/`; there is no database or
ORM layer. This document specifies each entity's on-disk shape and validation rules derived from
the spec's Key Entities section and Functional Requirements.

## Source Asset

**Location**: `meta/rabbit-wiki/sources/{slug}/`

| File | Purpose | Mutability |
|---|---|---|
| `original.{ext}` | Untouched copy of the ingested file, extension preserved | Immutable once written (FR-002) |
| `transformed.md` | Final converted Markdown, ready for `rabbit-analyze` to read | Immutable once written by `rabbit-ingest` |
| `raw.md` | Intermediate/raw conversion output kept for audit/debugging | Immutable once written by `rabbit-ingest` |

**Validation rules**:
- `{slug}` MUST match `{YYYY-MM-DD}-{kebab-title}[-N]` (FR-003).
- All three files MUST exist together for a Source Asset to be considered complete; `rabbit-analyze`
  MUST reject a folder missing `transformed.md` (Edge Cases).
- `rabbit-ingest` MUST NOT overwrite an existing `{slug}/` folder's files on re-run for the same
  slug — a collision instead produces a new numeric-suffixed slug (FR-003).

## Slug

**Type**: String identifier, not a stored file — derived and reused as both a folder name
(`sources/{slug}/`) and a file name (`wiki/{slug}.md`).

**Format**: `{YYYY-MM-DD}-{kebab-title}`, optionally suffixed `-2`, `-3`, ... on collision.

**Validation rules**:
- `{kebab-title}` MUST be non-empty; when no usable title can be derived from asset content, fall
  back to a kebab-cased version of the original filename (Edge Cases).
- Uniqueness is scoped to `meta/rabbit-wiki/sources/` folder names; collision check MUST run
  before writing any new source folder.

## Ontology

**Location**: `meta/rabbit-wiki/ontology.yaml` (single file)

**Shape**:
```yaml
concepts:
  - id: <kebab-case-concept-id>
    label: <human-readable name>
    category: <category id, optional>
    definition: <short description>
    sources: [<slug>, ...]        # Source Assets that introduced/reinforced this concept
relations:
  - from: <concept id>
    type: <relation type, e.g. "part-of", "depends-on", "synonym-of">
    to: <concept id>
    sources: [<slug>, ...]
categories:
  - id: <kebab-case-category-id>
    label: <human-readable name>
```

**Validation rules**:
- MUST NOT be merged into or read as a substitute for `docs/product/glossary.md` (FR-005).
- `rabbit-analyze` MUST add a new `concepts`/`categories`/`relations` entry only when the
  concept/relation does not already exist by `id`; existing concepts gain the new asset's slug
  appended to their `sources` list instead of a duplicate entry (Acceptance Scenario 3, User
  Story 2).
- `rabbit-session-close` is the only other skill permitted to write to this file, and only using
  material already drafted in the current session (FR-008, FR-010).

## Wiki Entry

**Location**: `meta/rabbit-wiki/wiki/{slug}.md`

**Frontmatter** (FR-007a): every entry MUST begin with a YAML frontmatter block above its body
sections.

| Field | Required | Type | Notes |
|---|---|---|---|
| `type` | Yes | string | Entry kind, e.g. `concept`, `decision`, `answer` (queries filed by `/rabbit-query` use `answer`) |
| `authored_by` | Yes | string | Skill that wrote/last-updated the entry, e.g. `rabbit-analyze`, `rabbit-query`, `rabbit-session-close` |
| `confidence` | Yes | enum: `high`\|`medium`\|`low` | Author's confidence in the entry's accuracy given its source material |
| `last_verified` | Yes | date (`YYYY-MM-DD`) | Date the entry's content was last confirmed accurate; refreshed on every in-place update |
| `source_type` | No | string | e.g. `document`, `recording`, `url`, `conversation` |
| `source_ref` | No | string | Path/slug of the originating `meta/rabbit-wiki/sources/{slug}/` folder, when one exists |
| `tags` | No | list of strings | Free-form topical tags |
| `scope` | No | string | Bounding context this entry applies to, if narrower than the whole wiki |
| `related` | No | list of strings | Slugs of related `wiki/*.md` entries (frontmatter-level shortcut; body's "Related entries" section remains the human-readable list) |

**Required sections** (FR-007, Acceptance Scenario 1 of User Story 2):
1. **Term/Concept** — the identifier/title of the entry.
2. **Definition** — a concise explanation.
3. **Ontology links** — references to related `ontology.yaml` concept ids.
4. **Source anchor** — a link back to `meta/rabbit-wiki/sources/{slug}/`.
5. **Related entries** — links to other `wiki/*.md` pages.

**Validation rules**:
- One Wiki Entry per Source Asset slug produced by `rabbit-analyze`; re-running `rabbit-analyze`
  for the same slug MUST update this file in place, not create a duplicate (FR-017).
- `rabbit-query` MAY create a new Wiki Entry (a new `{slug}.md`, using the same slug format) when
  it produces a genuinely new, reusable, not-already-captured answer (FR-012) — this is the one
  case where a Wiki Entry's slug does not necessarily correspond to a Source Asset folder.
- All four required frontmatter fields MUST be present on every write or update; `/rabbit-lint`
  MUST flag any entry missing a required field as a new Lint Finding category (Frontmatter gap).

## Session Draft

**Location**: Not a persisted file — exists only as in-conversation state (draft wiki/ontology
edits proposed but not yet written to `meta/rabbit-wiki/`) for the duration of one working
session, per the spec's Assumptions.

**Validation rules**:
- `rabbit-session-close` MUST persist only material already present in this in-session draft
  state — it MUST NOT perform new research or lookups to produce additional content (FR-010).
- If no draft material exists when `rabbit-session-close` runs, it MUST report "nothing to close"
  and make no file changes (Acceptance Scenario 2, User Story 5).

## Lint Finding

**Type**: Transient report output from `rabbit-lint` — not persisted as a file; printed back to
the user as the skill's response.

**Categories** (FR-014):
- Contradiction (two pages, same concept, conflicting claims)
- Stale claim (sourced from an asset superseded by a newer, contradicting source)
- Orphan page (no inbound links from any other page or ontology entry)
- Missing page candidate (concept mentioned across pages, no dedicated entry)
- Missing cross-reference
- Data gap (a web search could fill it — reported only, never auto-searched, FR-015)

**Validation rules**:
- Each finding MUST name the specific page(s) it concerns (Acceptance Scenarios of User Story 4).
