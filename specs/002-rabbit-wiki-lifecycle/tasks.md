---

description: "Task list for Rabbit Wiki Ingestion Lifecycle"
---

# Tasks: Rabbit Wiki Ingestion Lifecycle

**Input**: Design documents from `/specs/002-rabbit-wiki-lifecycle/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/skills.md](contracts/skills.md), [quickstart.md](quickstart.md)

**Tests**: Not requested. This feature is Markdown/YAML skill authoring with no compiled code
(see plan.md Technical Context: Testing). Validation instead uses the quickstart.md scenarios,
included below as manual verification tasks per user story, matching the existing
`rabbit-archive-to-markdown` skill's precedent (no automated suite).

**Organization**: Tasks are grouped by user story (P1–P5 from spec.md) so each story is
independently authorable and independently verifiable via its quickstart scenario.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1–US5)
- Include exact file paths in descriptions

## Path Conventions

Single repo-root project. Skill definitions live under `.agents/skills/{name}/SKILL.md`; the
matching invocable command wrapper lives under `.github/prompts/{name}.prompt.md` (the same
pairing already used by `.agents/skills/rabbit-archive-to-markdown/SKILL.md` and
`.github/prompts/rabbit-archive-to-markdown.prompt.md` — without this file the `/rabbit-*`
command is not actually invocable as a slash command in this repo's agent surface). Data lives
under `meta/rabbit-wiki/` and `pending_imports/` at the repo root (plan.md Project Structure).

<!--
  Sample tasks from the template have been replaced below with the actual tasks for this feature.
-->

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create the repo-root folders this feature's skills read from and write to.

- [X] T001 Create `pending_imports/.gitkeep` at the repo root (intake folder for `/rabbit-ingest`, per plan.md Project Structure and spec.md Assumptions)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shared `meta/rabbit-wiki/` storage scaffold that `/rabbit-analyze`, `/rabbit-query`,
`/rabbit-lint`, and `/rabbit-session-close` all read from or write to (FR-005, FR-016).

**⚠️ CRITICAL**: Complete before starting User Story 2 onward. User Story 1 only needs
`meta/rabbit-wiki/sources/` to exist, which `/rabbit-ingest` itself creates on first use
(research.md), so US1 is not blocked by this phase.

- [X] T002 [P] Create `meta/rabbit-wiki/wiki/.gitkeep` to establish the wiki entries directory (data-model.md Wiki Entry)
- [X] T003 [P] Create `meta/rabbit-wiki/ontology.yaml` with an empty `concepts: []`, `relations: []`, `categories: []` skeleton matching the shape in data-model.md's Ontology section (FR-005)

**Checkpoint**: `meta/rabbit-wiki/` scaffold exists — User Stories 2–5 can now be authored.

---

## Phase 3: User Story 1 - Ingest a new source asset (Priority: P1) 🎯 MVP

**Goal**: A team member drops a file into `pending_imports/` and `/rabbit-ingest` captures it as
a permanent, uniquely-slugged, non-destructive `meta/rabbit-wiki/sources/{slug}/` record.

**Independent Test**: Place one file in `pending_imports/`, run `/rabbit-ingest`, verify
`meta/rabbit-wiki/sources/{slug}/` contains `original.{ext}`, `transformed.md`, `raw.md`, and the
slug is reported (quickstart.md Scenario 1).

### Implementation for User Story 1

- [X] T004 [US1] Author `.agents/skills/rabbit-ingest/SKILL.md` implementing FR-001–FR-004: delegate steps 1–2 (input resolution, Markdown conversion) to `.agents/skills/rabbit-archive-to-markdown/SKILL.md`'s mechanics without modifying that skill; create `pending_imports/` and `meta/rabbit-wiki/` on first use; derive slug `{YYYY-MM-DD}-{kebab-title}` with filename fallback when no title is extractable (Edge Cases); append numeric suffix (`-2`, `-3`, ...) on collision against existing `meta/rabbit-wiki/sources/` folder names; write `original.{ext}`, `transformed.md`, `raw.md` under `meta/rabbit-wiki/sources/{slug}/`; never delete or mutate the original input; report the assigned slug (contracts/skills.md `/rabbit-ingest`)
- [X] T005 [US1] Author `.github/prompts/rabbit-ingest.prompt.md` following the frontmatter/body pattern of `.github/prompts/rabbit-archive-to-markdown.prompt.md`, invoking `.agents/skills/rabbit-ingest/SKILL.md`
- [X] T006 [US1] Manually validate quickstart.md Scenario 1 (ingest, slug-collision suffixing, original file left untouched in `pending_imports/`) and confirm SC-001

**Checkpoint**: User Story 1 is independently functional — a source asset can be ingested and archived.

---

## Phase 4: User Story 2 - Analyze an ingested asset into the wiki (Priority: P2)

**Goal**: `/rabbit-analyze` turns one ingested asset into a structured wiki entry and grows the
ontology.

**Independent Test**: Run `/rabbit-analyze` against one already-ingested asset; verify exactly
one `meta/rabbit-wiki/wiki/{slug}.md` entry exists with all required sections and
`meta/rabbit-wiki/ontology.yaml` reflects new concepts/relations (quickstart.md Scenario 2).

### Implementation for User Story 2

- [X] T007 [US2] Author `.agents/skills/rabbit-analyze/SKILL.md` implementing FR-006, FR-007, FR-017: require `meta/rabbit-wiki/sources/{slug}/transformed.md` to exist, reporting the missing prerequisite instead of fabricating an entry when it does not (Edge Cases); read the current `meta/rabbit-wiki/ontology.yaml`; write or update `meta/rabbit-wiki/wiki/{slug}.md` in place (never duplicate on re-run) containing Term/Concept, Definition, ontology links, a Source anchor to `meta/rabbit-wiki/sources/{slug}/`, and a Related entries section (data-model.md Wiki Entry); add new concept/category/relation entries to `ontology.yaml` only when not already present by `id`, otherwise append the asset's slug to an existing entry's `sources` list; never write to `docs/product/glossary.md` (contracts/skills.md `/rabbit-analyze`)
- [X] T008 [US2] Author `.github/prompts/rabbit-analyze.prompt.md` following the existing prompt pattern, invoking `.agents/skills/rabbit-analyze/SKILL.md`
- [X] T009 [US2] Manually validate quickstart.md Scenario 2 (new wiki entry with all 5 sections, ontology growth, glossary untouched, idempotent re-run, missing-`transformed.md` rejection) and confirm SC-002, SC-006

**Checkpoint**: User Stories 1 AND 2 both work independently — assets can be ingested and analyzed into wiki entries.

---

## Phase 5: User Story 3 - Query the wiki for a cited answer (Priority: P3)

**Goal**: `/rabbit-query` answers questions from existing wiki entries with citations, or states
plainly when no entry answers the question, and files genuinely new answers back into the wiki.

**Independent Test**: Ask `/rabbit-query` a question covered by existing wiki entries; verify the
response cites specific `meta/rabbit-wiki/wiki/*.md` entries or explicitly states no match exists
(quickstart.md Scenario 3).

### Implementation for User Story 3

- [X] T010 [US3] Author `.agents/skills/rabbit-query/SKILL.md` implementing FR-011–FR-013: search `meta/rabbit-wiki/wiki/` and `ontology.yaml` for entries relevant to the question; read matching entries; answer citing the specific wiki entries (and underlying source assets, where relevant) used; if no entry answers the question, state that explicitly rather than fabricating a citation; if multiple entries conflict, surface the conflict instead of silently picking one (Edge Cases); when the synthesized answer is genuinely new and not already captured, file it as a new `meta/rabbit-wiki/wiki/{slug}.md` page (FR-012); never modify an existing wiki page or the ontology as a side effect of answering (contracts/skills.md `/rabbit-query`)
- [X] T011 [US3] Author `.github/prompts/rabbit-query.prompt.md` following the existing prompt pattern, invoking `.agents/skills/rabbit-query/SKILL.md`
- [X] T012 [US3] Manually validate quickstart.md Scenario 3 (cited answer, explicit no-match statement, new page filed for a genuinely new answer) and confirm SC-003

**Checkpoint**: User Stories 1–3 work independently — the capture-and-query loop is complete.

---

## Phase 6: User Story 4 - Lint the wiki for health issues (Priority: P4)

**Goal**: `/rabbit-lint` reports wiki health issues (contradictions, staleness, orphans, missing
pages, missing cross-references, data gaps) without modifying anything or performing web
searches.

**Independent Test**: Run `/rabbit-lint` against a wiki containing at least one known issue (e.g.
an orphan page); verify the report flags it in the correct category, naming the specific page(s)
(quickstart.md Scenario 4).

### Implementation for User Story 4

- [X] T013 [US4] Author `.agents/skills/rabbit-lint/SKILL.md` implementing FR-014–FR-015: scan `meta/rabbit-wiki/wiki/` (read-only) and report, per data-model.md Lint Finding categories — contradictions between pages, claims that look stale relative to newer sources, orphan pages with no inbound links, concepts mentioned without their own page, missing cross-references, and data gaps a web search could fill; name the specific page(s) for each finding; never auto-fix a finding or perform the web searches it flags as gaps; never edit any wiki page, source, or the ontology (contracts/skills.md `/rabbit-lint`)
- [X] T014 [US4] Author `.github/prompts/rabbit-lint.prompt.md` following the existing prompt pattern, invoking `.agents/skills/rabbit-lint/SKILL.md`
- [X] T015 [US4] Manually validate quickstart.md Scenario 4 (introduced issue flagged in the correct category; no files modified; no web search performed for a reported gap) and confirm SC-004

**Checkpoint**: User Stories 1–4 work independently — the wiki now has a health-check safeguard.

---

## Phase 7: User Story 5 - Explicitly close a session's wiki updates (Priority: P5)

**Goal**: `/rabbit-session-close` folds already-drafted session material into the ontology and
wiki, only on explicit invocation, never performing new research.

**Independent Test**: Draft a wiki/ontology change conversationally, run
`/rabbit-session-close`, and verify only that drafted material is persisted; separately verify
the command never runs on its own (quickstart.md Scenario 5).

### Implementation for User Story 5

- [X] T016 [US5] Author `.agents/skills/rabbit-session-close/SKILL.md` implementing FR-008–FR-010: update `meta/rabbit-wiki/ontology.yaml` and affected `meta/rabbit-wiki/wiki/` entries using only material already drafted in the current session; perform no new research, web lookups, or fresh source ingestion; when no drafted material exists, report "nothing to close" and make no file changes (Acceptance Scenario 2); document explicitly that this skill runs only on standalone user invocation and MUST NOT be referenced or triggered from any other `/rabbit-*` skill (contracts/skills.md `/rabbit-session-close`)
- [X] T017 [US5] Author `.github/prompts/rabbit-session-close.prompt.md` following the existing prompt pattern, invoking `.agents/skills/rabbit-session-close/SKILL.md`
- [X] T018 [US5] Verify by inspection that `.agents/skills/rabbit-ingest/SKILL.md`, `rabbit-analyze/SKILL.md`, `rabbit-query/SKILL.md`, and `rabbit-lint/SKILL.md` (T004, T007, T010, T013) contain no reference to or automatic invocation of `/rabbit-session-close` (FR-009)
- [X] T019 [US5] Manually validate quickstart.md Scenario 5 (explicit close persists only drafted material; no-drafted-material no-op) and confirm SC-005

**Checkpoint**: All five user stories are independently functional — the full Rabbit Wiki lifecycle is authored.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Final consistency check across all five skills.

- [X] T020 Re-read all five `SKILL.md` files (T004, T007, T010, T013, T016) together and confirm none of them write to `docs/product/glossary.md` or `docs/context/` (FR-005, FR-016), and that `.agents/skills/rabbit-archive-to-markdown/SKILL.md` remains unmodified
- [X] T021 [P] Update .agents/skills/rabbit-analyze/SKILL.md to write/refresh required frontmatter (type, authored_by: rabbit-analyze, confidence, last_verified) on every wiki/{slug}.md write or in-place update, and to accept the 5 optional fields (source_type, source_ref, tags, scope, related) when derivable from the source asset, without writing to ontology.yaml or docs/context/index.yaml as part of this change (data-model.md Wiki Entry Frontmatter, FR-007a)
- [X] T022 [P] Update .agents/skills/rabbit-lint/SKILL.md to add a Frontmatter gap finding category: scan meta/rabbit-wiki/wiki/*.md for entries missing any of the 4 required frontmatter fields (type, authored_by, confidence, last_verified) and report each by page name, read-only, no auto-fix (data-model.md Lint Finding, FR-007a)
- [X] T023 Manually validate quickstart.md Scenario 2 still passes with the new frontmatter present on a freshly analyzed entry, and that an in-place re-run refreshes last_verified
- [X] T024 Manually validate quickstart.md Scenario 4 flags a Frontmatter gap when a wiki entry is missing a required field, and confirm ontology.yaml and docs/context/index.yaml are unchanged by both T021 and T022

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately.
- **Foundational (Phase 2)**: Depends on Setup. Blocks User Stories 2–5 (they read/write
  `meta/rabbit-wiki/ontology.yaml` and `meta/rabbit-wiki/wiki/`). Does NOT block User Story 1,
  which only needs `meta/rabbit-wiki/sources/`, created by `/rabbit-ingest` itself.
- **User Story 1 (Phase 3)**: Depends on Setup only — can start in parallel with Phase 2.
- **User Stories 2–5 (Phases 4–7)**: Each depends on Foundational (Phase 2) completing. US2
  additionally benefits from US1 existing (an ingested asset to analyze), but its `SKILL.md`
  authoring itself (T007) has no file dependency on US1's `SKILL.md`.
- **Polish (Phase 8)**: Depends on all five skills (T004, T007, T010, T013, T016) being authored.

### User Story Dependencies

- **US1 (P1)**: No dependencies on other stories.
- **US2 (P2)**: Independently authorable; its manual validation (T009) needs an asset produced by US1's validation (T006) to analyze.
- **US3 (P3)**: Independently authorable; its manual validation (T012) needs wiki entries produced by US2's validation (T009).
- **US4 (P4)**: Independently authorable; its manual validation (T015) needs an existing wiki directory (from US2/US3 validation) to introduce a known issue into.
- **US5 (P5)**: Independently authorable; T018 reads the other four `SKILL.md` files (T004, T007, T010, T013) as a verification input.

### Within Each User Story

- `SKILL.md` authoring before the matching `.prompt.md` wrapper.
- `.prompt.md` wrapper before manual quickstart validation.

### Parallel Opportunities

- T002 and T003 (Foundational) can run in parallel — different files.
- T004 (US1 `SKILL.md`) can be authored in parallel with T002/T003 (Foundational), since US1 does not depend on the Foundational phase.
- Once Foundational (Phase 2) is complete, T007, T010, T013, and T016 (the four remaining skills' `SKILL.md` authoring) can all be drafted in parallel — they are independent files with no code dependencies between them, though their *manual validation* tasks (T009, T012, T015, T019) are best run sequentially in priority order since each benefits from content produced by the previous story's validation.

---

## Parallel Example: Foundational + User Story 1

```bash
# Launch Foundational scaffold tasks together:
Task: "Create meta/rabbit-wiki/wiki/.gitkeep"
Task: "Create meta/rabbit-wiki/ontology.yaml skeleton"

# In parallel, start User Story 1 authoring (no dependency on the above):
Task: "Author .agents/skills/rabbit-ingest/SKILL.md"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001).
2. Complete Phase 3: User Story 1 (T004–T006).
3. **STOP and VALIDATE**: Run quickstart.md Scenario 1 independently.
4. Ship the ingest-only capability if that alone is valuable.

### Incremental Delivery

1. Setup → Foundational → foundation ready for US2–US5.
2. Add US1 → validate → MVP demo (ingest works, in parallel with Foundational).
3. Add US2 → validate → analyze works (turns ingested assets into wiki entries).
4. Add US3 → validate → query works (the wiki starts paying off).
5. Add US4 → validate → lint works (maintenance safeguard).
6. Add US5 → validate → session-close works (explicit reconciliation).
7. Run Phase 8 polish check across all five skills.

### Parallel Team Strategy

With multiple contributors:

1. One contributor completes Setup + Foundational (T001–T003).
2. A second contributor starts User Story 1 (T004–T006) immediately, in parallel with Foundational.
3. Once Foundational is done, up to four more contributors take US2, US3, US4, US5 (T007–T019) in parallel, each authoring an independent `SKILL.md` + `.prompt.md` pair.
4. One contributor runs Phase 8 polish (T020) once all five skills are authored.

---

## Notes

- No automated tests exist or are requested for this feature (skill content, not application code) — validation is the quickstart.md scenario per story.
- `[P]` tasks touch different files with no dependency on an incomplete task.
- `[Story]` labels map every implementation task to its spec.md user story for traceability.
- Each user story's `SKILL.md` + `.prompt.md` pair is independently completable and testable.
- `.agents/skills/rabbit-archive-to-markdown/SKILL.md` and `.github/prompts/rabbit-archive-to-markdown.prompt.md` are reused as-is and MUST NOT be modified by any task above.
