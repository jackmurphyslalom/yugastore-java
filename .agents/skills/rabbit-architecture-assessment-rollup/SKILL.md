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
- Check it is structurally valid: it contains the exact headings `## Context`, `## Findings`,
  `## Recommendation`, and `## 16-Factor Assessment` (the same headings the tier skill writes),
  with every one of the 16 factor rows carrying a Score and an Explanation. A file missing any
  required heading, missing a Score/Explanation on any factor row, or an empty/unreadable file,
  is treated identically to a missing file.
- Separately, for the foundational posture score section only (Step 2.6): check that every one
  of the 16 factor rows also carries a `Gap to 5` and `Quick Fix` column, and that
  `## Recommendation` carries `Size`, `Risk`, and human/agent time-on-task fields. A tier missing
  any of these is treated the same as a structurally invalid tier file for this section's gate
  (FR-023) — the rest of `README.md` (diagrams, index) still proceeds normally when the base
  Step 1 gate passes.

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
7. Write a **Foundational Posture Score** section aggregating all 7 tiers into one cross-tier
   sixteen-factor summary. When the gate in Step 1 (Gap to 5 / Quick Fix / Size / Risk / human
   and agent time-on-task present on every tier) passes: for each tier, cite its lowest-scoring
   factor(s) as its weakness, its Recommendation's `Size` as estimated cost, and its
   `Risk` category as estimated risk — do not restate the full 16-factor table, only the
   cross-tier summary of weaknesses/cost/risk grounded in each tier's own file (FR-023). When the
   gate does not pass for one or more tiers, state which tiers lack the required fields and omit
   only those tiers' rows from the summary (this does not block the diagrams or index above).
8. Write `meta/architecture-assessment/README.md`, fully overwriting any prior content (idempotent
   full regeneration on every successful re-run — never append or leave stale content).

## Completion Report

- On gate failure: report the exact list of missing/invalid tier filenames; confirm
  `README.md` was not created or modified.
- On success: report the output path, confirm exactly one C1, one C2, and one C3 Mermaid block
  were written and validated, confirm the index links all 7 tier files, and confirm whether the
  Foundational Posture Score section covers all 7 tiers or lists which tiers were omitted for
  missing fields.
