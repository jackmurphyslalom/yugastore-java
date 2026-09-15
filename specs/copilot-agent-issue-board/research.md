# Research: Copilot Agent Issue Board

All Technical Context items were resolved directly from the spec's confirmed clarifications and this repo's existing conventions; no items were left as NEEDS CLARIFICATION. This document records the supporting decisions.

## Decision: Wrap `gh` in small, single-purpose Bash scripts (not a Python/Node CLI)

- **Rationale**: The repo already standardizes on Bash for automation (`.specify/scripts/bash/*.sh`), so agents and humans have one scripting convention to learn. `gh` itself is the only required external dependency (`FR-013`); no language runtime is needed to shell out to it, keeping the tool trivially portable to any agent execution environment that already has `gh` installed and authenticated.
- **Alternatives considered**:
  - A Python CLI (e.g., using `PyGithub` or `gh` subprocess calls) — rejected: adds a runtime/dependency-management surface (venv, requirements.txt) for no functional benefit, and this repo has no existing Python tooling convention to extend.
  - Direct GraphQL/REST calls (via `curl` or a typed client) — explicitly excluded by FR-013, which mandates `gh` CLI as the sole interaction surface.

## Decision: GitHub Projects (v2) field updates via `gh project item-edit` / `gh project field-list`

- **Rationale**: `gh project item-edit --id <item-id> --field-id <field-id> --project-id <project-id> --single-select-option-id <option-id>` is the documented, supported path for setting single-select custom fields (Status, Priority) on a Projects v2 item from the CLI. Field and option IDs are looked up once via `gh project field-list <project-number> --owner <owner> --format json` and cached in `tools/gh-agent-board/config/board.json` rather than re-queried on every write, avoiding unnecessary API calls.
- **Alternatives considered**: Driving Projects v2 via raw GraphQL mutations — more flexible but forbidden by FR-013; `gh` covers the field-edit use case natively so no gap exists that would justify the exception.

## Decision: Status = {Todo, In Progress, In Review, Done}; Priority = {P0, P1, P2, P3}

- **Rationale**: Confirmed directly with the requester as the concrete value sets for FR-016. These are stored as the canonical option list in `config/board.json` so `set-field.sh` can validate an agent-supplied value before calling `gh`, failing fast on typos instead of letting `gh` reject an unknown option string deep in a script chain.
- **Alternatives considered**: High/Medium/Low priority levels, or a Backlog-prefixed status workflow — not selected; P0-P3 and the four-stage workflow were the requester's explicit choice.

## Decision: Shared bot/service account identity; per-action attribution via audit log metadata, not distinct GitHub identities

- **Rationale**: Confirmed with the requester for FR-015. `gh` already runs authenticated as one bot account; provisioning/rotating a distinct token per agent/session was explicitly rejected as unnecessary complexity. Instead, every script accepts (or infers, e.g. from an environment variable such as `AGENT_SESSION_ID`) an `agent_id`/`session_id` pair that `lib/audit-log.sh` stamps onto each JSONL entry, satisfying FR-012's "distinguish between agents/sessions" requirement without a GitHub-side identity change.
- **Alternatives considered**: Per-agent GitHub App installation tokens — more precise GitHub-native attribution, but adds credential-provisioning scope explicitly out of bounds per the spec's Assumptions section.

## Decision: Audit log as an append-only JSONL file at `docs/context/audit/agent-actions.jsonl`, retained indefinitely in-repo

- **Rationale**: Confirmed with the requester for FR-017. JSONL (one JSON object per line) is trivially appendable from Bash (`printf '%s\n' "$json" >> "$log_file"`), diff-friendly enough for git history, and greppable/`jq`-queryable without extra tooling. Placing it under `docs/context/audit/` keeps it alongside this repo's other durable AI-SDLC context rather than inside the tool's own directory, signaling it is project-durable output, not disposable script scratch state.
- **Alternatives considered**: An external log store (e.g., shipping to a SaaS logging service or GitHub Actions run logs) — rejected per the requester's explicit choice of repo-tracked, indefinite retention; also avoids adding an external-service dependency to a CLI tool meant to run in arbitrary agent environments.

## Decision: Test with `bats-core` against a stubbed `gh` executable

- **Rationale**: `bats-core` is the de facto standard for testing Bash scripts and is easy to add without a language-runtime dependency. Stubbing `gh` (a fake executable earlier on `PATH` that records the arguments it was called with and returns canned JSON) lets tests assert "script X calls `gh` with exactly these arguments and writes exactly this audit entry" without any real network access or GitHub credentials, keeping tests fast, deterministic, and safe to run in CI.
- **Alternatives considered**: Integration tests against a real (sandbox) GitHub repo — rejected as the default for unit-level coverage due to flakiness, required live credentials, and rate limits; may still be worth a manual/quickstart-level smoke test (see `quickstart.md`), but not as the automated test suite's foundation.
