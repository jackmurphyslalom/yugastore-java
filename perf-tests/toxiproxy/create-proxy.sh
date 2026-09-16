#!/usr/bin/env bash
# Creates a Toxiproxy proxy in front of YugabyteDB's YCQL port so that
# products/checkout/cart-microservice traffic to the database can be faulted.
#
# Usage:
#   ./create-proxy.sh [listen_host:port] [upstream_host:port] [proxy_name]
#
# Defaults proxy 127.0.0.1:9043 -> 127.0.0.1:9042 (local YugabyteDB YCQL port).
# Point a microservice at the proxy instead of the real DB, e.g.:
#   --cronos.yugabyte.hostname=host.docker.internal --cronos.yugabyte.port=9043
set -euo pipefail

LISTEN="${1:-127.0.0.1:9043}"
UPSTREAM="${2:-127.0.0.1:9042}"
NAME="${3:-yugabyte-ycql}"

if ! command -v toxiproxy-cli >/dev/null 2>&1; then
  echo "toxiproxy-cli not found. Install with: brew install toxiproxy" >&2
  exit 1
fi

toxiproxy-cli create --listen "$LISTEN" --upstream "$UPSTREAM" "$NAME" || \
  echo "Proxy '$NAME' may already exist; continuing."

toxiproxy-cli list
