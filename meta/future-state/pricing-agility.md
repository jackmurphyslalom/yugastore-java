# Pricing Agility Without Full Redeploys

## Client need

> pricing rules change weekly; engineers shouldn't need to redeploy everything.

## Current-state finding

No pricing-specific logic, service, or configuration was found in any of the seven tier
assessments under `meta/architecture-assessment/` — none of the seven files
([`eureka-server-local.md`](../architecture-assessment/eureka-server-local.md),
[`products-microservice.md`](../architecture-assessment/products-microservice.md),
[`checkout-microservice.md`](../architecture-assessment/checkout-microservice.md),
[`cart-microservice.md`](../architecture-assessment/cart-microservice.md),
[`api-gateway-microservice.md`](../architecture-assessment/api-gateway-microservice.md),
[`login-microservice.md`](../architecture-assessment/login-microservice.md),
[`react-ui.md`](../architecture-assessment/react-ui.md)) mentions price or pricing rules at all.
The closest related finding is
[`products-microservice.md`](../architecture-assessment/products-microservice.md)'s Complication:
`ProductMetadata` and related domain classes are duplicated by hand across
`products-microservice`, `checkout-microservice`, and `api-gateway-microservice` — any schema
change (which a new pricing-rules field would be) must currently be applied identically in at
least three places. There is explicitly no directly relevant pricing finding to cite beyond this
absence and the related duplication risk.

## Options considered

- **A**: Externalize pricing rules into runtime-loadable configuration (e.g., a Spring Cloud
  Config source or a dedicated `pricing_rules` table in YugabyteDB) read by
  `products-microservice`/`checkout-microservice` without a redeploy.
- **B**: Introduce a new, dedicated pricing microservice that owns rule evaluation, called by
  `checkout-microservice` and `products-microservice` through the existing gateway-fronted
  pattern.
- **C**: Add pricing fields directly to the existing duplicated `ProductMetadata` model and
  reload it without redeploying, accepting the multi-place duplication risk already flagged.

## Recommendation

**Chosen: Option A.** This is the lowest-lift path that directly answers "shouldn't need to
redeploy": runtime-loadable configuration or data removes pricing changes from the
build/redeploy cycle entirely, without requiring a new service (Option B) or perpetuating the
three-way domain-model duplication already flagged as a risk in
[`products-microservice.md`](../architecture-assessment/products-microservice.md) (Option C).

**Size**: M — a new runtime-loadable pricing-rules source (config or table) plus read paths in
`products-microservice` and `checkout-microservice`.

**Risk**: Medium. Not a wholesale refactor, but it touches two services and sits near the
already-flagged `ProductMetadata` duplication, so the schema must be coordinated carefully to
avoid adding a fourth hand-synchronized copy.


**Human time-on-task**: ~4-6 developer-days (schema design, two service read paths, rollout
verification).

**Agent time-on-task**: ~2-4 hours to scaffold the config/table schema and both services' read
paths, plus human review of the schema and duplication risk.
> Adopting this recommendation requires a future `/speckit.specify` cycle before any
> implementation begins — this document does not authorize implementation.

## Alternatives considered

- **B (dedicated pricing microservice)**: The most durable long-term architecture, cleanly
  separating pricing as its own bounded context, but it requires wiring a new REST client
  through `api-gateway-microservice` and introducing yet another copy of pricing-adjacent domain
  data — a bigger lift than the current absence of any pricing logic justifies today.
- **C (extend the existing duplicated model)**: Fastest to build, but it directly perpetuates the
  hand-synchronized, three-place domain-model duplication already identified as a risk in
  `products-microservice.md`, rather than reducing it.
