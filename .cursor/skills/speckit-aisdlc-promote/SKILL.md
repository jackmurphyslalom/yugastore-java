---
name: "speckit-aisdlc-promote"
description: "Capture durable learning and recommend what should be promoted into project docs."
compatibility: "Requires spec-kit project structure with .specify/ directory"
metadata:
  author: "aisdlc-framework"
  source: ".specify/templates/commands/aisdlc.promote.md"
---

When a hook command name contains dots, convert it to the matching skill name by replacing dots with hyphens.
Example: `speckit.aisdlc.preflight` -> `/speckit-aisdlc-preflight`.

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Shared Contract

Follow `.specify/extensions/aisdlc-context/references/context-routing.md` and
`.specify/extensions/aisdlc-context/references/context-analyzer.md` when they are available in the
target project. Select `command:speckit.aisdlc.promote`; if the row is unavailable, use and report
the exact-file compatibility fallback.

## Outline

1. Determine the active feature context.
   - Read `.specify/feature.json` when present to locate the current feature directory.
   - If a feature directory is available, use `FEATURE_DIR/context/` and `FEATURE_DIR/context/promotion-log.md`.

2. Ensure feature-scoped promotion tracking exists.
   - Create `FEATURE_DIR/context/` if missing.
   - Create `FEATURE_DIR/context/promotion-log.md` if missing.
   - Create `FEATURE_DIR/context/scratch/` only when temporary working files are needed.

3. Review the current evidence set.
   - Read the selected route's authority baseline, exact feature artifacts, and exact baseline docs.
   - Use the current diff as the trigger for source inspection and enumerate the exact changed files
     consulted.
   - Add another durable document only when a routing-map trigger applies; record that trigger and
     the exact path before reading it.

4. Identify durable change signals.
   - dependency or tooling changes
   - new or changed contracts and interfaces
   - schema or data model changes
   - new engineering patterns or conventions
   - operational, deployment, or configuration changes
   - product terminology or user-facing promise changes

5. Classify each candidate with one of these statuses:
   - `planned` for durable decisions captured after planning but not yet verified in implementation
   - `verified` for durable decisions supported by implementation evidence
   - `deferred` for worthwhile promotions that should wait for explicit human approval or later work
   - `no-op` when the durable docs already cover the change

6. Map each candidate to the smallest durable home.
   - long-lived architecture decisions -> `docs/architecture/overview.md` or `docs/architecture/adr/`
   - narrower durable implementation decisions -> `docs/decisions/`
   - reusable engineering patterns -> `docs/patterns/`
   - team and integration context -> `docs/context/`
   - product terminology and promises -> `docs/product/`

7. Update feature-scoped tracking, but do **not** auto-edit durable docs as part of this command.
   - Append a dated entry to `FEATURE_DIR/context/promotion-log.md`.
   - Include status, signal, suggested target, rationale, evidence paths, and confidence.
   - Recommend durable doc edits rather than applying them unless the user explicitly asks for the edits in the same run.

8. For every new durable document that should become baseline context, propose a routing-map row in
   the same recommendation.
   - Name the stable command or skill route ID, exact file path, selection reason, and affected
     workflow.
   - Do not update `docs/context/routing-map.md` without explicit confirmation in the same run.
   - Record a declined or uncertain routing change as `deferred` in the promotion log.

9. End with a required summary:

```md
### Promotion Summary

- Signals observed:
  - ...
- Planned candidates:
  - ...
- Verified recommendations:
  - ...
- Deferred recommendations:
  - ...
- Routing-map rows proposed:
  - ...
- Promotion log updated: yes/no (`specs/{feature}/context/promotion-log.md`)
```

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
