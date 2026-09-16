# Feature Specification: A/B Testing / Experimentation Framework

**Feature Branch**: `005-ab-testing-framework`

**Created**: 2026-09-16

**Status**: Draft

**Input**: User description: "let's lay out the future state architecture for an A/B testing / experimentation framework and then build out a backlog of work, grounded in meta/future-state/experimentation.md"

## Overview

Today, nothing in the system lets anyone change ranking, UX, or pricing behavior at runtime: `products-microservice`'s `application.yml` sets only `spring.application.name` (behavior lives in code, e.g. `YugabyteYCQLConfig`), `react-ui`'s dev proxy target is a static `package.json` value, and no feature-flag, toggle, or experiment mechanism exists anywhere in the fleet (`meta/future-state/experimentation.md`; `docs/context/gaps.md`, "Rapid experimentation / A/B testing"). A product manager who wants to try a different ranking order or UX variant must file a ticket, wait for an engineer to change code, and wait for a redeploy — by the time the change ships, the window it was meant for has often passed.

This feature externalizes runtime experimentation configuration through a Spring Cloud Config Server — the same dependency family (Spring Cloud/Eureka) every one of the 7 tiers already registers with — so that a **product manager / experiment owner** can create, change, and retire ranking and UX experiment toggles without an engineering redeploy, and `products-microservice`, `checkout-microservice`, and `react-ui`'s proxy target read the current values directly. This spec captures the future-state architecture at the business-behavior level; the downstream `/speckit.plan` → `/speckit.tasks` flow produces the implementation backlog.

Pricing-rule experimentation is intentionally coordinated with, not duplicated by, `specs/001-externalized-dynamic-pricing/`: that feature owns the effective-price computation and history; this feature owns the runtime-toggle mechanism a pricing experiment could later plug into, per the shared-infrastructure opportunity noted in `meta/future-state/experimentation.md`.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Experiment owner changes ranking/UX behavior without an engineering release (Priority: P1)

A product manager (experiment owner) opens the toggle surface, changes a ranking-order parameter or a UX toggle value, and confirms the change. Within a few minutes, shoppers see the new behavior on the storefront — no rebuild, redeploy, or code change of `products-microservice`, `react-ui`, or any other tier is involved.

**Why this priority**: This is the entire reason the capability exists — removing engineering from the loop for routine experimentation. It is also the smallest slice that delivers standalone value: even with an API-only toggle surface (no dedicated admin UI), an experiment owner (or their engineering partner) can change behavior without a release.

**Independent Test**: Change a ranking-order toggle value through the config surface. Reload the product list and verify the new ordering is served within the target propagation window, with no rebuild or redeploy of `products-microservice`, `react-ui`, or `api-gateway-microservice`.

**Acceptance Scenarios**:

1. **Given** `products-microservice` is currently serving ranking order A, **When** an experiment owner changes the ranking toggle to order B through the config surface, **Then** within the propagation window shoppers see order B without a redeploy.
2. **Given** a UX toggle controls a storefront display variant, **When** an experiment owner flips the toggle, **Then** `react-ui` reflects the new variant on next page load without a rebuild.
3. **Given** an experiment owner attempts an invalid toggle value (e.g., an undefined ranking strategy name), **When** the change is submitted, **Then** the change is rejected with a clear reason and the previously active value keeps serving.
4. **Given** an active experiment, **When** the experiment owner retires it, **Then** the affected tier(s) revert to the documented default behavior within the same propagation window, with no operator redeploy.

---

### User Story 2 - Shoppers experience one consistent variant per experiment, not a flicker (Priority: P1)

While an experiment is active, a shopper's storefront behavior for that experiment (e.g., ranking order, a UX variant) stays consistent across the pages they visit in the same session — it does not flip between values because of propagation lag or because different tiers picked up the new config at different times.

**Why this priority**: An experimentation mechanism that produces visibly inconsistent behavior within a single shopper's session undermines trust and makes the experiment's own results unreliable. This is a correctness expectation for the mechanism itself, not an optional nicety.

**Independent Test**: Change a ranking toggle value mid-session for a browsing shopper. Verify that within-flight page loads either consistently show the old value or consistently show the new value once propagated — never an unlabeled mix on the same page.

**Acceptance Scenarios**:

1. **Given** a shopper is browsing while a ranking toggle changes, **When** they view the product list again after the propagation window has elapsed, **Then** they consistently see the new ranking order on every subsequent page load.
2. **Given** `products-microservice` and `react-ui` may read updated config at slightly different times, **When** a toggle change is in flight, **Then** no single page render combines a UX variant from one config generation with a ranking result from another in a way that produces a broken or contradictory experience.

---

### User Story 3 - Experiment owner and engineering can see which configuration is currently active (Priority: P2)

An experiment owner or on-call engineer can inspect the currently active toggle values for ranking and UX experiments — what value is live, since when, and (where available) who last changed it — without reading source code or redeploying anything.

**Why this priority**: Without visibility into current state, experiment owners cannot trust that their change took effect, and engineers cannot diagnose "why is the storefront behaving this way" during an incident. This is P2 because Story 1 (the ability to change values) must exist first.

**Independent Test**: Change a toggle value, then query the config surface for the currently active values. Verify the queried value matches what was just set and that the query does not require code access or a redeploy.

**Acceptance Scenarios**:

1. **Given** a ranking toggle was changed an hour ago, **When** an engineer queries the current configuration, **Then** the currently active value is returned along with when it took effect.
2. **Given** the config server is the single source of truth for ranking/UX toggles, **When** any of the three consuming tiers (`products-microservice`, `checkout-microservice`, `react-ui`) is asked "what value are you currently serving," **Then** the answer is traceable back to the same config source, never a locally cached or hardcoded divergent value.

---

### User Story 4 - Experimentation configuration remains available when a consuming tier is degraded (Priority: P2)

If the config server is slow or briefly unavailable, the storefront continues serving a documented last-known-good configuration rather than failing outright or reverting to an undocumented default.

**Why this priority**: Making the config server a new single point of failure for basic storefront behavior would be a regression, not an improvement. This coordinates with, and does not duplicate, the resilience investigation tracked separately for graceful degradation (`meta/future-state/graceful-degradation.md`); this story only requires that experimentation's own toggle-read path fails safely.

**Independent Test**: Simulate the config server being unresponsive. Verify that `products-microservice`, `checkout-microservice`, and `react-ui` continue serving their last successfully retrieved toggle values rather than raising a shopper-visible error.

**Acceptance Scenarios**:

1. **Given** the config server becomes unavailable, **When** a shopper loads the product list, **Then** the storefront continues serving the last-known-good ranking/UX configuration rather than an error page.
2. **Given** the config server recovers, **When** the consuming tiers next poll for configuration, **Then** they resume reading current values without requiring an operator restart.

---

### Edge Cases

- **Overlapping toggles affecting the same surface** (e.g., a ranking toggle and a UX toggle both changing product-list rendering): each toggle's effect is independently documented so an experiment owner can reason about combined behavior without guessing at precedence.
- **Rapid, repeated changes to the same toggle** within the propagation window: the last committed value wins; there is no requirement to queue or replay intermediate values.
- **Toggle removed or renamed** while a tier still expects it: the consuming tier falls back to its documented default rather than failing to start or serving an undefined value.
- **Config server briefly unavailable during a fresh deploy** (a tier starting up with no last-known-good value cached yet): the tier uses its documented built-in default rather than failing to start.
- **Bulk toggle changes** (e.g., retiring several experiments at once): must not cause a shopper-visible outage or a partially-applied mix of old and new values across tiers.
- **Unauthorized or accidental toggle change**: rejected or requires a documented authorization path (see FR-009); the previous value continues serving.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST provide a runtime configuration source (a Spring Cloud Config Server, per `meta/future-state/experimentation.md`'s recommendation) that externalizes ranking and UX toggle values outside of any tier's compiled code or static `application.yml`.
- **FR-002**: `products-microservice`, `checkout-microservice`, and `react-ui`'s proxy/config-consuming layer MUST read current toggle values from the config source at runtime rather than from hardcoded or build-time values.
- **FR-003**: A change to a toggle value MUST propagate to all consuming tiers within a documented propagation window without requiring a rebuild, redeploy, or manual restart of any tier.
- **FR-004**: The system MUST validate toggle changes at submission time and reject invalid values (e.g., an undefined ranking strategy name) with a specific, human-readable reason, leaving the previously active value in effect.
- **FR-005**: Each consuming tier MUST register with the Eureka registry (`eureka-server-local`) and reach the config source only through the pattern already used for existing Spring Cloud/Eureka registration, per the project's Gateway-Only Service Boundary principle.
- **FR-006**: The system MUST expose the currently active toggle values, and since-when they took effect, in a form queryable by an experiment owner or engineer without code access or a redeploy.
- **FR-007**: When the config source is unavailable or slow, each consuming tier MUST continue serving its last-known-good toggle values rather than raising a shopper-visible error; a tier with no cached value yet MUST fall back to a documented built-in default.
- **FR-008**: The system MUST support retiring an experiment (returning a toggle to its documented default) within the same propagation window as a normal change, with no operator redeploy.
- **FR-009**: The system MUST authorize toggle writes so that only an authorized experiment owner or engineer can change active configuration. For this iteration, authorization is enforced at the infrastructure layer (API/config-file-only access, no new authenticated admin surface) rather than through a dedicated admin UI, consistent with `login-microservice` remaining out of scope; a UI-based access-control layer is a candidate for a later iteration, not this one.
- **FR-010**: New capability reachable from outside the microservice reactor MUST be reachable only through `api-gateway-microservice`; the config source itself is an internal, Eureka-registered dependency, not a new externally-reachable surface.
- **FR-011**: The initial scope of "experiment" for this iteration is a **global runtime toggle/parameter** (one active value shared by all shoppers at a time), matching `meta/future-state/experimentation.md`'s recommendation. Per-shopper randomized variant assignment (classic statistical A/B bucketing) is explicitly out of scope for this iteration and would be a distinct future feature.
- **FR-012**: Existing terms (ASIN, api-gateway, Eureka/service discovery) MUST be preserved as-is, and new durable terms introduced by this feature (**Experiment Toggle**, **Config Source**, **Experiment Owner**, **Propagation Window**) MUST be added to the product glossary as part of delivery.
- **FR-013**: The system MUST NOT alter or bypass existing stock-check, order-write, or checkout consistency behavior; toggle-driven experimentation is additive to the read/rendering path, not a change to the transactional order-write path.

### Key Entities *(include if feature involves data)*

- **Experiment Toggle**: A named, externally-editable configuration value (e.g., a ranking strategy identifier, a UX display variant flag) read at runtime by one or more consuming tiers. Identity is its name/key plus current value.
- **Config Source**: The Spring Cloud Config Server instance that stores and serves current toggle values to `products-microservice`, `checkout-microservice`, and `react-ui`.
- **Propagation Window**: The documented maximum time between a toggle change being committed and all consuming tiers serving the new value.
- **Last-Known-Good Value**: The most recent successfully retrieved toggle value a consuming tier caches locally, served when the Config Source is unavailable (FR-007).
- **Experiment Owner** *(actor, not a persisted domain object introduced by this feature)*: The primary human actor changing toggle values, subject to authorization resolved by FR-009.
- **Toggle Change Event** *(if history/audit is scoped in)*: A record of who changed a toggle, when, and its before/after value — needed to answer "which experiment produced this outcome" (Story 3).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: An experiment owner can change a ranking or UX toggle value and see it reflected on the storefront in **under 5 minutes end-to-end**, with **zero engineering actions** (no rebuild, no redeploy, no manual restart).
- **SC-002**: For any active toggle, all three consuming tiers (`products-microservice`, `checkout-microservice`, `react-ui`) report the same currently active value **100% of the time** once the propagation window has elapsed (measured by an automated cross-tier parity check).
- **SC-003**: When the config source is unavailable for a simulated outage of at least 5 minutes, the storefront continues serving a usable, non-error response using last-known-good or default toggle values in **at least 99% of requests**.
- **SC-004**: Retiring an experiment returns all consuming tiers to the documented default value within the same propagation window measured in SC-001, in **100% of a sampled batch of retirements**.
- **SC-005**: The change reduces the time from "experiment owner decides on a behavior change" to "shoppers see it" from the current baseline (a code change and redeploy) to the **SC-001 target of under 5 minutes**, without introducing any regression in existing checkout/order-placement success rates.

## Assumptions

- **Deployment target is localhost only.** Per `docs/architecture/adr/0001-deployment-target-localhost.md`, the Config Server runs alongside existing services via the `docker-run.sh` / per-service local model; no cloud-managed config or feature-flag SaaS is in scope.
- **The Config Server is a new, Eureka-registered internal dependency, not a new externally reachable surface.** It is read by `products-microservice`, `checkout-microservice`, and `react-ui`'s consuming layer directly; it is not fronted by `api-gateway-microservice` as a shopper-facing API, per FR-010.
- **Scope is ranking and UX toggles first; pricing-experiment integration is coordinated separately.** Effective-price computation and its history remain owned by `specs/001-externalized-dynamic-pricing/`; this feature's Config Source is the shared mechanism a future pricing experiment could read from, per `meta/future-state/experimentation.md`'s stated opportunity, not a re-implementation of pricing rules.
- **This iteration targets global runtime toggles, not per-shopper randomized bucketing** (FR-011) — the recommendation this spec is grounded in (`meta/future-state/experimentation.md`) describes externalized parameters, not a statistical experimentation platform. Per-shopper bucketing is deferred to a future feature.
- **`login-microservice` remains out of scope.** Toggle-write authorization (FR-009) is enforced at the infrastructure layer for this iteration and must not silently expand this feature into finishing `login-microservice` without a separate, explicit decision.
