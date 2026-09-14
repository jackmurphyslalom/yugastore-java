---
description: Execute the implementation plan by processing all tasks in tasks.md.
---

## User Input

```text
$ARGUMENTS
```

## Outline

1. Read `.specify/feature.json` to get the feature directory path and optional `implementation_repository`.

2. If `workspace.yaml` has profile `context-hub`, resolve the target before any write: explicit `--target <repo-key>`, feature target, workspace default, sole implementation repository, otherwise stop and ask. Verify it is declared, has role `implementation`, exists at the configured path, and is a Git repository. Persist it without removing other feature fields.

3. **Load context** from the hub: `.specify/memory/constitution.md` and `<feature_directory>/spec.md` and `<feature_directory>/plan.md` and `<feature_directory>/tasks.md`. Run source, build, and test work in the resolved implementation repository.

4. **Execute tasks** in order:
   - Complete each task before moving to the next
   - Mark completed tasks by changing `- [ ]` to `- [x]` in `<feature_directory>/tasks.md`
   - Halt on failure and report the issue

5. **Validate**: Verify all tasks are completed and the implementation matches the spec.

Never target a reference repository. Do not fetch, pull, switch branches, commit, push, or orchestrate multi-repository commits automatically.

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
