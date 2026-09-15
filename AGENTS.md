<!-- AI-SDLC:AGENTS START -->
# AI-SDLC Framework v0.17.1

## Overview

This project uses Spec Kit v0.13.4 plus the AI-SDLC core preset, context extension, and workflow.

## Quick Reference

### Before Any Implementation

1. **Bootstrap context if needed**: `.agents/prompts/bootstrap-context-repo.md`
2. **Read project context**: `docs/README.md`
3. **Check for specs**: `specs/{feature-name}/`
4. **Use skills**: start with framework-managed `aisdlc-skill-authoring`, then add more via `npx skills`
5. **Follow patterns**: apply spec + project guidance
6. **Verify**: tests, security, and docs before completion

### Framework-Managed Skills

Framework-managed skills:
- `.agents/skills/aisdlc-skill-authoring`
- `.agents/skills/aisdlc-grilling`
- `.agents/skills/aisdlc-domain-modeling`
- `.agents/skills/aisdlc-knowledge-ingestion`
- `.agents/skills/aisdlc-pr`
- Linked into selected agent-native skills directories when supported

### Add More Skills

- Learn more: https://skills.sh/
- Install additional skills:
  `npx skills add https://github.com/anthropics/skills --skill <skill-name>`

### Spec-Kit Prompts

Spec Kit is installed under `.specify/`. Skills-enabled agents expose the workflow as `speckit-*` skills, while markdown-based agents expose `/speckit.*` commands.

- `.agents/prompts/bootstrap-context-repo.md` - AI-SDLC bootstrap prompt for durable repo context
- `/speckit.aisdlc.bootstrap` - Bootstrap durable project context for a brownfield repo
- `/speckit.aisdlc.preflight` - Build a concise repo-specific context briefing before core Spec Kit phases
- `/speckit.aisdlc.triage` - Analyze raw intake against repo context before choosing the smallest justified next action
- `/speckit.constitution` - Create/update the project constitution at `.specify/memory/constitution.md`
- `/speckit.specify` - Create/update a feature spec (typically `specs/{feature-name}/spec.md`)
- `/speckit.aisdlc.mockup` - Generate static UI mockups and handoff notes for UI-relevant specs
- `/speckit.clarify` - Ask focused questions to remove ambiguity before planning/implementing
- `/speckit.plan` - Produce a technical plan from a spec (typically `specs/{feature-name}/plan.md`)
- `/speckit.tasks` - Break a plan into implementable tasks (typically `specs/{feature-name}/tasks.md`)
- `/speckit.implement` - Implement the next task(s) from tasks while consulting project context + installed skills
- `/speckit.converge` - Audit implementation against spec, plan, and tasks; append gap-closing tasks when needed
- `/speckit.aisdlc.pr` - Run local PR readiness by default, or collect provider feedback with `feedback <PR URL>`
- `/speckit.checklist` - Run a pre-finish checklist (tests, security, docs, edge cases)
- `/speckit.analyze` - Analyze the existing codebase to inform planning/changes
- `/speckit.taskstoissues` - Convert `tasks.md` into GitHub issues (optional)
- `/speckit.aisdlc.promote` - Promote durable implementation knowledge back into `docs/` and feature context

Canonical templates, scripts, extensions, presets, and workflows live under `.specify/`.

Recommended sequence:

1. `.agents/prompts/bootstrap-context-repo.md` or `/speckit.aisdlc.bootstrap`
2. `/speckit.specify` -> optional `/speckit.aisdlc.mockup` for UI specs -> `/speckit.clarify` -> `/speckit.plan` -> `/speckit.tasks` -> `/speckit.analyze` (per feature)
3. `/speckit.implement` -> optional `/speckit.converge` when drift from the spec is suspected -> complete appended tasks
4. `/speckit.aisdlc.pr ready` -> create the pull request explicitly -> `/speckit.aisdlc.pr feedback <PR URL>` as feedback arrives
5. `/speckit.checklist` and `/speckit.aisdlc.promote` as required by the active workflow

Use `/speckit.constitution` when bootstrap has not been run yet or when the constitution needs an intentional rewrite.

## Project Constitution

See `.specify/memory/constitution.md` for project-specific guidelines and decisions.

## Project Context

Long-lived context lives in `docs/` (start with `docs/README.md`).

## Project Name

`yugastore-java`

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
<!-- AI-SDLC:AGENTS END -->

<!-- SPECKIT START -->
For additional context about technologies to be used, project structure,
shell commands, and other important information, read the current plan
at specs/001-gh-board-crud-prompts/plan.md
<!-- SPECKIT END -->
