---
name: aisdlc-skill-authoring
description: Author and refine focused agent skills. Use when creating a skill, improving an existing skill's trigger or instructions, organizing skill resources, or preparing a skill for validation and packaging.
license: Complete terms in LICENSE.txt
---

# AI-SDLC Skill Authoring

> Notice: This skill adapts guidance from the sources listed in `NOTICE`.

Make each skill reliably discoverable, focused on a real job, and easy for an agent to follow.

## Start With Usage

Ground the skill in 3–5 realistic requests before designing its files. Include:

- a typical request the skill must handle;
- a difficult or ambiguous request it must still handle;
- a near miss that should use ordinary agent behavior or another skill.

Example:

- In scope: “Create a project skill that reviews database migrations for backward compatibility.”
- Difficult: “Two migration policies conflict; help the user resolve the conflict before reviewing.”
- Near miss: “Explain what a database migration is.”

The skill is ready to design when its examples establish a clear boundary.

## Authoring Workflow

### 1. Define the job and trigger

Write one sentence describing the outcome the skill enables. Then draft frontmatter:

- `name` is specific, lowercase, and hyphenated.
- `description` says what the skill does and names the distinct situations that should trigger it.
- Trigger language reflects realistic user wording without listing redundant synonyms.

Avoid broad claims such as “helps with documentation” that compete with unrelated skills.

Completion criterion: the typical and difficult examples match the description, and the near miss does not.

### 2. Choose the right level of control

Match instruction precision to the work:

- Give goals and constraints for judgment-heavy work.
- Add ordered steps when sequence matters.
- Use templates or pseudocode when the shape matters but details vary.
- Use scripts for fragile, repetitive, or deterministic operations.

Prefer the least restrictive form that still makes the behavior dependable.

Completion criterion: every strict instruction protects an actual requirement or observed failure.

### 3. Design the information hierarchy

Keep material where the agent needs it:

1. Put the core workflow, decision points, and critical constraints in `SKILL.md`.
2. Put conditional or detailed knowledge in directly linked `references/`.
3. Put deterministic operations in `scripts/`.
4. Put reusable output files in `assets/`.

Inline what every use needs. Move branch-specific detail behind a link whose wording says when to read it. Keep references one hop from `SKILL.md`.

Use [workflow patterns](references/workflows.md) for workflow and branching design. Use [output patterns](references/output-patterns.md) when output shape matters.

Completion criterion: every file has one purpose, and required instructions are not hidden behind optional navigation.

### 4. Initialize or audit

For a new skill:

```bash
python3 scripts/init_skill.py <skill-name> --path <output-directory>
```

Create optional resource directories only when they have a known purpose:

```bash
python3 scripts/init_skill.py <skill-name> --path <output-directory> \
  --resources scripts,references,assets
```

For an existing skill, first identify its live behavior, duplicated guidance, broken navigation, and obsolete content. Preserve useful behavior while simplifying its expression.

Completion criterion: the proposed file set contains no placeholders or speculative resources.

### 5. Write for action

Use direct, positive instructions that name the desired behavior. For each ordered step:

- state the action;
- include only the constraints needed at that point;
- finish with an observable completion criterion.

Keep definitions, rules, and caveats for one concept together. Remove:

- duplicated meanings;
- background that does not affect execution;
- generic advice the agent already follows;
- stale branches and process commentary.

Split a skill only when a distinct trigger or a genuinely separate workflow earns the extra navigation and context cost.

Completion criterion: each instruction changes behavior, and each important step has a checkable end.

### 6. Validate and sanity-check

Run structural validation:

```bash
python3 scripts/quick_validate.py <path/to/skill-folder>
```

Then exercise the three grounding prompts:

1. The typical request should follow the intended workflow.
2. The difficult request should use the skill’s decision guidance without inventing facts.
3. The near miss should not pull the agent into the skill.

These are sanity checks, not a benchmark. Fix the trigger description first when invocation is wrong; fix the relevant instruction when execution is wrong.

Completion criterion: validation passes and all three prompts behave within the intended boundary.

### 7. Package

```bash
python3 scripts/package_skill.py <path/to/skill-folder> [output-directory]
```

Completion criterion: the package contains only files required to use the skill.

## Definition of Done

- The trigger boundary is clear from realistic examples.
- `SKILL.md` is concise, actionable, and free of duplicated reference content.
- Navigation is one hop and every referenced file exists.
- Scripts, when present, are deterministic and tested.
- Structural validation and the three prompt checks pass.

## Quick Links

- [Workflow patterns](references/workflows.md) — sequence, branching, and completion criteria.
- [Output patterns](references/output-patterns.md) — strict and flexible output guidance.
- [Quality gates](references/quality-gates.md) — final pruning and packaging review.

Bundled Python helpers require `python3`; validation and packaging also require `PyYAML`.
