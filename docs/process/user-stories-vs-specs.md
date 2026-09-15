# GitHub Issues vs. Spec Kit Feature Specs

This page defines the boundary between GitHub Issues and Spec Kit `specs/<feature>/` artifacts,
so it's clear which one is authoritative at each stage of delivery. See
[specs/001-user-story-spec-boundary/spec.md](../../specs/001-user-story-spec-boundary/spec.md)
for the full spec behind this page.

## The two artifacts

- **GitHub Issue** — the product-level backlog/planning artifact, tracked on GitHub for
  `jackmurphyslalom/yugastore-java` (the project board plus the `tools/gh-agent-board` tooling).
  An Issue may exist standalone, or reference a `specs/<feature>/` once one is created.
- **Spec Kit Feature (`specs/<feature>/`)** — the local, per-feature delivery artifact set
  produced by the Spec Kit workflow: `spec.md`, `plan.md`, `tasks.md`, and an optional
  `context/`. A feature may reference the GitHub Issue it originated from.

**Worked examples**:

- **Issue only**: [issue #19](https://github.com/jackmurphyslalom/yugastore-java/issues/19) (the
  Brewfile for local dev setup) was resolved directly by
  [PR #38](https://github.com/jackmurphyslalom/yugastore-java/pull/38) — no `specs/<feature>/`
  was created, and none was needed.
- **Issue + `specs/` feature**: `specs/copilot-agent-issue-board/` is a full Spec Kit feature
  (`spec.md`/`plan.md`/`tasks.md`) whose originating Issue is linked to it via
  `tools/gh-agent-board/scripts/link-artifacts.sh`.

## When to promote an Issue into a `specs/` feature

Promote a GitHub Issue into a `specs/<feature>/` Spec Kit feature as soon as **any one** of these
is true. If none are true, resolve the Issue directly (a PR, with no `specs/` feature required):

- It decomposes into **2 or more independently testable user journeys** (candidate `spec.md`
  "User Story" sections — see the terminology note below).
- It **touches more than one microservice or module** in this repo.
- It needs a `plan.md`/`tasks.md` breakdown before implementation can start safely.

Applying this rule to the worked examples above: issue #19 was a single-file, single-service
change with no distinct user journeys — Issue only. The `copilot-agent-issue-board` work spanned
multiple scripts and multiple independently testable capabilities (create, set-field, link,
reopen, etc.) — Issue + `specs/` feature.

## Which artifact is authoritative, by stage

| Stage | Authoritative artifact |
|-------|------------------------|
| Intake / backlog (before any spec exists) | The GitHub Issue |
| `/speckit.specify` (spec.md created) | `spec.md` — update or link the Issue to match, not the reverse |
| `/speckit.plan` | `plan.md`, scoped by the current `spec.md` |
| `/speckit.tasks` | `tasks.md`, scoped by the current `plan.md` |
| `/speckit.implement` | `tasks.md` (task completion state) plus the code/docs it produces |
| Done / closed | Both are updated, but independently: see [Lifecycle and closure](#lifecycle-and-closure) below |

If a GitHub Issue's description and a linked `spec.md` ever disagree, `spec.md` wins once it
exists — update the Issue (or link it) to match, rather than reinterpreting the spec from the
Issue text.

## Terminology note: `spec.md` "User Story" section vs. GitHub Issue

The Spec Kit `spec.md` template uses `### User Story N - ... (Priority: Px)` as a section
heading. **This is not a GitHub Issue.** A `spec.md` "User Story" section is a prioritized user
journey documented *inside* one Spec Kit feature — it is always a subsection of a single
`spec.md`, never a standalone backlog item. A GitHub Issue, by contrast, is the product-level
backlog artifact described above. Don't treat a `spec.md` User Story section as something that
needs its own Issue, and don't treat a GitHub Issue as a substitute for writing out `spec.md`'s
User Story sections once a feature is promoted.

## Lifecycle and closure

- Closing a GitHub Issue remains a **human-only** action — there is no `close-issue.sh` script in
  `tools/gh-agent-board` (see `tools/gh-agent-board/README.md`).
- A `specs/<feature>/` and its originating Issue are linked via
  `tools/gh-agent-board/scripts/link-artifacts.sh`, not by convention alone.
- The Issue's open/closed state and the `specs/<feature>/` completion state (e.g. all `tasks.md`
  items done) are tracked **independently** — finishing implementation does not auto-close the
  Issue, and closing the Issue does not imply every task is complete.
