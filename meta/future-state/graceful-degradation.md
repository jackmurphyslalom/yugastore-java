# Graceful Degradation When a Service Slows or Goes Down

## Client need

> when any service slows down or goes down, the storefront must degrade gracefully.

## Current-state finding

[`api-gateway-microservice.md`](../architecture-assessment/api-gateway-microservice.md)'s
Complication states directly: "No fallback/circuit-breaker code was found in any `*RestClient`
... a downstream outage (e.g. `checkout-microservice` down) is not currently handled gracefully
by observed code; a caller would see a raw failure rather than a degraded response." Its
16-Factor row IX (Disposability) adds that "the missing circuit-breaker logic ... means an
in-flight request during a downstream outage may fail slowly rather than fail fast." This is
corroborated by `docs/architecture/overview.md`'s Important Flows section, which independently
notes "No fallback/circuit-breaker code was found in the gateway's REST clients." Because
`react-ui` only ever calls `api-gateway-microservice`
([`react-ui.md`](../architecture-assessment/react-ui.md)), this gateway-layer gap is the single
point where a downstream outage becomes a hard, ungraceful failure for every storefront request.

## Options considered

- **A**: Add circuit breakers, timeouts, and fallback responses (e.g., via Resilience4j) to the
  `*RestClient` classes inside `api-gateway-microservice`.
- **B**: Add client-side degradation in `react-ui` — show cached/stale product data or a
  friendly error state when a gateway call fails.
- **C**: Adopt a service mesh (e.g., Istio) to provide circuit breaking at the infrastructure
  layer, independent of application code.

## Recommendation

**Chosen: Option A.** The gap is precisely and only located in `api-gateway-microservice`'s
`*RestClient` classes, and that tier is already the system's single external API surface (the
Gateway-Only Service Boundary principle in `.specify/memory/constitution.md`). Fixing it there
closes the gap for every caller (including `react-ui`) in one place, with the smallest code
surface change and no new infrastructure. Resilience4j is a natural fit for the existing Spring
Boot 2.6.3 / Spring Cloud stack.

**Size**: S — localized to the existing `*RestClient` classes in one tier
(`api-gateway-microservice`); no new service or infrastructure.

**Risk**: Low. Scoped to one already-identified tier and pattern, not a wholesale refactor; the
main risk is choosing sane default timeouts/fallback responses per downstream call.

**Human time-on-task**: ~2-3 developer-days (add Resilience4j, wrap each `*RestClient` call,
define fallback responses, add tests).

**Agent time-on-task**: ~2-4 hours to scaffold the Resilience4j wiring and fallback stubs across
the `*RestClient` classes, plus human review of the chosen timeout/fallback values.

> Adopting this recommendation requires a future `/speckit.specify` cycle before any
> implementation begins — this document does not authorize implementation.

## Alternatives considered

- **B (client-side degradation in react-ui)**: Pushes responsibility to the frontend, which has
  no visibility into which downstream microservice actually failed; it is a weaker leverage
  point than fixing the single gateway chokepoint directly.
- **C (service mesh)**: Would add infrastructure-level resilience without application code
  changes, but is a disproportionately large infrastructure investment for a small demo-scale
  deployment with no existing mesh or container-orchestration layer observed in any tier
  assessment.
