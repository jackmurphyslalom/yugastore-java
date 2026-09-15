# Architecture Assessment: `react-ui`

**Tier**: `react-ui` | **Port**: 8080 | **Assessed**: 2026-09-15

## SCQA Overview

**Situation**: `react-ui` (`frontend/`) is the React storefront (React 16.2, `react-scripts` 1.1.1)
built with Create React App conventions (`components/Home`, `Products`, `App`, `ShowProduct`,
`Cart`, `Main`, `common`). Its `package.json` proxies all requests to
`http://localhost:8081` — `api-gateway-microservice` — confirming it never calls any other
microservice directly, matching the documented Request flow.

**Complication**: The dependency set (`react-scripts@1.1.1`, `react@16.2.0`, `bootstrap@3.3.7`,
CRA-era tooling) is several major versions behind current React/CRA releases; this is expected for
a multi-year-old demo app but represents accumulated dependency-freshness and security-patch drift
if the app is ever hardened for production use.

**Question**: Is upgrading the frontend dependency stack in scope for this engagement, or is the
current stack acceptable as-is for the demo's purposes?

**Answer/recommendation**: Record as observed fact only; no upgrade performed by this assessment
(per plan.md's constraint that no application source code under the 7 modules may be modified).
Flag as a candidate for `docs/context/gaps.md` if frontend modernization becomes an explicit
engagement goal.

## 16-Factor Assessment

| # | Name | Assessment |
|---|---|---|
| I | Codebase | Single Maven module wrapper (`react-ui/`) containing the CRA-managed `frontend/` app, tracked in the same reactor/VCS as the other 6 tiers. |
| II | Dependencies | Declared explicitly via `frontend/package.json` (npm dependency manifest); no system-level dependency assumed for the frontend build. |
| III | Config | The dev proxy target (`http://localhost:8081`) is set in `package.json`, a static dev-time value rather than a runtime environment variable — the least externalized config of any tier (a CRA-era convention, not necessarily a defect). |
| IV | Backing services | `api-gateway-microservice` is the sole backing service this tier calls, treated as an attached, swappable resource behind the proxy target / built API base URL. |
| V | Build, release, run | CRA's `npm run build` (release artifact) is distinct from `npm start` (dev run); the Maven wrapper module's own `pom.xml`/`Dockerfile` handle packaging this static build for deployment. |
| VI | Processes | Client-side React app; runs as stateless page loads from the server's perspective, with UI state held in the browser, not a server-side process. |
| VII | Port binding | Dev server binds to port 8080 per `docs/architecture/overview.md`; production serving depends on the chosen static-hosting/reverse-proxy setup. |
| VIII | Concurrency | N/A in the traditional server-process sense — scaling is a static-asset/CDN concern, not a multi-process concurrency model. |
| IX | Disposability | Standard CRA dev-server start/stop; production build is a static artifact with no long-running process disposability concerns of its own. |
| X | Dev/prod parity | The hardcoded local proxy target (`http://localhost:8081`) is a real dev/prod parity gap — a production build must be reconfigured with the real gateway URL through a separate mechanism not visible in this file alone. |
| XI | Logs | Browser console logging only in dev; no server-side log stream from this tier itself. |
| XII | Admin Processes | No admin/one-off task scripts observed beyond the standard CRA `npm run build/start/test/eject` scripts. |
| XIII | Prompts as code | N/A — no AI/LLM component observed in this tier. |
| XIV | State as a service | N/A — no AI/LLM component observed in this tier. |
| XV | Observability for non-determinism | N/A — no AI/LLM component observed in this tier. |
| XVI | Trust & safety by design | N/A — no AI/LLM component observed in this tier. |
