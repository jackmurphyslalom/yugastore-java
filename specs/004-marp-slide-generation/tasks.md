# Tasks: Marp-Based Slide Generation for Major Repo Changes

**Input**: Design documents from `/specs/004-marp-slide-generation/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, quickstart.md

**Tests**: No automated test suite applies — this is a docs/tooling-only feature (plan.md Technical
Context: "N/A, no executable code"). Verification instead uses the manual scenarios in
`quickstart.md`, captured below as explicit validation tasks per user story.

**Organization**: Tasks are grouped by user story (spec.md) to enable independent authoring and
validation of each story's slice of the feature.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

Single docs subdirectory addition to the existing Java/Maven repo (plan.md Project Structure):

```text
docs/slides/
├── README.md                          # Authoring + export conventions
└── ai-sdlc-bootstrap-overview.md      # Sample deck (12 themes)
```

No `contracts/`, no application code, no `package.json`, no CI changes.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Establish the canonical deck location

- [X] T001 Create the `docs/slides/` directory at the repo root as the canonical Marp deck
      location (plan.md Project Structure; spec.md FR-002)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core authoring documentation that every user story's independent test depends on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T002 Author `docs/slides/README.md` covering: (a) discoverability as the entry point for a
      contributor with no prior Marp knowledge (FR-007), (b) the authoring convention — Marp front
      matter (`marp: true`, `theme`, `paginate`, etc.) and `---` slide separators, per
      data-model.md's Slide Deck entity (FR-002, FR-003), (c) the `npx @marp-team/marp-cli
      <deck>.md` render invocation with no repo-level Node setup required (FR-001), and (d) an
      explicit statement that deck content — including the sample deck — is hand-authored/curated
      and that generating slides from git history or diffs is out of scope (FR-005)

**Checkpoint**: Foundation ready — user story work can now begin

---

## Phase 3: User Story 1 - Author a deck summarizing a completed change (Priority: P1) 🎯 MVP

**Goal**: A contributor can turn an existing decision/ADR/spec into a new Marp deck under
`docs/slides/` using only `docs/slides/README.md`, and render it with the documented `npx`
command.

**Independent Test**: Take an existing decision/spec document, write a new Markdown deck under
`docs/slides/` following the documented convention, and render it to a viewable slide deck using
only the documented `npx` command (spec.md User Story 1).

### Validation for User Story 1

- [X] T003 [P] [US1] Execute quickstart.md Scenario 2 end-to-end: following only
      `docs/slides/README.md`, author a scratch example deck (e.g.
      `docs/slides/_scratch-example.md`) from an existing document under `docs/decisions/`, with
      Marp front matter and at least two slides; render it with `npx @marp-team/marp-cli
      docs/slides/_scratch-example.md -o /tmp/_scratch-example.html`; confirm it renders without
      error and completes in under 5 minutes (SC-001); then delete the scratch file so only
      intentional decks remain committed under `docs/slides/`

**Checkpoint**: At this point, the authoring workflow (README convention + render command) is
proven end-to-end and independently testable

---

## Phase 4: User Story 2 - Reviewer browses the sample deck covering recent repo history (Priority: P2)

**Goal**: A reviewer can open one sample deck and identify every major repo-history theme from
PRs #1-#52 without cross-referencing git history, decisions, or specs.

**Independent Test**: Open the sample deck and confirm it contains a distinct, identifiable slide
or section for each of the 12 major merged-PR themes listed in spec.md's scope (spec.md User
Story 2).

### Implementation for User Story 2

- [X] T004 [P] [US2] Author `docs/slides/ai-sdlc-bootstrap-overview.md` with Marp front matter and
      one distinct slide or clearly labeled section for each of the 12 named themes (FR-004):
      AI-SDLC bootstrap, requirements transcripts, context bootstrap docs, project constitution
      ratification, gh-agent-board tooling, writing style guide, MCP config, Context7
      instructions, Brewfile dev setup, GitHub Issues/Spec Kit boundary docs, CI/CD bootstrap, CI
      stabilization, and Java testing framework alignment (JUnit 5 + Mockito + AssertJ + JaCoCo);
      hand-curate content from `docs/decisions/`, `docs/architecture/adr/`, `docs/product/`,
      `AGENTS.md`, `.github/instructions/context7.instructions.md`, and `Brewfile` per
      research.md, not generated from git history/diffs (FR-005)

- [X] T005 [US2] Execute quickstart.md Scenario 1: render
      `docs/slides/ai-sdlc-bootstrap-overview.md` with `npx @marp-team/marp-cli
      docs/slides/ai-sdlc-bootstrap-overview.md -o /tmp/ai-sdlc-bootstrap-overview.html`; confirm
      the command completes without error and the output contains all 12 themes as distinct
      slides/sections, each understandable without consulting git history (SC-002) (depends on
      T004)

**Checkpoint**: At this point, User Stories 1 AND 2 both work independently — the sample deck
exists, renders cleanly, and covers every required theme

---

## Phase 5: User Story 3 - Share a deck as PDF/HTML with people who don't use Marp (Priority: P3)

**Goal**: A presenter can export any deck to a static PDF and/or HTML file using only documented
commands, with no manual troubleshooting.

**Independent Test**: Run the documented export command/script against an existing deck and
confirm a PDF and/or HTML file is produced (spec.md User Story 3).

### Implementation for User Story 3

- [X] T006 [US3] Add an "Exporting decks" section to `docs/slides/README.md` documenting
      `npx @marp-team/marp-cli <deck>.md --pdf` and `npx @marp-team/marp-cli <deck>.md --html` as
      manual, on-demand commands, with no Maven plugin, npm script, or CI wiring (FR-006;
      research.md Export workflow) (depends on T002 — same file)

- [X] T007 [US3] Execute quickstart.md Scenario 3: run
      `npx @marp-team/marp-cli docs/slides/ai-sdlc-bootstrap-overview.md --pdf` and
      `npx @marp-team/marp-cli docs/slides/ai-sdlc-bootstrap-overview.md --html`; confirm both a
      `.pdf` and a `.html` file are produced alongside the source with no manual troubleshooting
      beyond the documented commands (SC-003) (depends on T004, T006)

**Checkpoint**: All three user stories are independently functional — authoring, reviewing, and
exporting all work end-to-end

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final validation across all user stories

- [X] T008 [P] Run the full quickstart.md validation checklist (all four items — Scenario 1
      renders with all 12 themes, Scenario 2 completable from README alone, Scenario 3 produces
      both PDF and HTML, README states hand-authored/no-auto-generation) and confirm every item
      passes

- [X] T009 [P] Proofread `docs/slides/README.md` and `docs/slides/ai-sdlc-bootstrap-overview.md`
      for correct Marp front matter syntax, valid `---` slide separators, and working
      cross-references to `docs/decisions/`, `docs/architecture/adr/`, `docs/product/`,
      `AGENTS.md`, and `Brewfile`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion — BLOCKS all user stories
- **User Stories (Phase 3-5)**: All depend on Foundational phase completion
  - US1 (T003) has no dependency on US2/US3 and can run in parallel with US2's T004
  - US2 (T004-T005) has no dependency on US1/US3
  - US3 (T006-T007) depends on T002 (README) and, for T007, on T004 (sample deck) and T005
    (rendered/validated sample deck)
- **Polish (Phase 6)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) — no dependency on US2/US3
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) — no dependency on US1/US3
- **User Story 3 (P3)**: Can start after Foundational (Phase 2) for T006 (README edit); T007
  additionally needs the US2 sample deck (T004) to exist

### Parallel Opportunities

- T003 (US1 scratch-deck validation) and T004 (US2 sample deck authoring) touch different files
  and can run in parallel once T002 is done
- T008 and T009 (Polish) touch different concerns and can run in parallel once all prior phases
  are complete

---

## Parallel Example: Post-Foundational

```bash
# Once T001-T002 are complete, launch these together:
Task: "Execute quickstart.md Scenario 2 scratch-deck validation (US1) — docs/slides/_scratch-example.md"
Task: "Author docs/slides/ai-sdlc-bootstrap-overview.md sample deck (US2)"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (`docs/slides/README.md`)
3. Complete Phase 3: User Story 1 validation
4. **STOP and VALIDATE**: Confirm a contributor can author and render a deck from README alone
5. This alone satisfies the issue's "Marp tooling is installed/documented" acceptance criterion

### Incremental Delivery

1. Setup + Foundational → `docs/slides/README.md` exists and documents authoring (MVP foundation)
2. Add User Story 1 validation → authoring workflow proven (MVP!)
3. Add User Story 2 → sample deck exists and covers all 12 themes → satisfies issue's core
   acceptance criteria
4. Add User Story 3 → export documented and proven → satisfies remaining acceptance criteria
5. Polish → full quickstart checklist confirmed green

---

## Notes

- No `[P]` conflicts: T002 and T006 both edit `docs/slides/README.md` sequentially (T006 depends
  on T002); T004 creates a distinct new file so it can run in parallel with T003
- This feature has no code, so "tests" above are the manual quickstart.md scenarios acting as
  acceptance validation, not automated test suites
- Commit after each task or logical group
- Stop at any checkpoint to validate a story independently
