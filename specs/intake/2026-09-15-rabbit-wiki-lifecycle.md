# Rabbit Wiki Ingestion Lifecycle — Proposal 1 of 3

Raw intake, not yet a spec. Feed into `/speckit.aisdlc.triage` or `/speckit.specify` after a
grilling session confirms domain intent.

## Source
- Split from `docs/next.md` (2026-09-15). See sibling proposals:
  `2026-09-15-architecture-assessment.md` and `2026-09-15-future-state-recommendations.md`.
- Origin: request to build local wiki tooling around the Karpathy LLM glossary gist
  (https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f).

## Dependencies
- None. Independent of the other two proposals. Can be grilled and specified in parallel with
  Proposal 2.

## Summary of request
Establish a single source of truth for a local wiki with a tagging ontology, and a lifecycle of
prompt/skill pairs under a `/rabbit-*` prefix:

- `/rabbit-ingest` — take a new asset from a `pending_imports/` root folder and create an
  immutable chain-of-custody record: original asset, transformed document, and raw markdown,
  under a unique slug.
- `/rabbit-analyze` — run subagents that read new ingested markdown, consult the current
  ontology, write an idiomatic wiki KB entry, and extend the ontology with new
  concepts/relations as needed.
- `/rabbit-session-close` — reflection step run at the end of an activity that opportunistically
  updates the knowledge graph and associated formats.
- Later: primary Query and Lint prompts from the Karpathy approach (not detailed yet).

## Grilling outcome (confirmed 2026-09-15, storage paths revised same day)

Grilled via `aisdlc-grilling`. All decisions below are user-confirmed and ready for
`/speckit.specify`.

**Storage root revision**: all paths originally proposed under `docs/` were moved to a new
top-level `meta/rabbit-wiki/` root, to avoid collisions with AI-SDLC-managed durable context
under `docs/`. See `meta/` layout confirmed alongside Proposal 2's grilling session.

1. `/rabbit-ingest` extends the existing `rabbit-archive-to-markdown` skill (reuses its
   conversion step) and adds: intake from `pending_imports/`, original-file retention, and a
   unique slug.
2. Each asset's three artifacts (original, transformed, raw markdown) live together in
   `meta/rabbit-wiki/sources/{slug}/` as `original.{ext}`, `transformed.md`, `raw.md`.
3. Slug format: `{YYYY-MM-DD}-{kebab-title}`, with a numeric suffix (`-2`, `-3`, ...) on
   collision — same convention as the existing skill.
4. The ontology lives at `meta/rabbit-wiki/ontology.yaml` as structured data (concepts,
   categories, typed relations), kept separate from `docs/product/glossary.md`.
5. `/rabbit-analyze` reads the ontology, writes one wiki KB entry per asset to a new
   `meta/rabbit-wiki/wiki/{slug}.md`, using its own template (Term/Concept, Definition, Ontology
   links, Source anchor, Related entries), and extends the ontology with new concepts/relations.
6. `/rabbit-session-close` runs only when the user explicitly invokes it. It updates
   `ontology.yaml` and `meta/rabbit-wiki/wiki/` entries only from changes already drafted during
   the session — no new research.
7. `/rabbit-query` and `/rabbit-lint` are in scope for this proposal's spec now, matching
   Karpathy's definitions (source: https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f):
   - Query: search the wiki index, read relevant pages, synthesize a cited answer, and file good
     answers back into the wiki as new pages.
   - Lint: periodic health check for contradictions between pages, stale claims superseded by
     newer sources, orphan pages with no inbound links, important concepts mentioned but lacking
     their own page, missing cross-references, and data gaps fillable by a web search.

## Not Yet Resolved
- None. Ready for `/speckit.specify`.
