---
name: "speckit-aisdlc-bootstrap"
description: "Bootstrap durable AI-SDLC context in guided or automated mode."
compatibility: "Requires spec-kit project structure with .specify/ directory"
metadata:
  author: "aisdlc-framework"
  source: ".specify/templates/commands/aisdlc.bootstrap.md"
user-invocable: true
disable-model-invocation: false
argument-hint: "Optional repo area or context gaps to prioritize during bootstrap"
---

When a hook command name contains dots, convert it to the matching skill name by replacing dots with hyphens.
Example: `speckit.aisdlc.preflight` -> `/speckit-aisdlc-preflight`.

## User Input

```text
$ARGUMENTS
```

Consider the user input before proceeding. A one-run `--mode guided|automated` override takes precedence over `.agents/config.yaml` at `context.bootstrap.mode`. Default to `guided` when neither is present. Reject any other value before editing files.

Follow `.specify/extensions/aisdlc-context/references/context-routing.md` and
`.specify/extensions/aisdlc-context/references/context-analyzer.md`. Use the framework-managed
`aisdlc-domain-modeling` skill in both modes and `aisdlc-grilling` in guided mode when available.

## Boundaries

- This command may edit only project context, documentation, `.specify/memory/constitution.md`, and `docs/context/bootstrap-report.md`.
- Never edit application source, tests, build configuration, deployment configuration, or dependencies.
- Stop and report missing evidence instead of fabricating facts.
- `docs/product/glossary.md` is the sole default canonical language source. Preserve an existing project-authored structure.
- Never create `CONTEXT.md`, `CONTEXT-MAP.md`, a parallel glossary hierarchy, or application code.
- Create no ADR unless the guided ADR gates below are all satisfied. Automated mode never creates ADRs.

## Evidence Pass

1. Determine whether this is a single repository or a workspace.
   - For a `context-hub`, treat the hub as owner of durable docs, specs, plans, tasks, and analysis.
   - Read declared repositories from `workspace.yaml`.
   - Treat `reference` repositories as read-only evidence sources.
   - Use `applies_to` repository keys on context-index entries when evidence or guidance is repository-specific.
2. Inspect evidence before asking questions:
   - existing product, architecture, glossary, decision, and operations docs;
   - top-level README files, manifests, lockfiles, CI and test configuration;
   - schemas, contracts, migrations, infrastructure files, and relevant entrypoints.
3. Separate evidence-backed facts from human decisions. Record source paths, confidence (`high`, `medium`, or `low`), and verification date.
4. Ensure these support artifacts exist without overwriting curated content:
   - `docs/product/overview.md`
   - `docs/architecture/overview.md`
   - `docs/product/glossary.md`
   - `docs/context/repo-map.md`
   - `docs/context/index.yaml`
   - `docs/context/gaps.md`
   - `.specify/memory/constitution.md`
   - `docs/context/routing-map.md`
   - `docs/context/bootstrap-report.md`

## Routing Map Refresh

1. Read the existing routing map before changing it. Preserve project-authored rows and comments.
2. For a new map, install the framework's stable command and skill route IDs with exact file
   placeholders. Never use a directory or glob as a baseline.
3. Compare durable documents discovered during the evidence pass with the active route rows.
4. Add or refresh a row only when evidence proves that its exact file should be baseline context for
   the named command or skill. Record the selection reason beside the route ID.
5. When a discovered document may be useful but baseline status is uncertain, put the proposed route
   change in `docs/context/gaps.md` instead of activating it.
6. Preserve an existing user row unless guided-mode explicit confirmation authorizes its replacement.

## Guided Mode

1. Present discoverable facts separately from decisions requiring human judgment.
2. Ask one decision at a time. Include a recommended answer and the material tradeoff.
3. Wait for confirmation before changing authoritative terminology or recording a decision.
4. Split canonical language into multiple indexed files only after an explicit human decision.
5. Create an ADR under `docs/architecture/adr/` only when all three conditions hold:
   - the decision is hard to reverse;
   - it would be surprising without context;
   - a genuine tradeoff produced the selection.
6. Summarize the proposed shared understanding and require explicit final confirmation.
7. Mark context entries `verified` only after that final confirmation. Until then, use `draft`.

## Automated Mode

1. Record only facts directly supported by reviewed evidence.
2. Mark generated or changed context entries `draft`.
3. Put unresolved choices, contradictions, and weak signals in `docs/context/gaps.md`.
4. Never create ADRs, select authoritative domain language silently, or claim shared understanding.
5. Require human review in the completion report. Automated output is a draft, not equivalent to guided authority.

## Context Manifest

Each `docs/context/index.yaml` entry includes `id`, `category`, `path`, `summary`, `source_paths`, `confidence`, `last_verified`, and `status`. Valid statuses are `scaffold-only`, `draft`, `verified`, and `stale`. `applies_to` is optional; absent scope means project-wide.

Every free-text prose field written to `docs/context/index.yaml` must be YAML-safe. Use a block
scalar for `summary` and any other prose field you add, or explicitly quote the value. Prefer this
shape for summaries:

```yaml
  - id: product-overview
    category: product
    path: docs/product/overview.md
    summary: |
      Draft product context inferred from package evidence: preserve public behavior and document
      unresolved decisions separately.
    source_paths:
      - README.md
    confidence: medium
    last_verified: 2026-07-25
    status: draft
```

Do not write unquoted prose scalars such as `summary: Evidence says: preserve behavior`; a colon
followed by a space can make the manifest invalid YAML.

Before reporting success, validate that `docs/context/index.yaml` parses by running `aisdlc status`
from the project root and confirming the output does not contain `Context Manifest: invalid`. If
`aisdlc` is unavailable in a POSIX or WSL shell, load an existing NVM installation and retry once:

```sh
if ! command -v aisdlc >/dev/null 2>&1; then
  if [ -n "${NVM_DIR:-}" ] && [ -s "$NVM_DIR/nvm.sh" ]; then
    . "$NVM_DIR/nvm.sh"
  elif [ -s "$HOME/.nvm/nvm.sh" ]; then
    . "$HOME/.nvm/nvm.sh"
  fi
fi
aisdlc status
```

Do not install tools or modify shell profiles. If `aisdlc` remains unavailable, report `Status: failed`,
state that manifest validation could not run, and provide the applicable remediation command: use
`. ~/.nvm/nvm.sh && aisdlc status` when that loader exists, otherwise install or expose the
AI-SDLC CLI on `PATH`. If the manifest is invalid, fix it and run the check again. If it
still cannot be validated, stop and report `Status: failed`; do not report `completed`.

## Completion Report

Report:

- mode and resulting status;
- evidence reviewed;
- durable docs created or refreshed;
- route IDs created or refreshed, exact files selected, and deferred route proposals;
- manifest and constitution changes;
- manifest validation result;
- glossary changes and confirmations;
- unresolved gaps and highest-risk assumptions;
- ADRs created, or `none`;
- confirmation state;
- explicit human-review requirement for automated mode;
- confirmation that no application code was changed.

## Required Structured Step Report

End the final response with exactly one fenced `aisdlc-step-report` JSON object:

```aisdlc-step-report
{
  "schema_version": 1,
  "status": "pass|blocked|fail",
  "blocker_code": null,
  "attempted_fallbacks": [],
  "external_write": false,
  "summary": "human-readable result"
}
```

Use `null` only for a passing result. For blocked or failed results, use one of:

- `INVALID_COMPARISON_BASE`
- `UNSAFE_CHECKOUT`
- `CONTRACT_CONFLICT`
- `MISSING_SCRIPT`
- `MISSING_TEMPLATE`
- `TOOL_FAILURE`

Invoke only framework scripts declared in this command's frontmatter. Never discover,
download, install, or execute a package to replace a missing framework script.
