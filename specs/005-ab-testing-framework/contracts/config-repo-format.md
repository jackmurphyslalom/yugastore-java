# Config Repo Format

**Input**: [data-model.md](data-model.md), [research.md](research.md) R-1

## `config-server-microservice/config-repo/application.yml`

The shared profile Spring Cloud Config Server's native backend serves to every registered
client application (`products-microservice`, `checkout-microservice`, and indirectly `react-ui`
via the gateway). One top-level key per `Experiment Toggle`.

```yaml
experiment:
  ranking-strategy: default        # allowed: default, price-desc, newest-first
  ux-variant: control              # allowed: control, variant-a
```

- Adding a new toggle key requires (a) adding it here with a safe default value and (b) adding
  it to `ToggleAllowList` in `config-server-microservice` — both are code changes gated by normal
  review, not a runtime-writable registration mechanism, for this iteration.
- Editing this file directly (instead of through `PUT /admin/toggles/{key}`) is a valid write
  path under FR-009's "API/config-file-only" resolution, but bypasses FR-004 validation and does
  not append a `toggle-history.json` entry — the admin endpoint is the recommended path for any
  change an experiment owner wants tracked.

## `config-server-microservice/config-repo/toggle-history.json`

Append-only. One JSON array; each accepted write via `PUT /admin/toggles/{key}` appends one
entry. Never mutated or truncated by this feature.

```json
[
  {
    "key": "experiment.ranking-strategy",
    "previousValue": "default",
    "newValue": "price-desc",
    "changedAt": "2026-09-16T14:32:00Z",
    "changedBy": "pm-jordan"
  }
]
```

- `previousValue` is `null` for a key's first-ever recorded write.
- `changedBy` is optional free text (FR-009 resolution: no authenticated identity system backs
  this field for this iteration).
- Read by `GET /admin/toggles/history` (optionally filtered by `key`); never read by
  `products-microservice`, `checkout-microservice`, or `api-gateway-microservice` — history is an
  operator/experiment-owner concern (Story 3), not a runtime behavior input.
