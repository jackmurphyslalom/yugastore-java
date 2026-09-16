# Feature Specification: Externalized Dynamic Pricing

**Feature Branch**: `001-externalized-dynamic-pricing`

**Created**: 2026-09-15

**Status**: Draft

**Input**: User description: "let's lay out the future state architecture for externalized dynamic pricing and then build out a backlog of work"

## Overview

Today, yugastore's product prices are baked into the same data rows as the product catalog and are read verbatim by the storefront and by checkout total math. Changing a price for a category or running a time-bound promotion requires editing catalog data (or the reload script) and, in practice, a redeploy path — merchandisers cannot move on their own weekly cadence.

This feature externalizes pricing so that a **merchandiser / category manager** owns price changes through a rules-driven surface, and the storefront, cart, and checkout all read the same **effective price** from one source of truth. The result is a future-state architecture where "what should this ASIN cost right now?" is answered by a dedicated capability rather than by a static catalog column, without breaking the transactional stock/order path or the historical integrity of already-placed orders.

The user's request has two parts: (1) lay out the future-state architecture, which this spec captures at the business-behavior level, and (2) build out a backlog of work, which is produced by the downstream `/speckit.plan` → `/speckit.tasks` flow driven by this spec.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Merchandiser changes an effective price without an engineering release (Priority: P1)

A merchandiser opens the pricing surface, changes the effective price of one product (or a category of products), or schedules a time-bound promotion, and confirms the change. Within a few minutes, shoppers see the new price on the product list, product detail page, cart, and checkout total. No engineering redeploy, catalog reload, or code change is involved.

**Why this priority**: This is the entire reason the capability exists. Without it, everything else in the spec is optional plumbing. It is also the smallest slice that delivers standalone business value: even with no admin UI, an API-only surface would let a merchandiser (or their engineering partner) change prices without a release.

**Independent Test**: Change the effective price for a single ASIN through the pricing surface. Reload the product detail page and add the item to a cart. Verify the displayed price and the cart/checkout total reflect the new value within the target propagation window. Verify no rebuild or deploy of `products-microservice`, `checkout-microservice`, `api-gateway-microservice`, or `react-ui` was required.

**Acceptance Scenarios**:

1. **Given** an ASIN has an existing effective price of $10, **When** a merchandiser sets the effective price to $8 through the pricing surface, **Then** within the propagation window the storefront (product list, product detail), cart line item, and checkout total for that ASIN reflect $8.
2. **Given** an ASIN currently priced at $10, **When** a merchandiser schedules a promotion of $7 that starts at a future time and ends 24 hours later, **Then** shoppers see $10 before the start time, $7 during the window, and $10 again after the window ends — with no operator action at the boundaries.
3. **Given** the merchandiser sets a category-wide 20% discount, **When** a shopper browses that category, **Then** every applicable ASIN's effective price reflects the discount, and ASINs outside the category are unchanged.
4. **Given** a merchandiser attempts an invalid change (e.g., negative price, end-before-start window), **When** the change is submitted, **Then** the change is rejected with a clear reason and no shopper-visible price changes.

---

### User Story 2 - Shopper sees a single, consistent effective price everywhere (Priority: P1)

A shopper browses the storefront, adds items to their cart, and proceeds to checkout. The unit price shown on the product list, on the product detail page, in the cart, and in the checkout total is the same effective price, computed from the same source of truth. There are no surprise price changes between "add to cart" and "place order" that were not caused by an intentional merchandiser change.

**Why this priority**: Consistency is the trust contract with the shopper. If the storefront and checkout can disagree, dynamic pricing becomes a defect generator rather than a business capability. This slice can be delivered on top of Story 1 even if the merchandiser surface is API-only.

**Independent Test**: For a set of ASINs (including one with a scheduled promotion and one at list price), verify that the price displayed on product list, product detail, cart line item, and checkout unit price all agree at the same instant. Verify that a merchandiser change made after items are added to a cart but before checkout is reflected consistently across cart and checkout in the shopper's next interaction.

**Acceptance Scenarios**:

1. **Given** an ASIN's effective price is $8, **When** the shopper views the product list, opens the product detail page, and adds it to the cart, **Then** all three surfaces show $8 for the same ASIN in the same session.
2. **Given** an item is in the shopper's cart at $8, **When** the shopper proceeds to checkout, **Then** the checkout unit price and line total use the same effective-price source that produced the $8 display.
3. **Given** a shopper is browsing when a scheduled promotion begins, **When** the shopper refreshes the product detail page after the boundary, **Then** the newly effective price is shown without needing to clear their cart or start a new session.

---

### User Story 3 - Placed orders keep the price they were placed at (Priority: P1)

Once a shopper places an order, the unit price captured on each order line is fixed. A later merchandiser price change, or the natural end of a promotional window, does not alter the totals on the already-placed order. Refunds, order history, and any downstream reporting continue to reflect what the shopper actually paid.

**Why this priority**: This protects the transactional integrity called out by the project's consistency principle for the order-write path. Without it, "dynamic" becomes retroactive, which is unacceptable for a commerce system. This story is a P1 because it is a correctness invariant, not a nice-to-have.

**Independent Test**: Place an order for an ASIN at a promotional price. After the order is placed, change the effective price for that ASIN and end/adjust the promotion. Re-open the placed order and verify the line unit price, line total, and order total match the values captured at the moment the order was placed.

**Acceptance Scenarios**:

1. **Given** an order was placed with an ASIN at $8 during a promotion, **When** the promotion ends and the effective price returns to $10, **Then** the placed order still shows $8 for that line and the same total it was placed at.
2. **Given** an order was placed at list price, **When** a merchandiser later reduces the list price for the same ASIN, **Then** the placed order is unaffected.
3. **Given** the pricing surface is unavailable at the moment of checkout, **When** an order is nevertheless placed (see Story 4), **Then** the price captured on the order line is documented, deterministic, and later auditable — not silently different from what the shopper saw.

---

### User Story 4 - Shopping continues when the pricing source degrades (Priority: P2)

If the pricing capability becomes slow or unavailable, shoppers can still browse and, where the business allows, complete a purchase using a documented fallback effective price rather than seeing an empty page or a hard error. Behavior at the boundary is explicit rather than accidental.

**Why this priority**: This makes dynamic pricing a resilient dependency rather than a new single point of failure. It is deliberately P2 because Stories 1–3 must land first — you cannot have a fallback for a source you have not built. This story also intentionally coordinates with the graceful-degradation feature already tracked at `specs/002-graceful-degradation-resilience/` and does not duplicate it.

**Independent Test**: Simulate the pricing source being unresponsive. Verify that the storefront still renders products with a documented fallback price (for example, the last-known list price) and a clear indicator to internal operators that fallback is in effect. Verify that placing an order in fallback mode either uses the fallback price on the order line or refuses to place the order, per the documented rule chosen.

**Acceptance Scenarios**:

1. **Given** the pricing source is unavailable, **When** a shopper opens the product list, **Then** every product is still displayed with a documented fallback effective price (not blank, not "$0", not an error page).
2. **Given** the pricing source is unavailable, **When** the shopper attempts to check out, **Then** the system takes the documented action (allow with fallback price captured on the order line, or refuse with a clear message) — and never silently uses a mixed set of prices from different sources on the same order.
3. **Given** the pricing source recovers, **When** shoppers next load prices, **Then** the storefront resumes using effective prices from the pricing source without operator action.

---

### User Story 5 - Merchandiser can review and audit their pricing changes (Priority: P3)

A merchandiser (or their manager) can see the history of pricing changes for a product or category — who changed what, when, and, where applicable, why (for example, which promotion window). This supports catching mistakes quickly and building trust in a self-service pricing workflow.

**Why this priority**: This is a P3 because the capability is valuable but not required to deliver merchandiser self-service or price consistency. It becomes urgent shortly after the primary flow ships and merchandisers start making real changes.

**Independent Test**: Make a sequence of pricing changes for one ASIN over a day (e.g., promotion start, promotion end, base price change). Query the change history for that ASIN and verify each change is listed with the acting merchandiser, timestamp, before/after values, and the rule or promotion that produced it (where applicable).

**Acceptance Scenarios**:

1. **Given** several pricing changes have been made to an ASIN, **When** a merchandiser opens that ASIN's pricing history, **Then** they see an ordered list of changes with actor, timestamp, and old/new effective values.
2. **Given** a promotion was scheduled and ended, **When** a merchandiser reviews the category's history, **Then** the promotion's start, end, and net effect are visible as distinct history entries.
3. **Given** a mistaken change was made, **When** the merchandiser initiates a rollback to a prior recorded value, **Then** the rollback is itself recorded in the same history as a distinct change.

---

### Edge Cases

- **Overlapping rules on the same ASIN** (e.g., a category-wide 20% discount and an ASIN-specific promotion): the effective price is deterministic — precedence is defined and documented, and merchandisers can see which rule is winning for a given ASIN at a given time.
- **Rule scheduled entirely in the past** (start and end both before now): the rule is treated as historical and does not affect current effective prices, but it remains visible in change history (Story 5).
- **Rule with an open-ended end date**: allowed for base-price changes; for promotions, the spec assumes a required end date (see Assumptions) unless clarified otherwise.
- **Very rapid changes** (multiple merchandiser changes to the same ASIN within the propagation window): the last committed change wins; intermediate values are still recorded in history.
- **Item added to cart at price A, purchased after price change to B**: the price captured on the order line is the effective price at the moment of order placement, not the moment of "add to cart"; shoppers see the current effective price at checkout before confirming, so this is not a surprise.
- **Currency and rounding**: prices are in the same currency the storefront currently displays; rounding rules match the current storefront and checkout math (no new currency or locale support is introduced by this feature).
- **Non-purchasable items** (out of stock, delisted): the effective-price rules still resolve, but stock and availability checks remain the source of truth for whether an item can be added to a cart or ordered — pricing does not gate purchasability.
- **Bulk import of rules** (e.g., a spreadsheet of 500 category changes): must not cause a shopper-visible outage or a partially-applied set of prices in the middle of the import.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST expose a merchandiser-facing pricing surface through which authorized users can create, update, schedule, and end price rules that affect the effective price of one or more products.
- **FR-002**: The system MUST support at least three rule scopes: a single ASIN, a category of ASINs, and a time-bound promotion window layered on top of either of the above.
- **FR-003**: The system MUST compute a single **effective price** for each ASIN at read time from the applicable rules and the ASIN's list price, using a deterministic precedence order that is documented and observable.
- **FR-004**: The storefront (product list, product detail), the cart, and the checkout unit-price and total math MUST all obtain the effective price from the same pricing source, so that a shopper never sees inconsistent prices across these surfaces at the same instant.
- **FR-005**: A merchandiser change to a price rule MUST propagate to shopper-visible prices within the documented propagation window (see Assumptions) without any redeploy, code change, or manual catalog reload.
- **FR-006**: The system MUST validate merchandiser input at submission time and reject invalid rules (e.g., non-positive prices, malformed scopes, end-before-start windows) with a specific, human-readable reason and no shopper-visible effect.
- **FR-007**: Once an order is placed, the unit price captured on each order line MUST be immutable regardless of subsequent price-rule changes, promotion expirations, or list-price changes.
- **FR-008**: The system MUST record each merchandiser-initiated pricing change with actor, timestamp, scope, before/after values, and originating rule or promotion identifier, and MUST make that history queryable by ASIN and by category.
- **FR-009**: The system MUST NOT alter or bypass the existing stock-check and order-write behavior (inventory decrement, "not enough products in stock" rejection); pricing is a read-side concern applied to the unit price captured on the order line, not a change to the transactional order-write path.
- **FR-010**: The system MUST behave predictably when the pricing source is unavailable or slow: shopper-facing surfaces MUST display a documented fallback effective price (e.g., last-known list price) rather than failing, and checkout MUST take a single documented action (allow-with-fallback or refuse) rather than mixing sources within one order.
- **FR-011**: The system MUST make it possible for an internal operator to see whether effective prices are currently being served from the pricing source or from the documented fallback.
- **FR-012**: Existing terms (ASIN, api-gateway) MUST be preserved as-is, and new durable terms introduced by this feature (**Effective Price**, **List Price**, **Price Rule**, **Promotion**, **Merchandiser**) MUST be added to the product glossary as part of delivery.
- **FR-013**: Any new capability that is reachable from outside the microservice reactor MUST be reachable only through the `api-gateway-microservice`; direct calls from `react-ui` or from another service into a new pricing capability are not permitted.
- **FR-014**: Pricing rule authoring, effective-price reads, and pricing-change history reads MUST be independently addressable so that a slow or degraded rule-authoring surface does not block shopper reads, and vice versa.
- **FR-015**: The system MUST authorize merchandiser writes so that only authorized merchandisers can change price rules; [NEEDS CLARIFICATION: merchandiser admin surface + authentication approach — new admin UI in react-ui vs. CLI/config workflow vs. API-only for this iteration, and given login-microservice is out of scope, does merchandiser auth defer, use a documented local-only mechanism, or scope login-microservice back in?]
- **FR-016**: The system MUST define whether pricing rules and A/B pricing experimentation ship together or separately; [NEEDS CLARIFICATION: pricing + experimentation scope — does this feature ship rules-only with a documented extension point for experiments, or rules + A/B variant selection together?]
- **FR-017**: The system MUST persist price rules, effective-price computation inputs, and change history in a store that is compatible with the project's localhost-only deployment target and consistency-sensitive data-path principle; [NEEDS CLARIFICATION: pricing store choice — new YCQL table under the existing keyspace, a new YSQL schema (as used elsewhere), or a config-managed store — which best satisfies "propagate within minutes" and localhost-only constraints without breaking the order-write path?]

### Key Entities *(include if feature involves data)*

- **Product (identified by ASIN)**: The item being priced. This feature does not change what a product is; it changes how the product's price is determined. ASIN remains the identifier used everywhere.
- **List Price**: The baseline price associated with a product independent of any rule or promotion. Used as the effective price when no rule applies, and as the fallback described in FR-010.
- **Price Rule**: A merchandiser-authored statement of the form "for this scope (ASIN or category), during this window (open-ended or bounded), the effective price is <computed value>." Scope, window, and computation form the rule's identity.
- **Promotion**: A specialization of a Price Rule that is time-bound and typically discounts an existing price. Modeled here as a distinct concept for merchandiser workflow clarity; it may or may not be a separate entity in the future implementation.
- **Effective Price**: The resolved unit price for a given ASIN at a given instant, computed from applicable rules and the list price using the documented precedence order. Not stored per read; captured only when an order is placed (see FR-007).
- **Pricing Change History Entry**: An immutable record of who made what pricing change, when, and its effect. Queryable by ASIN and by category.
- **Order Line Price Snapshot**: The unit price recorded on an order line at order-placement time. Immutable per FR-007; the mechanism that decouples "current dynamic price" from "price the shopper paid."
- **Merchandiser** *(actor, not a persisted domain object introduced by this feature)*: The primary human actor authoring price rules. May be authenticated via a mechanism resolved by FR-015.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A merchandiser can change the effective price of a single ASIN and see the change reflected on the storefront and at checkout in **under 5 minutes end-to-end**, with **zero engineering actions** (no rebuild, no redeploy, no manual data reload).
- **SC-002**: For any ASIN under any rule state, the effective price displayed on the product list, product detail page, cart line item, and checkout unit price agrees **100% of the time within a single shopper session at a single instant** (measured by an automated cross-surface parity check).
- **SC-003**: For orders placed during a promotion, the recorded order total remains unchanged after the promotion ends in **100% of a randomly sampled batch** — no order total drifts because of a later pricing change.
- **SC-004**: When the pricing source is fully unavailable, the storefront product-list page still returns a usable, non-empty response for shoppers with a documented fallback effective price in **at least 99% of requests** during the outage window (target measured over a simulated outage of at least 5 minutes).
- **SC-005**: For a merchandiser-authored change, the pricing change history entry is queryable within **1 minute** of the change being committed, and includes actor, timestamp, scope, and before/after values in **100% of recorded changes**.
- **SC-006**: The change reduces the time from "merchandiser decides on a price" to "shopper sees the price" from the current baseline (which requires a code/redeploy path) to **the SC-001 target of under 5 minutes**, and does so without introducing any regression in the existing order-placement success rate (measured against the existing test surface for stock-check and order-write).

## Assumptions

- **Deployment target is localhost only.** Solutioning must fit the `docker-run.sh` / per-service local model recorded in the project's deployment-target decision. Cloud pub/sub, cloud feature-flag SaaS, and cloud-managed rule stores are out of scope; the pricing capability runs alongside the existing services locally.
- **New capability is a new microservice reached through the api-gateway.** Because the constitution requires that any externally reachable capability sit behind the `api-gateway-microservice` and register with Eureka, the future-state architecture assumes a new pricing microservice fronted by a new gateway client. This assumption is encoded in FR-013 and is not up for negotiation without amending the constitution.
- **Effective price is computed at read time, not stored per ASIN.** The system resolves list price + applicable rules on read. Effective price is captured (snapshotted) only at order placement, per FR-007.
- **ASIN remains the product identity everywhere.** Rules key off ASIN and, for scope, off category identifiers already understood by the catalog.
- **`ProductMetadata.price` remains the "list price" for backward compatibility** during and after this feature; the effective price is a new concept computed by the pricing capability. The existing catalog field is not repurposed silently.
- **`CheckoutServiceImpl.calculatePrice()` is updated to source the unit price from the pricing capability** rather than reading the list-price field directly, without changing the transactional order-write path (stock check, inventory decrement, order write) — this preserves the consistency-sensitive data-path principle.
- **Promotions are assumed to have both a start and an end time.** Open-ended promotions are out of scope for the first iteration; base-price changes are open-ended by nature.
- **Merchandiser is the primary persona.** A "pricing / revenue analyst" persona is out of scope unless clarification FR-016 pulls A/B experimentation in.
- **`login-microservice` is out of scope by the project's current scope decision.** Merchandiser authorization is therefore expected to be resolved either by a documented local-only mechanism or by an explicit scope change in a separate specification. This spec does not assume merchandiser SSO.
- **Recommendation-engine work is out of scope.** The intake noted it as greenfield; this feature does not attempt to fold it in.
- **The "backlog of work" in the user's request is produced by `/speckit.plan` → `/speckit.tasks` based on this spec.** This spec captures the future-state behavior; the ordered task list is created downstream and is not hand-authored in `spec.md`.
- **Coverage targets** referenced in project intake (informally ~85%) are treated as an aspirational target for the new pricing capability and not encoded here as a merge gate; SC-006 instead requires no regression against the existing order-placement test surface.
- **Coordination with the resilience feature.** Story 4 (graceful degradation of pricing) intentionally aligns with `specs/002-graceful-degradation-resilience/`; that spec is the general resilience contract, and this spec adds the pricing-specific fallback behavior. The two must not restate the same operator-facing controls.
