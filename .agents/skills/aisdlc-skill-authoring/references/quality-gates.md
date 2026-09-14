# Skill Quality Gates

Use this checklist before shipping a skill.

## 1. Trigger Quality

- `name` is lowercase hyphen-case and specific.
- `description` states the outcome and distinct trigger contexts.
- Trigger language reflects realistic requests without redundant synonyms.
- Typical and difficult requests match; the near miss does not.

## 2. Scope and Structure

- `SKILL.md` covers only core workflow and decision points.
- Variant-heavy detail is moved to `references/`.
- Repetitive deterministic steps are moved to `scripts/`.
- Output artifacts/templates are placed in `assets/`.
- Every strict sequence or constraint protects a real requirement.

## 3. Context Efficiency

- No duplicate content between `SKILL.md` and references.
- `SKILL.md` is concise and navigable.
- Reference files are directly linked from `SKILL.md` (one-hop discoverability).
- Required instructions are inline; optional branches are behind clear pointers.
- Definitions, rules, and caveats for one concept are kept together.

## 4. Operational Reliability

- Script entry points are invoked through their declared runtimes and tested.
- File paths in instructions are correct.
- Important steps end with observable completion criteria.
- Instructions name the desired behavior instead of relying on prohibitions.
- Validation passes via:
  - `python3 scripts/quick_validate.py <skill-path>`

## 5. Real-World Behavior

Run three prompt sanity checks:

1. Typical in-scope request
2. Edge-case in-scope request
3. Near-miss request (should avoid triggering)

Treat these checks as boundary confirmation, not a benchmark. Update only the source of the failure:

- frontmatter trigger wording
- workflow ordering/branching
- script coverage
- reference organization

## 6. Pruning

- Remove instructions that do not change agent behavior.
- Remove duplicated meanings rather than rephrasing them.
- Remove stale branches, background exposition, and process commentary.
- Split only for a distinct trigger or genuinely separate workflow.

## 7. Packaging Readiness

- Folder contains only needed execution files.
- No process-only docs (`README.md`, `CHANGELOG.md`, etc.).
- Package can be generated:
  - `python3 scripts/package_skill.py <skill-path> [output-dir]`
