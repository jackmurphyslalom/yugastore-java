# AI-SDLC Framework v0.17.1

This project uses the AI-SDLC Framework for spec-driven development with framework-managed and external skills.

## Before Implementing Any Task

1. **Read project context**: Start with `docs/README.md`
2. **Check for specs**: Look in `specs/` directory for feature specifications
3. **Use relevant skills**: Start with framework-managed `aisdlc-skill-authoring`, then add more as needed
4. **Fallback guidance**: Use project docs and shared framework context in `.agents/`

## Framework-Managed Skill

- `.agents/skills/aisdlc-skill-authoring`

## Add More Skills

- https://skills.sh/
- `npx skills add https://github.com/anthropics/skills --skill <skill-name>`

## Spec-Kit Commands

Spec Kit assets are installed under `.specify/`. Use the following prompts:

- `speckit.specify` - Create or update a spec
- `speckit.clarify` - Clarify requirements
- `speckit.plan` - Create a technical plan
- `speckit.tasks` - Break a plan into tasks
- `speckit.implement` - Implement from tasks
- `speckit.converge` - Audit implementation against spec, plan, and tasks; append gap-closing tasks when needed
- `speckit.analyze` - Analyze spec consistency
- `speckit.checklist` - Generate quality checklists
- `speckit.constitution` - Update project constitution
- `speckit.taskstoissues` - Convert tasks to GitHub issues
- `speckit.aisdlc.bootstrap` - Bootstrap durable project context for a brownfield repo
- `speckit.aisdlc.mockup` - Generate static UI mockups for UI-relevant specs
- `speckit.aisdlc.pr` - Run PR readiness or collect provider feedback
- `speckit.aisdlc.promote` - Promote durable context updates after planning or implementation

## Implementation Workflow

1. Read the spec (if exists)
2. Identify task type
3. Apply framework-managed skill guidance, then any additional installed skills
4. Implement and test
5. Document changes

## Project Constitution

Project-specific rules: `.specify/memory/constitution.md`

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
