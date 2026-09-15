# Graceful Degradation When a Service Slows or Goes Down

## Outcome

We recommend adding Resilience4j circuit breakers, timeouts, and fallback responses at **both**
`api-gateway-microservice`'s `*RestClient`s and `checkout-microservice`'s own
`ShoppingCartRestClient`/`ProductCatalogRestClient`. This closes the only two hops in the call
chain where a downstream slowdown or outage today turns into a raw, ungraceful failure, using a
single proven pattern applied twice rather than new infrastructure.

**Top 10 solutions considered** (ranked, most to least viable):

1. Resilience4j circuit breakers/timeouts/fallbacks at **both** the gateway's `*RestClient`s and
   `checkout-microservice`'s `*RestClient`s.
2. Resilience4j circuit breakers/timeouts/fallbacks at the gateway's `*RestClient`s only.
3. Bulkhead/thread-pool isolation per downstream call, so one slow dependency can't exhaust the
   request-handling threads serving calls to healthy dependencies.
4. API-gateway response caching (stale-while-revalidate) for read-heavy product endpoints, so a
   downstream outage serves last-known-good data instead of a raw failure.
5. Client-side degradation in `react-ui` — show cached/stale product data or a friendly error
   state when a gateway call fails.
6. Adopt a service mesh (e.g., Istio) to provide circuit breaking at the infrastructure layer,
   independent of application code.
7. Eureka peer-replication / multi-instance service registry, addressing the registry's own
   documented single-instance risk (`eureka-server-local.md`, 16-Factor VIII, score 2) as a
   discovery-layer point of failure.
8. Asynchronous, queue-based decoupling between `checkout-microservice` and
   `cart-microservice`/`products-microservice` for non-critical calls, trading synchronous
   coupling for eventual consistency.
9. Health-check-driven retry/backoff at REST-client callers, relying on Eureka's existing
   instance health checks to route away from unhealthy service instances.
10. Formalize an incident-response runbook — no code change, document and rehearse manual
    recovery steps for a downstream outage.

(Ranking basis: solutions are ordered by how directly and completely they close the two
documented gaps — the gateway's and checkout's unprotected `*RestClient`s — weighed against cost
and risk. Options 1-2 attack the gap directly with a stack-idiomatic library; options 3-5
complement but don't fully substitute for it; option 6 solves it at a much larger infrastructure
cost; options 7-10 address adjacent but distinct failure modes — registry availability, service
coupling, retry timing, and operational response — rather than the missing fallback/circuit-
breaker logic itself.)

## Client need

> when any service slows down or goes down, the storefront must degrade gracefully.

## Solution

[`api-gateway-microservice.md`](../architecture-assessment/api-gateway-microservice.md)'s
Findings state directly: "No fallback/circuit-breaker code was found in any `*RestClient` ... a
downstream outage (e.g. `checkout-microservice` down) is not currently handled gracefully by
observed code; a caller would see a raw failure rather than a degraded response." Its 16-Factor
row IX (Disposability, score 2) adds that "the missing circuit-breaker logic ... means requests
can fail slowly during a downstream outage rather than failing fast." Because `react-ui` only
ever calls `api-gateway-microservice`
([`react-ui.md`](../architecture-assessment/react-ui.md)), this gateway-layer gap is one point
where a downstream outage becomes a hard, ungraceful failure for every storefront request — but
not the only one:
[`checkout-microservice.md`](../architecture-assessment/checkout-microservice.md) independently
flags the identical gap for its own downstream calls to `cart-microservice` and
`products-microservice` (16-Factor VIII, Concurrency, score 2: "synchronous calls to two
downstream services with no circuit-breaker/timeout protection create cascading-failure risk
under concurrent load") and already recommends the same Resilience4j fix for itself. This
finding is also the second entry in `docs/context/gaps.md`'s Current Gaps list, confirming the
same absence of degradation logic through both artifacts. Adding Resilience4j at both hops
closes the gap end to end, using the same technique already a natural fit for both tiers'
existing Spring Boot 2.6.3 / Spring Cloud stack.

## Comparative Analysis (Top 6)

### 1. Resilience4j at both gateway and checkout-microservice

**SWOT**
- Strengths: Closes both documented gaps at once with one proven library already suited to the
  existing Spring Boot/Spring Cloud stack.
- Weaknesses: Touches two tiers instead of one, so it takes longer to ship than a single-tier fix.
- Opportunities: Establishes one consistent resilience pattern the fleet can reuse for any future
  `*RestClient`.
- Threats: Inconsistent default timeouts/fallback values between the two tiers could create
  confusing, tier-dependent degradation behavior if not coordinated.

**Buy vs. Build vs. Partner**
- Classification: Build.
- Rationale: Resilience4j is an open-source library already idiomatic for the existing stack;
  wrapping existing `*RestClient`s is in-house work, not a vendor engagement.

**TCO**
- Integration cost: Low-Medium — well-understood library, but two tiers to wrap instead of one.
- Operations cost: Low — no new running component, just configuration on existing services.
- Migration cost: Low — additive; existing calls keep working, wrapped with new behavior.
- Retirement cost: Low — annotations/wrappers can be removed without data migration.
- Overall signal: Low — the small increase in scope over Option 2 buys full-chain coverage.

### 2. Resilience4j at the gateway only

**SWOT**
- Strengths: Smaller, faster to ship; closes the external-edge gap for every storefront request.
- Weaknesses: Leaves `checkout-microservice`'s own downstream calls to cart/products unprotected
  — an already-documented, independently-flagged gap, not a hypothetical one.
- Opportunities: Could be shipped first as a fast partial fix, with checkout-microservice
  following later.
- Threats: A slow `cart-microservice` or `products-microservice` response during checkout still
  cascades ungracefully even after this fix ships, understating the client need's actual scope.

**Buy vs. Build vs. Partner**
- Classification: Build.
- Rationale: Same library, smaller scope; no external dependency involved.

**TCO**
- Integration cost: Low — one tier, three `*RestClient`s.
- Operations cost: Low.
- Migration cost: Low.
- Retirement cost: Low.
- Overall signal: Low sticker cost, but TCO must be read alongside the SWOT gap it leaves open —
  the client's "any service" requirement is not actually met.

### 3. Bulkhead/thread-pool isolation per downstream call

**SWOT**
- Strengths: Prevents one slow dependency from exhausting shared request threads, a failure mode
  circuit breakers alone don't fully address.
- Weaknesses: Does not by itself provide a fallback response — a caller still sees a failure,
  just a contained one, unless paired with Option 1 or 2.
- Opportunities: Complements Options 1/2 well as a defense-in-depth addition, not a standalone
  substitute.
- Threats: Misconfigured pool sizes can starve legitimate traffic just as effectively as the
  cascading-failure problem it's meant to solve.

**Buy vs. Build vs. Partner**
- Classification: Build (Resilience4j also provides bulkhead primitives).
- Rationale: Same library family as Options 1/2; no new vendor.

**TCO**
- Integration cost: Medium — thread-pool sizing requires load-informed tuning per downstream call.
- Operations cost: Medium — pool exhaustion needs monitoring distinct from circuit-breaker state.
- Migration cost: Low.
- Retirement cost: Low.
- Overall signal: Medium — real defense-in-depth value, but not a complete answer on its own.

### 4. API-gateway response caching for read-heavy endpoints

**SWOT**
- Strengths: Turns a downstream outage into stale-but-available data instead of a hard failure
  for read paths — arguably a better user experience than a fallback error message.
- Weaknesses: Only applies to read/GET-style product endpoints; write paths (checkout, cart
  mutation) have nothing safe to cache.
- Opportunities: Pairs naturally with Option 1/2's fallback responses — cache can *be* the
  fallback for reads.
- Threats: Serving stale data risks showing incorrect prices or inventory if not paired with a
  clear staleness signal to the client.

**Buy vs. Build vs. Partner**
- Classification: Build.
- Rationale: Gateway-local caching layer; no vendor needed.

**TCO**
- Integration cost: Medium — cache invalidation policy must be designed per endpoint.
- Operations cost: Medium — cache memory/size to monitor and tune.
- Migration cost: Low.
- Retirement cost: Low.
- Overall signal: Medium — valuable for reads specifically, but doesn't cover the write-path
  scenarios circuit breakers do.

### 5. Client-side degradation in react-ui

**SWOT**
- Strengths: Improves perceived experience at the point closest to the user.
- Weaknesses: `react-ui` has no visibility into which downstream microservice actually failed,
  and does nothing for the internal checkout -> cart/products hop.
- Opportunities: Cheap, low-risk complement to a server-side fix, not a substitute for one.
- Threats: If treated as the primary fix, the underlying server-side cascading-failure risk in
  `checkout-microservice` remains completely unaddressed.

**Buy vs. Build vs. Partner**
- Classification: Build.
- Rationale: Frontend-only change; no vendor or infrastructure involved.

**TCO**
- Integration cost: Low.
- Operations cost: Low.
- Migration cost: Low.
- Retirement cost: Low.
- Overall signal: Low, but see SWOT — low cost for a solution that doesn't reach the internal
  service-to-service hop at all.

### 6. Service mesh (e.g., Istio)

**SWOT**
- Strengths: Would add infrastructure-level resilience at every hop, including the internal
  checkout -> cart/products call, without application code changes.
- Weaknesses: No existing mesh or container-orchestration layer was observed in any tier
  assessment — this is a net-new platform investment, not an extension of anything adopted today.
- Opportunities: Scales well if the fleet grows well beyond its current 7 tiers.
- Threats: Disproportionately large infrastructure investment for a small demo-scale deployment.

**Buy vs. Build vs. Partner**
- Classification: Partner (adopt and operate an open-source mesh platform, closer to a platform
  partnership than in-house library code).
- Rationale: A service mesh is infrastructure the team would operate but not author — closer to
  adopting a platform than writing application code.

**TCO**
- Integration cost: High — requires a container-orchestration layer not currently observed
  anywhere in the fleet.
- Operations cost: High — an entirely new operational discipline (mesh control plane, sidecars).
- Migration cost: Medium-High — every service's networking model changes.
- Retirement cost: High — unwinding a mesh after adoption is a significant undertaking.
- Overall signal: High — TCO clearly reverses the initial "no app code changes" appeal.

## Recommendation

**Chosen: Solution #1, Resilience4j at both gateway and checkout-microservice.** The client need
is that *any* service slowing down or going down must degrade gracefully, not just the external
edge. SWOT for Option 2 (gateway-only) explicitly surfaces the gap Option 1 closes: checkout's
own downstream calls. The Buy vs. Build vs. Partner analysis favors Build for both tiers since
Resilience4j is already idiomatic for the stack, unlike Option 6's Partner-a-mesh path. TCO
confirms Option 1's incremental cost over Option 2 is small (Low vs. Low), while Option 6's TCO
is High — the same conclusion the SWOT/TCO framework reaches independently for each layer.
Options 3 and 4 remain valuable defense-in-depth additions but neither alone closes both
documented gaps, and Option 5 doesn't reach the internal checkout-to-downstream hop at all.

**Size**: M — Resilience4j wrapping across the gateway's three `*RestClient`s plus
checkout-microservice's two `*RestClient`s; still no new service or infrastructure.

**Risk**: Low-Medium. Same proven pattern applied at two already-identified tiers, not a
wholesale refactor; the main risk is choosing sane, consistent default timeouts/fallback
responses across both tiers so behavior doesn't diverge between the edge and the internal hop.

**Human time-on-task**: ~4-6 developer-days (add Resilience4j, wrap each `*RestClient` call in
both tiers, define fallback responses, add tests for both).

**Agent time-on-task**: ~3-5 hours to scaffold the Resilience4j wiring and fallback stubs across
both tiers' `*RestClient` classes, plus human review of the chosen timeout/fallback values.

> Adopting this recommendation requires a future `/speckit.specify` cycle before any
> implementation begins — this document does not authorize implementation.

## Alternatives considered

- **Solution #2 (gateway-only)**: Smaller and faster to ship, but its own SWOT identifies the
  exact gap Solution #1 closes — checkout-microservice's own downstream calls remain unprotected.
- **Solution #3 (bulkhead isolation)**: Valuable defense-in-depth, but does not itself provide a
  fallback response — a real complement to Solution #1, not a standalone replacement.
- **Solution #4 (gateway response caching)**: Strong fit for read paths, but doesn't cover the
  write-path (checkout/cart) scenarios that circuit breakers handle.
- **Solution #5 (client-side degradation)**: Cheapest option analyzed, but has no visibility into
  which downstream service failed and does nothing for the internal checkout hop.
- **Solution #6 (service mesh)**: Would cover every hop uniformly, but TCO is High against a
  fleet with no existing container-orchestration or mesh layer — a disproportionate investment.
- **Solution #7 (Eureka peer-replication, ranked 7-10, not analyzed)**: Addresses the registry's
  own single-instance risk, a related but distinct failure mode from the `*RestClient` gap this
  document targets.
- **Solution #8 (async/queue decoupling, ranked 7-10, not analyzed)**: A larger architectural
  change than the client need requires today; better suited to a future iteration if synchronous
  coupling itself becomes the bottleneck.
- **Solution #9 (health-check-driven retry/backoff, ranked 7-10, not analyzed)**: A useful
  complement, but relies on Eureka de-registration timing rather than fixing the missing
  fallback behavior directly.
- **Solution #10 (formalize an incident runbook, ranked 7-10, not analyzed)**: Fastest to
  "complete," but purely operational — does nothing to make the storefront itself degrade
  gracefully.

