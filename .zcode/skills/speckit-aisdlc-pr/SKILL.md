---
name: "speckit-aisdlc-pr"
description: "Assess local PR readiness or collect feedback from a supported provider pull request"
compatibility: "Requires spec-kit project structure with .specify/ directory"
metadata:
  author: "aisdlc-framework"
  source: ".specify/templates/commands/aisdlc.pr.md"
---

When a hook command name contains dots, convert it to the matching skill name by replacing dots with hyphens.
Example: `speckit.aisdlc.preflight` -> `$speckit-aisdlc-preflight`.

# AI-SDLC Pull Request Workflow

Use the framework-managed `.agents/skills/aisdlc-pr/SKILL.md` workflow.

Parse `$ARGUMENTS` as one of:

- blank: `ready`
- `ready`: readiness with automatic comparison-base resolution
- `ready <base-ref>`: readiness using the explicit validated base
- `feedback <pull-request-url>`: provider feedback for exactly one validated GitHub or Azure
  DevOps pull-request URL

Reject unknown actions and extra arguments that do not belong to the selected action.

For `ready`, run the complete local readiness workflow. If an explicit base is invalid, pause
immediately; do not fall through to another candidate. Report separate committed, staged,
unstaged, and untracked inventories; independent Standards and Spec findings; verification
evidence; a PR draft; `ready`, `changes-requested`, or `incomplete`; and that no external write was
made.

For `feedback`, require a supported HTTPS pull-request URL before authentication or collection.
Collect through the provider-neutral contract. Never call a provider for blank, malformed,
unsupported-provider, or non-PR URLs. Show the exact eligible marked-summary write and obtain
explicit confirmation before every create or update.

Never create a pull request, push, modify Git history, discard work, infer a reviewer, or expand
provider scope.

## Required Structured Step Report

End the final response with exactly one fenced `aisdlc-step-report` JSON object:

```aisdlc-step-report
{
  "schema_version": 1,
  "status": "pass|blocked|fail",
  "blocker_code": null,
  "attempted_fallbacks": [],
  "external_write": false,
  "summary": "human-readable result including the readiness or feedback outcome"
}
```

A completed readiness review is `pass` even when its review outcome is `changes-requested`.
Use `blocked` or `fail` only when the workflow cannot complete. Use `null` only for a passing
result. For blocked or failed results, use one of:

- `INVALID_COMPARISON_BASE`
- `UNSAFE_CHECKOUT`
- `CONTRACT_CONFLICT`
- `MISSING_SCRIPT`
- `MISSING_TEMPLATE`
- `TOOL_FAILURE`

Invoke only framework scripts declared in this command's frontmatter. Never discover, download,
install, or execute a package to replace a missing framework script.
