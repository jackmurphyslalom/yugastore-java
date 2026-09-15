# Feature Specification: Rabbit Wiki Ingestion Lifecycle

**Feature Branch**: `002-rabbit-wiki-lifecycle`

**Created**: 2026-09-15

**Status**: Draft

**Input**: User description: "Build the Rabbit Wiki ingestion lifecycle: three prompt/skill pairs (/rabbit-ingest, /rabbit-analyze, /rabbit-session-close) plus /rabbit-query and /rabbit-lint, implementing Karpathy's 'LLM Wiki' pattern (source: https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) for this repo. Decisions confirmed via aisdlc-grilling on 2026-09-15 (specs/intake/2026-09-15-rabbit-wiki-lifecycle.md)."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Ingest a new source asset (Priority: P1)

A team member drops a new source asset (document, recording, webpage export, or similar) into
a `pending_imports/` folder at the repo root and asks the assistant to ingest it. The assistant
converts it to Markdown, assigns it a unique, stable identifier, and keeps a permanent
chain-of-custody record of the original file alongside its converted forms, without deciding
yet what the content means.

**Why this priority**: Every other capability in this feature (wiki entries, ontology growth,
querying, linting) depends on assets first being captured in a durable, uniquely identified,
non-destructive form. Without ingestion, there is nothing to analyze, query, or lint.

**Independent Test**: Can be fully tested by placing one file in `pending_imports/`, running the
ingest capability, and verifying that a new `meta/rabbit-wiki/sources/{slug}/` folder exists
containing the original file, a transformed Markdown copy, and a raw Markdown copy — with no
wiki or ontology changes required for this story alone to deliver value (a searchable,
non-destructive archive).

**Acceptance Scenarios**:

1. **Given** a new file in `pending_imports/` with a clear title, **When** the user runs
   `/rabbit-ingest`, **Then** the system creates `meta/rabbit-wiki/sources/{YYYY-MM-DD}-{kebab-title}/`
   containing `original.{ext}` (the untouched source file), `transformed.md` (converted output),
   and `raw.md` (the intermediate/raw conversion), and reports the assigned slug back to the user.
2. **Given** an asset whose generated slug would collide with an existing `meta/rabbit-wiki/sources/`
   folder for the same day and title, **When** ingestion runs, **Then** the system appends a
   numeric suffix (`-2`, `-3`, ...) to produce a unique slug instead of overwriting the existing
   folder.
3. **Given** a successfully ingested asset, **When** the user inspects `pending_imports/`,
   **Then** the original file is no longer required there (it has been retained permanently
   under its source folder), and the system does not silently delete or mutate the user's
   original file content.

---

### User Story 2 - Analyze an ingested asset into the wiki (Priority: P2)

After an asset is ingested, a team member asks the assistant to analyze it. The assistant reads
the asset's converted Markdown, consults the current ontology, drafts one wiki knowledge-base
entry summarizing the asset's key terms and concepts, links that entry to the ontology, and
extends the ontology with any new concepts, categories, or typed relations the asset introduces.

**Why this priority**: This is the step that turns a raw archive into reusable, structured
project knowledge — the core value of the "LLM Wiki" pattern — and it depends on User Story 1
having already produced a converted asset to read.

**Independent Test**: Can be fully tested by running `/rabbit-analyze` against a single
already-ingested asset and verifying that exactly one new `meta/rabbit-wiki/wiki/{slug}.md`
entry exists with the required sections, and that `meta/rabbit-wiki/ontology.yaml` reflects any
new concepts or relations found in that asset — independent of whether querying or linting are
ever used.

**Acceptance Scenarios**:

1. **Given** an ingested asset at `meta/rabbit-wiki/sources/{slug}/transformed.md`, **When** the
   user runs `/rabbit-analyze` for that asset, **Then** the system writes
   `meta/rabbit-wiki/wiki/{slug}.md` containing, at minimum, a Term/Concept section, a
   Definition, links to relevant ontology entries, a Source anchor pointing back to the asset's
   source folder, and a Related entries section.
2. **Given** an asset that introduces a concept not yet present in the ontology, **When**
   analysis runs, **Then** `meta/rabbit-wiki/ontology.yaml` gains a new concept/category/relation
   entry for it, without altering `docs/product/glossary.md`.
3. **Given** an asset whose concepts already exist in the ontology, **When** analysis runs,
   **Then** the new wiki entry links to the existing ontology entries rather than duplicating
   them.

---

### User Story 3 - Query the wiki for a cited answer (Priority: P3)

A team member asks a question. The assistant searches the wiki and ontology for relevant
entries, reads them, synthesizes an answer that cites the specific wiki entries and source
assets it drew from, and — when the answer is good and not already captured — files it back
into the wiki as a new page for future reuse.

**Why this priority**: This is the primary way the wiki pays off day to day (Karpathy's "Query"
step) and is the most direct user-facing value once enough entries exist from Stories 1–2, but
it depends on those stories having populated the wiki first.

**Independent Test**: Can be fully tested by asking `/rabbit-query` a question whose answer is
covered by existing wiki entries, and verifying the response cites specific
`meta/rabbit-wiki/wiki/*.md` entries (or explicitly states no matching entry exists), and that a
new page is only added when the answer is genuinely new and worth retaining.

**Acceptance Scenarios**:

1. **Given** wiki entries exist that cover a topic, **When** the user runs `/rabbit-query` with
   a question about that topic, **Then** the assistant returns an answer citing the specific
   wiki entries (and, where relevant, their underlying source assets) it used.
2. **Given** no wiki entry answers the question, **When** `/rabbit-query` runs, **Then** the
   assistant states that no existing entry answers the question rather than fabricating a
   citation.
3. **Given** a query produces a genuinely new, reusable answer not already captured in the wiki,
   **When** the query completes, **Then** the assistant files that answer back into
   `meta/rabbit-wiki/wiki/` as a new page.

---

### User Story 4 - Lint the wiki for health issues (Priority: P4)

A team member periodically asks the assistant to check the wiki's health. The assistant scans
`meta/rabbit-wiki/wiki/` for contradictions between pages, claims that look stale relative to
newer sources, orphan pages with no inbound links, important concepts that are mentioned but
lack their own page, missing cross-references, and gaps that a web search could fill — and
reports findings for a human to act on.

**Why this priority**: Lint is a maintenance/quality safeguard for the wiki built by Stories 1–3;
it adds durability value but is not required for the wiki to be usable, so it is lower priority
than the core capture-and-query loop.

**Independent Test**: Can be fully tested by running `/rabbit-lint` against an existing wiki
directory containing at least one known issue (e.g., an orphan page or a duplicated concept)
and verifying the report surfaces that issue in the correct category, without requiring
`/rabbit-query` to have ever been used.

**Acceptance Scenarios**:

1. **Given** two wiki pages that make contradictory claims about the same concept, **When**
   `/rabbit-lint` runs, **Then** the report flags the contradiction and names both pages.
2. **Given** a wiki page with no inbound links from any other page or ontology entry, **When**
   `/rabbit-lint` runs, **Then** the report flags it as an orphan page.
3. **Given** a concept mentioned across multiple pages but with no dedicated wiki entry, **When**
   `/rabbit-lint` runs, **Then** the report flags it as a missing page candidate.
4. **Given** a wiki claim sourced from an asset later superseded by a newer, contradicting
   source, **When** `/rabbit-lint` runs, **Then** the report flags the claim as potentially
   stale.

---

### User Story 5 - Explicitly close a session's wiki updates (Priority: P5)

At the end of a working session, a team member explicitly asks the assistant to reflect on what
was drafted during that session and fold it into the durable wiki and ontology. The assistant
updates `meta/rabbit-wiki/ontology.yaml` and affected `meta/rabbit-wiki/wiki/` entries using only
material already drafted in the current session — it never performs new research or fresh
source lookups on its own.

**Why this priority**: This is a deliberate, explicitly-triggered reconciliation step rather
than part of the core capture-or-query loop, so it is the lowest priority of the five —
valuable for keeping the wiki tidy, but not required for Stories 1–4 to deliver value.

**Independent Test**: Can be fully tested by drafting session notes referencing a concept
change, then running `/rabbit-session-close`, and verifying the ontology/wiki reflect only that
already-drafted change — and, separately, verifying the command never runs on its own without
an explicit user invocation.

**Acceptance Scenarios**:

1. **Given** a session in which new concepts or corrections were drafted but not yet persisted,
   **When** the user explicitly runs `/rabbit-session-close`, **Then**
   `meta/rabbit-wiki/ontology.yaml` and the relevant `meta/rabbit-wiki/wiki/` entries are updated
   to reflect exactly that drafted material.
2. **Given** a session with no drafted wiki/ontology changes, **When** the user runs
   `/rabbit-session-close`, **Then** the system reports there is nothing to close and makes no
   changes.
3. **Given** any other `/rabbit-*` command completes, **When** the session continues, **Then**
   `/rabbit-session-close` is not triggered automatically — it runs only on explicit user
   invocation.

### Edge Cases

- What happens when `pending_imports/` contains a file whose derived title is empty or
  unusable for a slug (e.g., no extractable title)? The system MUST fall back to a
  filename-derived kebab-case title rather than failing ingestion.
- What happens when `/rabbit-analyze` is run against a source folder that has no
  `transformed.md` yet (ingestion incomplete or failed)? The system MUST report the missing
  prerequisite rather than fabricating a wiki entry from partial data.
- What happens when `/rabbit-analyze` is re-run for an already-analyzed asset? The system MUST
  update the existing `meta/rabbit-wiki/wiki/{slug}.md` and ontology entries in place rather than
  creating a duplicate wiki page for the same slug.
- What happens when `/rabbit-query` finds multiple wiki entries that conflict with each other?
  The system MUST surface the conflict to the user instead of silently picking one side.
- What happens when `/rabbit-lint` finds a data gap that a web search could fill? The system
  MUST report the gap as a finding for human follow-up rather than performing the web search
  itself as part of lint.
- What happens when a user invokes `/rabbit-session-close` mid-session before any
  `/rabbit-ingest` or `/rabbit-analyze` work has produced draftable material? The system MUST
  no-op safely (see Acceptance Scenario 2 of User Story 5).
- What happens when an asset's derived slug collides with a slug from a different day (unlikely
  given the date prefix, but possible for backfilled/re-dated assets)? The same numeric-suffix
  collision rule from User Story 1 applies.
- What happens when `/rabbit-analyze` updates an existing entry in place — does it preserve or
  refresh `last_verified`? `last_verified` MUST be refreshed to the current date on every
  `/rabbit-analyze` re-run (ties to FR-017's in-place update rule).

## Iterations

### Iteration 2026-09-15: Wiki Entry frontmatter schema

**Change**: Add a required/optional YAML frontmatter block (4 required, 5 optional fields) to
every `meta/rabbit-wiki/wiki/*.md` entry, without touching `ontology.yaml` or
`docs/context/index.yaml`.
**Scope**: Feature-wide
**Artifacts updated**: spec.md, data-model.md, contracts/skills.md, quickstart.md, tasks.md
**Tasks added**: T021, T022, T023, T024
**Tasks removed**: none
**Tasks marked complete**: none (all prior tasks T001–T020 were already complete)

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST provide a `/rabbit-ingest` capability that reads a source asset
  from `pending_imports/` at the repository root and converts it to Markdown, reusing the
  existing `rabbit-archive-to-markdown` skill's conversion step.
- **FR-002**: `/rabbit-ingest` MUST retain the original, untouched source asset file permanently
  alongside its converted output (it MUST NOT delete, move-and-discard, or overwrite the
  original once ingestion completes).
- **FR-003**: `/rabbit-ingest` MUST assign each ingested asset a unique slug in the format
  `{YYYY-MM-DD}-{kebab-title}`, appending a numeric suffix (`-2`, `-3`, ...) only when a
  collision with an existing slug occurs.
- **FR-004**: `/rabbit-ingest` MUST store each asset's three artifacts together under
  `meta/rabbit-wiki/sources/{slug}/` as `original.{ext}`, `transformed.md`, and `raw.md`.
- **FR-005**: The system MUST maintain a structured ontology at
  `meta/rabbit-wiki/ontology.yaml` containing concepts, categories, and typed relations, kept
  separate from and never merged into `docs/product/glossary.md`.
- **FR-006**: The system MUST provide a `/rabbit-analyze` capability that, for a given ingested
  asset, reads the current ontology, writes (or updates) one wiki knowledge-base entry at
  `meta/rabbit-wiki/wiki/{slug}.md`, and extends the ontology with any new concepts or relations
  discovered in that asset.
- **FR-007**: Each `meta/rabbit-wiki/wiki/{slug}.md` entry MUST include, at minimum: a
  Term/Concept identifier, a Definition, links to related ontology entries, a Source anchor back
  to `meta/rabbit-wiki/sources/{slug}/`, and a Related entries section, in addition to the
  frontmatter block required by FR-007a.
- **FR-007a**: Each `meta/rabbit-wiki/wiki/{slug}.md` entry MUST begin with a YAML frontmatter
  block containing four required fields: `type`, `authored_by`, `confidence`, and
  `last_verified`.
- **FR-008**: The system MUST provide a `/rabbit-session-close` capability that updates
  `meta/rabbit-wiki/ontology.yaml` and `meta/rabbit-wiki/wiki/` entries using only material
  already drafted during the current session.
- **FR-009**: `/rabbit-session-close` MUST NOT run automatically as a side effect of any other
  `/rabbit-*` command or any other workflow — it MUST run only on explicit user invocation.
- **FR-010**: `/rabbit-session-close` MUST NOT perform new research, web lookups, or fresh
  source ingestion; it operates only on already-drafted session material.
- **FR-011**: The system MUST provide a `/rabbit-query` capability that searches the wiki and
  ontology for entries relevant to a user's question, reads the relevant entries, and returns an
  answer that cites the specific wiki entries (and underlying sources, where applicable) it used.
- **FR-012**: When `/rabbit-query` produces a new, reusable answer not already captured in the
  wiki, it MUST file that answer back into `meta/rabbit-wiki/wiki/` as a new page.
- **FR-013**: When `/rabbit-query` finds no wiki entry that answers the question, it MUST state
  that explicitly rather than fabricating a citation.
- **FR-014**: The system MUST provide a `/rabbit-lint` capability that scans
  `meta/rabbit-wiki/wiki/` and reports: contradictions between pages, claims that appear stale
  relative to newer sources, orphan pages with no inbound links, important concepts mentioned
  without their own page, missing cross-references, and data gaps a web search could fill.
- **FR-015**: `/rabbit-lint` MUST report findings for human review and MUST NOT automatically
  perform the web searches it identifies as potential gap-fillers.
- **FR-016**: All Rabbit Wiki storage (`sources/`, `ontology.yaml`, `wiki/`) MUST live under a
  top-level `meta/rabbit-wiki/` root, distinct from `docs/context/` and other AI-SDLC-managed
  durable context locations.
- **FR-017**: Re-running `/rabbit-analyze` for an already-analyzed slug MUST update that slug's
  existing wiki entry and ontology contributions in place rather than creating a duplicate entry.

### Key Entities *(include if feature involves data)*

- **Source Asset**: A single ingested artifact, identified by its unique slug. Comprises three
  co-located files under `meta/rabbit-wiki/sources/{slug}/`: the retained original file, a
  transformed Markdown copy, and a raw Markdown copy. Immutable chain-of-custody record — never
  overwritten by later analysis.
- **Slug**: The unique identifier for a Source Asset and its corresponding Wiki Entry, in the
  form `{YYYY-MM-DD}-{kebab-title}`, with an optional numeric collision suffix.
- **Ontology**: Structured data at `meta/rabbit-wiki/ontology.yaml` describing concepts,
  categories, and typed relations between them; grows over time as assets are analyzed; distinct
  from the product glossary.
- **Wiki Entry**: A knowledge-base page at `meta/rabbit-wiki/wiki/{slug}.md`, derived from
  exactly one Source Asset, containing a required YAML frontmatter block (`type`,
  `authored_by`, `confidence`, `last_verified`, plus optional provenance/tagging fields) followed
  by a Term/Concept, Definition, ontology links, a Source anchor, and Related entries.
- **Session Draft**: The set of wiki/ontology changes proposed but not yet persisted during the
  current working session; consumed only by an explicit `/rabbit-session-close` invocation.
- **Lint Finding**: A single reported health issue about the wiki (contradiction, stale claim,
  orphan page, missing page candidate, missing cross-reference, or data gap), scoped to specific
  named pages.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A team member can take a new source file from drop-in to a searchable,
  chain-of-custody-preserved record in one ingestion action, with zero manual file renaming or
  folder creation required.
- **SC-002**: 100% of ingested assets produce a corresponding wiki entry, upon analysis, that
  contains all five required sections (Term/Concept, Definition, ontology links, Source anchor,
  Related entries).
- **SC-003**: A team member asking a question already covered by the wiki receives a cited
  answer referencing specific wiki entries, without needing to know which underlying source
  asset holds the answer.
- **SC-004**: Running a wiki health check surfaces every orphan page and every cross-page
  contradiction present in the wiki at the time of the check.
- **SC-005**: No `/rabbit-session-close` run ever introduces content that was not already
  drafted earlier in the same session, and the command never executes without an explicit user
  request.
- **SC-006**: The ontology and product glossary never require merge conflict resolution against
  each other because they remain stored and maintained as separate artifacts.

## Assumptions

- `pending_imports/` is a repo-root folder created on first use if it does not already exist;
  it holds assets awaiting `/rabbit-ingest` and is expected to be emptied over time as assets are
  ingested (originals move into permanent storage, not left duplicated in both places).
- `/rabbit-ingest` reuses the existing `rabbit-archive-to-markdown` skill's conversion mechanics
  (file/URL resolution, Markdown conversion) rather than reimplementing conversion; ingestion
  adds the `pending_imports/` intake path, original-retention, and slugging behavior on top.
- `meta/` is a new top-level folder, sibling to `docs/`, `specs/`, and the microservice modules;
  it is dedicated to Rabbit Wiki storage and is not managed by the AI-SDLC context tooling under
  `docs/context/`.
- The ontology (`meta/rabbit-wiki/ontology.yaml`) and `docs/product/glossary.md` may reference
  overlapping real-world terms, but are separate artifacts with separate lifecycles; this spec
  does not require reconciling or syncing them.
- "Session" for `/rabbit-session-close` means the current conversational working session; there
  is no separate persistent session-tracking store beyond what the assistant already has drafted
  and not yet written to `meta/rabbit-wiki/`.
- `/rabbit-query` and `/rabbit-lint` operate only over `meta/rabbit-wiki/` content (wiki entries,
  ontology, and source assets) — they are not general-purpose repo-wide search or lint tools.
- Concurrent ingestion of two assets with the same derived slug on the same day is rare enough
  that the numeric-suffix collision rule (reused from `rabbit-archive-to-markdown`) is sufficient
  without additional locking.
