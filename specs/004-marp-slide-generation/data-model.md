# Phase 1 Data Model: Marp-Based Slide Generation

No application data, database schema, or persisted entity is introduced by this feature (docs
and tooling convention only). The "entities" below are documentation/file conventions, captured
here for traceability to the spec's Key Entities section.

## Slide Deck

A Marp-formatted Markdown file stored under `docs/slides/`.

| Field | Description | Constraint |
|---|---|---|
| File path | `docs/slides/<deck-name>.md` | Must live directly under `docs/slides/` (FR-002) |
| Front matter | Marp config block (`marp: true`, `theme`, `paginate`, etc.) | Required at top of file so `npx @marp-team/marp-cli` recognizes it as a deck |
| Slide separator | `---` between slides | Standard Marp convention, documented in `docs/slides/README.md` |
| Content | Hand-authored/curated Markdown per slide | MUST NOT be auto-generated from git history/diffs (FR-005) |

**Lifecycle**: Authored once per change/period of history it summarizes; treated as a
point-in-time snapshot (spec Edge Cases) — not kept in sync automatically with later doc changes.

**Relationships**: A deck may reference/summarize one or more `docs/decisions/*.md`,
`docs/architecture/adr/*.md`, or `specs/*/spec.md` documents, but does not formally link to them
(no required cross-reference mechanism beyond prose).

## Deck Export

A PDF or HTML file generated from a Slide Deck's Markdown source via `npx @marp-team/marp-cli`.

| Field | Description | Constraint |
|---|---|---|
| Source | The originating Slide Deck file | 1:1 derivation, regenerated on demand |
| Format | `.pdf` or `.html` | Both are Marp's standard built-in export targets (spec Assumptions) |
| Storage | Alongside the source `.md` file, or ad hoc output location | Derived artifact, not a source of truth; not required to be committed |

**Lifecycle**: Regenerable at any time from the current Slide Deck source; no versioning or
staleness tracking beyond "was it re-exported after the source changed" (manual responsibility,
per spec Edge Cases).

## Validation rules (from spec Functional Requirements)

- A Slide Deck MUST be renderable by the documented `npx` command with no additional repo setup
  (FR-001, SC-001).
- The sample deck (`docs/slides/ai-sdlc-bootstrap-overview.md`) MUST contain a distinct,
  identifiable slide or section for each of the 12 named themes (FR-004, SC-002).
- `docs/slides/README.md` MUST document both the authoring convention and the export commands,
  reachable without prior Marp knowledge (FR-003, FR-006, FR-007).
