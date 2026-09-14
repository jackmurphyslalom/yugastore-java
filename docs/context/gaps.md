# Context Gaps

Use this file to record important things the repo does not yet prove clearly enough.

Keep unresolved or weak-signal context here so later feature work does not quietly guess through it.

## What Belongs Here

- product or architecture questions that still need a human answer
- stale docs or conflicting evidence discovered during bootstrap or promotion
- important source areas that have not been reviewed yet
- repo conventions that seem real but are not verified strongly enough to treat as durable guidance

## What Does Not Belong Here

- feature task lists
- implementation TODOs that belong in `specs/`
- temporary scratch notes better kept in `specs/<feature>/context/scratch/`

## Current Gaps

- **Area**: Pricing changes without redeploy (from `specs/intake/2026-09-14-ai-immersion-open-questions.md`)
  - **Why it matters**: A referenced client requirement says pricing rules should change weekly
    without an engineering redeploy.
  - **Evidence checked**: `resources/schema.cql` confirms `cronos.products.price` and
    `cronos.product_rankings.price` are plain `double` columns on the product/ranking record — there
    is no separate pricing-rules table, service, or config layer observed anywhere in the codebase.
    This verifies the meeting's suspected mismatch; it does not resolve what the requirement should be.
  - **Next best reviewer or source**: Human confirmation of the actual client requirement (the
    source slide deck was not available to this pass).

- **Area**: Graceful degradation when a dependent service is down (same intake source)
  - **Why it matters**: A referenced client requirement says the storefront should degrade
    gracefully if a dependency (e.g., checkout) is unavailable.
  - **Evidence checked**: `api-gateway-microservice/src/main/java/.../rest/clients/*RestClient.java`
    and the `*ServiceRest`/`*ServiceRestImpl` classes were reviewed; no circuit breaker, fallback, or
    timeout/degradation logic was found. Eureka (`eureka-server-local`) provides discovery only, not
    degradation behavior by itself.
  - **Next best reviewer or source**: Human confirmation of scope before designing a degradation
    strategy; likely a `/speckit.specify` candidate once prioritized.

- **Area**: Rapid experimentation / A/B testing (same intake source)
  - **Why it matters**: A referenced client requirement wants constant pricing/UX experiments
    without engineering being the bottleneck.
  - **Evidence checked**: No experimentation/feature-flag framework or config was found in any
    microservice.
  - **Next best reviewer or source**: Needs its own investigation once real client requirements are
    available; no code evidence to verify or refute yet.

- **Area**: `login-microservice` completion status and integration plan
  - **Why it matters**: README marks it "still a work in progress," and `api-gateway-microservice`
    has no REST client for it — unclear if finishing it is in scope for this engagement.
  - **Evidence checked**: `login-microservice/src/main/java/.../{repo,service,model,web}` exist
    (User/Role/UserController), but no corresponding client exists under
    `api-gateway-microservice/src/main/java/.../rest/clients/`.
  - **Next best reviewer or source**: Human confirmation of engagement scope.

- **Area**: Deployment target ambiguity (AWS vs. existing Cloud Foundry `manifest.yml` files)
  - **Why it matters**: Kickoff decisions tentatively picked AWS (by available credentials only,
    explicitly reversible), but every microservice already ships a Cloud Foundry `manifest.yml`.
  - **Evidence checked**: `docs/decisions/2026-09-14-1758-immersion-kickoff-decisions.md`; each
    microservice's `manifest.yml`.
  - **Next best reviewer or source**: Revisit once real client cloud constraints are known.

- **Area**: `.specify/memory/constitution.md` is still the unfilled template
  - **Why it matters**: No ratified project principles exist yet; downstream commands treat the
    constitution as authoritative when present.
  - **Evidence checked**: File still contains bracketed placeholders (`[PRINCIPLE_1_NAME]`, etc.).
  - **Next best reviewer or source**: Run `/speckit.constitution` once the team has real principles
    to ratify (test policy, per-service deployment rules, etc.); bootstrap intentionally does not
    author it.
