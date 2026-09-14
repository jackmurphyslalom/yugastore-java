<!-- AI-SDLC:ZCODE START -->
# ZCode Instructions

This file provides ZCode-specific configuration for the yugastore-java project.

**Please read and follow the guidance in [`AGENTS.md`](AGENTS.md)** for project context,
external skills, and development practices. For Spec Kit invocations, this file and the
generated ZCode skills take precedence over the generic examples in `AGENTS.md`.

## ZCode-Specific Settings

- ZCode Spec Kit workflow skills are located in `.zcode/skills/` under `speckit-*` folders
- Use `$speckit-*` skill names for the Spec Kit workflow in ZCode
- Do not copy command invocation syntax from `AGENTS.md`; use only the dollar-prefixed,
  hyphenated forms described here
- Framework version: 0.17.1

## Managed Context

Spec Kit plan-reference blocks are managed by the bundled `agent-context` extension.
AI-SDLC durable context lives in `docs/context/`, `docs/`, and feature-scoped `specs/*/context/` artifacts.
Use framework-managed `aisdlc-grilling` and `aisdlc-domain-modeling` and `aisdlc-knowledge-ingestion` and `aisdlc-pr` skills during context bootstrap.
Guided bootstrap requires one-at-a-time decisions and final shared-understanding confirmation before context is verified. Automated bootstrap creates evidence-backed drafts, requires human review, and never creates ADRs.
`docs/product/glossary.md` is the sole default canonical language source. Bootstrap edits documentation and context only, never application code.
Session start is the sole owner of repository synchronization. Before dispatching a mutating command, run `git fetch` for the configured remote, then classify the checkout. If fetch fails, pause and report the error. If the checkout is clean and equal to its upstream, continue without a pull. If it is clean and strictly behind its configured upstream, run `git pull --ff-only`. If the current branch is the clean detected default branch with no upstream and the remote default branch is detected, run `git pull --ff-only <remote> <default-branch>`. If a non-default branch has no upstream, pause; never treat the remote default branch as its tracking branch. Pause and explain the recovery path for dirty states (including untracked files), ahead, diverged, detached, missing remote, missing upstream, or missing default branch. If `git pull --ff-only` fails, pause, report the error, and do not retry with a broader operation. Never reset, stash, merge, rebase, push, discard work, or switch branches automatically. Read-only commands do not fetch or pull; they classify from local refs and report remote freshness as unknown. After session start, command bodies never fetch, pull, switch branches, or independently repeat checkout classification.
`speckit.aisdlc.preflight`, `speckit.aisdlc.triage`, and the `ready` action of `speckit.aisdlc.pr` remain read-only: never fetch, pull, switch branches, edit files, or mutate Git refs; report remote freshness as unknown when local tracking refs cannot prove it. The `feedback` action collects provider data read-only and requires explicit confirmation before an eligible summary write.
Every framework command must end its final response with exactly one fenced
`aisdlc-step-report` JSON object using schema version 1 and fields `status`,
`blocker_code`, `attempted_fallbacks`, `external_write`, and `summary`.
Initial blocker codes are `INVALID_COMPARISON_BASE`, `UNSAFE_CHECKOUT`,
`CONTRACT_CONFLICT`, `MISSING_SCRIPT`, `MISSING_TEMPLATE`, and
`TOOL_FAILURE`. Never invent a command or install a package to replace a
missing framework script; report `MISSING_SCRIPT` with its installed path.
<!-- AI-SDLC:ZCODE END -->
