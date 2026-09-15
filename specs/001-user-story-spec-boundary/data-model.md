# Data Model: GitHub Issue vs. Spec Kit Feature Spec Boundary

This feature has no database or application data model. The "entities" below are the three
conceptual artifacts the new documentation must distinguish (from [spec.md](spec.md) Key
Entities), captured here for traceability into the doc content and tasks.

## GitHub Issue

- **What it represents**: The product-level backlog/planning artifact, tracked on GitHub for
  `jackmurphyslalom/yugastore-java` (project board + `tools/gh-agent-board` tooling).
- **Lifecycle**: Open → (optionally linked to a `specs/<feature>/`) → closed. Closing remains a
  human-only action (no `close-issue.sh` script exists — see `tools/gh-agent-board/README.md`).
- **Relationship**: May exist standalone (small changes, e.g. issue #19) or reference a
  `specs/<feature>/` via `link-artifacts.sh` (larger changes, e.g. issue that seeded
  `specs/copilot-agent-issue-board/`).

## Spec Kit Feature (`specs/<feature>/`)

- **What it represents**: The local delivery artifact set — `spec.md`, `plan.md`, `tasks.md`,
  optional `context/` — produced by the Spec Kit workflow for one unit of implementation work.
- **Lifecycle**: Draft (`spec.md` created) → planned (`plan.md`) → tasked (`tasks.md`) →
  implemented. Tracked independently of the originating Issue's open/closed state.
- **Relationship**: May reference an originating GitHub Issue (via `link-artifacts.sh`); is the
  authoritative artifact for scope/requirements once it exists (per spec.md User Story 2).

## User Story (`spec.md` section)

- **What it represents**: A prioritized (P1/P2/P3) user journey documented *inside* a single
  `spec.md`, per the Spec Kit template's own "User Story N" heading convention.
- **Relationship**: Not a standalone artifact — always a subsection of one Spec Kit Feature's
  `spec.md`. Explicitly distinct from a GitHub Issue (spec.md User Story 3 / FR-005); the new
  documentation must state this distinction directly to prevent the terminology collision.
