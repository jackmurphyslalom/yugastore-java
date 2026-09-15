# Architecture Assessment: `react-ui`

**Tier**: `react-ui` | **Port**: 8080 | **Assessed**: 2026-09-15

## Context

`react-ui` (`frontend/`) is the React storefront (React 16.2, `react-scripts` 1.1.1) built with
Create React App conventions (`components/Home`, `Products`, `App`, `ShowProduct`, `Cart`,
`Main`, `common`). Its `package.json` proxies all requests to `http://localhost:8081` —
`api-gateway-microservice` — confirming it never calls any other microservice directly, matching
the documented Request flow. Evidence consulted: `docs/architecture/overview.md`,
`react-ui/frontend/package.json`.

## Findings

- The dependency set (`react-scripts@1.1.1`, `react@16.2.0`, `bootstrap@3.3.7`, CRA-era tooling)
  is several major versions behind current React/CRA releases (Dependencies, score 2);
  represents accumulated dependency-freshness and security-patch drift if the app is ever
  hardened for production use.
- The dev proxy target (`http://localhost:8081`) is hardcoded in `package.json` rather than
  externalized via environment variables (Config, score 2; Dev/prod parity, score 2) — a
  production build must be reconfigured with the real gateway URL through a separate mechanism
  not visible in this file alone.
- No server-side log stream exists for this tier — only browser console logging in dev
  (Logs, score 1).
- Load/performance-testing status: no load-testing or simulation tooling was observed for this
  client-side tier; none identified. Client-side load characteristics are governed by
  static-asset delivery/CDN capacity rather than server-side concurrency, so a conventional
  backend load test would not be the right tool here — a synthetic browser-performance test
  (e.g. Lighthouse CI) would be the more appropriate agent-derived next step.

## Recommendation

Is upgrading the frontend dependency stack in scope for this engagement, or is the current stack
acceptable as-is for the demo's purposes? Record as observed fact only; no upgrade performed by
this assessment (per plan.md's constraint that no application source code under the 7 modules
may be modified). Flag as a candidate for `docs/context/gaps.md` if frontend modernization
becomes an explicit engagement goal.

**Size**: L — upgrading the React/CRA dependency stack (`react-scripts` 1.1.1 to a current major
version) typically requires re-verifying every component against breaking changes, not a small
patch.

**Risk**: Medium-High. A CRA/React major-version upgrade is close to a wholesale refactor of the
build tooling even though component code itself may need only moderate changes.

**Human time-on-task**: ~5-8 developer-days to upgrade and re-verify the full component tree.

**Agent time-on-task**: ~3-5 hours to scaffold the upgrade and run automated regression checks,
with human review required for visual/behavioral regressions.

## 16-Factor Assessment

| # | Name | Score | Explanation | Gap to 5 | Quick Fix |
|---|---|---|---|---|---|
| I | Codebase | 3 | Single codebase tracked in version control, deployable across environments; the Maven-wrapper module boundary plus the shared monorepo with 6 other tiers weakens independent-deployability separation-of-concerns relative to a dedicated-repo ideal. | 2 | Consider a dedicated repo/module boundary for independent frontend release cadence. |
| II | Dependencies | 2 | Explicitly declared in `package.json` (structural compliance), but severely outdated (`react@16.2.0`, `react-scripts@1.1.1`, `bootstrap@3.3.7`) — accumulated technical debt and unaddressed security-patch drift. | 3 | Upgrade `react-scripts`/`react`/`bootstrap` to current supported major versions. |
| III | Config | 2 | The dev proxy target (`http://localhost:8081`) is hardcoded as a static dev-time value in `package.json` rather than externalized via environment variables — minimal compliance with the "config in the environment" principle. | 3 | Externalize the API proxy target via environment variables (e.g. `REACT_APP_API_URL`). |
| IV | Backing services | 4 | `api-gateway-microservice` is the sole backing service this tier calls, treated as a swappable resource accessed via the configurable proxy target / API base URL. | 1 | Confirm the gateway URL is fully swappable across all build modes. |
| V | Build, release, run | 4 | `npm run build` (release artifact) is clearly separated from `npm start` (dev run); the Maven wrapper module's `pom.xml`/`Dockerfile` handle packaging for deployment; no CI/CD automation or immutable artifact versioning observed. | 1 | Add CI/CD automation and immutable artifact versioning for frontend builds. |
| VI | Processes | 4 | Client-side React app is stateless from the server's perspective; UI state is held in the browser, not a server-side process; backing-service integration for persistent data was not independently re-verified here. | 1 | No action needed; state is already browser-resident. |
| VII | Port binding | 3 | Dev server self-contained on port 8080, but production serving depends on an external static-hosting/reverse-proxy setup rather than the app itself being fully self-contained in all environments. | 2 | Confirm production serving/static-hosting setup is documented and repeatable. |
| VIII | Concurrency | 4 | Traditional server-process concurrency does not apply to a client-side app; scaling is correctly treated as a static-asset/CDN distribution concern instead. | 1 | No action needed beyond standard CDN/static-hosting scaling. |
| IX | Disposability | 4 | Production build is a static artifact with no long-running-process disposability concerns; dev server offers predictable, quick start/stop via standard CRA tooling. | 1 | No action needed; static artifact already has low disposability risk. |
| X | Dev/prod parity | 2 | The hardcoded local proxy target (`http://localhost:8081`) creates a real dev/prod parity gap requiring manual reconfiguration for production through a mechanism not visible in this file. | 3 | Externalize the proxy/API target so dev and prod configs converge. |
| XI | Logs | 1 | No server-side log stream exists for this tier in production — only browser console logging in dev, which does not satisfy the 12-factor "logs as event streams" principle for a deployed service. | 4 | Add production error/log reporting (e.g. a client-side logging service). |
| XII | Admin Processes | 3 | Only standard CRA scripts (`build`/`start`/`test`/`eject`) exist; no dedicated, reproducible admin/one-off task infrastructure (e.g. migrations, seeding) was observed. | 2 | Add a dedicated seeding/migration script if admin tasks are ever needed. |
| XIII | Prompts as code | N/A | Traditional React e-commerce storefront with no AI/LLM component or prompt-management infrastructure observed. | N/A | — |
| XIV | State as a service | N/A | Application state is browser-resident (component state); no AI/LLM conversational-session concern. | N/A | — |
| XV | Observability for non-determinism | N/A | Deterministic React rendering with no AI/LLM model output. | N/A | — |
| XVI | Trust & safety by design | N/A | No AI/LLM component, generative-content surface, or model-inference pathway observed in this tier. | N/A | — |
