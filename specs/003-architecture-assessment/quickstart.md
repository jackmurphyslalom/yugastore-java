# Quickstart: Architecture Assessment

Manual validation guide — no automated test suite (see `research.md`). Run these scenarios after
implementation to confirm the feature works end to end.

## Prerequisites

- Both skills implemented and discoverable: `.agents/skills/rabbit-architecture-assessment-tier/SKILL.md`
  and `.agents/skills/rabbit-architecture-assessment-rollup/SKILL.md`, each with a companion
  prompt under `.github/prompts/`.
- `docs/context/sources/2026-09-14-twelve-to-sixteen-factor-app.md` and
  `docs/architecture/overview.md` present (both already exist in this repo).

## Scenario 1: Assess a single tier (User Story 1)

1. Invoke the per-tier skill (e.g., via `/rabbit-architecture-assessment-tier`) with target
   `products-microservice`.
2. Confirm `meta/architecture-assessment/products-microservice.md` is created.
3. Open the file and confirm it has:
   - A Context section, a Findings section, and a Recommendation section.
   - A 16-factor table with all 16 rows, each row showing a Score, an Explanation, a `Gap to 5`
     value (`5 − Score`, or `N/A`), and a `Quick Fix` suggestion for any factor scored below 5;
     factors XIII-XVI marked `N/A`.
   - A Findings section stating the tier's load/performance-testing tooling status (or
     explicitly "none identified").
   - A Recommendation section stating an explicit rationale, a T-shirt size (S/M/L/XL), a risk
     category, and both a human and an agent time-on-task estimate.
4. Repeat for a second tier, `login-microservice`, and confirm its file additionally records the
   WIP/unwired finding.

**Expected outcome**: matches spec Acceptance Scenarios 1-3 under User Story 1.

## Scenario 2: Reject an out-of-scope target

1. Invoke the per-tier skill with a target outside the 7 tiers (e.g., `.github`).
2. Confirm no file is written and the skill reports the target as out of scope.

**Expected outcome**: matches spec Edge Cases (out-of-scope target handling), FR-002.

## Scenario 3: Rollup refuses on incomplete input (User Story 3)

1. With fewer than 7 tier files present (e.g., only 4), invoke the rollup skill.
2. Confirm `meta/architecture-assessment/README.md` is NOT created/modified.
3. Confirm the report names exactly the missing tiers.
4. Complete the remaining tier assessments (Scenario 1, repeated), then delete or empty one tier
   file and re-run the rollup; confirm it re-detects and names that tier as missing/invalid.

**Expected outcome**: matches spec Acceptance Scenarios 1-2 under User Story 3, SC-003.

## Scenario 4: Rollup succeeds with all 7 tiers present (User Story 2)

1. Ensure all 7 tier files exist and are structurally valid (repeat Scenario 1 for the remaining
   tiers: `eureka-server-local`, `checkout-microservice`, `cart-microservice`,
   `api-gateway-microservice`, `react-ui`).
2. Invoke the rollup skill.
3. Confirm `meta/architecture-assessment/README.md` is created containing exactly one C1, one
   C2, and one C3 Mermaid block (see `contracts/rabbit-architecture-assessment-rollup.md` for
   required content), that it links/identifies all 7 tier files, and that it contains a
   foundational posture section referencing all 7 tiers with their concrete weaknesses and risk
   levels.
4. Validate each Mermaid block (e.g., with the repo's Mermaid validator/preview tooling).
5. Confirm `docs/architecture/overview.md` carries a one-line cross-reference to
   `meta/architecture-assessment/README.md` (FR-015).

**Expected outcome**: matches spec Acceptance Scenarios 1-2 under User Story 2, SC-002.

## Scenario 5: Idempotent regeneration

1. Re-run the per-tier skill for an already-assessed tier; confirm its file is fully overwritten
   (not appended to).
2. Re-run the rollup skill after a successful run; confirm `README.md` is regenerated in full
   (no stale content from the prior version).

**Expected outcome**: matches spec Edge Cases + FR-016/FR-017.

## Scenario 6: Skill-tailoring A/B comparison spike

1. Assess one tier once with the dedicated `rabbit-architecture-assessment-tier` skill and once
   with a generic, untailored prompt covering the same 16-factor model.
2. Record a qualitative quality comparison of the two outputs in `research.md`.

**Expected outcome**: the comparison is recorded in `research.md`, not dropped (per the
2026-09-15 recap).
