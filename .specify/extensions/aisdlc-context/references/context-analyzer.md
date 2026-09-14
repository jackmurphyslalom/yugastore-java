# AI-SDLC Context Analyzer Contract

Use this contract whenever AI-SDLC commands need project-specific context.

## Routing contract

Follow `.specify/extensions/aisdlc-context/references/context-routing.md`. When
`docs/context/routing-map.md` exists, select one stable command or skill route ID and use its
two-pass exact-file contract. Record the route ID and why every selected file applies.

For an older project without a routing map or a matching route row, use the routing contract's
compatibility fallback. Never replace a missing file with a whole-directory read, glob, ownership
expansion, dependency traversal, or speculative implementation search.

For a `context-hub`, read `workspace.yaml` before repository evidence. The hub owns durable docs and planning artifacts. Repository entries with role `reference` are read-only evidence sources. Use optional `applies_to` repository keys for scoped context; an absent scope means project-wide.

`docs/product/glossary.md` remains the sole default source of canonical language when the selected
route or a concrete expansion trigger includes it.

## Manifest requirements

Each `docs/context/index.yaml` entry includes:

- `id`
- `category`
- `path`
- `summary`
- `source_paths`
- `confidence`
- `last_verified`
- `status`: `scaffold-only`, `draft`, `verified`, or `stale`
- optional `applies_to`

Every free-text prose field in `docs/context/index.yaml` must be YAML-safe. Use block scalars for
`summary` values and any added prose fields, or explicitly quote the value:

```yaml
  - id: architecture-overview
    category: architecture
    path: docs/architecture/overview.md
    summary: |
      Draft architecture context inferred from implementation evidence: preserve public extension
      contracts and verify unresolved tradeoffs with maintainers.
    source_paths:
      - src/index.ts
    confidence: medium
    last_verified: 2026-07-25
    status: draft
```

Do not write unquoted prose scalars containing `: `, such as `summary: Evidence says: preserve
behavior`.

## Freshness rules

Freshness inspection is local-only:

- inspect current branch and working-tree state;
- compare ahead/behind only with existing local tracking refs;
- never fetch, pull, switch branches, or mutate Git refs;
- report remote freshness as unknown when local refs cannot prove it;
- mark context `stale` when source paths materially changed, required context is missing, summaries conflict with evidence, or verification is no longer reliable.

Untouched scaffolds are `scaffold-only`, not evidence. Automated bootstrap output is `draft` until human review. Only guided final confirmation can mark newly bootstrapped shared understanding `verified`.

## Language and decisions

`docs/product/glossary.md` is the sole default source of canonical language. Preserve existing author-created structure. Do not create another glossary hierarchy unless a human explicitly chooses a split during guided bootstrap.

Create an ADR only if the decision is hard to reverse, surprising without context, and selected through a genuine tradeoff. Automated bootstrap never creates ADRs.

## Output rule

When confidence is weak, record the gap explicitly. Do not replace missing project knowledge with generic best-practice filler.
