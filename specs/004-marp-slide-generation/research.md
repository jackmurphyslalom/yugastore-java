# Phase 0 Research: Marp-Based Slide Generation

All items below were already resolved by the user during spec clarification; this file records
the decisions and rationale for traceability rather than open unknowns.

## Marp tooling invocation

- **Decision**: Use `npx @marp-team/marp-cli` for all rendering/export. No `package.json`, no
  pinned CLI version, no VS Code extension requirement.
- **Rationale**: This is a Java/Maven repo; adding a Node dependency footprint for a docs-only
  convenience tool is disproportionate. `npx` fetches the package on demand, satisfying the
  "first invocation works with no repo setup" edge case in the spec.
- **Alternatives considered**:
  - Vendoring `@marp-team/marp-cli` in a root `package.json` — rejected, adds an unnecessary
    Node toolchain to a Java repo (violates FR-001).
  - Marp for VS Code extension as the primary workflow — rejected, spec explicitly requires no
    VS Code extension dependency so the convention works for any contributor/CI shell.

## Slide deck location and file convention

- **Decision**: `docs/slides/` is the canonical directory; one Markdown file per deck, using
  standard Marp front matter (`marp: true`, `theme`, `paginate`, etc.) and `---` slide separators.
- **Rationale**: Matches the existing `docs/` subdirectory convention (`docs/architecture/`,
  `docs/decisions/`, `docs/patterns/`, `docs/product/`) already established in this repo, so it's
  discoverable the same way other durable docs are.
- **Alternatives considered**: `specs/*/slides/` (per-feature) — rejected, decks summarize
  cross-cutting repo history (e.g., the sample deck spans PRs #1-#52), not a single feature.

## Export workflow

- **Decision**: Document `npx @marp-team/marp-cli <deck>.md --pdf` and `--html` as manual,
  on-demand commands. No Maven plugin, npm script, or CI job wiring.
- **Rationale**: Spec's Out of Scope / Assumptions state no CI automation is required; exports
  are derived/regenerable artifacts (Deck Export entity), not gated build outputs.
- **Alternatives considered**: A `docs/slides/export.sh` wrapper script — considered but not
  required by any FR; the two documented `npx` invocations are already simple enough for SC-003
  ("no manual troubleshooting"). Left as a possible future enhancement, not required scope.

## Sample deck content source

- **Decision**: `docs/slides/ai-sdlc-bootstrap-overview.md` covers exactly the 12 named themes
  from the spec (AI-SDLC bootstrap, requirements transcripts, context bootstrap docs, project
  constitution ratification, gh-agent-board tooling, writing style guide, MCP config, Context7
  instructions, Brewfile dev setup, GitHub Issues/Spec Kit boundary docs, CI/CD bootstrap, CI
  stabilization, Java testing framework alignment) as one slide or clearly labeled section each.
- **Rationale**: Directly satisfies FR-004 and SC-002; content is hand-curated from existing
  durable docs (`docs/decisions/`, `docs/architecture/adr/`, `docs/product/`, `AGENTS.md`,
  `.github/instructions/context7.instructions.md`, `Brewfile`) rather than generated from git
  history/diffs (explicitly out of scope per FR-005).
- **Alternatives considered**: Auto-generating slide content from `git log`/PR API — explicitly
  out of scope in the spec; not evaluated further.

## Naming/terminology check

- **Decision**: No new terms added to `docs/product/glossary.md`. "Slide Deck" and "Deck Export"
  are feature-scoped Key Entities defined in the spec itself, not repo-wide domain vocabulary
  (unlike ASIN, YCQL, Cronos, etc.).
- **Rationale**: Constitution Principle III scopes the glossary to canonical *product/domain*
  terminology; Marp authoring terms are tooling conventions, consistent with how other `docs/`
  subdirectories (e.g., `docs/patterns/`) document their own vocabulary locally.
