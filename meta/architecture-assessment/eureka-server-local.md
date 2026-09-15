# Architecture Assessment: `eureka-server-local`

**Tier**: `eureka-server-local` | **Port**: 8761 | **Assessed**: 2026-09-15

## Context

`eureka-server-local` is a Spring Cloud Netflix Eureka service registry (`YugastoreEurekaServer`).
Every other Spring Boot tier registers with it on startup and it must be the first service
started, per `docs/architecture/overview.md`'s Startup flow. Its own `application.yml` disables
self-registration (`registerWithEureka: false`, `fetchRegistry: false`), consistent with running
as a standalone registry rather than a peer. Evidence consulted: `docs/architecture/overview.md`,
`eureka-server-local/application.yml`, `eureka-server-local/pom.xml`, `eureka-server-local/Dockerfile`,
`eureka-server-local/manifest.yml`.

## Findings

- A single-instance registry is a single point of failure for service discovery; no
  peer-replication config was observed, so an outage here would break inter-service discovery
  for the whole fleet even though each individual downstream service might otherwise be healthy
  (Concurrency, score 2; Disposability, score 2).
- No custom admin/one-off task classes exist in this tier; only Eureka's stock dashboard is
  present, not custom application admin tooling (Admin Processes, score 1).
- Config is split across `application.yml` and a sibling `application-cloud.yml`, which is a
  reasonable environment-profile pattern but stops short of full environment-variable injection
  (Config, score 3; Dev/prod parity, score 3).

## Recommendation

Is a single, non-replicated Eureka instance an acceptable risk for this engagement's target
deployment, or does resilience scope (see `docs/context/gaps.md`'s graceful degradation entry)
require a highly-available registry? Treat as unresolved pending the same graceful-degradation
scoping decision already logged in `docs/context/gaps.md` — do not add peer replication config
speculatively; record this as a related consideration if that gap is picked up later.

## 16-Factor Assessment

| # | Name | Score | Explanation |
|---|---|---|---|
| I | Codebase | 5 | The tier is a single Maven module within a unified git repository alongside all other tiers, enabling version-controlled codebase management with independent module builds and deployments. |
| II | Dependencies | 5 | All dependencies are explicitly declared with pinned versions (no floating ranges), properly isolated by scope (test scope clearly marked), and managed through BOMs (spring-boot-starter-parent, spring-cloud.version). |
| III | Config | 3 | Configuration uses YAML files with an environment-specific profile (`application-cloud.yml`), showing intentional separation from code and no hardcoded constants, but lacks explicit environment-variable injection required for strict 12-factor compliance. |
| IV | Backing services | 5 | The tier has no backing service dependencies to manage, so it trivially satisfies the principle of externalizing and attaching backing services as external resources (there are none to misconfigure or hardcode). |
| V | Build, release, run | 5 | Maven build, Docker release stage, and Cloud Foundry run manifest demonstrate strict separation of all three stages with no mixing of concerns, consistent across all repository tiers. |
| VI | Processes | 5 | The app is stateless with no sticky sessions or session persistence; in-memory registry state is ephemeral and rebuildable, fully meeting 12-factor Processes requirements. |
| VII | Port binding | 5 | Self-contained via Spring Boot's embedded server with explicit configuration (port 8761), requires no external web server, and the port is documented and consistent with `docs/architecture/overview.md`. |
| VIII | Concurrency | 2 | Multiple instances would create isolated split-brain registries instead of forming a scalable cluster, violating the 12-factor process model for concurrency. |
| IX | Disposability | 2 | Spring Boot provides fast startup and graceful shutdown, but because every other tier registers with this one at startup, its own restart transiently breaks discovery for the whole fleet until clients re-register. |
| X | Dev/prod parity | 3 | Separate environment-specific config profiles (`application.yml` vs `application-cloud.yml`) create acknowledged configuration divergence between dev and cloud deployments, and Dockerfile parity across environments is unconfirmed. |
| XI | Logs | 4 | Relies on Spring Boot's default stdout logging with no custom file-writing code or log-rotation config, which is stream-friendly for container platforms. |
| XII | Admin Processes | 1 | No custom admin/one-off task classes observed; only Eureka's built-in web dashboard exists, which is a stock framework feature, not custom application admin tooling. |
| XIII | Prompts as code | N/A | No AI/LLM component, prompt infrastructure, or generative-AI integration observed in this tier. |
| XIV | State as a service | N/A | Pure service registry with no conversational or AI-context state concerns. |
| XV | Observability for non-determinism | N/A | Deterministic service registry with no AI/LLM components or model outputs. |
| XVI | Trust & safety by design | N/A | Pure infrastructure service registry with no AI/LLM components or user-generated-content surfaces. |
