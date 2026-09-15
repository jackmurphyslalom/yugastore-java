---
name: rabbit-architecture-assessment-tier
description: Assess a single yugastore-java application tier against an SCQA overview and the full 16-factor (12-factor + 4 AI-era factors) model, writing meta/architecture-assessment/{tier-name}.md. Use when the user wants a per-tier architecture assessment for one of the 7 recognized tiers (eureka-server-local, products-microservice, checkout-microservice, cart-microservice, api-gateway-microservice, login-microservice, react-ui).
license: MIT
---

# Architecture Assessment: Tier

Produce a per-tier assessment file for exactly one of the repo's 7 recognized application tiers.
This is the producer half of the architecture-assessment feature; its sibling skill,
`rabbit-architecture-assessment-rollup`, gates on the files this skill writes and never performs
its own 16-factor scoring. Contract: `specs/003-architecture-assessment/contracts/rabbit-architecture-assessment-tier.md`.

## Recognized Application Tiers (fixed enumeration)

Exactly these 7 values are valid targets (from `specs/003-architecture-assessment/data-model.md`):

- `eureka-server-local`
- `products-microservice`
- `checkout-microservice`
- `cart-microservice`
- `api-gateway-microservice`
- `login-microservice`
- `react-ui`

## Step 1: Validate the target

- The target tier MUST be exactly one of the 7 values above (case-sensitive, exact match).
- Reject any other target, including paths under `.agents/`, `.specify/`, or `.github/`, or any
  free-text description that doesn't match one of the 7 values exactly.
- On rejection: write no file. Report the rejected target and state it is outside the 7
  recognized application tiers, listing the 7 valid values.

## Step 2: Gather tier facts

- Read `docs/architecture/overview.md` for the tier's module table row, ports, responsibilities,
  and any flows or open questions naming this tier.
- Read the tier's own directory (`application.yml`, `pom.xml`, `Dockerfile`, `README.md` if
  present, and `src/main/java` package layout) for concrete, tier-specific evidence — do not
  paraphrase from memory alone.
- Do not modify any file under the 7 microservice/`react-ui` module directories — this skill only
  reads that source; all writes go to `meta/architecture-assessment/`.

## Step 3: Write the SCQA overview

Under the exact heading `## SCQA Overview`, write four short paragraphs or bullet groups specific
to this tier:

- **Situation**: what this tier is and its role in the system today.
- **Complication**: friction, risk, or open question specific to this tier (grounded in observed
  evidence, e.g. `docs/architecture/overview.md`'s Assumptions and Open Questions, or gaps found
  in source).
- **Question**: the key architecture question this tier raises.
- **Answer/recommendation**: a grounded, evidence-based recommendation (not speculation beyond
  what the source supports).

## Step 4: Write the 16-factor table

Under the exact heading `## 16-Factor Assessment`, write one Markdown table with exactly 16 rows,
one per factor, grounded in `docs/context/sources/2026-09-14-twelve-to-sixteen-factor-app.md`.
Columns: `Factor | Name | Assessment`. Use this exact ordered factor list (name column):

| # | Name |
|---|---|
| I | Codebase |
| II | Dependencies |
| III | Config |
| IV | Backing services |
| V | Build, release, run |
| VI | Processes |
| VII | Port binding |
| VIII | Concurrency |
| IX | Disposability |
| X | Dev/prod parity |
| XI | Logs |
| XII | Admin Processes |
| XIII | Prompts as code |
| XIV | State as a service |
| XV | Observability for non-determinism |
| XVI | Trust & safety by design |

- Score factors I-XII with a concrete assessment grounded in this tier's actual configuration
  and code (e.g. Config -> `application.yml` env-driven values; Port binding -> the tier's port
  from `docs/architecture/overview.md`'s module table; Logs -> whether structured/stdout logging
  is observed).
- Mark factors XIII-XVI as `N/A` unless this tier has an observed AI/LLM component (none of the 7
  tiers do today, per the spec's Assumptions) — still include all 4 rows, marked `N/A` with a
  one-line reason (no AI/LLM component observed).

## Step 5: `login-microservice`-only WIP/unwired finding

Only when the target is exactly `login-microservice`, add an explicit finding (its own short
subsection or a bolded line within the SCQA overview) citing `docs/architecture/overview.md`'s
module table row verbatim in substance: `login-microservice` is **WIP**, with no `api-gateway`
REST client wired yet (no corresponding client exists under
`api-gateway-microservice/src/main/java/.../rest/clients/`). Do not add this finding for any
other tier.

## Step 6: Write the file

- Write exactly one file: `meta/architecture-assessment/{tier-name}.md`, where `{tier-name}` is
  the exact validated target value.
- If the file already exists, fully overwrite it — never merge, append, or hand-preserve prior
  content (idempotent full-overwrite behavior on every re-run).
- Create `meta/architecture-assessment/` first if it does not yet exist.

## Completion Report

Report: the validated target tier, the output file path, and a one-line confirmation that both
the `## SCQA Overview` and `## 16-Factor Assessment` headings are present. On rejection, report
only the rejected target and the 7 valid values — no file path.
