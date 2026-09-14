# Workflow Patterns

## Sequential Workflows

Use an ordered workflow when changing the order would change the result. Give each step an observable completion criterion:

```markdown
Filling a form:

1. Run `analyze_form.py`.
   Complete when every writable field has a stable identifier.
2. Create `fields.json`.
   Complete when every required identifier has a proposed value.
3. Run `validate_fields.py`.
   Complete when validation reports no missing or unknown fields.
4. Run `fill_form.py`, then verify the rendered output.
   Complete when the output opens and every mapped value is visible.
```

## Conditional Workflows

Put a decision before the branch. Name the evidence that selects a path:

```markdown
1. Determine the modification type:
   - No existing artifact: follow "Create".
   - Existing artifact supplied: follow "Edit".
   - Evidence is ambiguous: ask which artifact is authoritative.

2. Follow only the selected branch.
```

Move a large branch to a directly linked reference when other uses do not need it. Keep the selection rule in `SKILL.md`.

## When Not to Add Steps

Use goals and constraints instead of a fixed sequence when multiple approaches are equally valid. A step earns its place when it protects an ordering dependency, confirmation gate, safety boundary, or required artifact.
