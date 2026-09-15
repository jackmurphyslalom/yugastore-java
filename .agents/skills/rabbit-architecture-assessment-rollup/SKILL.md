---
name: rabbit-architecture-assessment-rollup
description: Roll up all 7 per-tier architecture assessments into meta/architecture-assessment/README.md with C1/C2/C3 Mermaid diagrams. Hard-gates on all 7 tier files existing and being structurally valid before writing anything. Use when the user wants the whole-system architecture rollup after tier assessments exist.
license: MIT
---

# Architecture Assessment: Rollup

Read the 7 fixed tier assessment files under `meta/architecture-assessment/` and either (a) refuse
to write anything and report exactly which tiers are missing/invalid, or (b) write
`meta/architecture-assessment/README.md` with C1/C2/C3 Mermaid diagrams plus an index. This skill
takes no target argument. Contract:
`specs/003-architecture-assessment/contracts/rabbit-architecture-assessment-rollup.md`. This skill
never performs its own per-tier 16-factor assessment — it only reads files produced by
`rabbit-architecture-assessment-tier`.

## Fixed Tier Filenames (hard gate input)

Exactly these 7 files under `meta/architecture-assessment/` are checked, in this order:

1. `eureka-server-local.md`
2. `products-microservice.md`
3. `checkout-microservice.md`
4. `cart-microservice.md`
5. `api-gateway-microservice.md`
6. `login-microservice.md`
7. `react-ui.md`

## Step 1: Hard gate — check existence and structural validity

For each of the 7 fixed filenames above:

- Check the file exists under `meta/architecture-assessment/`.
- Check it is structurally valid: it contains both the exact heading `## SCQA Overview` and the
  exact heading `## 16-Factor Assessment` (the same two headings the tier skill writes). A file
  missing either heading, or an empty/unreadable file, is treated identically to a missing file.

If **any** of the 7 files is missing or structurally invalid:

- **MUST NOT** create or modify `meta/architecture-assessment/README.md` — leave it untouched
  (including not creating it if it does not yet exist). No partial or placeholder write is ever
  permitted.
- **MUST NOT** perform any per-tier 16-factor assessment itself to "fill the gap" — it only
  reports the gap.
- Report the exact list of every missing or structurally invalid tier filename (not a generic
  failure message), and stop. Do not proceed to Step 2.

## Step 2: Success path (all 7 tiers present and valid)

Only reached when Step 1 finds all 7 files present and structurally valid.

1. Generate exactly one **C1 (System Context)** Mermaid diagram covering the whole system: all 7
   tiers plus the external YugabyteDB (YCQL + YSQL) store and the end user/browser actor, showing
   `react-ui` as the sole user-facing entry point and `api-gateway-microservice` as the single
   downstream fan-out point (per `docs/architecture/overview.md`'s Request flow).
2. Generate exactly one **C2 (Container)** Mermaid diagram covering the whole system: each of the
   7 tiers as a container, `eureka-server-local` as the shared registry every other container
   registers with, and YugabyteDB YCQL/YSQL as external containers.
3. Generate exactly one **C3 (Component)** Mermaid diagram scoped to `api-gateway-microservice`
   only: its `*Controller` -> `*ServiceRest` -> `rest/clients/*RestClient` internal components,
   fanning out to Checkout/ShoppingCart/ProductCatalog per `docs/architecture/overview.md`'s
   Request flow. Do not include internal components of any other tier in this diagram.
4. **MUST NOT** generate a C4-Code (level 4) diagram of any kind.
5. Validate each of the 3 Mermaid blocks with this repo's Mermaid validator before writing (per
   `research.md`'s decision) — fix any syntax error before proceeding; do not write the file with
   an unvalidated or invalid block.
6. Write an index section identifying/linking all 7 per-tier files by their exact paths under
   `meta/architecture-assessment/`, so the file works as the human-facing entry point.
7. Write `meta/architecture-assessment/README.md`, fully overwriting any prior content (idempotent
   full regeneration on every successful re-run — never append or leave stale content).

## Completion Report

- On gate failure: report the exact list of missing/invalid tier filenames; confirm
  `README.md` was not created or modified.
- On success: report the output path, confirm exactly one C1, one C2, and one C3 Mermaid block
  were written and validated, and confirm the index links all 7 tier files.
