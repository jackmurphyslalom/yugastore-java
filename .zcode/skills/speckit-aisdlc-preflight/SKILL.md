---
name: "speckit-aisdlc-preflight"
description: "Build a concise project-specific context and local-freshness briefing before a core phase."
compatibility: "Requires spec-kit project structure with .specify/ directory"
metadata:
  author: "aisdlc-framework"
  source: ".specify/templates/commands/aisdlc.preflight.md"
---

When a hook command name contains dots, convert it to the matching skill name by replacing dots with hyphens.
Example: `speckit.aisdlc.preflight` -> `$speckit-aisdlc-preflight`.

## User Input

```text
$ARGUMENTS
```

Consider the user input before proceeding. Follow
`.specify/extensions/aisdlc-context/references/context-routing.md` and
`.specify/extensions/aisdlc-context/references/context-analyzer.md`.

## Outline

1. Read `.specify/feature.json` when present for `feature_directory` and optional `implementation_repository`.
2. Read `workspace.yaml` when present. Report:
   - workspace profile;
   - missing declared repositories;
   - repository roles;
   - resolved or unresolved implementation target.
3. Resolve a context-hub implementation target in this order:
   - explicit `--target <repo-key>`;
   - feature `implementation_repository`;
   - `workspace.yaml` `execution.default_target`;
   - the sole `implementation` repository;
   - otherwise stop and ask the user.
   Never select a `reference` repository.
4. Inspect local Git state for the hub and relevant repositories:
   - current branch;
   - dirty state;
   - ahead/behind using existing local tracking refs;
   - remote freshness as unknown when local refs cannot prove it.
   Never fetch, pull, switch branches, or mutate refs.
5. Resolve the upcoming command in this order:
   - explicit command input;
   - the invoking lifecycle hook: `before_specify` -> `speckit.specify`, `before_plan` ->
     `speckit.plan`, or `before_implement` -> `speckit.implement`;
   - otherwise ask the user which command this briefing is preparing for instead of guessing.
6. Read `docs/context/routing-map.md` when present and select the upcoming command's exact route ID.
   Read the authority baseline, artifact inputs, baseline docs, and required skills from that row
   before any triggered expansion. Record the selected route ID and why it matches.
7. If the map or matching row is absent, report `route ID: compatibility-fallback` and use only the
   exact-file compatibility baseline below.
8. The compatibility exact-file baseline is:
   - `docs/context/index.yaml` and its verification states;
   - `docs/context/gaps.md`;
   - `.specify/memory/constitution.md`;
   - `docs/product/glossary.md`;
   - `docs/product/overview.md`;
   - `docs/architecture/overview.md`;
   - `docs/context/repo-map.md`;
   - `docs/decisions/README.md`;
   - `docs/patterns/README.md`.
9. Do not read an entire category or feature directory without a concrete trigger.
10. Expand to linked files, directories, globs, feature context, dependencies, ownership, or implementation
   source only when a baseline file or the task supplies a concrete trigger.
11. Record why each file was selected. If required context is missing or stale, inspect the
   smallest current source-of-truth set needed to resolve it. Treat `reference` repositories as
   read-only.
12. Do not edit files.

## Output

Produce exactly:

- `## Routing Decision`
- `## Governing Constraints`
- `## Existing Patterns To Reuse`
- `## Terminology To Preserve`
- `## Relevant Source Paths`
- `## Workspace And Target`
- `## Local Freshness`
- `## Missing Or Stale Context`

Within the relevant sections, distinguish exact baseline files from triggered expansion and pair
every triggered file with its selection reason. In `## Routing Decision`, cite the selected route
ID, the upcoming command, every baseline file and its reason, every omitted missing file, and every
expansion trigger used.

Recommend `$speckit-aisdlc-bootstrap` when the durable scaffold is missing. Describe automated bootstrap as evidence-backed draft generation requiring human review.

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
