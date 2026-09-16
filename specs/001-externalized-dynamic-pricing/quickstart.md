# Quickstart — Externalized Dynamic Pricing

Feature: [001-externalized-dynamic-pricing](spec.md) | Plan: [plan.md](plan.md)

A validation runbook. This document proves that each of the five user stories in [spec.md](spec.md) works end-to-end on localhost. It does **not** include implementation code, migrations, or full test suites — those are produced by `/speckit.tasks` and executed under `/speckit.implement`.

Prerequisites and setup below assume the plan's Phase 2 tasks are already applied to the tree.

## Prerequisites

- macOS with the [Brewfile](../../Brewfile) installed: `brew bundle` from repo root brings up Java 17, Maven, Node, jq, Docker Desktop, and the Cassandra loader.
- Docker Desktop running (see [docker-run.sh](../../docker-run.sh)).
- A local Yugabyte with the `cronos` keyspace, seeded via [resources/dataload.sh](../../resources/dataload.sh) after [resources/schema.cql](../../resources/schema.cql) is applied.
- Allow-list your merchandiser id in the new module's `application.yml`:

  ```yaml
  cronos:
    pricing:
      admin:
        allowed-merchandisers:
          - "test-merchandiser-1"
  ```

- Confirm reactor pins for Spring Boot 2.6.3 / Spring Cloud 2021.0.0 are unchanged after the new module is added:

  ```zsh
  ./mvnw -q -pl pricing-microservice help:evaluate -Dexpression=spring-boot.version
  ```

## Bring the stack up

```zsh
./docker-run.sh
```

After the script settles, the reactor exposes:

| Service                | Port | Notes                                                        |
|------------------------|------|--------------------------------------------------------------|
| `eureka-server-local`  | 8761 | Service registry.                                            |
| `api-gateway-microservice` | 8080 | Only external surface.                                  |
| `products-microservice`| 8081 |                                                              |
| `checkout-microservice`| 8082 |                                                              |
| `pricing-microservice` | 8083 | **New** — see the new stanza added by tasks to `docker-run.sh`. |

Sanity check that pricing registered:

```zsh
curl -s http://localhost:8761/eureka/apps | grep -o '<name>[^<]*</name>' | sort -u
```

`PRICING-MICROSERVICE` should appear alongside the other registered services.

## Story-by-story validation

Each numbered subsection maps 1:1 to a user story in [spec.md](spec.md). The commands here are curl-based validations; the actual behavioral tests live under `pricing-microservice/src/test/java/**` per [research.md § R-8](research.md#r-8-testing-shape).

### Story 1 — Merchandiser changes an effective price without an engineering release

Reference: [spec.md § User Story 1](spec.md#user-story-1---merchandiser-changes-an-effective-price-without-an-engineering-release-priority-p1) · Contract: [contracts/pricing-rest.openapi.yaml § /pricing/rules](contracts/pricing-rest.openapi.yaml) · Data: [data-model.md § Price Rule](data-model.md#1-price-rule-cronosprice_rules)

Pick a real ASIN from the seeded catalog (`resources/products.json`); for this doc we use `ASIN-EXAMPLE-1`.

1. **Baseline**: read the current effective price. It should equal the catalog `list_price`.

   ```zsh
   curl -s "http://localhost:8080/pricing/effective?asin=ASIN-EXAMPLE-1" | jq
   ```

   Expect `.source == "LIST_PRICE"` and `.unit_price == .list_price`.

2. **Merchandiser creates a `LIST_PRICE_OVERRIDE` rule**:

   ```zsh
   curl -s -X POST http://localhost:8080/pricing/rules \
     -H "Content-Type: application/json" \
     -H "X-Merchandiser-Id: test-merchandiser-1" \
     -d '{
       "scope_kind": "ASIN",
       "scope_value": "ASIN-EXAMPLE-1",
       "rule_kind": "LIST_PRICE_OVERRIDE",
       "unit_price": 8.00,
       "priority": 10
     }' | jq
   ```

   Expect `201` and a persisted `PriceRule` body with a server-generated `rule_id`.

3. **Verify propagation** (SC-001, under 5 minutes end-to-end, no rebuild):

   ```zsh
   curl -s "http://localhost:8080/pricing/effective?asin=ASIN-EXAMPLE-1" | jq
   ```

   Expect `.source == "RULE"`, `.source_rule_id == <rule_id from step 2>`, and `.unit_price == 8.00`.

4. **Confirm no rebuild happened**: none of `products-microservice`, `checkout-microservice`, `api-gateway-microservice`, or `react-ui` was rebuilt or restarted for this change.

5. **Validation-failure case** (FR-006):

   ```zsh
   curl -s -o /dev/null -w '%{http_code}' -X POST http://localhost:8080/pricing/rules \
     -H "Content-Type: application/json" \
     -H "X-Merchandiser-Id: test-merchandiser-1" \
     -d '{"scope_kind":"ASIN","scope_value":"ASIN-EXAMPLE-1","rule_kind":"LIST_PRICE_OVERRIDE","unit_price":-3,"priority":0}'
   ```

   Expect `400` with body `{ "code": "PRICE_NON_POSITIVE", ... }` per [data-model.md § Validation rules](data-model.md#validation-rules-used-by-write-endpoints).

### Story 2 — Shopper sees a single, consistent effective price everywhere

Reference: [spec.md § User Story 2](spec.md#user-story-2---shopper-sees-a-single-consistent-effective-price-everywhere-priority-p1)

With the Story 1 rule still active:

1. **Product list**: hit the storefront's product-list surface through the gateway (existing route; the plan does not change its path — only its response now includes `effectivePrice`):

   ```zsh
   curl -s http://localhost:8080/products | jq '.[] | select(.asin=="ASIN-EXAMPLE-1") | {asin, price, effectivePrice}'
   ```

   Expect `.effectivePrice == 8.00` and `.price == <original list price>`.

2. **Product detail**:

   ```zsh
   curl -s "http://localhost:8080/products/ASIN-EXAMPLE-1" | jq '{asin, price, effectivePrice}'
   ```

   Expect `.effectivePrice == 8.00`.

3. **Cart**: add the ASIN via the existing cart route, then render:

   ```zsh
   curl -s -X POST http://localhost:8080/cart -H "Content-Type: application/json" -d '{"userId":"quickstart-shopper","asin":"ASIN-EXAMPLE-1","qty":1}'
   curl -s "http://localhost:8080/cart?userId=quickstart-shopper" | jq
   ```

   The cart line for `ASIN-EXAMPLE-1` should render at $8.00.

4. **Checkout unit price** (does not place the order):

   ```zsh
   curl -s "http://localhost:8080/checkout/preview?userId=quickstart-shopper" | jq
   ```

   Unit price for the line should be $8.00.

**SC-002 parity check**: assert that `$8.00` appears in every one of the four responses above for the same ASIN in the same session.

### Story 3 — Placed orders keep the price they were placed at

Reference: [spec.md § User Story 3](spec.md#user-story-3---placed-orders-keep-the-price-they-were-placed-at-priority-p1) · Snapshot column: [data-model.md § Order Line Price Snapshot](data-model.md#4-order-line-price-snapshot-additive-column-on-the-existing-order-line)

1. **Place an order** for `ASIN-EXAMPLE-1` while the rule is still in effect:

   ```zsh
   curl -s -X POST "http://localhost:8080/checkout?userId=quickstart-shopper" | jq
   ```

   Note the returned `order_id`.

2. **Verify snapshot** (via YCQL, since order reads may not expose the new columns yet):

   ```zsh
   cqlsh -e "SELECT unit_price_at_order, pricing_source_at_order FROM cronos.orders WHERE order_id = <order_id>;"
   ```

   Expect `unit_price_at_order = 8.00` and `pricing_source_at_order = 'RULE'`.

3. **Retract the rule**:

   ```zsh
   curl -s -X DELETE "http://localhost:8080/pricing/rules/<rule_id>" \
     -H "X-Merchandiser-Id: test-merchandiser-1" -o /dev/null -w '%{http_code}\n'
   ```

   Expect `204`.

4. **Reload the placed order** through whatever order-read path exists today, and confirm the total is unchanged:

   ```zsh
   cqlsh -e "SELECT unit_price_at_order FROM cronos.orders WHERE order_id = <order_id>;"
   ```

   Still `8.00`. SC-003 satisfied.

### Story 4 — Shopping continues when the pricing source degrades

Reference: [spec.md § User Story 4](spec.md#user-story-4---shopping-continues-when-the-pricing-source-degrades-priority-p2) · Design: [research.md § R-7](research.md#r-7-graceful-degradation-of-pricing-dependency)

1. **Stop pricing-microservice**:

   ```zsh
   docker stop pricing-microservice
   ```

2. **Storefront product list still renders** with a documented fallback (SC-004):

   ```zsh
   curl -s http://localhost:8080/products | jq 'length'
   ```

   Expect a non-empty array. Spot-check one product's response body for `.effectivePrice == .price` (list-price fallback) OR the last-cached rule-derived value.

3. **Serving-mode flag surfaces the degradation** (FR-011):

   ```zsh
   curl -s http://localhost:8080/actuator/info | jq '.pricing'
   ```

   Expect `.pricing.serving_mode == "LIST_PRICE_FALLBACK"` or `.pricing.serving_mode == "CACHE"` depending on cache warmth.

4. **Checkout takes the documented action** (fallback = `ALLOW_WITH_LIST_PRICE` by default):

   ```zsh
   curl -s -X POST "http://localhost:8080/checkout?userId=quickstart-shopper" | jq
   ```

   Expect a placed order. Verify:

   ```zsh
   cqlsh -e "SELECT unit_price_at_order, pricing_source_at_order FROM cronos.orders WHERE order_id = <order_id>;"
   ```

   `pricing_source_at_order = 'LIST_PRICE_FALLBACK'`.

5. **Restart and recover**:

   ```zsh
   docker start pricing-microservice
   # wait for Eureka to re-register (see UI at http://localhost:8761)
   curl -s http://localhost:8080/actuator/info | jq '.pricing.serving_mode'
   ```

   Expect `"SOURCE"` once the client's next successful call lands.

### Story 5 — Merchandiser can review and audit their pricing changes

Reference: [spec.md § User Story 5](spec.md#user-story-5---merchandiser-can-review-and-audit-their-pricing-changes-priority-p3) · Table: [contracts/ycql-schema.md § `cronos.price_rule_history`](contracts/ycql-schema.md#cronosprice_rule_history)

1. **Create a promotion, then update it, then retract it**:

   ```zsh
   RULE_ID=$(curl -s -X POST http://localhost:8080/pricing/rules \
     -H "Content-Type: application/json" \
     -H "X-Merchandiser-Id: test-merchandiser-1" \
     -d '{"scope_kind":"ASIN","scope_value":"ASIN-EXAMPLE-1","rule_kind":"PROMOTION","unit_price":7.00,"priority":50,
          "starts_at":"2026-09-15T12:00:00Z","ends_at":"2026-09-16T12:00:00Z"}' | jq -r .rule_id)

   curl -s -X PUT "http://localhost:8080/pricing/rules/$RULE_ID" \
     -H "Content-Type: application/json" \
     -H "X-Merchandiser-Id: test-merchandiser-1" \
     -d '{"unit_price":6.50}' | jq

   curl -s -X DELETE "http://localhost:8080/pricing/rules/$RULE_ID" \
     -H "X-Merchandiser-Id: test-merchandiser-1" -o /dev/null -w '%{http_code}\n'
   ```

2. **Query history by ASIN**:

   ```zsh
   curl -s "http://localhost:8080/pricing/rules/history?asin=ASIN-EXAMPLE-1" \
     -H "X-Merchandiser-Id: test-merchandiser-1" | jq
   ```

   Expect three entries for this rule id ordered `event_at DESC`: `RETRACTED` → `UPDATED` → `CREATED`, each with actor `"test-merchandiser-1"` and correct `_before`/`_after` diffs (SC-005 satisfied).

3. **Rollback recorded as a distinct change**: creating a fresh rule that restores the prior value counts as a new `CREATED` entry, not a mutation of a retracted rule — this matches spec.md Story 5's third acceptance scenario.

## Running the behavior tests

Per [plan.md § Testing](plan.md#technical-context) and [research.md § R-8](research.md#r-8-testing-shape). Nothing in the module wires a JaCoCo coverage `check` goal, so these commands can be run independently without triggering a whole-reactor coverage gate.

| Purpose                         | Command                                                                 |
|---------------------------------|-------------------------------------------------------------------------|
| Targeted (one class)            | `./mvnw -pl pricing-microservice -Dtest=PriceRuleResolverTests test`    |
| Focused (module only)           | `./mvnw -pl pricing-microservice -am test`                              |
| CI-equivalent (whole reactor)   | `./mvnw -B test`                                                        |
| Broadest — final authority       | `./mvnw -B verify`                                                      |

The broadest suite (`verify`) is the final authority: it runs every module's tests plus the reactor `package` phase, and is what a release build runs today.

## Cleanup

```zsh
./docker-run.sh --down   # or manual: docker stop <container>; docker rm <container>
```

To reset pricing state without re-seeding the whole catalog:

```zsh
cqlsh -e "TRUNCATE cronos.price_rules; TRUNCATE cronos.price_rules_by_scope; TRUNCATE cronos.price_rule_history; TRUNCATE cronos.price_rule_history_by_scope;"
```

`cronos.orders` and `cronos.product_inventory` are **not** truncated by this quickstart.
