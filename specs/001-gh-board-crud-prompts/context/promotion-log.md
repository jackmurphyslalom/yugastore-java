# Promotion Log: 001-gh-board-crud-prompts

## 2026-09-15 — /speckit.aisdlc.promote run

### 1. Glossary terms: "Ticket", "Owner"/"Assignee"

- **Status**: verified
- **Signal**: product terminology — Constitution Principle III (Canonical Terminology) flagged in
  `plan.md`'s Constitution Check as new durable terms not yet in `docs/product/glossary.md`.
- **Target**: `docs/product/glossary.md`
- **Rationale**: Both terms are defined and used consistently across `spec.md` (Key Entities,
  FR-004) and the implementing scripts; confirmed 2026-09-15 per spec.md, not a guess.
- **Evidence**: `specs/001-gh-board-crud-prompts/spec.md` (Key Entities, FR-004), `plan.md`
  (Constitution Check, Principle III).
- **Confidence**: high
- **Action taken**: added both rows to `docs/product/glossary.md`; updated
  `docs/context/index.yaml`'s `product-glossary` entry.

### 2. Shared ticket-resolution + script-reuse pattern and new `change_owner` audit action

- **Status**: verified
- **Signal**: new engineering pattern (shared `lib/board-item.sh` resolver, reuse of
  `set-field.sh` from new wrapper scripts) plus a schema/contract change (new `change_owner` audit
  action value extending `specs/copilot-agent-issue-board/data-model.md`'s audit vocabulary).
- **Target**: `docs/decisions/2026-09-15-gh-agent-board-crud-prompts.md` (new)
- **Rationale**: Narrower than a full ADR, but durable enough that future gh-agent-board scripts
  should follow the same resolve-then-reuse-existing-script approach, and any audit-log consumer
  needs to know about the new action value.
- **Evidence**: `specs/001-gh-board-crud-prompts/plan.md`, `research.md`, `contracts/scripts.md`.
- **Confidence**: high
- **Action taken**: created the decision file; added a `decision-2026-09-15-gh-agent-board-crud-prompts`
  entry to `docs/context/index.yaml`.

### 3. "Won't Fix" Status option gap (retire prompt)

- **Status**: no-op
- **Signal**: known limitation already surfaced in spec.md (User Story 5, Scenario 2) and
  `research.md`.
- **Target**: `docs/context/gaps.md` (already has a matching entry: "No `Won't Fix` Status option
  configured for the gh-agent-board Projects (v2) field").
- **Rationale**: Existing gap entry already cites `board.json`, `data-model.md`, and this feature's
  `research.md`, and correctly states the next step (human adds the board option). No edit needed.
- **Evidence**: `docs/context/gaps.md` (existing entry, dated to this feature's `/speckit.plan`
  run).
- **Confidence**: high
- **Action taken**: none (verified current, left as-is).

### 4. `rabbit-gh-board-*.prompt.md` naming

- **Status**: no-op
- **Signal**: reusable naming convention (new prompt files use the `rabbit-` prefix).
- **Target**: repo naming-convention guidance.
- **Rationale**: Already durable, repo-memory-tracked guidance (`rabbit-` prefix for non-framework
  prompts/skills/tools); this feature's prompt files simply follow it correctly. No new doc needed.
- **Evidence**: `specs/001-gh-board-crud-prompts/plan.md` (Project Structure), existing
  `/memories/repo/naming-conventions.md`.
- **Confidence**: high
- **Action taken**: none.

### Routing-map proposals

- None. Both new durable docs (glossary rows, decision file) are already covered by existing
  routing-map rows (`command:speckit.specify`, `command:speckit.constitution`, and the
  compatibility fallback all already read `docs/product/glossary.md`; `docs/decisions/README.md`
  is already a baseline doc for `command:speckit.plan`/`command:speckit.tasks`/etc., and individual
  decision files are discovered via the triggered-expansion "manifest entry directly matches the
  task" rule against `docs/context/index.yaml`). No new row needed.
