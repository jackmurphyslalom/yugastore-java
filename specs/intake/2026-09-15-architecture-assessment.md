# Architecture Assessment — Proposal 2 of 3

Raw intake, not yet a spec. Feed into `/speckit.aisdlc.triage` or `/speckit.specify` after a
grilling session confirms domain intent.

## Source
- Split from `docs/next.md` (2026-09-15). See sibling proposals:
  `2026-09-15-rabbit-wiki-lifecycle.md` and `2026-09-15-future-state-recommendations.md`.
- Origin: onboarding assessment for a new client (Yugastore) codebase, per-tier evaluation.

## Dependencies
- None. Independent of Proposal 1. Proposal 3 (future-state recommendations) depends on this
  proposal's completed output.

## Summary of request
When approaching this unfamiliar codebase, produce a reusable skill + prompt that assesses each
tier (api-gateway, cart, checkout, eureka-server, login, products, react-ui) and generates:

- A SCQA overview per component.
- A 16-factor-app assessment per component.
- Markdown output living in a new `architecture_assessment/` folder.
- A root `README.md` acting as the entry point into the assessment.
- After all tiers are assessed, a rollup into a C4 model (C1–C4) with Mermaid diagrams on the
  index page.

## Grilling outcome (confirmed 2026-09-15)

Grilled via `aisdlc-grilling`. All decisions below are user-confirmed and ready for
`/speckit.specify`.

1. Framework: use Google Cloud's AI 16-factor model as-is (classic 12 + XIII Prompts as code,
   XIV State as a service, XV Observability for non-determinism, XVI Trust & safety by design;
   source: `docs/context/sources/2026-09-14-twelve-to-sixteen-factor-app.md`). Mark factors
   XIII–XVI "N/A" for tiers with no AI component today.
2. Storage root: `meta/architecture-assessment/` — a new top-level `meta/` folder (shared with
   Proposal 1's `meta/rabbit-wiki/`), chosen to avoid collisions with AI-SDLC-managed durable
   context under `docs/`. Add a one-line cross-reference from `docs/architecture/overview.md`
   pointing to it.
3. Scope: the 7 application tiers only — `eureka-server-local`, `products-microservice`,
   `checkout-microservice`, `cart-microservice`, `api-gateway-microservice`,
   `login-microservice`, `react-ui`. AI-SDLC framework content (`.agents/`, `.specify/`,
   `.github/`) is explicitly excluded from assessment.
4. `login-microservice` gets the same full assessment as the other 6 tiers, with its
   WIP/unwired status (per `docs/architecture/overview.md`) called out as a finding.
5. Two skills: a per-tier assessment skill (run once per tier, writing
   `meta/architecture-assessment/{tier-name}.md`), and a separate rollup skill that reads all 7
   completed tier files and writes the C4 model into `meta/architecture-assessment/README.md`.
6. C4 depth: C1 (System Context) and C2 (Container) for the whole system, plus one C3
   (Component) diagram for `api-gateway-microservice` only. C4-Code (level 4) is out of scope.
7. The rollup skill hard-gates: it refuses to run and lists missing tiers if any of the 7 tier
   files aren't present yet.

## Not Yet Resolved
- None. Ready for `/speckit.specify`.
