# Feature Specification: GitHub Issue vs. Spec Kit Feature Spec Boundary

**Feature Branch**: `001-user-story-spec-boundary`

**Created**: 2026-09-15

**Status**: Draft

**Input**: User description: "Establish a separation between user stories and local feature specs: define and document a clear boundary between product-level user stories (backlog/planning artifacts, i.e. GitHub Issues) and the Spec Kit local specs/ feature specs (spec.md/plan.md/tasks.md), so it's clear which artifact is the source of truth at each stage and how they relate. (github.com/jackmurphyslalom/yugastore-java#21)"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Decide where new work should be tracked (Priority: P1)

A contributor (human or agent) has a new piece of work to file. They need a documented rule for
whether a GitHub Issue alone is sufficient, or whether the work also needs a `specs/<feature>/`
Spec Kit feature (spec.md/plan.md/tasks.md), so they don't guess or over/under-invest in process.

**Why this priority**: Without this, every new piece of work re-litigates "do I need a spec?" —
this is the most frequent decision point and the direct trigger for issue #21.

**Independent Test**: Given the documented promotion criteria, a contributor can correctly sort
three example intakes (a one-line config fix, a multi-service feature, and an ambiguous
in-between case) into "Issue only" or "Issue + specs/ feature" without asking a teammate.

**Acceptance Scenarios**:

1. **Given** a small, self-contained change (e.g. issue #19, the Brewfile), **When** a contributor
   checks the documented criteria, **Then** the doc confirms an Issue plus a direct PR is
   sufficient and no `specs/` feature is required.
2. **Given** a multi-step change with distinct user journeys (e.g. `copilot-agent-issue-board`),
   **When** a contributor checks the documented criteria, **Then** the doc confirms the Issue
   should be promoted into a `specs/<feature>/` Spec Kit feature before implementation.

---

### User Story 2 - Resolve which artifact is authoritative (Priority: P2)

A contributor or agent finds that a GitHub Issue's description and a `specs/<feature>/spec.md`
disagree (e.g. the Issue was edited after the spec was written, or vice versa). They need a
documented precedence rule per delivery stage (intake, specify, plan, tasks, implement, done) to
know which artifact to trust and update.

**Why this priority**: Prevents silent drift between the backlog artifact and the delivery
artifact once both exist for the same piece of work.

**Independent Test**: Given a documented precedence table, a reader can state, for each of the six
delivery stages, which single artifact is authoritative, without contradiction.

**Acceptance Scenarios**:

1. **Given** an open Issue linked to an in-progress `specs/<feature>/`, **When** the Issue body and
   `spec.md` disagree on scope, **Then** the doc states that `spec.md` (post-`/speckit.specify`) is
   authoritative and the Issue should be updated or linked to reflect it, not the reverse.
2. **Given** an Issue with no linked `specs/<feature>/` yet, **When** a contributor asks what's
   authoritative, **Then** the doc states the Issue is authoritative until a spec is created.

---

### User Story 3 - Avoid conflating spec.md "User Story" sections with backlog Issues (Priority: P3)

A contributor reads a `spec.md` and sees `### User Story 1 - ... (Priority: P1)` sections, then
sees the term "user story" used elsewhere to describe a GitHub Issue. They need the documentation
to explicitly distinguish these two uses of "user story" so they don't treat a `spec.md` section as
a standalone backlog item, or a GitHub Issue as a `spec.md` subsection.

**Why this priority**: Lower frequency than P1/P2, but a recurring terminology trap since the
Spec Kit template itself uses "User Story" as a spec.md heading.

**Independent Test**: Given the documented terminology note, a reader can correctly answer "is a
`spec.md` User Story section the same artifact as a GitHub Issue?" (no) without additional
clarification.

**Acceptance Scenarios**:

1. **Given** the new documentation, **When** a reader looks up "user story", **Then** they find an
   explicit note that a `spec.md` "User Story" section is a prioritized journey *within* one
   Spec Kit feature, distinct from a GitHub Issue (the product-level backlog item).

### Edge Cases

- What happens when a GitHub Issue is closed by a direct PR and no `specs/` feature was ever
  created (e.g. issue #19)? → Documented as the expected "Issue only" path, not a process gap.
- What happens when a `specs/<feature>/` exists but its originating GitHub Issue was never linked
  (no `link-artifacts.sh` call recorded)? → Documented as a defect to fix by linking after the
  fact, not a reason to duplicate the Issue.
- How is scope growth handled when an Issue starts as a small fix but grows into something that
  needs a `specs/` feature mid-flight? → Documented: promote at the point scope grows, and link the
  existing Issue into the newly created `specs/<feature>/` rather than opening a second Issue.
- What happens to the GitHub Issue when the linked `specs/<feature>/` implementation lands?
  → Documented: closing the Issue remains a human-only action (per `tools/gh-agent-board`); the
  spec's own "Status" and the Issue's open/closed state are tracked independently.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The documentation MUST define GitHub Issues (tracked in
  `jackmurphyslalom/yugastore-java`, using the existing project board and `tools/gh-agent-board`
  tooling) as the product-level backlog/planning artifact.
- **FR-002**: The documentation MUST define `specs/<feature>/{spec,plan,tasks}.md` as the local,
  per-feature Spec Kit delivery artifacts, distinct from the backlog artifact in FR-001.
- **FR-003**: The documentation MUST state, per delivery stage (intake/backlog, `/speckit.specify`,
  `/speckit.plan`, `/speckit.tasks`, `/speckit.implement`, done/closed), which single artifact is
  authoritative.
- **FR-004**: The documentation MUST give concrete promotion criteria — with at least one
  real example of "Issue only" (e.g. issue #19 / the Brewfile PR) and one example of "Issue +
  `specs/` feature" (e.g. `specs/copilot-agent-issue-board`) — for when a GitHub Issue should be
  promoted into a `specs/` feature versus handled as a direct change.
- **FR-005**: The documentation MUST clarify that a `spec.md` "User Story" (P1/P2/P3) section
  describes a prioritized user journey within a single Spec Kit feature, and is not itself a
  backlog item, to prevent the terminology collision described in User Story 3.
- **FR-006**: The documentation MUST describe the lifecycle/closure convention: closing a GitHub
  Issue remains a human-only action; a `specs/<feature>/` and its originating Issue are linked via
  `tools/gh-agent-board/scripts/link-artifacts.sh`, and their open/closed or in-progress/done state
  is tracked independently.
- **FR-007**: The documentation MUST live at `docs/process/` and be linked from
  `docs/process/README.md`.

### Key Entities

- **GitHub Issue**: The product-level backlog/planning artifact tracked on GitHub for
  `jackmurphyslalom/yugastore-java`; may exist standalone (small changes) or linked to a
  `specs/<feature>/` (larger changes).
- **Spec Kit Feature (`specs/<feature>/`)**: The local delivery artifact set (`spec.md`,
  `plan.md`, `tasks.md`, optional `context/`) produced by the Spec Kit workflow for one unit of
  implementation work; may be linked back to an originating GitHub Issue.
- **User Story (`spec.md` section)**: A prioritized (P1/P2/P3) user journey documented *inside* a
  single `spec.md`; distinct from, and not a substitute for, a GitHub Issue.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A contributor reading the new documentation correctly classifies all 3 example
  scenarios in User Story 1 (small direct fix, multi-story feature, ambiguous case) into
  "Issue only" vs. "Issue + `specs/` feature".
- **SC-002**: The documentation states, without contradiction, which artifact is authoritative for
  all 6 delivery stages listed in FR-003.
- **SC-003**: The documentation is discoverable within one click from both `docs/README.md` and
  `docs/process/README.md`.

## Assumptions

- GitHub Issues in `jackmurphyslalom/yugastore-java` (using the existing "Rabbit Mode" project
  board and `tools/gh-agent-board` tooling) are the sole product-level backlog artifact; no
  separate ticketing system is in use.
- This is a documentation-only feature: no application code, build scripts, or `gh-agent-board`
  automation changes are required to satisfy it.
- `specs/copilot-agent-issue-board` (which already links its originating Issue to
  spec/plan/tasks via `link-artifacts.sh`) is the reference example for the "promoted" path and
  must not be contradicted by the new documentation.
- Adding new terms to `docs/product/glossary.md` (e.g. distinguishing "GitHub Issue" from
  "Spec Kit feature spec" from "spec.md User Story") is left as a follow-up recommendation for
  `/speckit.aisdlc.promote` rather than a hard requirement of this feature, since Constitution
  Principle III governs canonical terminology separately.
