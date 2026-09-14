---
description: Create a plan and store it in plan.md.
---

## User Input

```text
$ARGUMENTS
```

## Outline

1. Read `.specify/feature.json` to get the feature directory path and optional `implementation_repository`.

2. If `workspace.yaml` has profile `context-hub`, resolve the implementation target before writing in this order: explicit `--target <repo-key>`, feature target, workspace default, sole implementation repository, otherwise stop and ask. Reject reference repositories and merge the result into `.specify/feature.json`.

3. **Load context**: `.specify/memory/constitution.md` and `<feature_directory>/spec.md`. Keep planning artifacts in the hub and read technical evidence from the resolved implementation repository.

4. Create an implementation plan and store it in `<feature_directory>/plan.md`.
   - Technical context: tech stack, dependencies, project structure
   - Design decisions, architecture, file structure

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
