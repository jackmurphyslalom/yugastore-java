# Bootstrap Repository Context

Create or refresh durable project context without implementing application code.

## Mode

Use a one-run `--mode guided|automated` override when supplied; otherwise read `.agents/config.yaml` `context.bootstrap.mode`. Default to `guided`.

- `guided` is recommended and produces verified context only after explicit final confirmation.
- `automated` generates an evidence-backed draft requiring human review.

Use `.agents/skills/aisdlc-domain-modeling/SKILL.md` in both modes and `.agents/skills/aisdlc-grilling/SKILL.md` in guided mode.

## Evidence first

Inspect existing docs, README files, manifests, tests, CI configuration, schemas, contracts, migrations, infrastructure files, and relevant entrypoints. For a context hub, read `workspace.yaml`; treat `reference` repositories as read-only evidence sources and keep durable artifacts in the hub.

Separate evidence-backed facts from human decisions. Track source paths, confidence, and verification dates. Stop instead of inventing facts.

Derive repository test conventions from source evidence rather than generic
ecosystem defaults:

- inspect the test tree to record exact test-file naming and placement patterns;
- inspect manifests and CI to record targeted, CI, and full test commands as an
  explicit hierarchy;
- identify the broadest suite and state which additional checks it includes
  beyond narrower commands (for example type, browser, integration, coverage,
  mutation, or race checks).

## Artifact rules

- Create or refresh `docs/product/overview.md`, `docs/architecture/overview.md`, `docs/context/repo-map.md`, `docs/context/routing-map.md`, `.specify/memory/constitution.md`, and `docs/context/bootstrap-report.md`.
- Record the evidenced test naming/placement conventions and test-command
  hierarchy in `docs/architecture/overview.md`, with source paths. Summarize the
  relevant test locations and commands in `docs/context/repo-map.md`.
- Use `docs/product/glossary.md` as the sole default canonical language source.
- Preserve an existing project-authored glossary structure.
- Use `docs/context/index.yaml` with statuses `scaffold-only`, `draft`, `verified`, and `stale`.
- In `docs/context/index.yaml`, write `summary` and any other free-text prose field as a block
  scalar or an explicitly quoted string. Prefer:
  `summary: |` followed by indented prose. Never write unquoted prose like
  `summary: Evidence says: preserve behavior`, because `: ` can make YAML invalid.
- Add optional `applies_to` repository keys only for context-hub routing; absent scope is project-wide.
- Put unresolved choices in `docs/context/gaps.md`.
- Never create `CONTEXT.md`, `CONTEXT-MAP.md`, or a parallel glossary hierarchy.
- Edit only context, documentation, `.specify/memory/constitution.md`, and `docs/context/bootstrap-report.md`.
- Never edit application source, tests, build or deployment configuration, or dependencies.

## Routing map refresh

Read the existing routing map before changing it and preserve project-authored rows. A fresh map uses
stable command and skill route IDs with exact file baselines. Compare durable documents discovered
during bootstrap with those rows; add or refresh a row only when evidence proves the exact file
belongs in that command or skill baseline. Record the selection reason beside the route ID. Put
uncertain proposals in `docs/context/gaps.md`, and require guided-mode explicit confirmation before
replacing a user-authored row.

## Guided mode

After inspecting evidence, distinguish facts from decisions. Ask one decision at a time with a recommended answer and material tradeoff. Wait for confirmation before changing authoritative terminology. Require final shared-understanding confirmation before marking newly bootstrapped context `verified`.

Create an ADR only after human confirmation and only when the decision is hard to reverse, surprising without context, and selected through a genuine tradeoff.

## Automated mode

Record only evidence-backed facts. Mark generated context `draft`, record unresolved choices in `docs/context/gaps.md`, create no ADRs, and make no silent authoritative domain decisions. The completion report must require human review.

## Completion report

Report the mode, status, evidence reviewed, artifacts changed, route IDs and exact files refreshed,
deferred route proposals, glossary confirmations, gaps, ADRs or `none`, final confirmation state,
review requirement, manifest validation result, and confirmation that no application code changed.
Before reporting success, run `aisdlc status` from the project root and confirm it does not report
`Context Manifest: invalid`. If `aisdlc` is unavailable in a POSIX or WSL shell, load an existing
NVM installation and retry once before treating validation as failed:

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
AI-SDLC CLI on `PATH`. If the manifest is invalid, fix it and rerun validation; otherwise stop with
`Status: failed` instead of claiming completion.
