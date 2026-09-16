# Quickstart: A/B Testing / Experimentation Framework

**Input**: [contracts/](contracts/), [data-model.md](data-model.md)

Validates all 4 user stories end-to-end on a localhost run (per [ADR-0001](../../docs/architecture/adr/0001-deployment-target-localhost.md)).

## Prerequisites

1. Full local stack running in dependency order (per repo `README.md`): `eureka-server-local` →
   `config-server-microservice` → `products-microservice`, `checkout-microservice`,
   `cart-microservice` → `api-gateway-microservice` → `react-ui`.
2. `config-server-microservice` registered in Eureka (check `http://localhost:8761`).
3. `products-microservice` and `checkout-microservice` both started with
   `spring.config.import=optional:configserver:http://localhost:8888` resolved successfully
   (check each app's startup log for a config-server fetch, not a fallback warning).

## Story 1 — Change a toggle without a redeploy

```bash
# View current ranking-strategy value
curl -s http://localhost:8888/admin/toggles | jq '."experiment.ranking-strategy"'

# Change it
curl -s -X PUT http://localhost:8888/admin/toggles/experiment.ranking-strategy \
  -H 'Content-Type: application/json' \
  -d '{"value":"price-desc","changedBy":"quickstart"}'

# Wait <= the documented propagation window (default poll interval 30s, documented max 60s),
# then confirm products-microservice is serving the new order:
curl -s "http://localhost:8081/gateway/products?category=Books&limit=5"
```

Expected: the returned product order changes to reflect `price-desc` within the documented
propagation window, with no rebuild/redeploy/restart of any tier (FR-003, SC-001).

**Invalid-value check (Acceptance Scenario 3)**:

```bash
curl -s -X PUT http://localhost:8888/admin/toggles/experiment.ranking-strategy \
  -H 'Content-Type: application/json' \
  -d '{"value":"not-a-real-strategy"}'
```

Expected: HTTP 400 with a `ValidationError` body naming the rejected value and the allowed set
(FR-004); a follow-up `GET /admin/toggles` shows the value is unchanged from before this call.

**Retirement (Acceptance Scenario 4)**:

```bash
curl -s -X PUT http://localhost:8888/admin/toggles/experiment.ranking-strategy \
  -H 'Content-Type: application/json' \
  -d '{"value":"default"}'
```

Expected: within the same propagation window, `products-microservice` reverts to `default`
ordering (FR-008).

## Story 2 — Consistent variant, no flicker

1. Change `experiment.ranking-strategy` as in Story 1.
2. Repeatedly call `GET /gateway/products?category=Books` every few seconds during the
   propagation window.
3. Expected: each individual response is either fully old-order or fully new-order — never a
   response that mixes a UX variant from one generation with a ranking result from another.

## Story 3 — Inspect currently active configuration

```bash
curl -s http://localhost:8888/admin/toggles
curl -s http://localhost:8888/admin/toggles/history?key=experiment.ranking-strategy | jq
```

Expected: the first call's value/`updatedAt` matches the most recent entry from the second call
(FR-006); this matches what `products-microservice`, `checkout-microservice`, and the gateway are
currently serving (Acceptance Scenario 2 of Story 3 — cross-tier traceability).

## Story 4 — Degraded Config Source

```bash
# Stop config-server-microservice (simulate outage)
docker stop config-server-microservice   # or kill the local process

curl -s "http://localhost:8081/gateway/products?category=Books&limit=5"
```

Expected: the storefront/gateway continues serving the last-known-good ranking/UX values (no
error page) — this is the in-memory `Environment` state described in
[research.md R-4](research.md#r-4-last-known-good-fallback-mechanics-fr-007), not a fresh error.
Restart `config-server-microservice`; within the next scheduled poll, consumers resume reading
current values with no manual restart of `products-microservice`/`checkout-microservice`
required.

## Cross-cutting check (SC-002)

```bash
diff <(curl -s http://localhost:8082/products-microservice/experiments/active) \
     <(curl -s http://localhost:8081/gateway/experiments/toggles)
```

Expected: empty diff once the propagation window has elapsed — all consuming tiers agree on the
currently active value (SC-002's 100% cross-tier parity check).
