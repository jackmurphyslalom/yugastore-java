# Experimentation Without an Engineering Bottleneck

## Client need

> run constant experiments (pricing, UX, recommendations) without engineering becoming a bottleneck.

## Current-state finding

No feature-flagging, A/B testing, or dynamic-configuration mechanism exists anywhere in the
assessed system. Configuration is mostly static and code-adjacent rather than externalized at
runtime:

- [`products-microservice.md`](../architecture-assessment/products-microservice.md) (16-Factor
  III, Config): `application.yml` sets only `spring.application.name`; YCQL connection details
  and other behavior live in `YugabyteYCQLConfig`, i.e. in code rather than runtime-editable
  config.
- [`react-ui.md`](../architecture-assessment/react-ui.md) (16-Factor III, Config): the dev proxy
  target (`http://localhost:8081`) is a static `package.json` value, "the least externalized
  config of any tier."
- [`api-gateway-microservice.md`](../architecture-assessment/api-gateway-microservice.md)
  confirms the gateway is the single external API surface, but no runtime toggle/flag mechanism
  was found there either.

Together these findings show that changing ranking, UX, or pricing behavior today requires a
code change and a full redeploy of the owning service — there is no existing seam for
engineering-light experimentation.

## Options considered

- **A**: Adopt a dedicated feature-flag/experimentation platform (e.g., a LaunchDarkly-style
  SaaS or self-hosted flag service) integrated at the `api-gateway-microservice` layer.
- **B**: Build an embedded A/B variant-selection mechanism directly inside
  `products-microservice`'s ranking logic (`ProductRankingServiceImpl`).
- **C**: Introduce a Spring Cloud Config Server to externalize configuration at runtime,
  extending the Spring Cloud ecosystem the fleet already depends on (Eureka).

## Recommendation

**Chosen: Option C.** The fleet already runs on Spring Cloud Netflix (Eureka registration is a
constitutional requirement per `docs/architecture/overview.md`), so adding Spring Cloud Config
is an incremental extension of an already-adopted dependency family rather than a new vendor or
infrastructure component. It directly closes the gap found above — static, code-level config —
letting pricing/UX/ranking parameters change at runtime without a redeploy, which is the
engineering-bottleneck complaint itself. It is a smaller lift than a full experimentation
platform (Option A) and, unlike Option B, is not scoped to a single service.

> Adopting this recommendation requires a future `/speckit.specify` cycle before any
> implementation begins — this document does not authorize implementation.

## Alternatives considered

- **A (dedicated feature-flag platform)**: Would offer richer experimentation primitives
  (targeting, gradual rollout, statistical reporting) but introduces a new vendor or
  self-hosted infrastructure dependency not present anywhere else in the stack today — a bigger
  lift than the current finding justifies.
- **B (embedded A/B logic in products-microservice)**: Couples experimentation to one service's
  ranking code and does not help the pricing or UX experiments the client need explicitly
  names, since those concerns live outside `products-microservice`.
