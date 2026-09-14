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

Use one short entry per unresolved item:

- **Area**: Existing admin/observability views (uptime dashboard, metrics, non-production
  latency-injection toggle)
  - **Why it matters**: A client interview raised whether a resilience feature should include an
    uptime dashboard/metrics or a non-production toggle to intentionally add latency for
    chaos-style testing, but the client themselves was unsure whether such views already exist in
    the site. Any resilience spec should confirm this against the code first rather than assume
    either way.
  - **Evidence checked**: None yet — the client interview transcript only records uncertainty, not
    a code-level answer.
  - **Next best reviewer or source**: Inspect `api-gateway-microservice` and any admin UI in
    `react-ui` for existing health/metrics endpoints or admin screens before scoping the
    resilience feature described in
    `specs/intake/2026-09-14-client-requirements-interview.md`.
