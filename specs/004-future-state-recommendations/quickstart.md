# Quickstart: Validating the Future-State Recommendations Deliverable

## Prerequisites

- This repository checked out locally.
- For **scaffolding validation** (buildable now): no other prerequisite.
- For **content validation** (blocked — see below): `meta/architecture-assessment/` must exist
  with real, generated output from Feature 003's implemented and executed skills
  (`rabbit-architecture-assessment-tier`, `rabbit-architecture-assessment-rollup`). At plan time
  (2026-09-15), this directory does not exist — content validation cannot yet be performed.

## Scaffolding validation (available now)

1. Confirm exactly 4 files exist under `meta/future-state/`:
   - `README.md`
   - `experimentation.md`
   - `graceful-degradation.md`
   - `pricing-agility.md`
2. Open `meta/future-state/README.md` and confirm it lists all 3 client needs, each with a
   working relative link to its file, and a `Status` column that says `Scaffolded — pending
   Feature 003` for every file that has no content yet (FR-001, spec Edge Cases).
3. Open each of the three recommendation files and confirm:
   - The `## Client need` section states its client need **verbatim**, matching the table in
     [contracts/recommendation-document-format.md](./contracts/recommendation-document-format.md)
     exactly (FR-004).
   - The remaining four sections (`Current-state finding`, `Options considered`,
     `Recommendation`, `Alternatives considered`) exist as headings, each containing only the
     blocked placeholder note — no fabricated finding, option, or recommendation (FR-012).
4. Confirm no ADR files were created under `docs/architecture/adr/` as a side effect (FR-009).
5. Confirm no file under any `*-microservice/src` or `react-ui/frontend` directory was modified
   (FR-010, SC-004) — e.g. `git status` shows no changes outside `meta/future-state/`.

## Content validation (blocked until Feature 003 output exists)

Do not attempt this section until `meta/architecture-assessment/` exists with real tier
assessments and a rollup `README.md`. When that precondition is met:

1. Re-open each of the three recommendation files and confirm:
   - `Current-state finding` cites a specific file/section from `meta/architecture-assessment/`
     (or explicitly notes the absence of a directly relevant finding — spec Edge Cases), not a
     generic claim (FR-005, SC-002).
   - `Options considered` lists at least two real, distinct alternatives labeled A, B, (C, ...)
     (FR-006, SC-003).
   - `Recommendation` names exactly one labeled option and gives a tradeoff rationale (FR-007,
     SC-003).
   - `Alternatives considered` gives a brief reason for each non-chosen option (FR-008).
   - The recommendation section states that adoption requires a future `/speckit.specify` cycle
     (FR-011, SC-005).
2. Re-open `meta/future-state/README.md` and confirm the `Status` column now reads `Content
   complete` for each file whose content has been filled in (no file should ever silently jump
   from `Scaffolded` to `Content complete` without an actual content-authoring pass).
3. A reader unfamiliar with the engagement should be able to find all three recommendations from
   the index in under 1 minute (SC-001) — time this manually as a sanity check.

## Out of scope for this quickstart

- Verifying Feature 003's own tier assessments or rollup output — that is Feature 003's
  quickstart, not this feature's.
- Any application code build, test, or run steps — this feature does not touch application code.
