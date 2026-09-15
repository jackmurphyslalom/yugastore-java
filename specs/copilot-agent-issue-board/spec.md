# Feature Specification: Copilot Agent Issue Board

**Feature Branch**: `copilot-agent-issue-board`

**Created**: 2026-09-14

**Status**: Draft

**Input**: User description: "We want a simple, idiomatic approach to managing bodies of work programmatically on GitHub, so that Copilot coding agents can interact with and create project artifacts. Agents get full read/write access to a GitHub Projects (v2) board (with custom fields such as status and priority) backed by standard repo Issues, and can open PRs linked to issues. Agents interact with GitHub primarily via the GitHub CLI (`gh`). Agents manage the full range of Spec Kit artifacts (issues, specs/plans/tasks, PRs, checklists, ADRs, milestones) with Projects v2 as the tracking layer. Agents write freely without per-write human approval, but every agent-driven action must be logged in a durable, auditable trail (what changed, when, and by which agent/session)."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Agent files and tracks a new body of work (Priority: P1)

A Copilot coding agent, working through a feature from intake to delivery, needs to represent that body of work on GitHub as a trackable, visible unit: an Issue linked into the project board, positioned in the right status column, tagged with the right priority, and associated with the repo-local Spec Kit artifacts (spec, plan, tasks) that describe it in detail.

**Why this priority**: Without this, agents have no way to make their work visible or trackable to humans on the board; this is the foundational capability every other scenario depends on.

**Independent Test**: An agent can create a new Issue for a feature, add it to the project board, set its Status and Priority fields, and link it to the feature's `specs/{feature}/` artifacts — all without a human performing any manual board or issue setup step first.

**Acceptance Scenarios**:

1. **Given** an agent has identified a new body of work, **When** it creates a GitHub Issue describing that work, **Then** the Issue is automatically (or via a single agent-issued command) added as an item on the project board.
2. **Given** an Issue has been added to the board, **When** the agent sets the Status and Priority custom fields, **Then** the board reflects those field values immediately and they are readable by any subsequent `gh` query.
3. **Given** a feature has repo-local Spec Kit artifacts (`specs/{feature}/spec.md`, `plan.md`, `tasks.md`), **When** the agent creates or updates the linked Issue, **Then** the Issue body or comments reference those artifact paths so a human or agent can navigate from the Issue to the underlying documents.

---

### User Story 2 - Agent advances work through its lifecycle (Priority: P1)

As an agent completes stages of work, it needs to move the corresponding board item through status transitions (e.g., Todo -> In Progress -> In Review -> Done) and update priority as circumstances change, all without waiting on a human to make the same update manually. Closing the Issue is a separate, human decision, not an agent action; an agent may reopen an Issue it is resuming work on.

**Why this priority**: Board state must reflect real progress for the board to be useful for tracking; this is the core "operate the board" capability distinct from initial creation.

**Independent Test**: An agent can move a single existing board item across at least three distinct status values, with the board's final state matching the agent's last update, verifiable via `gh project item-list` or equivalent. A separate test confirms no agent script can close an Issue.

**Acceptance Scenarios**:

1. **Given** an Issue tracked on the board with Status "Todo", **When** the agent begins working on it, **Then** the agent updates Status to "In Progress" using `gh`.
2. **Given** an Issue with Status "In Progress" whose work is complete, **When** the agent finishes, **Then** the agent updates Status to "In Review" or "Done"; the Issue itself remains open until a human closes it.
3. **Given** new information changes urgency, **When** the agent re-evaluates a tracked item, **Then** the agent updates the Priority field and the change is visible on the board without any other field being unintentionally reset.
4. **Given** an Issue a human previously closed, **When** an agent resumes work on it, **Then** the agent may reopen the Issue using `gh`.

---

### User Story 3 - Agent opens a linked pull request (Priority: P1)

An agent that has implemented the tasks for a feature needs to open a pull request that is linked to the originating Issue, so that merging the PR (or referencing it) closes or updates the Issue and the board item automatically reflects the PR's existence and state.

**Why this priority**: PR creation is explicitly in scope (not read-only triage) and is the mechanism by which tracked work actually ships; without it agents can only describe work, not deliver it.

**Independent Test**: An agent can open a PR via `gh pr create` that references a specific Issue number using a closing keyword (e.g., "Closes #123"), and the Issue/board item shows the linked PR.

**Acceptance Scenarios**:

1. **Given** an Issue representing completed implementation work, **When** the agent opens a PR referencing that Issue with a closing keyword, **Then** GitHub links the PR to the Issue and the project board shows the association.
2. **Given** a linked PR is merged, **When** the merge completes, **Then** the linked Issue is closed and its board Status reflects a completed/done state.
3. **Given** an agent needs reviewer context, **When** it opens the PR, **Then** the PR description includes a summary of the change and references the relevant spec/plan/tasks artifacts.

---

### User Story 4 - Human reviews the audit trail of agent activity (Priority: P2)

A human maintainer, at any time after the fact, needs to review what agent-driven changes were made to Issues, the project board, and PRs — including which agent or session performed each action and when — without having had to approve each write beforehand.

**Why this priority**: Governance requires retrospective accountability since writes are not gated by per-action human approval; this scenario is what makes unattended agent write access acceptable to maintainers.

**Independent Test**: A human can, for any agent-created or agent-modified Issue/board item/PR within a given time range, retrieve a durable record showing the action taken, its timestamp, and the identifying agent or session, without relying solely on GitHub's own UI activity feed.

**Acceptance Scenarios**:

1. **Given** an agent creates an Issue, updates a board field, or opens a PR, **When** the action completes, **Then** an audit log entry is durably recorded capturing the action type, target artifact, timestamp, and originating agent/session identity.
2. **Given** a human wants to review recent agent activity, **When** they consult the audit trail, **Then** they can reconstruct a chronological sequence of agent-driven changes across Issues, board fields, and PRs.
3. **Given** an audit log entry references an agent/session, **When** a human inspects it, **Then** they can distinguish which distinct agent run or session performed the action (not just "an agent did something").

---

### User Story 5 - Agent manages the broader artifact taxonomy (Priority: P3)

Beyond Issues and PRs, an agent needs to create and reference the other artifact types used by this repo's Spec Kit workflow — checklists, ADRs, and milestones — and represent their existence/status through the same GitHub tracking layer where applicable.

**Why this priority**: This extends coverage to the full artifact taxonomy but is not required for the MVP loop of create -> work -> ship -> audit; it rounds out completeness once the core loop is proven.

**Independent Test**: An agent can associate a milestone with a group of related Issues, and reference a checklist or ADR document from an Issue/PR description, verifiable by inspecting the Issue/PR body and the milestone's issue list.

**Acceptance Scenarios**:

1. **Given** a set of related Issues belong to the same larger effort, **When** the agent organizes them, **Then** it assigns them to a shared GitHub milestone.
2. **Given** a feature requires a pre-completion checklist (`specs/{feature}/checklists/*.md`), **When** the agent finishes implementation, **Then** the linked Issue or PR references the checklist file and its completion state.
3. **Given** a durable architecture decision is made during the work, **When** the agent records it under `docs/architecture/adr/`, **Then** the linked Issue or PR references the ADR file.

---

### Edge Cases

- What happens when an agent tries to add an Issue to the project board but the board's required custom fields (Status, Priority) have not been configured on that board yet?
- How does the system behave when two agents/sessions concurrently update the same board item's field (e.g., both change Status within the same window) — is the last write authoritative, and is the overwritten change still visible in the audit trail?
- What happens when an agent's `gh` invocation partially succeeds (e.g., Issue is created but adding it to the project board fails) — is the audit trail still able to record the partial state, and does the agent retry or surface the inconsistency?
- How does the system handle an agent attempting to open a PR against a protected branch or one requiring reviews it cannot satisfy — is it still allowed to create the PR (unmerged), consistent with "full read/write access... open PRs"?
- What happens when an agent tries to close or edit an Issue/PR it did not originally create (e.g., one created by a human or a different agent)?
- How does the audit trail behave if the `gh` CLI command itself fails or the agent process is interrupted mid-action — is a partial/failed attempt still logged, or only completed actions?
- What happens when an agent needs to reference a repo-local artifact (spec/plan/tasks/ADR/checklist) that does not yet exist at the time the Issue is created?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Agents MUST be able to create a new GitHub Issue representing one Spec Kit feature (one Issue per `specs/{feature}/` directory, not per task) and add it as an item on the repository's GitHub Projects (v2) board using the `gh` CLI.
- **FR-002**: Agents MUST be able to read and write the board's custom fields (at minimum Status and Priority) on any item they create or are authorized to modify, using the `gh` CLI.
- **FR-003**: Agents MUST be able to transition a board item's Status field through the board's defined workflow states (e.g., Todo, In Progress, In Review, Done) as work progresses; setting Status to "Done" MUST NOT itself close the linked Issue — the Status field and the Issue's open/closed state are independent.
- **FR-004**: Agents MUST be able to reopen an Issue via the `gh` CLI. Agents MUST NOT close Issues — closing an Issue is a human-only action performed outside this tooling.
- **FR-005**: Agents MUST be able to open a pull request via the `gh` CLI that references and links to an originating Issue (e.g., via a closing keyword), so that the Issue and board item reflect the PR's existence and eventual merge/close state.
- **FR-006**: Agents MUST be able to associate an Issue or PR with the repo-local Spec Kit artifacts that describe the underlying work, at minimum `specs/{feature}/spec.md`, `plan.md`, and `tasks.md`, by referencing their paths in the Issue/PR body or comments.
- **FR-007**: Agents MUST be able to associate related Issues with a shared GitHub milestone.
- **FR-008**: Agents MUST be able to reference checklist files (`specs/{feature}/checklists/*.md`) and ADR files (`docs/architecture/adr/`) from an Issue or PR body when those artifacts exist for the work being tracked.
- **FR-009**: The system MUST NOT require a human approval step before an agent's write action (Issue create/edit/reopen, board field update, PR create) is committed to GitHub — writes happen immediately upon agent invocation.
- **FR-010**: The system MUST durably record an audit log entry for every agent-driven write action (Issue create/edit/reopen, board item add/field update, PR create), capturing at minimum: the action type, the target artifact (Issue/item/PR identifier), a timestamp, and the identity of the agent or session that performed it.
- **FR-011**: The audit trail MUST be reviewable by a human after the fact, independent of whether GitHub's own native activity/timeline view is used, so that agent activity remains reconstructable even if that native view is incomplete or hard to query in bulk.
- **FR-012**: The system MUST distinguish, within the audit trail, between actions performed by different agents or different sessions of the same agent, not merely attribute all agent activity to one generic identity.
- **FR-013**: Agents MUST interact with GitHub Issues, Projects v2, and PRs primarily through the GitHub CLI (`gh`), not through raw REST/GraphQL calls, GitHub Actions, or webhook-driven automation.
- **FR-014**: The board's custom fields (Status, Priority, and any others in scope) MUST be backed by standard repository Issues linked into the Projects (v2) board, not by project-only "draft" items disconnected from a real Issue.

- **FR-015**: Agents MUST authenticate to GitHub for write actions using a single shared bot/service account; per-action attribution to a specific agent or session MUST be captured in the audit log entry's metadata rather than via distinct GitHub identities.
- **FR-016**: The Status and Priority custom fields MUST support the following set of allowed values: Status = {Todo, In Progress, In Review, Done}; Priority = {P0, P1, P2, P3}.
- **FR-017**: Audit log entries MUST be retained indefinitely in a repo-tracked log file (versioned alongside the codebase), rather than in an external log store.
- **FR-018**: A "session" for audit attribution MUST mean one continuous agent run; all write actions performed by that run MUST share one `session_id`, not a fresh identifier per script invocation.

### Key Entities *(include if feature involves data)*

- **Issue**: A standard GitHub repository Issue representing a discrete unit of trackable work; has a title, body, labels, milestone, open/closed state, and is the anchor that a Projects v2 item wraps.
- **Project Item**: The Projects (v2) board's wrapper around a linked Issue (or PR); carries the board's custom field values and board-position/grouping state distinct from the Issue itself.
- **Status Field**: A custom single-select field on the Project Item representing the item's current workflow stage (e.g., Todo, In Progress, In Review, Done).
- **Priority Field**: A custom single-select field on the Project Item representing the relative urgency/importance of the tracked work.
- **Pull Request**: A GitHub PR opened by an agent, linked to one or more Issues via closing keywords or manual reference, representing the delivered change for tracked work.
- **Milestone**: A GitHub milestone grouping related Issues (and their linked Project Items) toward a common delivery target.
- **Linked Artifact**: A repo-local document (spec, plan, tasks, checklist, or ADR file path) referenced from an Issue or PR body/comments, connecting the GitHub tracking layer to the underlying Spec Kit documentation.
- **Audit Log Entry**: A durable record of one agent-driven write action, capturing action type, target artifact identifier, timestamp, and originating agent/session identity, independent of GitHub's native activity feed.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: An agent can take a new body of work from "described in a Spec Kit spec" to "visible, correctly-fielded Issue on the project board" using only `gh` CLI commands, with zero manual board setup steps by a human.
- **SC-002**: 100% of agent-driven writes to Issues, board fields, and PRs during a review period have a corresponding audit log entry that a human can retrieve without inspecting GitHub's native UI activity feed.
- **SC-003**: A human reviewing the audit trail for any given day can identify which agent/session performed each recorded action with no ambiguity.
- **SC-004**: Agents can move a tracked item from creation through to a merged, linked PR and closed Issue without requiring a human to perform any of the intermediate status, field, or linking updates by hand.
- **SC-005**: A human can locate the repo-local spec/plan/tasks (and, when applicable, checklist/ADR) artifacts for any board item within one navigation step from the Issue or PR.

## Assumptions

- The repository already has (or will have, as a prerequisite outside this spec's scope) a GitHub Projects (v2) board provisioned with at least a Status and a Priority custom field; this spec covers agent interaction with that board, not its initial provisioning.
- Agents run with `gh` CLI already authenticated with sufficient repository and project permissions to create/edit Issues, edit project item fields, and open PRs; credential provisioning/rotation is outside this spec's scope.
- "Durable" audit trail means the record survives beyond a single agent session and beyond GitHub's own activity retention/UI limits, but the specific storage mechanism is left to the implementation plan.
- Full read/write access means agents are trusted to act without per-write human approval, but branch protection rules (e.g., required reviews to merge) remain governed by existing repository settings and are not overridden by this feature.
- Existing Spec Kit artifact conventions (`specs/{feature}/spec.md`, `plan.md`, `tasks.md`, `checklists/`, `docs/architecture/adr/`) continue to be the source of truth for detailed work content; GitHub Issues/Projects v2 serve as the tracking/visibility layer on top of them, not a replacement.
