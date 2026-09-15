# Implementation Plan: gh-agent-board CRUD, Change-Owner, and Reassign Prompts

**Branch**: `001-gh-board-crud-prompts` | **Date**: 2026-09-15 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/001-gh-board-crud-prompts/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command; its definition describes the execution workflow.

## Summary

Add six new agent-invocable prompt files under `.github/prompts/` (lookup, create, update,
change-owner, reassign, retire) that each accept a ticket (GitHub Issue) number and call a
gh-agent-board script under `tools/gh-agent-board/scripts/`. `create` reuses the existing
`create-issue.sh` unchanged. The other five prompts are backed by four new/extended pieces of
tooling: a shared `lib/board-item.sh` helper that resolves a ticket number to its Projects v2 item
(and current Status/Priority/assignees, or a clear not-found result); a new read-only
`view-ticket.sh`; a new `update-ticket.sh` and `retire-ticket.sh` that resolve the item id and then
invoke the existing `set-field.sh` (reuse, no duplicated field-validation/audit logic); and a new
`change-owner.sh` shared by both the change-owner and reassign prompts. Every new write path keeps
the existing `--agent-id`/`--session-id`/audit-log contract; the read-only lookup path writes no
audit entry, consistent with the existing "write action" audit contract.

## Technical Context

**Language/Version**: Bash (bash 3.2+ compatible), matching `tools/gh-agent-board`'s existing
scripts and this repo's `.specify/scripts/bash/*` convention.

**Primary Dependencies**: GitHub CLI (`gh` v2.x, `gh project`/`gh issue` subcommands, already
authenticated as the shared bot account per `specs/copilot-agent-issue-board/`), `jq`.

**Storage**: Same repo-tracked, append-only JSONL audit log (`docs/context/audit/agent-actions.jsonl`)
used by the existing gh-agent-board scripts; no new storage.

**Testing**: `bats-core`, following the existing stubbed-`gh`-on-`PATH` pattern in
`tools/gh-agent-board/tests/` (`tests/fixtures/gh-stub`, `tests/helpers.bash`).

**Target Platform**: Local/CI shells (macOS + Linux) where Copilot agents run and `gh` is
pre-authenticated, same as the existing tooling.

**Project Type**: CLI tooling extension (single project — new scripts/lib additions to the
existing `tools/gh-agent-board/` tree) plus new prompt files under `.github/prompts/`; no
application (microservice) code is touched.

**Performance Goals**: N/A beyond single-ticket operations completing within a few seconds,
bounded by GitHub API latency — same as the existing scripts.

**Constraints**: MUST use only the `gh` CLI (FR-007, carried over from FR-013 of
`specs/copilot-agent-issue-board/spec.md`); MUST validate the ticket number exists before any
board/Issue mutation (FR-006); MUST NOT call `gh issue close` (FR-009); every write MUST append one
audit entry before exit, reusing the existing `lib/audit-log.sh` contract (FR-008).

**Scale/Scope**: Same single repository (`yugastore-java`), low volume, shared bot `gh` identity —
unchanged from the existing gh-agent-board tooling's scale.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. Gateway-Only Service Boundary**: Not applicable. This feature adds repo-management CLI
  tooling and agent prompts; it does not touch `api-gateway-microservice` or any other
  microservice, and introduces no service-to-service calls. PASS.
- **II. Consistency-Sensitive Data Paths**: Not applicable. No YCQL/YSQL writes, no
  `cronos.orders`/`cronos.product_inventory` interaction. PASS.
- **III. Canonical Terminology**: The spec's "Ticket" (= GitHub Issue tracked on the board) and
  "Owner"/"Assignee" (synonyms) are new durable terms not yet in `docs/product/glossary.md`.
  Per this principle they MUST be added rather than left as unwritten team knowledge. **Action**:
  flag both terms for `/speckit.aisdlc.promote` after implementation, since glossary edits are
  documentation-only and not a design gate. Not a blocking violation.
- **IV. Context-Grounded Change**: This plan cites concrete evidence — the spec, this repo's
  existing `specs/copilot-agent-issue-board/contracts/scripts.md`, `tools/gh-agent-board/config/board.json`,
  and the existing script/lib source. One new unresolved question was found (the "won't-fix" retire
  outcome has no matching configured Status option) and is recorded in `docs/context/gaps.md`
  rather than guessed (see Research decision below). PASS.
- **V. Incremental Test Hardening**: Every new script ships with `bats-core` tests exercising its
  actual behavior (successful path, not-found path, `gh` failure path), following the existing
  `tests/*.bats` pattern — not smoke-test-only coverage. PASS.

No principle is violated; no entries are required in Complexity Tracking.

## Project Structure

### Documentation (this feature)

```text
specs/001-gh-board-crud-prompts/
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
│   ├── gh-common.sh        # existing: shared gh-invocation wrapper (reused, unchanged)
│   ├── audit-log.sh        # existing: append-only JSONL writer (reused, unchanged)
│   └── board-item.sh        # NEW: resolves a ticket/Issue number to its Projects v2 item id +
│                             #      current Status/Priority/assignees, or a not-found result
├── scripts/
│   ├── create-issue.sh      # existing: reused as-is by the new "create" prompt (FR-001)
│   ├── set-field.sh         # existing: reused (not modified) by update-ticket.sh/retire-ticket.sh
│   ├── view-ticket.sh       # NEW: read-only lookup (FR-002) — no audit entry (not a write)
│   ├── update-ticket.sh     # NEW: resolves item id, then calls set-field.sh (FR-003)
│   ├── change-owner.sh      # NEW: shared by change-owner and reassign prompts (FR-004/FR-005)
│   └── retire-ticket.sh     # NEW: resolves item id, maps outcome->Status, calls set-field.sh (FR-009)
├── config/
│   └── board.json           # existing: unchanged by this feature (see research.md gap re: "won't-fix")
└── tests/
    ├── board-item.bats       # NEW
    ├── view-ticket.bats      # NEW
    ├── update-ticket.bats    # NEW
    ├── change-owner.bats     # NEW
    └── retire-ticket.bats    # NEW

.github/prompts/
├── rabbit-gh-board-view.prompt.md          # NEW: FR-002 lookup
├── rabbit-gh-board-create.prompt.md        # NEW: FR-001 create (calls existing create-issue.sh)
├── rabbit-gh-board-update.prompt.md        # NEW: FR-003 update Status/Priority
├── rabbit-gh-board-change-owner.prompt.md  # NEW: FR-004 change owner
├── rabbit-gh-board-reassign.prompt.md      # NEW: FR-005 reassign (same script as change-owner)
└── rabbit-gh-board-retire.prompt.md        # NEW: FR-009 retire (done | won't-fix)

docs/context/audit/agent-actions.jsonl   # existing: gains one new action value, "change_owner"
```

**Structure Decision**: Extend the existing `tools/gh-agent-board/` CLI tooling tree in place
rather than starting a second tool tree, since this feature is additional operations on the same
Issues/Projects-v2 board the existing scripts already manage, and must keep sharing the same
`lib/gh-common.sh` (gh invocation) and `lib/audit-log.sh` (audit contract) so the audit trail stays
uniform across all gh-agent-board actions. New prompt files go under `.github/prompts/` alongside
the existing `speckit.*.prompt.md` files (this repo's established agent-prompt location), using a
`rabbit-gh-board-*` naming prefix to distinguish this suite from the Spec Kit workflow prompts without
introducing a new prompts directory.

## Complexity Tracking

*No constitution gates were violated (see Constitution Check above); no entries required here.*
