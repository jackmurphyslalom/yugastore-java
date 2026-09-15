---
type: concept
authored_by: rabbit-analyze
confidence: high
last_verified: 2026-09-15
source_type: url
source_ref: meta/rabbit-wiki/sources/2026-09-15-twelve-to-sixteen-factor-app
tags: [sixteen-factor, twelve-factor, ai, methodology, architecture]
related: [2026-09-15-twelve-factor-app]
---

# Sixteen-Factor App

## Term/Concept

**Sixteen-Factor App** — Google Cloud's proposed extension of the Twelve-Factor App methodology
(Kunal Kumar Gupta) with four additional factors addressing generative-AI application concerns:
conversational memory, non-determinism, and AI-specific security risks.

## Definition

Retains all twelve original factors and adds:

- **XIII. Prompts as code** — the true "source code" of an AI system has three parts: a
  behavior spec (golden datasets, persona guidelines, tests), the context-engineering logic
  (retrieval, history selection, tool selection), and the prompt template itself. All three must
  be versioned, tested, and evaluated in CI/CD — not just a magic string in a function.
- **XIV. State as a service** — conversational AI is inherently stateful, so externalize
  conversation memory into a dedicated backing service (e.g. a session service for short-term
  turn state, a memory service for long-term searchable history) rather than making the app
  process itself stateful.
- **XV. Observability for non-determinism** — an AI app can return HTTP 200 with a useless or
  wrong answer, so observability must extend beyond system health to AI quality/behavior: log
  prompts, responses, token counts, tool-use errors, and instrument user feedback.
- **XVI. Trust & safety by design** — architect for prompt injection and data exfiltration risks
  from the start, using defense in depth: model-level safety filters, application-level access
  control by user persona, and least-privilege infrastructure permissions.

This repo's own `rabbit-architecture-assessment-tier` skill scores each tier against "the full
16-factor (12-factor + 4 AI-era factors) model," directly applying this methodology.

## Ontology links

- [sixteen-factor-app](../ontology.yaml) (concept)
- [twelve-factor-app](../ontology.yaml) (concept, related — extends it)

## Source anchor

[meta/rabbit-wiki/sources/2026-09-15-twelve-to-sixteen-factor-app/](../sources/2026-09-15-twelve-to-sixteen-factor-app/)

## Related entries

- [2026-09-15-twelve-factor-app](2026-09-15-twelve-factor-app.md) — the base methodology this
  extends.
