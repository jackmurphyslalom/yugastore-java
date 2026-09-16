# Performance & Fault-Injection Testing (Issue #55)

Goal: identify the point at which the yugastore-java app degrades or fails
under simulated traffic, and validate resiliency to a database fault via
Toxiproxy. This directory contains the load-test scripts, fault-injection
helper scripts, and the results/findings captured from real runs against a
local Docker stack.

## Contents

- `k6/store-journey.js` — main ramping load test simulating
  browse -> add-to-cart -> checkout against `api-gateway-microservice`.
- `k6/fault-injection-smoke.js` — short, constant-VU smoke test (browse only)
  used to quickly compare behavior with/without a Toxiproxy toxic active.
- `toxiproxy/create-proxy.sh` — creates a Toxiproxy proxy in front of
  YugabyteDB's YCQL port (used by `products-microservice`).
- `toxiproxy/inject-toxics.sh` — adds/removes toxics (`latency`, `timeout`,
  `reset`, `clear`) on that proxy for fault-injection scenarios.
- `results/*.json` — k6 `--summary-export` output from the runs described
  below.
- `results/findings-report-2026-09-15-baseline.md` — a standalone,
  comparison-friendly snapshot of the baseline metrics below, meant to be
  diffed against a re-run after fixes land.

## Failure-point thresholds (from issue #55)

- Error rate (`http_req_failed` / `errors`) must stay under 1%.
- p95 latency (`http_req_duration`) must stay under 1000ms.
- Also watch for: saturation signals (CPU/memory/thread-pool exhaustion),
  connection pool exhaustion, and cascading failures across services.

These are encoded as k6 `thresholds` in both scripts.

## How to run

1. Start the stack (Eureka, products-microservice, api-gateway-microservice
   at minimum; see "Known limitations" below for what wasn't testable).
2. Load test:
   ```sh
   BASE_URL=http://localhost:8081/api/v1 \
     WARMUP_VUS=5 RAMP_VUS=25 SPIKE_VUS=75 \
     RUN_CART_JOURNEY=false \
     k6 run --summary-export=perf-tests/results/<name>.json perf-tests/k6/store-journey.js
   ```
3. Fault injection:
   ```sh
   ./perf-tests/toxiproxy/create-proxy.sh                 # once, proxy at 127.0.0.1:9043 -> yugabyte:9042
   ./perf-tests/toxiproxy/inject-toxics.sh latency         # or: timeout | reset
   BASE_URL=http://localhost:8081/api/v1 VUS=10 DURATION=20s \
     k6 run --summary-export=perf-tests/results/<name>.json perf-tests/k6/fault-injection-smoke.js
   ./perf-tests/toxiproxy/inject-toxics.sh clear
   ```
   `products-microservice` must be started with
   `--cronos.yugabyte.hostname=host.docker.internal --cronos.yugabyte.port=9043`
   (plus `--add-host=host.docker.internal:host-gateway`) so its DB traffic is
   routed through the proxy.

## Results

### Baseline load test (`store-journey.js`, browse-only, `RUN_CART_JOURNEY=false`)

5-minute ramp: 30s@5VU warm-up -> 1m ramp to 25VU -> 2m soak@25VU -> 1m
spike@75VU -> 30s ramp-down.

- `list products`: **0% errors**, p95 = 15.19ms, up to 75 concurrent VUs.
  No load-induced failure point found within this range.
- `product detail`: initially showed a 100% check failure rate. Root cause
  (confirmed via direct `curl`) was a **test-data artifact, not an
  application or load-induced failure**: the local database was unseeded, so
  looking up a nonexistent ASIN returns `500` (see "Known limitations /
  findings" below — this itself is a real bug worth fixing). The script now
  extracts a real ASIN from the `list products` response when the catalog is
  seeded, so this check is only unreliable on an empty database.
- Throughput: ~53 req/s average, up to 75 VUs, no saturation signals
  observed at this scale.

Full data: `results/baseline-browse.json`.

### Fault injection (`fault-injection-smoke.js`, constant 10 VUs, 20s, via Toxiproxy on the YCQL proxy)

| Scenario | p95 latency | Error rate | Throughput | Notes |
|---|---|---|---|---|
| No toxic (baseline) | 6.18ms | 0% | ~2492 req/s | `results/fault-baseline.json` |
| `latency` (500ms ± 100ms jitter, both directions) | **1.15s** (breaches the 1s SLO) | 0% | ~9.5 req/s | Requests succeed but are serialized behind the injected DB latency; throughput collapses ~260x. `results/fault-latency.json` |
| `reset_peer` (upstream, 1000ms timeout) | 119ms (of failed requests) | **100%** | ~317 req/s | Every request fails with HTTP 500; app logs show `com.datastax.oss.driver.api.core.NoNodeAvailableException: No node was available to execute the query`. `results/fault-reset.json` |

Additional finding from the `reset_peer` scenario: after the toxic was
cleared, the service **did not recover instantly**. `products-microservice`
kept returning `500`/`NoNodeAvailableException` for roughly 10-20s post-clear
before the DataStax driver reconnected and requests started succeeding again
(confirmed by polling the endpoint every 10s after clearing the toxic). This
is a real, observed **cascading-failure / recovery-lag** finding: a
transient DB network blip can cause an outage window measurably longer than
the fault itself.

### Interpretation vs. issue #55's failure signals

- **Error rate > 1%**: hit under the `reset_peer` scenario (100%) and during
  the post-recovery lag window; not hit under normal load up to 75 VUs.
- **p95 > 1s**: hit under the `latency` scenario (1.15s); not hit under
  normal load up to 75 VUs (15.19ms).
- **Saturation / connection pool exhaustion**: not observed from
  application-level load in the tested VU range; instead, the ~2GB Docker
  Desktop memory ceiling on the test host was itself a saturation point (see
  below) that limited how many services could run concurrently.
- **Cascading failures**: observed and documented above (reset_peer ->
  sustained outage past toxic removal).

## Known limitations / environment findings

These were discovered while setting up a real environment to run the tests
above. They are documented here because they materially affect what could be
tested and are relevant "failure point" findings in their own right.

1. **Eureka bootstrap hostname precedence bug.** `bootstrap.yml` in each
   service hardcodes `eureka.instance.hostname: localhost`, which has higher
   precedence than main-context command-line args in Spring Cloud's
   bootstrap property source layering. Passing
   `--eureka.instance.hostname=<ip>` on the CLI is silently ignored, and
   setting an `EUREKA_URI` env var does not help either. Workaround: pass
   the fully-resolved property directly,
   `--eureka.client.serviceUrl.defaultZone=http://<ip>:8761/eureka`, which
   bypasses the broken placeholder resolution.
2. **`cart-microservice` has a hardcoded Postgres datasource** pointing at
   `127.0.0.1:5433`, with no CLI-overridable host/port property (unlike
   `products-microservice`/`checkout-microservice`, which expose
   `cronos.yugabyte.hostname`/`cronos.yugabyte.port`). This blocked
   cart/checkout journey testing entirely in this environment; the full
   store-journey script supports it (`RUN_CART_JOURNEY=true`) but could not
   be exercised here.
3. **Docker Desktop's default memory allocation (~2GB)** on the test host
   caused JVM containers to be OOM-killed (exit 137) when running the full
   stack (eureka + products + cart + checkout + gateway + react + yugabyte)
   concurrently. This is itself a legitimate "saturation signal" per the
   issue's definition, just at the infrastructure layer rather than the
   application layer. Testing proceeded with a minimal stack (eureka +
   products + api-gateway, memory-capped containers).
4. **`GET /api/v1/product/{asin}` returns `500` instead of `404`** for a
   nonexistent ASIN. This is a correctness/robustness bug independent of
   load: missing-resource lookups should return `404`, not an unhandled
   `500`. It was the root cause of the initial "product detail" check
   failures in the baseline run.

## Recommendations

- Fix `GET /api/v1/product/{asin}` to return `404` for unknown ASINs instead
  of `500`.
- Make `cart-microservice`'s datasource host/port configurable (mirroring
  `cronos.yugabyte.hostname`/`cronos.yugabyte.port` on the other services)
  so cart/checkout can be included in perf/fault-injection testing.
- Fix or document the `bootstrap.yml` Eureka hostname precedence issue so
  `--eureka.instance.hostname` overrides work as expected without needing
  the `defaultZone` workaround.
- Investigate the DataStax driver's reconnection/backoff behavior after a
  `NoNodeAvailableException`, since the observed ~10-20s recovery lag after
  a transient DB network fault clears extends an outage beyond the fault's
  actual duration; consider tuning reconnection policy or adding
  circuit-breaker/retry logic at the application layer.
- Increase Docker Desktop's memory allocation to at least 6GB for local perf
  testing of the full stack, or run these tests in a properly resourced CI
  runner / cloud VM to find true application-level breaking points beyond
  what a 2GB-constrained laptop environment can exercise.
- Seed the local database (`resources/dataload.sh` / `resources/products.json`)
  before running perf tests so `product detail` and cart/checkout flows
  exercise real data paths.
