# Implementation Plan: Copilot Agent Issue Board

**Branch**: `copilot-agent-issue-board` | **Date**: 2026-09-14 | **Spec**: [specs/copilot-agent-issue-board/spec.md](spec.md)

**Input**: Feature specification from `/specs/copilot-agent-issue-board/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command; its definition describes the execution workflow.

## Summary

Provide a small set of `gh`-CLI-wrapping scripts (plus shared libraries) that let Copilot agents create/track Issues on a GitHub Projects (v2) board, drive Status/Priority fields through a fixed workflow, open linked PRs, associate repo-local Spec Kit artifacts (spec/plan/tasks/checklists/ADRs) and milestones, and — on every write — append a durable, attributable entry to a repo-tracked JSONL audit log. All writes happen immediately (no human approval gate); the audit log is the sole reviewability mechanism, since agents share one bot/service account.

## Technical Context

**Language/Version**: Bash (bash 3.2+ compatible, matching this repo's existing `.specify/scripts/bash/*` convention)

**Primary Dependencies**: GitHub CLI (`gh` v2.x, with the `gh project` subcommand and `read:project`/`project` scopes already granted to the shared bot account), `jq` for JSON parsing/construction

**Storage**: Repo-tracked, append-only JSONL audit log file (`docs/context/audit/agent-actions.jsonl`); no database or external log store

**Testing**: `bats-core` (Bash Automated Testing System) with a stubbed `gh` executable on `PATH` so scripts are tested without hitting the real GitHub API

**Target Platform**: Local/CI shells (macOS + Linux) where Copilot agents run and `gh` is pre-authenticated as the shared bot account

**Project Type**: CLI tooling (single project — a small scripts/lib tree, no frontend/backend split)

**Performance Goals**: N/A beyond single-item operations completing within a few seconds, bounded by GitHub API latency; no throughput target

**Constraints**: Must use the `gh` CLI exclusively for all GitHub interaction (FR-013 — no raw REST/GraphQL, no Actions/webhooks); writes MUST NOT block on human approval (FR-009); every write MUST produce a durable audit entry before the script exits successfully (FR-010, FR-012)

**Scale/Scope**: Single repository (`yugastore-java`), low volume (tens of Issues/PRs per day), a handful of concurrent agent sessions sharing one `gh` identity

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

`.specify/memory/constitution.md` is still the unfilled template (all principle sections contain placeholder tokens) — there are no ratified, project-specific principles to gate against. This plan therefore proceeds with no constitution-derived constraints beyond the spec's own functional requirements. **Gap noted for follow-up**: recommend running `/speckit.constitution` or `/speckit.aisdlc.bootstrap` to ratify real principles (e.g., around credential handling, script testing rigor, or audit-log integrity) so future features in this space have an enforceable baseline. No violations to justify in Complexity Tracking since no gates exist yet.

## Project Structure

### Documentation (this feature)

```text
specs/copilot-agent-issue-board/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command)
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
tools/gh-agent-board/
├── lib/
│   ├── gh-common.sh       # shared gh-invocation wrapper: run + capture exit code/stderr
│   └── audit-log.sh       # append-only JSONL writer for docs/context/audit/agent-actions.jsonl
├── scripts/
│   ├── create-issue.sh    # FR-001: create Issue + add as Projects v2 item
│   ├── set-field.sh       # FR-002/003: set Status or Priority custom field on an item
│   ├── reopen-issue.sh    # FR-004: reopen an Issue (closing is human-only, not scripted)
│   ├── open-pr.sh         # FR-005: open a PR linked to an originating Issue
│   ├── link-artifacts.sh  # FR-006/008: append spec/plan/tasks/checklist/ADR paths to an Issue/PR body
│   └── set-milestone.sh   # FR-007: associate Issues with a shared milestone
├── config/
│   └── board.json         # project number, field names/IDs, allowed Status/Priority values (FR-016)
└── tests/
    ├── fixtures/gh-stub    # fake `gh` executable put on PATH during tests
    └── *.bats              # bats-core tests per script

docs/context/audit/
└── agent-actions.jsonl    # durable, repo-tracked audit trail (FR-010/011/012/017), retained indefinitely
```

**Structure Decision**: Single-project CLI tooling layout under `tools/gh-agent-board/`, kept outside the Java Maven microservice modules since this feature is repo-management tooling, not application code. Each `scripts/*.sh` entry point is a thin, independently invokable command an agent runs directly; `lib/` holds the two cross-cutting concerns (calling `gh` safely, writing audit entries) shared by every script so audit logging can never be skipped. The audit log itself lives under `docs/context/audit/` (repo-tracked, git-versioned, indefinite retention per FR-017) rather than alongside the tool code, so it reads naturally as project-durable context rather than disposable tool output.

## Complexity Tracking

*No constitution gates exist yet (template unfilled — see Constitution Check above), so there are no violations to justify here.*
