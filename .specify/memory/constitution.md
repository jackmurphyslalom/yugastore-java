<!--
Sync Impact Report
Version change: (template, unratified) → 1.0.0
Modified principles: n/a (initial ratification)
Added sections:
  - Core Principles: I. Gateway-Only Service Boundary
  - Core Principles: II. Consistency-Sensitive Data Paths
  - Core Principles: III. Canonical Terminology
  - Core Principles: IV. Context-Grounded Change
  - Core Principles: V. Incremental Test Hardening
  - Deployment & Scope Boundaries
  - Development Workflow
  - Governance
Removed sections: none (template placeholders replaced)
Templates requiring updates:
  - .specify/templates/plan-template.md ✅ (Constitution Check section already derives gates from this file; no hardcoded principle names to update)
  - .specify/templates/spec-template.md ✅ (no constitution-specific references found)
  - .specify/templates/tasks-template.md ✅ (no constitution-specific references found)
  - .specify/templates/checklist-template.md ✅ (no constitution-specific references found)
  - Framework command/skill files (speckit.*) ✅ (reviewed; none hardcode principle names)
Follow-up TODOs:
  - TODO(DEPLOYMENT_TARGET): AWS vs. existing Cloud Foundry manifests unresolved (see docs/context/gaps.md); constitution intentionally leaves this open rather than picking a side.
  - TODO(LOGIN_MICROSERVICE_SCOPE): whether login-microservice completion is in engagement scope is unresolved (see docs/context/gaps.md).
-->
# yugastore-java Constitution

## Core Principles

### I. Gateway-Only Service Boundary
All external and UI traffic MUST route exclusively through `api-gateway-microservice`; no
client or microservice MAY call another microservice's REST API directly. Every microservice
MUST register with the Eureka registry (`eureka-server-local`) for discovery.
Rationale: this is the only verified integration contract in the codebase (see
`docs/architecture/overview.md`); bypassing it breaks the single external surface the rest of
the system assumes.

### II. Consistency-Sensitive Data Paths
Order placement and inventory checks MUST go through the existing transactional writes on
`cronos.orders` and `cronos.product_inventory` (YCQL transactions enabled) and MUST preserve
stock verification (`NotEnoughProductsInStockException`) before an order commits. Schema or
code changes touching these tables MUST be reviewed for consistency impact before merge.
Rationale: these are the only tables built with explicit distributed-transaction guarantees;
bypassing the check would reintroduce overselling or order/inventory data loss.

### III. Canonical Terminology
Code, docs, specs, and commit messages MUST use the terms defined in
`docs/product/glossary.md` (e.g., ASIN, YCQL, YSQL, api-gateway) instead of ad hoc synonyms.
The legacy internal name "Cronos" MUST stay confined to code/package references and MUST NOT
appear in user-facing or product-facing text. New durable terms MUST be added to the glossary
rather than left as unwritten team knowledge.
Rationale: the glossary is the project's sole canonical-language source, and downstream
AI-SDLC commands depend on it staying accurate.

### IV. Context-Grounded Change
Before specifying or implementing a change, contributors MUST check `docs/context/gaps.md`,
`docs/product/overview.md`, and `docs/architecture/overview.md` for open questions relevant to
that change, and MUST record newly discovered unresolved questions in `docs/context/gaps.md`
instead of guessing silently. Specs and plans MUST cite the concrete evidence (files, schema,
code) they rely on.
Rationale: this repo is actively used for AI-SDLC bootstrap and immersion exercises; unverified
assumptions compound quickly across specs when not written down.

### V. Incremental Test Hardening
New or changed behavior MUST ship with tests that exercise the actual behavior change, not only
Spring Boot context-load smoke tests. Existing low-signal smoke tests MAY remain but MUST NOT be
treated as sufficient coverage for new work.
Rationale: `docs/architecture/overview.md` records current tests as low behavioral signal; the
project needs a rising floor on new work rather than a mandate to retroactively rewrite every
existing test.

## Deployment & Scope Boundaries

- Target deployment platform is unresolved: kickoff decisions tentatively picked AWS (by
  available credentials only, explicitly reversible), but every microservice still ships a
  Cloud Foundry `manifest.yml`. Neither is constitutionally mandated; treat the choice as open
  until resolved via an ADR (`docs/architecture/adr/`) and reflected here.
  TODO(DEPLOYMENT_TARGET): resolve and update this section once a target is ratified.
- `login-microservice` is unfinished and has no `api-gateway-microservice` REST client wired to
  it. Completing or integrating it is out of scope by default; any change to wire it in MUST go
  through `/speckit.specify` first rather than being bundled into unrelated work.
  TODO(LOGIN_MICROSERVICE_SCOPE): resolve and update this section once engagement scope is confirmed.

## Development Workflow

- Non-trivial changes MUST follow the Spec Kit workflow recorded in `AGENTS.md`
  (`/speckit.specify` → `/speckit.clarify` → `/speckit.plan` → `/speckit.tasks` →
  `/speckit.analyze` → `/speckit.implement`).
- Durable architecture decisions MUST be captured as ADRs under `docs/architecture/adr/`
  per `docs/architecture/adr/README.md`, not left only in chat history or PR descriptions.
- Reviews MUST check new/changed code against the principles above before merge; a violation
  MUST either be fixed or justified via an explicit constitution amendment, not silently waived.

## Governance

This constitution supersedes ad hoc practice for every module in this repository. Amendments
MUST update `CONSTITUTION_VERSION` per semantic versioning (MAJOR: incompatible principle
removal/redefinition; MINOR: new or materially expanded principle/section; PATCH: clarification
or wording fix), update **Last Amended**, and record a Sync Impact Report at the top of this
file. Any PR, spec, or plan that conflicts with a principle MUST either comply or propose a
constitution amendment alongside the change; silent exceptions are not permitted. Use
`docs/context/gaps.md` to track open governance questions until they can be ratified here.

**Version**: 1.0.0 | **Ratified**: 2026-09-14 | **Last Amended**: 2026-09-14

<!-- AI-SDLC:CONTEXT-ROUTING START -->
## AI-SDLC Context Routing

- Use `docs/context/routing-map.md` to select the smallest relevant context set.
- Start with exact-file baselines. Expand to directories, globs, dependencies, ownership, or implementation code only after a documented trigger.
- Record why each additional file was selected.
- Keep `.specify/memory/constitution.md` project-owned. Framework refreshes must preserve it.
<!-- AI-SDLC:CONTEXT-ROUTING END -->
