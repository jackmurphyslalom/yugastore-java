---

description: "Task list for Architecture Assessment feature"
---

# Tasks: Architecture Assessment

**Input**: Design documents from `/specs/003-architecture-assessment/`

**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/](./contracts/), [quickstart.md](./quickstart.md)

**Tests**: No automated test suite is added (per `research.md` "Decision: No automated test suite" — these are Markdown-generation agent skills, not compiled/interpreted application code). Verification instead uses manual runs of the two skills against the scenarios in `quickstart.md`, captured below as explicit tasks per user story.

**Organization**: Tasks are grouped by user story (US1, US2, US3) to enable independent implementation and verification of each story, per `spec.md`'s priorities (US1: P1, US3: P1, US2: P2).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

Single project — prompt/skill tooling only (per `plan.md`'s Project Structure), no `src/`/`backend`/`frontend` split:

- Skills: `.agents/skills/rabbit-architecture-assessment-{tier|rollup}/SKILL.md`
- Prompts: `.github/prompts/rabbit-architecture-assessment-{tier|rollup}.prompt.md`
- Generated output (produced by running the skills, not authored by these tasks): `meta/architecture-assessment/{tier-name}.md` and `meta/architecture-assessment/README.md`
- Doc cross-reference: `docs/architecture/overview.md`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Scaffold the two skill/prompt file pairs per `/memories/repo/naming-conventions.md`'s `rabbit-` convention.

- [X] T001 Create `.agents/skills/rabbit-architecture-assessment-tier/` and `.agents/skills/rabbit-architecture-assessment-rollup/` directories (each will hold a `SKILL.md`)
- [X] T002 [P] Create empty `.github/prompts/rabbit-architecture-assessment-tier.prompt.md` and `.github/prompts/rabbit-architecture-assessment-rollup.prompt.md` prompt files (to be filled in during T005/T010)

**Checkpoint**: Directory/file scaffolding exists; no content authored yet.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Fix the shared facts and conventions both skills MUST agree on before either is authored — if the tier skill's output headings and the rollup's structural-validity gate disagree, the whole feature breaks (FR-009/FR-010 depend on FR-004/FR-005 producing detectable sections).

**⚠️ CRITICAL**: T003 MUST complete before any skill-authoring task in Phase 3 or Phase 4.

- [X] T003 Read `docs/context/sources/2026-09-14-twelve-to-sixteen-factor-app.md` and `docs/architecture/overview.md`, then fix (for reuse verbatim in T004 and T009): (a) the ordered 16-factor list I-XVI with each factor's name, (b) the exact `login-microservice` WIP/unwired wording to cite, and (c) the exact section-heading strings both skills must use identically — e.g. `## SCQA Overview` and `## 16-Factor Assessment` — so the tier skill's output (producer, US1) and the rollup's structural-validity check (gate, US3) detect the same markers (data-model.md "Validity rule")

**Checkpoint**: Shared reference facts and heading conventions are fixed — skill authoring can begin.

---

## Phase 3: User Story 1 - Assess a single tier (Priority: P1) 🎯 MVP

**Goal**: A per-tier assessment skill that writes `meta/architecture-assessment/{tier-name}.md` with an SCQA overview and a complete 16-factor table for one of the 7 recognized tiers, rejecting any other target.

**Independent Test**: Run the skill against exactly one tier (e.g. `products-microservice`) and confirm the resulting file exists, contains both required sections, and covers all 16 factors (including any marked "N/A").

### Implementation for User Story 1

- [X] T004 [US1] Author `.agents/skills/rabbit-architecture-assessment-tier/SKILL.md`: frontmatter (`name: rabbit-architecture-assessment-tier`, description, license) per `/memories/repo/naming-conventions.md`; validation step rejecting any target outside the 7 tiers in `data-model.md` (including `.agents/`, `.specify/`, `.github/` paths) with no file written on rejection (FR-001, FR-002); output step writing `meta/architecture-assessment/{tier-name}.md` (FR-003) using the T003 heading conventions, containing an SCQA overview (FR-004) and a 16-factor table grounded in `docs/context/sources/2026-09-14-twelve-to-sixteen-factor-app.md` (FR-005) with factors XIII-XVI marked `N/A` when no AI/LLM component exists (FR-006); a `login-microservice`-specific step recording its WIP/unwired finding from `docs/architecture/overview.md` (FR-007); full-overwrite behavior on re-run (FR-016); reference `contracts/rabbit-architecture-assessment-tier.md` as the authoritative contract
- [X] T005 [P] [US1] Author `.github/prompts/rabbit-architecture-assessment-tier.prompt.md` that invokes the `rabbit-architecture-assessment-tier` skill with a required target-tier argument
- [X] T006 [P] [US1] Manually run the skill for target `products-microservice` (`quickstart.md` Scenario 1, steps 1-3) and confirm `meta/architecture-assessment/products-microservice.md` exists with an SCQA overview and a 16-factor table (factors XIII-XVI marked `N/A`)
- [X] T007 [P] [US1] Manually run the skill for target `login-microservice` (`quickstart.md` Scenario 1, step 4) and confirm its file additionally records the WIP/unwired finding
- [X] T008 [P] [US1] Manually run the skill with an out-of-scope target, e.g. `.github` (`quickstart.md` Scenario 2) and confirm no file is written and the target is reported as out of scope

**Checkpoint**: User Story 1 is fully functional and independently verifiable — a single tier can be assessed correctly and out-of-scope targets are rejected.

---

## Phase 4: User Story 3 - Rollup refuses to run on incomplete input (Priority: P1)

**Goal**: The rollup skill's hard gate — it must refuse to write/modify `README.md` and must name every missing or structurally invalid tier whenever fewer than all 7 valid tier files exist.

**Independent Test**: Delete or omit one or more of the 7 expected tier files, run the rollup skill, and confirm it exits without writing or modifying `README.md`, naming every missing tier.

**Note**: This phase and Phase 5 (User Story 2) both author `.agents/skills/rabbit-architecture-assessment-rollup/SKILL.md` — the gate (this phase, P1) is authored first since it must exist before the success path (Phase 5, P2) can safely extend the same file.

### Implementation for User Story 3

- [X] T009 [US3] Author `.agents/skills/rabbit-architecture-assessment-rollup/SKILL.md`: frontmatter (`name: rabbit-architecture-assessment-rollup`, description, license); gate step enumerating the 7 fixed tier filenames under `meta/architecture-assessment/` and checking each exists and is structurally valid (contains both T003's SCQA and 16-factor headings) (FR-009); on any missing/invalid tier, MUST NOT create or modify `meta/architecture-assessment/README.md` and MUST report the exact list of missing/invalid tier names (FR-010); explicit statement that the rollup MUST NOT itself perform per-tier 16-factor assessment (FR-008); reference `contracts/rabbit-architecture-assessment-rollup.md` as the authoritative contract — leave the success-path (C1/C2/C3 generation) section as a placeholder for T014
- [X] T010 [P] [US3] Author `.github/prompts/rabbit-architecture-assessment-rollup.prompt.md` that invokes the `rabbit-architecture-assessment-rollup` skill with no target argument
- [X] T011 [US3] Manually run the rollup skill with fewer than 7 tier files present (`quickstart.md` Scenario 3, steps 1-3) and confirm `meta/architecture-assessment/README.md` is NOT created/modified and the exact missing tiers are reported
- [X] T012 [US3] Manually run the tier skill (T004) for the 5 tiers not yet covered by T006/T007 — `eureka-server-local`, `checkout-microservice`, `cart-microservice`, `api-gateway-microservice`, `react-ui` — so all 7 tier files exist and are valid
- [X] T013 [US3] With all 7 tier files present, delete or empty one tier file, re-run the rollup skill (`quickstart.md` Scenario 3, step 4), confirm it re-detects and names that tier as missing/invalid, then restore the deleted/emptied file's content (re-run T004 for that tier) so all 7 are valid again for Phase 5

**Checkpoint**: The rollup's hard gate gate is fully functional and independently verifiable — incomplete or invalid input is always refused with an exact report, never a partial write.

---

## Phase 5: User Story 2 - Roll up completed tier assessments into a C4 model (Priority: P2)

**Goal**: With all 7 tier files present and valid, the rollup skill writes `meta/architecture-assessment/README.md` containing a C1 (System Context), a C2 (Container), and a C3 (Component, `api-gateway-microservice`-only) Mermaid diagram, plus an index linking all 7 tier files.

**Independent Test**: With all 7 tier files present, run the rollup skill and confirm `README.md` is created/updated containing exactly one C1, one C2, and one C3 diagram, all in valid Mermaid syntax.

### Implementation for User Story 2

- [X] T014 [US2] Extend `.agents/skills/rabbit-architecture-assessment-rollup/SKILL.md` (T009) with the success-path steps: when all 7 tiers are present and valid, generate one C1 (System Context, whole system) diagram, one C2 (Container, whole system) diagram, and one C3 (Component, `api-gateway-microservice`-only) diagram as fenced Mermaid blocks (FR-011); explicitly exclude any C4-Code (level 4) diagram (FR-012); validate each Mermaid block with this repo's Mermaid validator/preview tooling before writing (per `research.md`); write an index identifying/linking all 7 per-tier files so the file functions as the human-facing entry point (FR-013); full idempotent overwrite on every successful re-run (FR-017)
- [X] T015 [P] [US2] Add a one-line cross-reference in `docs/architecture/overview.md` pointing to `meta/architecture-assessment/README.md` (FR-015)
- [X] T016 [US2] Manually run the rollup skill with all 7 valid tier files present (`quickstart.md` Scenario 4, steps 1-3) and confirm `meta/architecture-assessment/README.md` is created with exactly one C1, one C2, and one C3 Mermaid block, and links/identifies all 7 tier files
- [X] T017 [P] [US2] Validate each of the 3 Mermaid blocks in the generated `README.md` with the repo's Mermaid validator (`quickstart.md` Scenario 4, step 4)
- [X] T018 [US2] Confirm `docs/architecture/overview.md` carries the T015 cross-reference (`quickstart.md` Scenario 4, step 5)

**Checkpoint**: All three user stories are independently functional — single-tier assessment, rollup gating, and rollup success-path C4 generation all verified.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Confirm idempotent regeneration behavior and complete the full quickstart pass.

- [X] T019 [P] Run `quickstart.md` Scenario 5: re-run the tier skill for an already-assessed tier and confirm its file is fully overwritten (not appended to); re-run the rollup skill after a successful run and confirm `README.md` is fully regenerated with no stale content
- [X] T020 Run the complete `quickstart.md` (all 5 scenarios) end to end as a final sign-off pass

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion — T003 BLOCKS all skill-authoring tasks in Phase 3 and Phase 4
- **User Story 1 (Phase 3)**: Depends only on Foundational (T003) — independent of US2/US3
- **User Story 3 (Phase 4)**: Depends on Foundational (T003); T012/T013 depend on the tier skill authored in T004 (US1) to generate the remaining tier files — this is a real cross-story file dependency, not just priority ordering
- **User Story 2 (Phase 5)**: Depends on User Story 3 (T009) because it extends the same `rabbit-architecture-assessment-rollup/SKILL.md` file, and on T012/T013 (all 7 tier files present and valid)
- **Polish (Phase 6)**: Depends on Phases 3-5 all being complete

### Within Each User Story

- Skill authored before its prompt file (or in parallel, since different files: T004/T005, T009/T010)
- Skill + prompt authored before manual verification runs
- Verification runs within a story may proceed in parallel once their shared prerequisite skill/prompt files exist

### Parallel Opportunities

- T002 (both prompt stub files) can run in parallel
- T005 can run in parallel with T004 (different files); same for T010/T009
- T006, T007, T008 can run in parallel once T004 and T005 are complete (independent verification runs)
- T015 can run in parallel with T014 (different files)
- T017 can run in parallel with other Phase 5 verification once T016 has produced `README.md`
- T019 can run in parallel with T020's setup, though T020 itself is a full sequential pass

---

## Parallel Example: User Story 1

```bash
# Author skill and prompt together (different files):
Task: "Author .agents/skills/rabbit-architecture-assessment-tier/SKILL.md"
Task: "Author .github/prompts/rabbit-architecture-assessment-tier.prompt.md"

# Once both exist, run independent verification in parallel:
Task: "Run skill for products-microservice, verify SCQA + 16-factor table"
Task: "Run skill for login-microservice, verify WIP finding"
Task: "Run skill with out-of-scope target, verify rejection"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (T003 — CRITICAL, blocks both skills)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: T006-T008 confirm the tier skill independently
5. This alone delivers onboarding value (single-tier assessments) even before the rollup exists

### Incremental Delivery

1. Setup + Foundational → shared conventions fixed
2. User Story 1 → tier skill usable standalone (MVP)
3. User Story 3 → rollup's hard gate proven safe before it ever produces output
4. User Story 2 → rollup's success path (C4 model) completes the feature
5. Polish → idempotency and full quickstart sign-off

### Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- No automated tests are added (see `research.md`); verification tasks run the actual skills per `quickstart.md`
- Commit after each task or logical group
- Stop at any checkpoint to validate a story independently
