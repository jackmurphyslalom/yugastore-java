#!/usr/bin/env bash
# Adds toxics to an existing Toxiproxy proxy to simulate degraded database
# connectivity (the "fault-injection / resiliency" scenario from issue #55).
#
# Usage:
#   ./inject-toxics.sh <scenario> [proxy_name]
#
# Scenarios:
#   latency  - adds 500ms +/- 100ms latency both directions (simulates a slow DB link)
#   timeout  - adds a downstream timeout toxic (connection hangs then resets)
#   reset    - adds a reset_peer toxic on the upstream direction (simulates DB connection drops)
#   clear    - removes all toxics from the proxy (restore baseline)
set -euo pipefail

SCENARIO="${1:?usage: inject-toxics.sh <latency|timeout|reset|clear> [proxy_name]}"
NAME="${2:-yugabyte-ycql}"

if ! command -v toxiproxy-cli >/dev/null 2>&1; then
  echo "toxiproxy-cli not found. Install with: brew install toxiproxy" >&2
  exit 1
fi

case "$SCENARIO" in
  latency)
    toxiproxy-cli toxic add -t latency -a latency=500 -a jitter=100 -n dbLatencyDown -d "$NAME"
    toxiproxy-cli toxic add -t latency -a latency=500 -a jitter=100 -n dbLatencyUp -u "$NAME"
    ;;
  timeout)
    toxiproxy-cli toxic add -t timeout -a timeout=3000 -n dbTimeout -d "$NAME"
    ;;
  reset)
    toxiproxy-cli toxic add -t reset_peer -a timeout=1000 -n dbResetPeer -u "$NAME"
    ;;
  clear)
    toxics=$(toxiproxy-cli inspect "$NAME" | awk -F'\t' 'NF>1 {print $1}')
    for toxic in $toxics; do
      toxiproxy-cli toxic remove -n "$toxic" "$NAME" || true
    done
    ;;
  *)
    echo "Unknown scenario: $SCENARIO" >&2
    exit 1
    ;;
esac

toxiproxy-cli inspect "$NAME"
