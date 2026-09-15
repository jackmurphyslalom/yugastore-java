# Implementation Plan: Rabbit Wiki Ingestion Lifecycle

**Branch**: `002-rabbit-wiki-lifecycle` | **Date**: 2026-09-15 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/002-rabbit-wiki-lifecycle/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command; its definition describes the execution workflow.

## Summary

Add five new agent-invocable skills under `.agents/skills/` — `rabbit-ingest`, `rabbit-analyze`,
`rabbit-query`, `rabbit-lint`, and `rabbit-session-close` — implementing Karpathy's "LLM Wiki"
capture/analyze/query/lint/close lifecycle over a new `meta/rabbit-wiki/` storage root. `rabbit-ingest`
reuses the existing `rabbit-archive-to-markdown` skill's conversion mechanics but writes to
`meta/rabbit-wiki/sources/{slug}/` (retaining `original.{ext}`, `transformed.md`, `raw.md`) instead of
`docs/context/sources/`. `rabbit-analyze` reads a source's `transformed.md`, drafts or updates
`meta/rabbit-wiki/wiki/{slug}.md`, and extends `meta/rabbit-wiki/ontology.yaml`. `rabbit-query` searches
wiki + ontology, answers with citations, and optionally files a new wiki page. `rabbit-lint` scans the
wiki for contradictions, staleness, orphans, missing pages, and gaps, reporting only (no auto-fix,
no web search). `rabbit-session-close` folds already-drafted session material into the wiki/ontology on
explicit invocation only. This is markdown/YAML skill authoring — no application (microservice) code,
build, or test-suite changes — modeled directly on the existing `rabbit-archive-to-markdown` skill's
single-`SKILL.md`, step-list structure.

## Technical Context

**Language/Version**: N/A (no compiled/interpreted application code). Skills are authored as Markdown
`SKILL.md` files with YAML frontmatter, read and executed by the agent at runtime — the same format as
every existing skill under `.agents/skills/`.

**Primary Dependencies**: The existing `rabbit-archive-to-markdown` skill (reused, unmodified, for its
Markdown-conversion step); the Markdown-conversion tool already available in this environment
(`mcp_markitdown_convert_to_markdown`); no new libraries, packages, or services.

**Storage**: Plain files under a new top-level `meta/rabbit-wiki/` root: `sources/{slug}/` (three files
per asset), `wiki/{slug}.md` (one Markdown page per analyzed asset or query-filed answer), and a single
`ontology.yaml` (structured concepts/categories/relations). No database, no `docs/context/` involvement
(FR-016). `pending_imports/` is a new repo-root intake folder, created on first use.

**Testing**: N/A in the conventional sense — there is no compiled code to unit-test. Validation is
scenario-based: each skill's `SKILL.md` "Steps" are exercised manually per the spec's Acceptance
Scenarios (see `quickstart.md`), the same validation approach already used for
`rabbit-archive-to-markdown` (no `.bats`/JUnit tests exist for that skill either).

**Target Platform**: Agent runtime inside this repo's VS Code / Copilot environment — same execution
context as every other `.agents/skills/*` skill; no server, container, or deployment target.

**Project Type**: Prompt/skill authoring (Markdown + YAML content only) — closest existing analog in
this repo is `tools/gh-agent-board`'s prompt files, but here the deliverable is skills, not scripts.

**Performance Goals**: N/A — human-in-the-loop, single-invocation operations; no throughput/latency
targets beyond "completes within one agent turn per invocation," matching every existing skill.

**Constraints**: MUST NOT modify `docs/product/glossary.md` from any `/rabbit-*` skill (FR-005); MUST
NOT let `/rabbit-session-close` run automatically as a side effect of any other command (FR-009); MUST
NOT let `/rabbit-session-close` perform new research or web lookups (FR-010); MUST NOT let `/rabbit-lint`
auto-run the web searches it flags as gaps (FR-015); all Rabbit Wiki storage MUST live under
`meta/rabbit-wiki/`, distinct from `docs/context/` (FR-016).

**Scale/Scope**: Single repository (`yugastore-java`), five new skill files plus their `meta/rabbit-wiki/`
data directories; no impact on the six existing Spring Boot microservices, `react-ui`, or
`tools/gh-agent-board`.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. Gateway-Only Service Boundary**: Not applicable. No microservice, REST client, or Eureka
  registration is touched; this feature is agent-tooling content only. PASS.
- **II. Consistency-Sensitive Data Paths**: Not applicable. No YCQL/YSQL writes, no interaction with
  `cronos.orders` or `cronos.product_inventory`. PASS.
- **III. Canonical Terminology**: The spec explicitly keeps `meta/rabbit-wiki/ontology.yaml` separate
  from and never merged into `docs/product/glossary.md` (FR-005, confirmed via grilling). This is an
  intentional, spec-confirmed exception to "add new durable terms to the glossary," not a violation:
  the ontology is a distinct, lower-ceremony knowledge structure by design (Assumptions section of the
  spec). No glossary edits are required or permitted by this feature. PASS.
- **IV. Context-Grounded Change**: This plan cites the confirmed spec (`specs/002-rabbit-wiki-lifecycle/spec.md`,
  itself grounded in the 2026-09-15 grilling intake) and the existing `rabbit-archive-to-markdown`
  `SKILL.md` as the structural template being extended. No new unresolved questions were found during
  planning; all storage-path and behavioral decisions were pre-confirmed in the spec. PASS.
- **V. Incremental Test Hardening**: Not applicable in the conventional sense — there is no compiled
  code path to unit-test, consistent with the existing `rabbit-archive-to-markdown` skill (also
  untested by an automated suite). Validation instead relies on the spec's per-story Acceptance
  Scenarios, explicitly exercised in `quickstart.md`. This mirrors the project's existing precedent for
  skill-only changes rather than lowering a code-testing bar. PASS.

No principle is violated; no entries are required in Complexity Tracking.

## Project Structure

### Documentation (this feature)

```text
specs/002-rabbit-wiki-lifecycle/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command)
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
.agents/skills/
├── rabbit-archive-to-markdown/
│   └── SKILL.md              # existing: reused, unmodified conversion mechanics (FR-001)
├── rabbit-ingest/
│   └── SKILL.md               # NEW: FR-001–FR-004 — pending_imports/ intake, slugging,
│                               #      original retention, meta/rabbit-wiki/sources/{slug}/ write
├── rabbit-analyze/
│   └── SKILL.md               # NEW: FR-006, FR-007, FR-017 — wiki entry + ontology extension
├── rabbit-query/
│   └── SKILL.md               # NEW: FR-011–FR-013 — cited search/answer, optional new page
├── rabbit-lint/
│   └── SKILL.md               # NEW: FR-014–FR-015 — health-check report, no auto-fix/search
└── rabbit-session-close/
    └── SKILL.md               # NEW: FR-008–FR-010 — explicit-only session reconciliation

pending_imports/
└── .gitkeep                   # NEW: repo-root intake folder for /rabbit-ingest (created on first use)

meta/rabbit-wiki/
├── ontology.yaml               # NEW: concepts/categories/typed relations (FR-005)
├── sources/
│   └── {YYYY-MM-DD}-{kebab-title}/
│       ├── original.{ext}      # untouched source file (FR-002)
│       ├── transformed.md      # converted output (FR-001, FR-004)
│       └── raw.md               # intermediate/raw conversion (FR-004)
└── wiki/
    └── {slug}.md                # NEW: one entry per analyzed asset or filed query answer (FR-007)
```

**Structure Decision**: Five new single-`SKILL.md` skill directories under `.agents/skills/`, matching
the existing flat structure used by every other skill in this repo (e.g. `rabbit-archive-to-markdown/SKILL.md`,
`aisdlc-knowledge-ingestion/SKILL.md`) — no scripts, no `resources/` subfolder, since each skill's logic
is a step-by-step instruction list for the agent to follow, not executable code. Data lives entirely
under the new `meta/rabbit-wiki/` root (sibling to `docs/`, `specs/`, and the microservice modules) plus
a new repo-root `pending_imports/` intake folder, per FR-016 and the spec's Assumptions. No existing
directory (`docs/context/`, any microservice module, `tools/gh-agent-board/`) is modified.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No violations — this section is not applicable.
