# AI-SDLC Domain Artifacts

## Canonical language

Use `docs/product/glossary.md`. For new projects, keep entries concise and include:

- definition;
- preferred term;
- avoided terms, when relevant;
- evidence;
- confidence;
- last verification date.

Preserve existing author-created organization and formatting in established projects.

## Context routing

Use `docs/context/index.yaml` as the routing manifest. Status values are:

- `scaffold-only`: placeholder content with no verified project knowledge;
- `draft`: evidence-backed content awaiting human review;
- `verified`: explicitly confirmed shared understanding;
- `stale`: previously useful context that now requires re-verification.

An entry may include `applies_to` with workspace repository keys. An absent scope means project-wide.

## Decisions

Store architecture decision records under `docs/architecture/adr/`. Create an ADR only when all three conditions hold:

1. the decision is hard to reverse;
2. the result would be surprising without its context;
3. a genuine tradeoff led to the selection.

If any condition is absent, keep the rationale in the relevant specification, plan, or task instead. Leave existing ADRs unchanged.
