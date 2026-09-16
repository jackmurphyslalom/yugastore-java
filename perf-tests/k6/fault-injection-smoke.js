// Short constant-load smoke script used to observe the delta in latency /
// error rate when a Toxiproxy toxic is active vs. not, without waiting for
// the full ramping scenario in store-journey.js. See ../README.md.
import http from 'k6/http';
import { check } from 'k6';

const BASE_URL = __ENV.BASE_URL || 'http://localhost:8081/api/v1';

export const options = {
  scenarios: {
    smoke: {
      executor: 'constant-vus',
      vus: Number(__ENV.VUS || 10),
      duration: __ENV.DURATION || '30s',
    },
  },
  thresholds: {
    http_req_failed: ['rate<0.01'],
    http_req_duration: ['p(95)<1000'],
  },
};

export default function () {
  const res = http.get(`${BASE_URL}/products?limit=20&offset=0`);
  check(res, { 'list products: status is 2xx': (r) => r.status >= 200 && r.status < 300 });
}
