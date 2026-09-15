# AI-SDLC Framework v0.17.1

This file provides instructions for GitHub Copilot. All essential guidance is included inline for cloud agent compatibility.

## Quick Reference

### Before Any Implementation
1. Check for existing specs in `specs/{feature-name}/`
2. Review project context in `docs/README.md` (if available)
3. Use framework-managed `aisdlc-skill-authoring` from `.agents/skills/aisdlc-skill-authoring`

### Add More Skills
- https://skills.sh/
- `npx skills add https://github.com/anthropics/skills --skill <skill-name>`

### Spec-Kit Commands
Use these prompts for spec-driven development:
- `/speckit.specify` - Create or update a specification
- `/speckit.plan` - Create a technical implementation plan
- `/speckit.analyze` - Analyze plan/spec/task consistency against repo context
- `/speckit.tasks` - Break plan into actionable tasks
- `/speckit.implement` - Implement tasks following the plan
- `/speckit.converge` - Audit implementation against spec, plan, and tasks; append gap-closing tasks when needed
- `/speckit.checklist` - Pre-completion quality checklist
- `/speckit.aisdlc.bootstrap` - Bootstrap durable project context for a brownfield repo
- `/speckit.aisdlc.mockup` - Generate static UI mockups for UI-relevant specs
- `/speckit.aisdlc.promote` - Promote durable decisions into docs and feature context

## Quality Gates (Always Apply)

Before completing any implementation:
- [ ] All acceptance criteria from the spec are met
- [ ] Tests written and passing (aim for 80%+ coverage on business logic)
- [ ] Documentation updated if public APIs changed
- [ ] No linting errors (`npm run lint` or equivalent)
- [ ] Self-review completed
- [ ] Security considerations addressed

## Security Essentials

- Validate and sanitize all user input
- Use parameterized queries (prevent SQL injection)
- Never commit secrets, API keys, or credentials
- Encode output appropriately (prevent XSS)
- Apply principle of least privilege
- Log security-relevant events (without sensitive data)

## Testing Patterns

- Use AAA pattern: Arrange-Act-Assert
- Test naming: "should {expected behavior} when {condition}"
- Mock external dependencies
- Test edge cases and error paths
- Aim for 80%+ coverage on business logic

## Code Review Categories

When reviewing code, use these categories:
- **[BLOCKER]** - Must fix before merge (security, correctness, data loss)
- **[SUGGESTION]** - Would improve code quality
- **[QUESTION]** - Need clarification on intent
- **[NIT]** - Minor style/preference issue

## Project Constitution

If `.specify/memory/constitution.md` exists, it contains project-specific principles and constraints that override general guidance.

## Extended Reference

For VS Code Copilot Chat users with full repository access:
- Architecture decisions: `docs/architecture/adr/`
- Business context: `docs/README.md`
- Framework assets: `.agents/`

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

## Writing style
Writing Style Guide Follow the instructions in #.github/writing-style-guide.md for consistent writing style

---
*This file is managed by the AI-SDLC Framework. Run `aisdlc init --here --force` to update.*
