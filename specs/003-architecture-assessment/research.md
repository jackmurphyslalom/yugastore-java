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
  and contains both an SCQA heading and a 16-factor table heading/marker; any missing or
  structurally invalid file blocks the run before any Mermaid generation or write begins.
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
