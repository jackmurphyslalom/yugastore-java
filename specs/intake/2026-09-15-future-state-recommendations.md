# Future-State Recommendations — Proposal 3 of 3

Raw intake, not yet a spec. Feed into `/speckit.aisdlc.triage` or `/speckit.specify` after a
grilling session confirms domain intent. **Gated on Proposal 2 completion.**

## Source
- Split from `docs/next.md` (2026-09-15). See sibling proposals:
  `2026-09-15-rabbit-wiki-lifecycle.md` and `2026-09-15-architecture-assessment.md`.
- Client requirements restated here from
  `specs/intake/2026-09-14-client-requirements-interview.md` and
  `docs/decisions/2026-09-14-1758-immersion-kickoff-decisions.md`.

## Dependencies
- **Hard dependency on Proposal 2** (`2026-09-15-architecture-assessment.md`), with two parts:
  1. Proposal 2's per-tier and rollup skills must be **implemented** (built), and
  2. those skills must then be **run** at least once against this repo, producing real content
     under `meta/architecture-assessment/`.
  This proposal's spec content (the actual recommendation files) cannot be finalized until both
  parts are done, since each recommendation must cite real findings from that generated content.
  The proposal/spec/tasks structure itself (skill scaffolding, file layout, task list) can be
  generated now; only the recommendation *content* tasks stay blocked pending Proposal 2's run.

## Summary of request
Using the completed current-state architecture assessment (Proposal 2) as a foundation, produce
a future-state document that:

- Proposes strategic enhancements to harden weak areas found in the current-state assessment.
- Directly answers the client's three core needs:
  1. Run constant experiments (pricing, UX, recommendations) without engineering becoming a
     bottleneck.
  2. Storefront must degrade gracefully when any dependent service slows or goes down.
  3. Pricing rules change weekly; engineers shouldn't need to redeploy everything to change them.

## Grilling outcome (structural decisions confirmed 2026-09-15; content gated on Proposal 2)

Grilled via `aisdlc-grilling`. Structural/scope decisions below are user-confirmed. Content for
each file cannot be finalized until Proposal 2's `meta/architecture-assessment/` output exists.

1. Output root: `meta/future-state/README.md` (index) — its own namespace parallel to
   `meta/architecture-assessment/` and `meta/rabbit-wiki/`.
2. Structure: one file per client need — `meta/future-state/experimentation.md`,
   `graceful-degradation.md`, `pricing-agility.md` — plus the index `README.md`. No ADRs.
3. Each file format ("A+"): states the client need, cites the relevant current-state finding
   from `meta/architecture-assessment/`, lists real alternatives (A/B/C), then gives one
   explicit recommendation with a short tradeoff rationale. Example shape:
   ```markdown
   # Graceful Degradation

   ## Client need
   "When any service slows down or goes down, the storefront must degrade gracefully."

   ## Current-state finding (from meta/architecture-assessment/)
   No fallback/circuit-breaker code found in the gateway's REST clients today.

   ## Options considered
   - A. Circuit breaker on gateway REST clients (e.g. Resilience4j)
   - B. Eureka-aware degradation checks before calling
   - C. Client-side (react-ui) fallback UI states

   ## Recommendation
   **A**, because ...

   ## Alternatives considered
   ...
   ```
4. Explicit "Out of Scope" section required in the spec: this proposal produces recommendations
   only — no code changes. Any adopted recommendation must go through its own
   `/speckit.specify` cycle before implementation.
5. **Gate reaffirmed:** this proposal's spec cannot be finalized/specified until Proposal 2's
   `meta/architecture-assessment/` content actually exists, since each recommendation file must
   cite real findings from it.

## Not Yet Resolved
- Content confirmation (the actual recommendations) is blocked on Proposal 2's implementation.
