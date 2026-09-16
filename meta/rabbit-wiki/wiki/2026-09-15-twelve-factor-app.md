---
type: concept
authored_by: rabbit-analyze
confidence: high
last_verified: 2026-09-15
source_type: url
source_ref: meta/rabbit-wiki/sources/2026-09-15-twelve-factor-app
tags: [twelve-factor, cloud-native, methodology, architecture]
related: [2026-09-15-twelve-to-sixteen-factor-app]
---

# Twelve-Factor App

## Term/Concept

**Twelve-Factor App** — a methodology (Heroku, Adam Wiggins) for building software-as-a-service
apps that are portable, scale cleanly, and minimize divergence between development and
production.

## Definition

Twelve declarative principles for cloud-native application design:

1. **Codebase** — one codebase tracked in revision control, many deploys.
2. **Dependencies** — explicitly declare and isolate dependencies.
3. **Config** — store config in the environment, not in code.
4. **Backing services** — treat backing services (databases, queues, caches) as attached,
   swappable resources.
5. **Build, release, run** — strictly separate the build, release, and run stages.
6. **Processes** — execute the app as one or more stateless, share-nothing processes.
7. **Port binding** — export services via port binding; the app is self-contained.
8. **Concurrency** — scale out via the process model, not by growing a single process.
9. **Disposability** — maximize robustness with fast startup and graceful shutdown.
10. **Dev/prod parity** — keep development, staging, and production as similar as possible.
11. **Logs** — treat logs as time-ordered event streams written to stdout, not managed by the
    app itself.
12. **Admin processes** — run one-off admin/management tasks in the same environment and release
    as long-running processes.

The methodology targets portability across execution environments and rapid, continuous
deployment, and is applicable regardless of programming language or backing services used.

## Ontology links

- [twelve-factor-app](../ontology.yaml) (concept)
- [sixteen-factor-app](../ontology.yaml) (concept, related — the sixteen-factor app extends
  these twelve principles with four AI-era factors)

## Source anchor

[meta/rabbit-wiki/sources/2026-09-15-twelve-factor-app/](../sources/2026-09-15-twelve-factor-app/)

## Related entries

- [2026-09-15-twelve-to-sixteen-factor-app](2026-09-15-twelve-to-sixteen-factor-app.md) — extends
  this methodology with four additional factors for AI applications.
