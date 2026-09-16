// k6 load test: simulates a browse -> add to cart -> checkout user journey
// against the api-gateway-microservice, ramping load to locate the point at
// which the app degrades or fails. See ../README.md for thresholds and usage.
import http from 'k6/http';
import { check, group, sleep } from 'k6';
import { Rate } from 'k6/metrics';

// Base URL of the api-gateway-microservice (entry point for the whole stack).
const BASE_URL = __ENV.BASE_URL || 'http://localhost:8081/api/v1';

// Set to "false" to skip the cart/checkout steps, e.g. when those services
// are not available in the environment under test (see README "Known
// limitations").
const RUN_CART_JOURNEY = (__ENV.RUN_CART_JOURNEY || 'true') !== 'false';

// A handful of ASINs to drive product-detail lookups. Update once the
// catalog is seeded with representative data (see resources/dataload.sh).
const ASINS = (__ENV.ASINS || '0000000000').split(',');

export const errorRate = new Rate('errors');

// Staged ramp: fixed warm-up -> ramp-up -> soak -> spike -> ramp-down.
// Stage durations/targets are intentionally small defaults so the script is
// safe to run against a laptop-sized dev environment; override via k6 CLI
// (--stage) or env-specific options files for real breaking-point runs.
export const options = {
  scenarios: {
    store_journey: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '30s', target: Number(__ENV.WARMUP_VUS || 5) }, // fixed warm-up
        { duration: '1m', target: Number(__ENV.RAMP_VUS || 25) }, // ramp-up
        { duration: '2m', target: Number(__ENV.RAMP_VUS || 25) }, // soak at ramp target
        { duration: '1m', target: Number(__ENV.SPIKE_VUS || 75) }, // spike
        { duration: '30s', target: 0 }, // ramp-down
      ],
      gracefulRampDown: '10s',
    },
  },
  thresholds: {
    // Failure-point definitions from the issue (issue #55):
    // - error rate must stay under 1% for a sustained window
    // - p95 latency must stay under 1s
    http_req_failed: ['rate<0.01'],
    http_req_duration: ['p(95)<1000'],
    errors: ['rate<0.01'],
  },
};

function recordCheck(res, name) {
  const ok = check(res, { [`${name}: status is 2xx`]: (r) => r.status >= 200 && r.status < 300 });
  errorRate.add(!ok);
  return ok;
}

export default function () {
  group('browse products', function () {
    const listRes = http.get(`${BASE_URL}/products?limit=20&offset=0`);
    const listOk = recordCheck(listRes, 'list products');

    // Prefer a real ASIN from the catalog response so "product detail" is a
    // valid lookup regardless of whether the DB has been seeded; fall back
    // to the configured ASINS list (which may be a placeholder in an
    // unseeded environment - see README "Known limitations").
    let asin = ASINS[Math.floor(Math.random() * ASINS.length)];
    if (listOk) {
      try {
        const products = listRes.json();
        if (Array.isArray(products) && products.length > 0 && products[0].asin) {
          asin = products[Math.floor(Math.random() * products.length)].asin;
        }
      } catch (e) {
        // non-JSON or unexpected shape; keep the configured fallback ASIN
      }
    }
    const detailRes = http.get(`${BASE_URL}/product/${asin}`);
    recordCheck(detailRes, 'product detail');
  });

  if (RUN_CART_JOURNEY) {
    group('add to cart', function () {
      const addRes = http.post(`${BASE_URL}/shoppingCart/addProduct?asin=${ASINS[0]}`);
      recordCheck(addRes, 'add to cart');
    });

    group('checkout', function () {
      const checkoutRes = http.post(`${BASE_URL}/shoppingCart/checkout`);
      recordCheck(checkoutRes, 'checkout');
    });
  }

  sleep(1);
}
