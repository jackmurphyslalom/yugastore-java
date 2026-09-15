# Feature Specification: Architecture Assessment

**Feature Branch**: `003-architecture-assessment`

**Created**: 2026-09-15

**Status**: Draft

**Input**: User description: "Build a reusable Architecture Assessment capability for onboarding
to this Yugastore codebase: a per-tier assessment skill and a separate C4-rollup skill. Assess
each of the 7 application tiers (eureka-server-local, products-microservice,
checkout-microservice, cart-microservice, api-gateway-microservice, login-microservice,
react-ui) against Google Cloud's AI 16-factor model, writing
`meta/architecture-assessment/{tier-name}.md` per tier (SCQA overview + 16-factor scoring
table). A separate rollup skill reads all 7 completed tier files and writes
`meta/architecture-assessment/README.md` containing a C4 model (C1 System Context, C2
Container for the whole system, one C3 Component diagram for api-gateway-microservice only,
all in Mermaid). The rollup hard-gates on all 7 tier files existing. Confirmed via an
aisdlc-grilling session recorded in
`specs/intake/2026-09-15-architecture-assessment.md`; treat those decisions as settled."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Assess a single tier (Priority: P1)

An engineer onboarding to this codebase invokes the per-tier assessment skill against one
application tier (for example, `products-microservice`). The skill produces
`meta/architecture-assessment/products-microservice.md`, containing an SCQA overview for that
tier and a scoring table against all 16 factors of Google Cloud's AI 16-factor model, with
factors XIII-XVI marked "N/A" where the tier has no AI component today.

**Why this priority**: This is the atomic unit of value — a single completed tier assessment is
independently useful for onboarding even before the other 6 tiers or the rollup exist.

**Independent Test**: Run the skill against exactly one tier and confirm the resulting file
exists, contains both required sections, and covers all 16 factors (12 classic + 4 AI-era,
including any marked "N/A").

**Acceptance Scenarios**:

1. **Given** no assessment file yet exists for `products-microservice`, **When** the per-tier
   assessment skill is invoked for that tier, **Then**
   `meta/architecture-assessment/products-microservice.md` is created with an SCQA overview and
   a complete 16-factor table.
2. **Given** a tier has no AI/LLM component today, **When** it is assessed, **Then** factors
   XIII (Prompts as code), XIV (State as a service), XV (Observability for non-determinism), and
   XVI (Trust & safety by design) are each explicitly marked "N/A" in that tier's table, rather
   than omitted or scored as failing.
3. **Given** `login-microservice` is flagged WIP/unwired in `docs/architecture/overview.md`,
   **When** it is assessed, **Then** it receives the same full 16-factor treatment as the other 6
   tiers, and its WIP/unwired status is recorded as an explicit finding in its assessment file
   rather than causing the tier to be skipped or lightly assessed.

---

### User Story 2 - Roll up completed tier assessments into a C4 model (Priority: P2)

Once all 7 tier assessment files exist, an engineer invokes the rollup skill. It reads all 7
files and writes `meta/architecture-assessment/README.md`, which serves as the human-facing
entry point into the assessment and contains a system-wide C1 (System Context) diagram, a
system-wide C2 (Container) diagram, and one C3 (Component) diagram scoped to
`api-gateway-microservice` only — all as Mermaid diagrams.

**Why this priority**: The rollup depends on all 7 per-tier assessments (User Story 1)
completing first; it is the second, dependent step in the workflow.

**Independent Test**: With all 7 tier files present, run the rollup skill and confirm
`meta/architecture-assessment/README.md` is created/updated containing exactly one C1 diagram,
one C2 diagram, and one C3 diagram (scoped to api-gateway-microservice), all in valid Mermaid
syntax.

**Acceptance Scenarios**:

1. **Given** all 7 tier assessment files exist under `meta/architecture-assessment/`, **When**
   the rollup skill is invoked, **Then** `meta/architecture-assessment/README.md` is written with
   a C1 System Context diagram and a C2 Container diagram covering all 7 tiers, plus a C3
   Component diagram for `api-gateway-microservice` only, each as a Mermaid code block.
2. **Given** the rollup skill has produced `meta/architecture-assessment/README.md`, **When** an
   engineer opens that file, **Then** it functions as the index/entry point into the assessment
   (linking to or otherwise identifying all 7 per-tier files).

---

### User Story 3 - Rollup refuses to run on incomplete input (Priority: P1)

An engineer invokes the rollup skill before all 7 tier assessments are complete (for example,
only 4 of 7 tier files exist). The rollup skill refuses to run and reports exactly which tiers
are missing, instead of producing a partial or silently incomplete C4 model.

**Why this priority**: This is a correctness/safety guarantee for the rollup output and must
hold from the first release of the rollup skill — a silently incomplete architecture diagram is
worse than no diagram, so this gate is as critical as the per-tier assessment itself.

**Independent Test**: Delete or omit one or more of the 7 expected tier files, run the rollup
skill, and confirm it exits without writing or modifying `README.md`, and its output names every
missing tier.

**Acceptance Scenarios**:

1. **Given** only 4 of the 7 required tier assessment files exist under
   `meta/architecture-assessment/`, **When** the rollup skill is invoked, **Then** it does not
   create or modify `meta/architecture-assessment/README.md` and instead reports the exact list
   of the 3 missing tier names.
2. **Given** all 7 tier files exist but one is subsequently deleted, **When** the rollup skill is
   invoked again, **Then** it re-detects the now-missing tier and refuses to run, naming that
   tier.

---

### Edge Cases

- What happens if a per-tier assessment is re-run for a tier that already has an assessment
  file? The skill overwrites that tier's file with a freshly generated assessment (assessments
  are not designed to be hand-edited and preserved across re-runs).
- What happens if the rollup skill is invoked while a tier file exists but is empty or otherwise
  malformed (missing the SCQA or 16-factor sections)? The rollup treats a structurally invalid
  tier file the same as a missing tier for gating purposes, and reports it as such.
- How does the per-tier assessment skill handle a tier name that is not one of the 7 recognized
  application tiers (for example, a typo, or a path under `.agents/`, `.specify/`, or
  `.github/`)? The skill refuses to produce an assessment for any tier outside the 7 recognized
  application tiers and reports that the requested target is out of scope.
- What happens to `meta/architecture-assessment/README.md` if the rollup skill is run a second
  time after it has already produced a valid rollup? It regenerates the file from the current
  state of all 7 tier files (idempotent overwrite), so the C4 model always reflects the latest
  per-tier assessments.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The per-tier assessment skill MUST accept exactly one of the 7 recognized
  application tiers as its target: `eureka-server-local`, `products-microservice`,
  `checkout-microservice`, `cart-microservice`, `api-gateway-microservice`,
  `login-microservice`, or `react-ui`.
- **FR-002**: The per-tier assessment skill MUST refuse to assess any target outside those 7
  tiers, including AI-SDLC framework content under `.agents/`, `.specify/`, and `.github/`, and
  MUST report that the target is out of scope.
- **FR-003**: The per-tier assessment skill MUST write its output to
  `meta/architecture-assessment/{tier-name}.md`, using the tier's exact directory name.
- **FR-004**: Each per-tier assessment file MUST contain an SCQA overview (Situation,
  Complication, Question, Answer/recommendation) specific to that tier.
- **FR-005**: Each per-tier assessment file MUST contain a scoring/assessment table covering all
  16 factors of Google Cloud's AI 16-factor model (the classic 12-factor principles plus XIII
  Prompts as code, XIV State as a service, XV Observability for non-determinism, XVI Trust &
  safety by design), grounded in
  `docs/context/sources/2026-09-14-twelve-to-sixteen-factor-app.md`.
- **FR-006**: For any tier with no AI/LLM component today, the per-tier assessment skill MUST
  mark factors XIII-XVI as "N/A" in that tier's table rather than omitting them or scoring them
  as deficient.
- **FR-007**: The `login-microservice` assessment MUST receive the same full 16-factor
  treatment as the other 6 tiers and MUST explicitly record its WIP/unwired status (per
  `docs/architecture/overview.md`) as a finding within its assessment file.
- **FR-008**: A separate rollup skill MUST read all 7 tier assessment files from
  `meta/architecture-assessment/` and MUST NOT itself perform per-tier 16-factor assessment.
- **FR-009**: The rollup skill MUST verify that all 7 expected tier assessment files exist and
  are structurally valid (contain both an SCQA overview and a 16-factor table) before producing
  any output.
- **FR-010**: If one or more of the 7 tier assessment files is missing or structurally invalid,
  the rollup skill MUST refuse to run, MUST NOT create or modify
  `meta/architecture-assessment/README.md`, and MUST report exactly which tiers are missing or
  invalid.
- **FR-011**: When all 7 tier files are present and valid, the rollup skill MUST write
  `meta/architecture-assessment/README.md` containing three Mermaid diagrams: one C1 (System
  Context) diagram covering the whole system, one C2 (Container) diagram covering the whole
  system, and one C3 (Component) diagram scoped to `api-gateway-microservice` only.
- **FR-012**: The rollup skill MUST NOT produce a C4-Code (level 4) diagram; that level is
  explicitly out of scope.
- **FR-013**: `meta/architecture-assessment/README.md` MUST also function as the human-facing
  entry point/index into the assessment, identifying or linking to all 7 per-tier assessment
  files.
- **FR-014**: The feature MUST add a new top-level `meta/` folder at the repository root (or
  reuse it if another feature has already created it), kept structurally separate from `docs/`.
- **FR-015**: `docs/architecture/overview.md` MUST gain a one-line cross-reference pointing to
  `meta/architecture-assessment/README.md`.
- **FR-016**: Re-running the per-tier assessment skill for a tier that already has an assessment
  file MUST overwrite that tier's existing file with a freshly generated assessment.
- **FR-017**: Re-running the rollup skill after a successful rollup MUST regenerate
  `meta/architecture-assessment/README.md` from the current state of all 7 tier files
  (idempotent overwrite), not append to or leave stale content in the prior version.

### Key Entities *(include if feature involves data)*

- **Tier assessment file**: A single Markdown file at `meta/architecture-assessment/{tier
  name}.md`, one per recognized application tier, containing an SCQA overview and a 16-factor
  scoring table for that tier.
- **AI 16-factor model**: The evaluation framework applied to every tier — the classic 12-factor
  app principles plus 4 AI-era factors (XIII Prompts as code, XIV State as a service, XV
  Observability for non-determinism, XVI Trust & safety by design), sourced from
  `docs/context/sources/2026-09-14-twelve-to-sixteen-factor-app.md`.
- **Rollup index (README.md)**: The single file at `meta/architecture-assessment/README.md`,
  generated from all 7 tier assessment files, containing the C1/C2/C3 Mermaid diagrams and
  serving as the human-facing entry point into the assessment.
- **Application tier**: One of the 7 in-scope deployable units of this codebase
  (`eureka-server-local`, `products-microservice`, `checkout-microservice`,
  `cart-microservice`, `api-gateway-microservice`, `login-microservice`, `react-ui`); explicitly
  excludes AI-SDLC framework content (`.agents/`, `.specify/`, `.github/`).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: All 7 application tiers have a corresponding, complete assessment file under
  `meta/architecture-assessment/`, each covering all 16 factors (with XIII-XVI explicitly marked
  where not applicable).
- **SC-002**: An engineer new to the codebase can read `meta/architecture-assessment/README.md`
  alone and correctly identify all 7 tiers, how they connect at the container level, and the
  internal structure of the api-gateway tier, without opening any tier's individual file.
- **SC-003**: Attempting to run the rollup before all 7 tier files exist produces a clear report
  of the missing tiers 100% of the time, with zero instances of a partial or silently incomplete
  `README.md` being written.
- **SC-004**: `login-microservice`'s WIP/unwired status is visibly called out in its own
  assessment file in 100% of generated assessments, never silently omitted.

## Assumptions

- The 7 application tiers and their directory names are fixed for this feature: they map
  1:1 to the top-level module directories `eureka-server-local`, `products-microservice`,
  `checkout-microservice`, `cart-microservice`, `api-gateway-microservice`,
  `login-microservice`, and `react-ui`.
- "Google Cloud's AI 16-factor model" refers specifically to the framework captured in
  `docs/context/sources/2026-09-14-twelve-to-sixteen-factor-app.md`; no other 16-factor
  variant is in scope.
- All 7 tiers currently have no AI/LLM component, so factors XIII-XVI are expected to be marked
  "N/A" across all initial assessments; this is expected to change only if a tier's actual code
  changes in the future.
- The per-tier assessment skill and the rollup skill are documentation-generation capabilities
  (agent skills/prompts), not application runtime code; this feature does not modify any
  microservice's source code or runtime behavior.
- `meta/` is a new top-level folder not currently tracked by any other feature's durable context
  scaffold; if a sibling feature (e.g., the rabbit-wiki-lifecycle feature) also creates `meta/`,
  both features share the same top-level folder without collision since they use distinct
  subdirectories (`meta/architecture-assessment/` vs. `meta/rabbit-wiki/`).
- No automated CI enforcement of "all 7 tiers assessed" is required by this feature; the
  rollup's hard gate at invocation time is the sole enforcement mechanism.
