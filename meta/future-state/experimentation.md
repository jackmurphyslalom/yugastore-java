# Experimentation Without an Engineering Bottleneck

## Outcome

**Before** — On Thursday afternoon, a product manager wants to try a lower weekend price on a
slow-moving product and a tweaked ranking order to see if it sells better. They file a ticket, an
engineer has to pick it up, change code, and redeploy, and by the time the change goes live the
weekend window it was meant for has already passed.

**After** — The same product manager now opens the toggle screen, changes the price and ranking
values themselves, and the storefront reflects the new values within seconds — for products,
ranking, and checkout pricing alike. Rolling a change back or retiring it is just as immediate,
with no engineer and no redeploy in the loop.

**Bridge** — A Spring Cloud Config Server becomes the single runtime-configuration source for
ranking, UX, and pricing toggles, extending the Spring Cloud/Eureka dependency family every one of
the 7 tiers already runs; `products-microservice`, `checkout-microservice`, and `react-ui`'s proxy
target read current values from it directly, at the lowest incremental infrastructure cost of any
option analyzed.

**Top 10 solutions considered** (ranked, most to least viable):

1. Spring Cloud Config Server — externalize ranking/UX/pricing parameters at runtime, extending
   the fleet's existing Spring Cloud/Eureka stack that every one of the 7 tiers already
   registers with.
2. YugabyteDB-backed experiment/variant table — store variant assignments as data behind the
   repository pattern already proven in `products-microservice`/`cart-microservice`/`checkout-microservice`.
3. Self-hosted open-source flag service (e.g. Unleash) as an 8th Eureka-registered tier —
   follows the same registration pattern every other tier already uses.
4. Dedicated feature-flag/experimentation SaaS (e.g. a LaunchDarkly-style platform) integrated
   at `api-gateway-microservice`, the system's single external API surface.
5. Per-tier environment-variable-driven toggles — extend the env-var config pattern already
   scored well in `cart-microservice.md` (16-Factor III, Config, score 4 — the fleet's best
   Config score) to the 3 consuming tiers instead of building shared infrastructure.
6. Embedded A/B variant-selection logic directly inside `products-microservice`'s
   `ProductRankingServiceImpl`.
7. Gateway-hosted admin toggle endpoint — reuse the fleet-wide Admin Processes gap (4 of 7 tiers
   score 2 or below per `README.md`'s Foundational Posture Score, worst at `eureka-server-local.md`
   16-Factor XII, score 1) as the seam for a lightweight, purpose-built experimentation control
   panel.
8. Client-side experiment SDK in `react-ui` — reads flags directly in the frontend, the tier
   already scored weakest on config externalization (`react-ui.md`, 16-Factor III, score 2).
9. Database-driven canary routing at `api-gateway-microservice` — route a percentage of traffic
   to a second, versioned `products-microservice` instance registered separately in Eureka.
10. Formalize the status quo — no new mechanism; instead, document and streamline the existing
    code-change-and-redeploy path as an explicit, faster change-management process.

## Client need

> run constant experiments (pricing, UX, recommendations) without engineering becoming a bottleneck.

## Solution

No feature-flagging, A/B testing, or dynamic-configuration mechanism exists anywhere in the
assessed system today. Configuration is mostly static and code-adjacent rather than externalized
at runtime:

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

A Spring Cloud Config Server closes this gap directly: it externalizes ranking, UX, and pricing
parameters at runtime, letting `products-microservice`, `checkout-microservice`, and `react-ui`'s
proxy target read current values without a redeploy. Because Eureka registration is already a
constitutional requirement (`docs/architecture/overview.md`) and every one of the 7 assessed
tiers already registers with `eureka-server-local`, adding Spring Cloud Config is an incremental
extension of an already-adopted dependency family, not a new vendor or infrastructure component.

## Comparative Analysis (Top 6)

### 1. Spring Cloud Config Server

**SWOT**
- Strengths: Same dependency family as the fleet's existing Eureka/Spring Cloud stack; every tier
  already knows how to register with and read from Spring Cloud infrastructure.
- Weaknesses: Flat, property-style values are a weaker fit for structured, relational data than a
  database table would be.
- Opportunities: One mechanism can simultaneously serve UX/ranking toggles here and pricing rules
  (see `pricing-agility.md`), avoiding two independent build efforts.
- Threats: If the config schema is not coordinated across the 3 consuming tiers, drift between
  environments could reintroduce the "in code, not configuration" problem in a new form.

**Buy vs. Build vs. Partner**
- Classification: Build (self-host an open-source Spring Cloud Config Server).
- Rationale: No cost to "buy" a license — Spring Cloud Config is open-source and already aligned
  with the team's existing Spring Cloud skill set, so building/operating it is faster than
  negotiating and integrating a third-party platform.

**TCO**
- Integration cost: Low — Eureka-style client bootstrap is a familiar pattern for this fleet.
- Operations cost: Low-Medium — one more Eureka-registered process to run and monitor, same
  operational model as `eureka-server-local`.
- Migration cost: Low — additive; no existing config needs to be torn out to adopt it.
- Retirement cost: Low — a config server can be decommissioned by reverting to static
  `application.yml` values with no data-migration step.
- Overall signal: Low.

### 2. YugabyteDB-backed experiment/variant table

**SWOT**
- Strengths: Reuses the Backing Services abstraction pattern already scored 4-5 (16-Factor IV)
  across `cart-microservice.md`, `checkout-microservice.md`, and `products-microservice.md` — no
  new infrastructure component at all.
- Weaknesses: Mixes experimentation state into the same repository seam as product/cart/checkout
  domain data, with no dedicated, auditable surface of its own.
- Opportunities: Queryable and relational, well-suited if experiment targeting logic grows
  complex (user segments, cohorts).
- Threats: Without care, experiment-assignment writes could contend with production domain-data
  traffic on the same database.

**Buy vs. Build vs. Partner**
- Classification: Build.
- Rationale: A new table behind an existing repository is pure internal build effort; nothing to
  buy or partner for.

**TCO**
- Integration cost: Low — extends an already-proven repository pattern.
- Operations cost: Low — no new backing service, just new schema on an already-operated database.
- Migration cost: Low — additive schema change.
- Retirement cost: Low — drop the table; no separate process to decommission.
- Overall signal: Low, but see SWOT: cheap does not offset the lack of a dedicated,
  auditable experimentation surface.

### 3. Self-hosted open-source flag service (Unleash-style), 8th Eureka-registered tier

**SWOT**
- Strengths: Purpose-built for feature flags/experiments (targeting rules, gradual rollout,
  kill-switches) — a more complete answer than repurposing general config infrastructure.
- Weaknesses: A genuinely new tier (8th service) to build, secure, and operate, unlike Options 1
  and 2 which extend existing infrastructure.
- Opportunities: Follows the exact registration pattern every other tier already uses with
  `eureka-server-local`, so operational onboarding is familiar even though the component is new.
- Threats: Adds a new single point of failure to an already Eureka-dependent fleet
  (`eureka-server-local.md` already flags single-instance risk for the registry itself).

**Buy vs. Build vs. Partner**
- Classification: Build (self-hosted open-source) with a Partner-lite dependency on the upstream
  OSS project for updates/security patches.
- Rationale: Open-source avoids license cost, but the team still owns operating a new service.

**TCO**
- Integration cost: Medium — new service to wire into Eureka and secure.
- Operations cost: Medium — a new always-on process to monitor, patch, and back up.
- Migration cost: Low — additive.
- Retirement cost: Medium — decommissioning requires migrating any live experiment
  configuration elsewhere first.
- Overall signal: Medium — purpose-built capability at the cost of a new operated component.

### 4. Dedicated feature-flag/experimentation SaaS at the gateway

**SWOT**
- Strengths: Most complete experimentation feature set (targeting, gradual rollout,
  kill-switches, analytics) without building any of it in-house.
- Weaknesses: Introduces a new external vendor dependency the fleet has no existing relationship
  with, unlike the Spring Cloud family already adopted.
- Opportunities: Fastest path to advanced experimentation capabilities (multivariate tests,
  statistical analysis) if the client's ambitions grow beyond simple toggles.
- Threats: Vendor lock-in and recurring subscription cost for a demo-scale deployment with no
  existing SaaS integrations observed in any tier assessment.

**Buy vs. Build vs. Partner**
- Classification: Buy.
- Rationale: A mature SaaS platform is the fastest way to full-featured experimentation, but only
  economically justified once experimentation needs exceed what Options 1-3 can deliver.

**TCO**
- Integration cost: Low-Medium — SDK integration at the gateway is straightforward, but a new
  vendor relationship (contracts, security review) adds overhead absent from Options 1-3.
- Operations cost: Low for the platform itself (vendor-managed), but recurring subscription cost
  scales with usage.
- Migration cost: Medium — exporting/re-implementing flag logic elsewhere later is nontrivial.
- Retirement cost: Medium-High — every flag consumer must be rewired away from the vendor SDK.
- Overall signal: Medium-High — the strongest capability, but the highest ongoing and exit cost
  of the top 6.

### 5. Per-tier environment-variable-driven toggles

**SWOT**
- Strengths: Lowest-lift option — extends a pattern already scored 4/5 in
  `cart-microservice.md` (16-Factor III, Config), no new infrastructure at all.
- Weaknesses: Environment variables require a process restart to pick up new values on most
  deployment setups — a materially weaker "no redeploy" story than a live config server.
- Opportunities: Immediately actionable with zero new components, useful as an interim step.
- Threats: Does not scale to frequent, ad-hoc experimentation — restarting a service to flip a
  toggle reintroduces engineering-in-the-loop friction, the exact complaint being solved for.

**Buy vs. Build vs. Partner**
- Classification: Build (trivial — configuration convention, not new code).
- Rationale: No component to build or buy; purely a deployment-configuration discipline change.

**TCO**
- Integration cost: Very low.
- Operations cost: Low, but hidden cost is operational toil from restart-to-toggle.
- Migration cost: Very low.
- Retirement cost: Very low.
- Overall signal: Low sticker cost, but TCO analysis reverses the initial "cheapest option"
  impression once restart-driven toggling is weighed against the actual client need.

### 6. Embedded A/B logic in products-microservice

**SWOT**
- Strengths: Fastest to build for ranking experiments specifically; no cross-tier coordination
  needed.
- Weaknesses: Scoped to one service and one concern (ranking) — does not help with pricing or UX
  experiments elsewhere in the fleet, unlike Options 1-4.
- Opportunities: Useful as a narrow, fast-follow proof of concept before broader adoption of
  Option 1.
- Threats: Risks becoming a one-off pattern other tiers reinvent independently, recreating the
  fragmentation the client need is trying to eliminate.

**Buy vs. Build vs. Partner**
- Classification: Build.
- Rationale: In-service logic change; no external dependency involved.

**TCO**
- Integration cost: Low — confined to one tier's existing ranking service.
- Operations cost: Low — no new process to run.
- Migration cost: Medium — logic embedded this way is harder to later generalize to other tiers.
- Retirement cost: Low — code deletion, no external state to unwind.
- Overall signal: Low today, but TCO rises if the fleet later needs the same capability
  elsewhere and has to re-platform off this embedded approach.

## Recommendation

**Chosen: Solution #1, Spring Cloud Config Server.** SWOT shows it is the only top-6 option that
extends an already-adopted dependency family while remaining broad enough to cover ranking, UX,
and pricing together (Options 2 and 6 are narrower; Options 3 and 4 add net-new operated
components). The Buy vs. Build vs. Partner analysis favors Build here specifically because the
skill set already exists in-house, unlike Option 4's Buy path. TCO confirms the lowest overall
signal among the options broad enough to matter (Option 5 looks cheaper on paper but its
restart-driven toggling directly reintroduces the engineering bottleneck the client is solving
for).

**Size**: M — a Spring Cloud Config Server plus wiring `products-microservice`,
`checkout-microservice`, and `react-ui`'s proxy target to read from it.

**Risk**: Low-Medium. Extends an already-adopted dependency family (the fleet's existing Eureka
/ Spring Cloud stack), so it is not a wholesale refactor; the main risk is coordinating the new
externalized config schema across the three consuming tiers.

**Human time-on-task**: ~3-5 developer-days (server setup, client wiring, one config schema).

**Agent time-on-task**: ~1-2 hours for scaffolding the Config Server and client bootstrap code,
plus human review of the schema and rollout plan.

> Adopting this recommendation requires a future `/speckit.specify` cycle before any
> implementation begins — this document does not authorize implementation.

## Alternatives considered

- **Solution #2 (YugabyteDB-backed variant data)**: Cheapest TCO of the analyzed options, but
  mixes experimentation state into the same seam as product/cart/checkout domain data rather than
  giving it its own dedicated, auditable externalization surface.
- **Solution #3 (self-hosted flag service, 8th tier)**: Most purpose-built capability, but adds a
  net-new operated component and single point of failure the fleet doesn't need yet at this scale.
- **Solution #4 (experimentation SaaS)**: Fastest to advanced capability, but the highest ongoing
  subscription cost and exit cost (TCO) of the top 6, and the only vendor dependency in the set.
- **Solution #5 (per-tier env-var toggles)**: Lowest integration cost, but TCO analysis reverses
  the initial preference — restart-driven toggling reintroduces the exact engineering-bottleneck
  problem being solved for.
- **Solution #6 (embedded A/B in products-microservice)**: Fastest narrow fix, but scoped to
  ranking only; does not serve the UX or pricing halves of the client need.
- **Solution #7 (gateway admin toggle endpoint, ranked 7-10, not analyzed)**: A bespoke,
  purpose-built control panel is a larger custom build than reusing Spring Cloud Config for the
  same outcome.
- **Solution #8 (react-ui client-side SDK, ranked 7-10, not analyzed)**: `react-ui` only ever
  calls `api-gateway-microservice`, so flag logic there can't control server-side ranking or
  pricing behavior — too narrow to answer the full client need.
- **Solution #9 (DB-driven canary routing at the gateway, ranked 7-10, not analyzed)**: Solves
  traffic-splitting, not parameter externalization — a different problem than "change behavior
  without redeploying."
- **Solution #10 (formalize the status quo, ranked 7-10, not analyzed)**: Fastest to declare
  "done," but does not remove engineering from the loop at all — fails the client need outright.

