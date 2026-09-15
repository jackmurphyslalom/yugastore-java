# Promotion Log: copilot-agent-issue-board

Tracks durable-knowledge promotion candidates identified for this feature. Recommendations here are
proposals only — durable docs under `docs/` are not edited by this log or by `/speckit.aisdlc.promote`
unless explicitly requested in the same run.

## 2026-09-14

### Candidate 1: `gh` CLI wrapper-script pattern

- **Status**: verified
- **Signal**: new engineering pattern / reusable convention
- **Evidence**: `tools/gh-agent-board/lib/gh-common.sh`, `tools/gh-agent-board/lib/audit-log.sh`,
  `tools/gh-agent-board/README.md`, `specs/copilot-agent-issue-board/contracts/scripts.md`; validated
  by 36 passing bats tests (`tools/gh-agent-board/tests/`) and a live smoke test against a real
  GitHub Projects (v2) board (T031 in `tasks.md`).
- **Pattern to capture**:
  - source a shared `lib/gh-common.sh` helper that runs `gh` and captures
    `GH_RUN_STDOUT`/`GH_RUN_STDERR`/`GH_RUN_EXIT_CODE` instead of calling `gh` inline in every script
  - always write exactly one audit-log entry (`lib/audit-log.sh`) before exiting, on both success and
    failure, so every write action is independently reviewable outside the `gh` UI
  - test `gh`-wrapping scripts against a stubbed `gh` executable (`tests/fixtures/gh-stub`) driven by
    an ordered response queue, rather than hitting the real API in unit tests
  - two real `gh` CLI quirks worth documenting as defaults for any future `gh`-wrapping script:
    1. `gh issue create` and `gh pr create` do **not** support `--json` — they print only a
       plain-text URL on success; parse the trailing path segment for the number instead.
    2. `gh project item-add` takes the project **number** plus `--owner` (`@me` for a personal/
       non-org project, the literal org login for an org-owned project) — this differs from
       `gh project item-edit`, which takes `--project-id` (the GraphQL node ID).
- **Suggested target**: new `docs/patterns/gh-cli-wrapper-scripts.md` (Status: Established)
- **Remaining work**: human review and creation of the pattern doc (not applied by this promotion
  pass); add a `docs/context/index.yaml` entry (category `patterns`) once created so existing routing
  rows that already read `docs/patterns/README.md` can discover it via triggered expansion.

### Candidate 2: unfilled project constitution

- **Status**: no-op (already tracked)
- **Signal**: governance gap noticed while reading the authority baseline
  (`.specify/memory/constitution.md` is still the unfilled Spec Kit template)
- **Evidence**: `.specify/memory/constitution.md`; GitHub Issue #18 ("Implement the baseline project
  constitution"), already filed and assigned to `youngc-build`, Status = Backlog
- **Remaining work**: none from this promotion pass — already captured as a backlog item; no
  duplicate action needed.
