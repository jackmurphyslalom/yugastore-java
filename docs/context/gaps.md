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

- **Area**: No `Won't Fix` Status option configured for the gh-agent-board Projects (v2) field
  (discovered during `/speckit.plan` for `specs/001-gh-board-crud-prompts/`, confirmed live
  2026-09-15)
  - **Why it matters**: `specs/001-gh-board-crud-prompts/spec.md`'s "retire" prompt (FR-009) needs
    to set Status to a value reflecting a "won't-fix" outcome, distinct from "done", but the live
    Project's Status field has no matching option.
  - **Evidence checked**: Live `gh project field-list 1 --owner @me` (2026-09-15) confirms the
    real Status options are `Backlog`/`Ready`/`In progress`/`In review`/`Done` (no `Won't Fix`,
    different casing/names than the spec's assumed `Todo`/`In Progress`/`In Review`/`Done`), and
    Priority options are only `P0`/`P1`/`P2` (no `P3`). `tools/gh-agent-board/config/board.json`
    has been updated to these real values; `config/board.smoke-test.json` records the same data.
    Live run of `retire-ticket.sh --outcome wont-fix` against issue #33 confirmed it fails with
    "field 'Status' or value 'Won't Fix' not configured in board.json", as expected.
  - **Next best reviewer or source**: A human with board-admin access must add a `Won't Fix`
    (or equivalent) option to the live Project's Status field and to `config/board.json` before
    the retire prompt's "won't-fix" path can succeed; until then it fails with a clear "field not
    configured" error rather than silently reusing `Done`.

- **Area**: GitHub Projects v2 built-in "close issue when Status = Done" workflow defeats the
  gh-agent-board retire prompt's "never closes the Issue" guarantee (discovered during live smoke
  test of `specs/001-gh-board-crud-prompts/`, 2026-09-15)
  - **Why it matters**: `retire-ticket.sh --outcome done` (FR-009) never calls `gh issue close`
    and its own output states the Issue "remains open — closing it is a human-only action." A live
    test on issue #33 showed the underlying Issue was closed anyway (`stateReason: COMPLETED`,
    closed at the same instant the Status field-write completed), because the Project has its own
    default automation ("Item closed when Status set to Done") that closes the Issue as a side
    effect of the field being set to a Done-mapped column. This is a real gap between the
    documented tooling guarantee (spec.md US5, FR-009) and the actual observed behavior: the
    `gh` CLI/API path used by our script is not the cause, but the net effect contradicts the
    contract.
  - **Evidence checked**: Live run against issue #33, 2026-09-15: `retire-ticket.sh --outcome done`
    succeeded and printed the "Issue remains open" message; immediate `gh issue view 33
    --json state,stateReason,closedAt` showed `{"state":"CLOSED","stateReason":"COMPLETED",
    "closedAt":"2026-09-15T19:02:40Z"}`, matching the retire call's timestamp. Issue was manually
    reopened afterward (`gh issue reopen 33`) as a corrective action, not by any script.
  - **Next best reviewer or source**: A human with board-admin access must disable the "Item
    closed when Status set to Done" (or equivalently named) default workflow on the live Project
    (via the Project's own Workflows settings UI — not exposed by `gh project` CLI subcommands) if
    the "never closes the Issue" guarantee must hold in practice. Until disabled, treat FR-009's
    "Issue remains open" guarantee as unverified for the `done` outcome on this specific Project.
