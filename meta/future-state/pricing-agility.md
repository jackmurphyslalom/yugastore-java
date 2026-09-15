# Pricing Agility Without Full Redeploys

## Outcome

We recommend a dedicated `pricing_rules` table in YugabyteDB, read by `products-microservice`
and `checkout-microservice` at request time. This is the lowest-lift path that removes pricing
changes from the build/redeploy cycle entirely, without introducing a new service or extending
the three-way domain-model duplication already flagged as a risk in this system.

**Top 10 solutions considered** (ranked, most to least viable):

1. Dedicated `pricing_rules` table in YugabyteDB, read by `products-microservice` and
   `checkout-microservice` without a redeploy.
2. Reuse the Spring Cloud Config Server recommended in
   [`experimentation.md`](./experimentation.md) as the single runtime-config source for pricing
   rules too, instead of a separate database table.
3. A new, dedicated pricing microservice that owns rule evaluation, called by
   `checkout-microservice` and `products-microservice` through the existing gateway-fronted
   pattern.
4. Add pricing fields directly to the existing duplicated `ProductMetadata` model, reloaded
   without redeploying, accepting the multi-place duplication risk already flagged.
5. A pricing rules engine embedded as a library inside `checkout-microservice` only, reading
   externalized rule data (from Option 1 or 2) but keeping evaluation logic in-process rather
   than in a new service.
6. A managed third-party pricing/rules-engine SaaS, integrated at `api-gateway-microservice`.
7. Batch-recompute pricing overnight into a static, versioned artifact deployed via the existing
   build pipeline — faster than ad hoc rule changes today, but still not truly "no redeploy."
8. Event-driven pricing updates via a message queue, decoupling rule publication from
   `products-microservice`/`checkout-microservice` read paths.
9. Admin UI directly against the production database (manual `UPDATE` statements against
   `ProductMetadata` or a new pricing table) as an unmanaged, ungoverned interim mechanism.
10. Formalize the status quo — no new mechanism; instead, document and expedite the existing
    code-change-and-redeploy path as a faster, more disciplined change-management process.

## Client need

> pricing rules change weekly; engineers shouldn't need to redeploy everything.

## Solution

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

A dedicated `pricing_rules` table answers the client need directly: it is runtime-loadable (no
redeploy to change a rule), queryable and versionable (unlike flat config), and additive — it
does not touch or extend the already-fragile, hand-duplicated `ProductMetadata` model.

## Comparative Analysis (Top 6)

### 1. Dedicated pricing_rules table in YugabyteDB

**SWOT**
- Strengths: Reuses the repository-abstraction pattern already proven across
  `products-microservice`/`checkout-microservice`/`cart-microservice`; queryable and versionable.
- Weaknesses: Two services (`products-microservice`, `checkout-microservice`) must each add a
  read path and stay in sync on schema.
- Opportunities: A clean, dedicated home for pricing data avoids extending the already-flagged
  `ProductMetadata` duplication (Option 4) any further.
- Threats: If the schema isn't carefully scoped, it risks becoming a second, independently
  duplicated model alongside `ProductMetadata` rather than a single source of truth.

**Buy vs. Build vs. Partner**
- Classification: Build.
- Rationale: A new table behind existing repositories is in-house schema/read-path work; no
  vendor or new service needed.

**TCO**
- Integration cost: Medium — two services need new read paths against the same schema.
- Operations cost: Low — no new backing service, just schema on an already-operated database.
- Migration cost: Low — additive; existing `ProductMetadata` is untouched.
- Retirement cost: Low — drop the table if pricing rules move elsewhere later.
- Overall signal: Low-Medium.

### 2. Reuse the Spring Cloud Config Server from experimentation.md

**SWOT**
- Strengths: Avoids building a second externalization mechanism; one infrastructure component
  serves both experimentation toggles and pricing rules.
- Weaknesses: Flat, property-style config is a weaker fit for structured, potentially per-product
  pricing rules than a queryable relational table.
- Opportunities: If pricing rules stay simple (a handful of global parameters), this is the
  cheapest incremental option since the server is already being built for `experimentation.md`.
- Threats: If pricing rules grow to per-product or per-category granularity, property-style
  config becomes unwieldy and the team ends up building a table anyway, on top of the config
  server.

**Buy vs. Build vs. Partner**
- Classification: Build.
- Rationale: Shares infrastructure with Option 1 of `experimentation.md`; no vendor involved.

**TCO**
- Integration cost: Low — the server already exists once `experimentation.md`'s recommendation
  ships; this is incremental schema on that server.
- Operations cost: Low — no additional operated component beyond what `experimentation.md`
  already introduces.
- Migration cost: Low.
- Retirement cost: Low.
- Overall signal: Low, but TCO must be weighed against the SWOT risk that structured pricing
  rules outgrow flat config and force a second build anyway.

### 3. Dedicated pricing microservice

**SWOT**
- Strengths: The most durable long-term architecture, cleanly separating pricing as its own
  bounded context with a clear owner.
- Weaknesses: Requires wiring a new REST client through `api-gateway-microservice` and
  introduces yet another copy of pricing-adjacent domain data.
- Opportunities: Scales well if pricing logic grows complex (tiered discounts, promotions,
  region-specific rules) beyond what a table or config server can express.
- Threats: A bigger lift than the current absence of any pricing logic justifies today — risk of
  over-building for a need not yet demonstrated.

**Buy vs. Build vs. Partner**
- Classification: Build.
- Rationale: In-house service; no existing pricing-engine vendor relationship observed anywhere
  in the fleet.

**TCO**
- Integration cost: High — new service, new gateway client, new Eureka registration.
- Operations cost: Medium-High — an 8th/9th tier to run, monitor, and secure.
- Migration cost: Medium — future migration to this service from Option 1 or 2 is straightforward
  since both are simpler precursors.
- Retirement cost: Medium — decommissioning requires migrating any live pricing data elsewhere.
- Overall signal: Medium-High — durable, but disproportionate to today's demonstrated need.

### 4. Extend the duplicated ProductMetadata model

**SWOT**
- Strengths: Fastest to build — no new table, service, or config server.
- Weaknesses: Directly perpetuates the hand-synchronized, three-place domain-model duplication
  already identified as a risk in `products-microservice.md`.
- Opportunities: None beyond short-term speed; does not reduce any existing risk.
- Threats: Every pricing-rule change now also needs to be replicated by hand across
  `products-microservice`, `checkout-microservice`, and `api-gateway-microservice` — the
  opposite of the client's "shouldn't need to redeploy/re-touch everything" need.

**Buy vs. Build vs. Partner**
- Classification: Build.
- Rationale: Pure in-house model change; fastest but riskiest of the top 6.

**TCO**
- Integration cost: Low upfront.
- Operations cost: High ongoing — every future schema change must be manually kept in sync
  across three places.
- Migration cost: Low now, but High later if this duplication must eventually be unwound.
- Retirement cost: High — untangling pricing fields from an already-duplicated model is harder
  than retiring a dedicated table or service.
- Overall signal: Low sticker cost, but TCO analysis reverses the initial "fastest" preference
  once ongoing duplication-maintenance cost is included.

### 5. Embedded pricing rules engine inside checkout-microservice

**SWOT**
- Strengths: Keeps rule evaluation logic close to where it's used (checkout), avoiding a new
  service while still separating rule *data* (from Option 1/2) from evaluation *logic*.
- Weaknesses: `products-microservice` (which also needs pricing for display/ranking) would not
  share this evaluation logic, risking a second, divergent implementation.
- Opportunities: A reasonable stepping stone toward Option 3 if evaluation logic grows complex
  later.
- Threats: Two services needing consistent pricing behavior (checkout and products) but only one
  owning evaluation logic risks exactly the kind of drift the client need is trying to prevent.

**Buy vs. Build vs. Partner**
- Classification: Build.
- Rationale: In-process library code; no vendor or new service.

**TCO**
- Integration cost: Medium — evaluation logic plus a read path against externalized rule data.
- Operations cost: Low — no new running component.
- Migration cost: Medium — logic embedded this way is harder to later share with
  `products-microservice`.
- Retirement cost: Low.
- Overall signal: Medium — reasonable, but narrower than Option 1/2 since it doesn't naturally
  serve `products-microservice` too.

### 6. Managed third-party pricing/rules-engine SaaS

**SWOT**
- Strengths: Most complete rules-engine feature set (complex discount logic, A/B pricing tests)
  without building any of it in-house.
- Weaknesses: A new external vendor dependency with no existing relationship anywhere in the
  fleet, similar to the SaaS option considered (and not chosen) in `experimentation.md`.
- Opportunities: Fastest path to sophisticated pricing logic if the client's ambitions grow well
  beyond simple weekly rule changes.
- Threats: Vendor lock-in and recurring cost for a demo-scale deployment with no pricing-specific
  requirement demonstrated yet beyond "change weekly without a redeploy."

**Buy vs. Build vs. Partner**
- Classification: Buy.
- Rationale: A mature SaaS platform is the fastest way to sophisticated pricing capability, but
  only justified once needs exceed a simple externalized table or config value.

**TCO**
- Integration cost: Medium — SDK/API integration plus a new vendor relationship.
- Operations cost: Low for the platform itself, but recurring subscription cost.
- Migration cost: Medium-High — pricing logic becomes coupled to a vendor's rule syntax.
- Retirement cost: High — unwinding vendor-specific rule definitions back into an in-house system
  is a significant effort.
- Overall signal: High — the strongest capability, but the highest ongoing and exit cost of the
  top 6, for a need not yet shown to require it.

## Recommendation

**Chosen: Solution #1, dedicated pricing_rules table in YugabyteDB.** SWOT shows it is the only
top-6 option that both removes pricing from the redeploy cycle and avoids extending the
already-flagged `ProductMetadata` duplication (unlike Option 4). The Buy vs. Build vs. Partner
analysis rules out Options 3 and 6 as disproportionate Build/Buy investments for a need not yet
shown to require a dedicated service or vendor platform. TCO confirms Option 1's Low-Medium
signal beats Option 3's Medium-High and Option 6's High, and directly reverses Option 4's
apparent "fastest" advantage once ongoing duplication-maintenance cost is counted. Option 2
(reuse Spring Cloud Config) remains a close, low-cost alternative, but a queryable table is a
better fit than flat config if pricing rules become structured or per-product.

**Size**: M — a new `pricing_rules` table plus read paths in `products-microservice` and
`checkout-microservice`.

**Risk**: Medium. Not a wholesale refactor, but it touches two services and sits near the
already-flagged `ProductMetadata` duplication, so the schema must be coordinated carefully to
avoid adding a fourth hand-synchronized copy.

**Human time-on-task**: ~4-6 developer-days (schema design, two service read paths, rollout
verification).

**Agent time-on-task**: ~2-4 hours to scaffold the table schema and both services' read paths,
plus human review of the schema and duplication risk.

> Adopting this recommendation requires a future `/speckit.specify` cycle before any
> implementation begins — this document does not authorize implementation.

## Alternatives considered

- **Solution #2 (reuse Spring Cloud Config)**: Cheapest incremental cost since the server already
  exists for `experimentation.md`, but flat config is a weaker fit than a relational table once
  pricing rules become structured or per-product.
- **Solution #3 (dedicated pricing microservice)**: The most durable long-term architecture, but
  TCO (new service, new gateway client, new Eureka registration) is disproportionate to today's
  demonstrated need.
- **Solution #4 (extend ProductMetadata)**: Fastest upfront, but TCO analysis reverses this once
  ongoing three-way duplication-maintenance cost is included — it directly perpetuates the risk
  already flagged in `products-microservice.md`.
- **Solution #5 (embedded engine in checkout-microservice)**: Reasonable middle ground, but
  doesn't naturally serve `products-microservice`'s pricing-display needs, risking divergent logic.
- **Solution #6 (pricing SaaS)**: Most capable option, but highest TCO and the only vendor
  dependency in the set, for a need not yet shown to require it.
- **Solution #7 (overnight batch-recompute artifact, ranked 7-10, not analyzed)**: Faster than
  today's ad hoc process, but still tied to the build pipeline — does not truly remove the
  redeploy dependency the client need asks for.
- **Solution #8 (event-driven/queue-based pricing updates, ranked 7-10, not analyzed)**: A larger
  architectural change than the client need requires today; worth revisiting if pricing update
  volume grows significantly.
- **Solution #9 (direct production DB edits, ranked 7-10, not analyzed)**: Technically avoids a
  redeploy, but ungoverned and unauditable — an operational risk, not a real solution.
- **Solution #10 (formalize the status quo, ranked 7-10, not analyzed)**: Fastest to declare
  "done," but does not remove the redeploy dependency at all — fails the client need outright.

