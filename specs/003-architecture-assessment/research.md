# Phase 0 Research: Architecture Assessment

No `NEEDS CLARIFICATION` markers remain in the Technical Context — the spec was fully confirmed
via the recorded `aisdlc-grilling` session (`specs/intake/2026-09-15-architecture-assessment.md`).
This file records the resulting decisions and the alternatives considered during planning.

## Decision: Skill naming and location

- **Decision**: Two new skills, `rabbit-architecture-assessment-tier` and
  `rabbit-architecture-assessment-rollup`, each under `.agents/skills/<name>/SKILL.md`, each with
  a companion prompt at `.github/prompts/<name>.prompt.md`.
- **Rationale**: `/memories/repo/naming-conventions.md` requires the `rabbit-` prefix for any new
  custom (non-framework) skill/prompt/tool/agent, to disambiguate from `speckit-*`/`aisdlc-*`
  framework-managed artifacts. `rabbit-archive-to-markdown` is the existing precedent for this
  skill+prompt pairing shape.
- **Alternatives considered**: A single combined skill handling both per-tier assessment and
  rollup — rejected because the spec (User Story 1 vs. User Story 2/3, FR-008) requires the
  rollup to be invocable and gated independently of per-tier runs, and a combined skill would
  blur that hard gate's boundary.

## Decision: Output location (`meta/` vs `docs/`)

- **Decision**: Generated assessments live under a new top-level `meta/architecture-assessment/`
  folder, not under `docs/`.
- **Rationale**: FR-014 and the spec's Assumptions require `meta/` to stay structurally separate
  from AI-SDLC's `docs/` durable-context tree; the sibling `002-rabbit-wiki-lifecycle` feature is
  expected to share the same top-level `meta/` folder via a distinct subdirectory
  (`meta/rabbit-wiki/`), so this feature reuses `meta/` rather than creating a second top-level
  folder.
- **Alternatives considered**: `docs/architecture/assessment/` — rejected per the confirmed
  grilling decision, to avoid entangling generated, potentially-stale-on-regeneration assessment
  output with AI-SDLC's curated durable context in `docs/`.

## Decision: 16-factor grounding source

- **Decision**: The per-tier skill's 16-factor table must be grounded in
  `docs/context/sources/2026-09-14-twelve-to-sixteen-factor-app.md` (the archived source for
  Google Cloud's AI 16-factor model), not the skill author's own recollection of the framework.
- **Rationale**: FR-005 and the spec's Assumptions name this file as the sole in-scope 16-factor
  variant; Constitution Principle IV (Context-Grounded Change) requires citing concrete evidence.
- **Alternatives considered**: Re-deriving the 16 factors from general knowledge each run —
  rejected; would risk drift between per-tier assessments if factor definitions were
  paraphrased differently across runs.

## Decision: Mermaid diagram validation

- **Decision**: The rollup skill must validate each of its 3 generated Mermaid blocks (C1, C2,
  C3) with the repo's available Mermaid validation tool before writing `README.md`.
- **Rationale**: FR-011 requires valid Mermaid syntax; validating before write avoids shipping a
  broken diagram in the one file meant to be the assessment's human-facing entry point (FR-013,
  SC-002).
- **Alternatives considered**: Skipping validation and relying on manual review — rejected, since
  it directly risks SC-002 (an onboarding engineer must be able to read the diagrams
  successfully without opening individual tier files).

## Decision: Rollup gating mechanism

- **Decision**: The rollup skill enumerates the 7 fixed tier filenames, checks each file exists
  and contains the `## Context`, `## Findings`, `## Recommendation`, and `## 16-Factor
  Assessment` headings; any missing or structurally invalid file blocks the run before any
  Mermaid generation or write begins.
- **Rationale**: FR-009/FR-010 and User Story 3 require a hard, all-or-nothing gate with an exact
  list of missing/invalid tiers reported — never a partial `README.md`.
- **Alternatives considered**: Best-effort rollup that fills in placeholders for missing tiers —
  explicitly rejected by FR-010 ("MUST NOT create or modify `README.md`" when incomplete).

## Decision: No automated test suite

- **Decision**: Validate this feature manually via `quickstart.md` (run each skill, inspect
  output), rather than adding an automated test harness.
- **Rationale**: These are natural-language skill definitions interpreted by an agent, not
  compiled/interpreted application code; the repo has no existing harness for skill-level
  behavior, and Constitution Principle V (Incremental Test Hardening) targets *application
  behavior changes*, which this feature explicitly does not make (spec Assumptions: "not
  application runtime code").
- **Alternatives considered**: Writing a scripted checker (e.g., a shell script asserting file
  existence/headings) — considered useful as an optional convenience but not required by any FR;
  left out of scope to avoid inventing an unrequested automation surface. `speckit.tasks` may
  still choose to add a lightweight manual-verification task instead.

## Decision: Track the skill-tailoring A/B comparison as a spike, not drop it

- **Decision**: Run a skill-tailoring A/B comparison — assess one tier once with the dedicated
  `rabbit-architecture-assessment-tier` skill and once with a generic, untailored prompt covering
  the same 16-factor model — and record a qualitative quality comparison here.
- **Rationale**: Raised in the 2026-09-15 client feedback recap
  (`meta/rabbit-wiki/wiki/2026-09-15-architecture-assessment-recap-part-2.md`) as a way to
  validate that the dedicated skill's structure/execution model (parallel per-factor subagents,
  fixed headings) produces materially better output than a generic prompt would. This is
  process/experimentation, not a functional requirement on the artifact format, so it is tracked
  as a `research.md` entry plus a `tasks.md` spike task rather than an FR.
- **Alternatives considered**: Dropping the comparison entirely — explicitly rejected by the
  2026-09-15 recap feedback; the client asked that this not be silently dropped.
- **Result**: Spike executed 2026-09-15 on `cart-microservice` — one run via the dedicated
  `rabbit-architecture-assessment-tier` skill (see `meta/architecture-assessment/cart-microservice.md`),
  one run via a bare generic prompt ("assess against 12-factor + 4 AI-era factors, score 1-5,
  give findings and a recommendation") with no fixed headings, no execution-model guidance, and
  no repo-specific grounding instructions.
  - **Structure/consistency**: the tailored skill produced a fully structured, machine-checkable
    output (exact `## Context`/`## Findings`/`## Recommendation`/`## 16-Factor Assessment`
    headings, `Gap to 5`/`Quick Fix` columns, `N/A` for factors XIII-XVI) that the rollup skill's
    hard gate can validate. The generic run used free-form prose headings, scored XIII as `0/5`
    instead of `N/A` (structurally invalid for the rollup gate), and had no Gap-to-5/Quick-Fix
    equivalent at all — it would fail the rollup's structural-validity check outright.
  - **Coverage gap the generic run caught that the tailored run missed**: the generic run
    inspected `SecurityConfiguration` and found `permitAll()`/CSRF-disabled/no-input-validation —
    a real, concrete security finding — and separately caught that `ShoppingCartImpl` is
    `@Scope(SCOPE_SESSION)`, a statefulness violation (Factor VI/XIV). Neither the security gap
    nor the session-scope finding appears in the tailored `cart-microservice.md` output, because
    the tailored skill's Step 2 evidence list (`application.yml`, `pom.xml`, `Dockerfile`,
    `README.md`, package layout) does not explicitly direct evidence-gathering into
    `SecurityConfiguration` or scope annotations the way the generic prompt's open-ended
    "assess against 12-factor" framing happened to.
  - **Where the tailored run was still stronger**: the tailored output's explanations cite
    concrete file paths and class names consistently across all 16 rows (not just the ones the
    generic run happened to inspect), includes the required Recommendation sizing/risk/time-on-
    task fields the generic run entirely omitted, and is directly consumable by the rollup gate.
  - **Conclusion**: the dedicated skill wins decisively on structural consistency and
    machine-checkability (its entire value proposition), but this spike surfaced a real content
    gap — Step 2's evidence list should also name `SecurityConfiguration`/`*Config` classes and
    `@Scope` annotations explicitly, since a generic prompt found them and the tailored one
    didn't. Recorded as a follow-up improvement candidate for the tier skill rather than a blocker
    for this iteration (out of scope for FR-018-FR-023; would need its own iteration/FR if
    pursued). No change made to `cart-microservice.md` or the tier skill as part of this spike.
