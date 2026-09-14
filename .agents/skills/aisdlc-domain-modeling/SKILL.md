---
name: aisdlc-domain-modeling
description: Build and sharpen an AI-SDLC project's domain language and model. Use for glossary work, domain boundaries, invariants, scenarios, context routing, and durable architecture decisions.
license: MIT
---

# AI-SDLC Domain Modeling

Make the project's language precise enough that documentation, specifications, and code describe the same domain.

Read [domain-artifacts.md](references/domain-artifacts.md) before changing domain artifacts.

## Method

1. Inspect existing project evidence and the context index.
2. Identify actors, capabilities, entities, value objects, lifecycle states, invariants, and failure cases.
3. Test each important term against concrete scenarios and existing code.
4. Surface overloaded, ambiguous, synonymous, or implementation-shaped language.
5. Propose the smallest terminology or model change that resolves the ambiguity.
6. In guided work, confirm authoritative language with the user before recording it.
7. Record evidence, confidence, and verification dates for new glossary entries.

Use examples and counterexamples to pressure-test the model. Prefer domain language over storage, framework, or transport terminology unless the technical term is itself part of the domain.

## Guardrails

- `docs/product/glossary.md` is the sole default source of canonical language.
- Preserve an existing project-authored glossary structure during brownfield work.
- Do not split the glossary unless a human makes that decision during guided bootstrap.
- Do not create `CONTEXT.md`, `CONTEXT-MAP.md`, or a parallel glossary hierarchy.
- Automated bootstrap may only record evidence-backed facts as draft and must place unresolved decisions in `docs/context/gaps.md`.
- Automated bootstrap must never create ADRs or make authoritative domain decisions.
- Stop instead of fabricating facts when evidence is insufficient.
