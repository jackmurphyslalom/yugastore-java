# Perf & Fault-Injection Findings Report — Baseline

- **Date:** 2026-09-15
- **Branch/commit:** `master` @ `df1e199`
- **Environment:** local Docker Desktop (~2GB VM memory), minimal stack
  (Eureka + `products-microservice` + `api-gateway-microservice`), YugabyteDB
  YCQL fronted by Toxiproxy for fault injection. `cart-microservice` /
  `checkout-microservice` not exercised (see Known Issues below).
- **Purpose:** capture a point-in-time baseline for issue #55 so results can
  be diffed against a re-run after the fixes listed under "Recommended
  fixes to re-test against" in [../README.md](../README.md).

Re-run instructions and full methodology: see [../README.md](../README.md).
Raw k6 exports for this baseline: `baseline-browse.json`, `fault-baseline.json`,
`fault-latency.json`, `fault-reset.json` (same directory).

## Metrics summary (compare future runs against these numbers)

| Test | Metric | Baseline value | Threshold | Pass/Fail |
|---|---|---|---|---|
| Load ramp (0→75 VUs), `list products` | p95 latency | 15.19 ms | < 1000 ms | ✅ Pass |
| Load ramp (0→75 VUs), `list products` | error rate | 0% | < 1% | ✅ Pass |
| Load ramp (0→75 VUs), `list products` | avg throughput | ~53 req/s | n/a | — |
| Load ramp (0→75 VUs), `product detail` | error rate | 100%* | < 1% | ❌ Fail (*test-data artifact, see below) |
| Fault-free smoke (10 VUs, 20s) | p95 latency | 6.18 ms | < 1000 ms | ✅ Pass |
| Fault-free smoke (10 VUs, 20s) | error rate | 0% | < 1% | ✅ Pass |
| Fault-free smoke (10 VUs, 20s) | throughput | ~2492 req/s | n/a | — |
| `latency` toxic (500ms±100ms, 10 VUs, 20s) | p95 latency | **1.15 s** | < 1000 ms | ❌ Fail |
| `latency` toxic (500ms±100ms, 10 VUs, 20s) | error rate | 0% | < 1% | ✅ Pass |
| `latency` toxic (500ms±100ms, 10 VUs, 20s) | throughput | ~9.5 req/s (−99.6%) | n/a | — |
| `reset_peer` toxic (upstream, 10 VUs, 20s) | error rate | **100%** | < 1% | ❌ Fail |
| `reset_peer` toxic — post-clear recovery lag | time to healthy | **~10–20 s** | n/a (target: near-instant) | ⚠️ Notable |

\* The `product detail` 100% failure is a test-data artifact (empty/unseeded
DB → nonexistent ASIN → app returns `500`), not a load-induced failure. It's
included here because it doubles as a real correctness bug (see below) and
should be re-measured after seeding data and/or fixing the 404 behavior.

## Bugs / environment issues found (fix candidates before re-test)

1. `GET /api/v1/product/{asin}` returns `500` instead of `404` for an unknown
   ASIN — application correctness bug.
2. `cart-microservice` has a hardcoded `127.0.0.1:5433` Postgres datasource
   with no CLI-overridable host/port — blocks cart/checkout from being
   included in this test at all.
3. Eureka `bootstrap.yml` hardcodes `eureka.instance.hostname: localhost`,
   which overrides CLI args due to Spring Cloud bootstrap-context precedence
   — required a `defaultZone` workaround to stand up the stack.
4. Local Docker Desktop memory ceiling (~2GB) OOM-killed containers when
   running the full stack concurrently — infrastructure-level saturation
   point, not application-level.
5. DataStax driver does not reconnect immediately after a transient DB
   network fault clears (`NoNodeAvailableException` persists ~10–20s past
   toxic removal) — cascading-failure / recovery-lag behavior.

## What "improved" should look like on re-run

- `product detail` check should pass (real ASIN + real `404` on miss, or DB
  seeded) instead of the current 100%-fail placeholder result.
- Cart/checkout groups should be included (`RUN_CART_JOURNEY=true`) once the
  datasource fix lands, with their own p95/error-rate baselines established.
- `reset_peer` recovery lag should shrink (target: near-instant reconnect)
  if driver reconnection/backoff tuning or app-level retry logic is added.
- `latency` toxic p95 will still exceed 1s by design (fault injects 500ms
  minimum) — track whether error rate stays at 0% (no error) or whether
  timeouts appear at higher latency/VU combinations, to find the actual
  breaking point.

## How to reproduce this exact baseline

```sh
# Load ramp baseline
BASE_URL=http://localhost:8081/api/v1 WARMUP_VUS=5 RAMP_VUS=25 SPIKE_VUS=75 \
  RUN_CART_JOURNEY=false \
  k6 run --summary-export=perf-tests/results/baseline-browse.json perf-tests/k6/store-journey.js

# Fault-free smoke
BASE_URL=http://localhost:8081/api/v1 VUS=10 DURATION=20s \
  k6 run --summary-export=perf-tests/results/fault-baseline.json perf-tests/k6/fault-injection-smoke.js

# Latency toxic
./perf-tests/toxiproxy/inject-toxics.sh latency
BASE_URL=http://localhost:8081/api/v1 VUS=10 DURATION=20s \
  k6 run --summary-export=perf-tests/results/fault-latency.json perf-tests/k6/fault-injection-smoke.js
./perf-tests/toxiproxy/inject-toxics.sh clear

# Reset toxic
./perf-tests/toxiproxy/inject-toxics.sh reset
BASE_URL=http://localhost:8081/api/v1 VUS=10 DURATION=20s \
  k6 run --summary-export=perf-tests/results/fault-reset.json perf-tests/k6/fault-injection-smoke.js
./perf-tests/toxiproxy/inject-toxics.sh clear
```
