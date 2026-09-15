# Contract: `rabbit-architecture-assessment-rollup` skill

This is a skill-invocation contract (inputs/outputs of an agent skill), not a network API.

## Input

- No target argument — the rollup always operates over the full fixed set of 7 tier assessment
  files under `meta/architecture-assessment/`.

## Preconditions / Validation (hard gate — FR-009, FR-010)

- MUST check that all 7 expected tier files exist under `meta/architecture-assessment/`.
- MUST check that each existing file is structurally valid: contains the `## Context`,
  `## Findings`, `## Recommendation`, and `## 16-Factor Assessment` headings (see
  `../data-model.md` validity rule). A structurally invalid file is treated identically to a
  missing file for gating purposes.
- If any of the 7 tiers is missing or invalid:
  - MUST NOT create or modify `meta/architecture-assessment/README.md`.
  - MUST report the exact list of missing/invalid tier names (not just a generic failure).
  - MUST NOT perform any per-tier 16-factor assessment itself (FR-008) — it only reads existing
    tier files, it never substitutes or repairs one.

## Output (on success — all 7 tiers present and valid)

- Writes exactly one file: `meta/architecture-assessment/README.md` (FR-011).
- File MUST contain, each as a distinct fenced Mermaid code block:
  - One C1 (System Context) diagram covering the whole system (all 7 tiers).
  - One C2 (Container) diagram covering the whole system (all 7 tiers).
  - One C3 (Component) diagram scoped to `api-gateway-microservice` only.
- MUST NOT contain a C4-Code (level 4) diagram (FR-012).
- MUST function as the human-facing index: identify or link to all 7 per-tier assessment files
  (FR-013).
- Each Mermaid block SHOULD be validated for syntax before write (see `../research.md`).

## Idempotency

- Re-running after a prior successful rollup fully regenerates `README.md` from the current
  state of the 7 tier files (FR-017) — never appends to or leaves stale content from the
  previous version.
