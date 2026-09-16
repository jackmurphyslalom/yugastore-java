# ADR-0001: Deployment target is localhost only

## Status

Accepted

## Context

The 2026-09-14 kickoff meeting tentatively picked AWS as the target cloud provider, chosen only
because it was the one provider a team member had working credentials for
(`docs/decisions/2026-09-14-1758-immersion-kickoff-decisions.md`). Every microservice also still
ships a Cloud Foundry `manifest.yml` (legacy Pivotal/CF target referenced by the README's hosted
demo link). Neither was ever exercised or verified during this engagement, and reversing a
cloud-provider choice after infrastructure work begins is expensive, so the ambiguity was tracked
as an open gap (`docs/context/gaps.md`) and left unresolved in the constitution
(`TODO(DEPLOYMENT_TARGET)`).

## Tradeoff

Alternatives considered: AWS (kickoff's tentative pick, no credentials exercised), Cloud Foundry
(manifests already exist per service but target platform was never confirmed as live/reachable).
Both require provisioning and ongoing access that this engagement does not have a verified need
for; running locally removes that dependency entirely while keeping every service runnable via
existing tooling (`docker-run.sh`, per-service `mvn spring-boot:run`).

## Decision

The deployment target for this engagement is **localhost only** — run via `docker-run.sh`
(container stack) or manual per-service `mvn spring-boot:run`. No cloud target (AWS or Cloud
Foundry) is in scope. Existing `manifest.yml` files remain in the repo but are dormant/unused.

## Consequences

- `docs/context/gaps.md`'s deployment-target ambiguity gap is resolved and removed.
- `.specify/memory/constitution.md`'s `TODO(DEPLOYMENT_TARGET)` is resolved via a constitution
  amendment referencing this ADR.
- `docs/architecture/overview.md` and `docs/context/bootstrap-report.md` open questions about
  AWS vs. Cloud Foundry vs. Docker are resolved in favor of local/Docker.
- Future work proposing a real cloud deployment must supersede this ADR rather than silently
  reintroducing AWS/CF as an assumption.
