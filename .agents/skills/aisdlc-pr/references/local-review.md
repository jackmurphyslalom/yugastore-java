# Two-Axis Local Review

Review the complete readiness scope along two independent axes:

- **Standards**: whether the change follows documented repository guidance.
- **Spec**: whether the change faithfully implements the originating feature artifacts.

Keep the axes isolated so one cannot mask the other. Run bounded read-only reviewers in parallel
when the host supports subagents. Otherwise run two explicitly separated sequential passes, clear
the axis-specific working notes between passes, and preserve the same output contract.

## Standards Axis

Load only routed standards such as `AGENTS.md`, `CONTRIBUTING.md`, the constitution, and exact
standards selected by `docs/context/index.yaml`. Documented repository guidance overrides the
baseline below. Skip checks already enforced deterministically by formatting, linting, type
checking, or tests.

Apply these baseline smells only as labelled judgment calls, never hard violations:

- **Mysterious Name**: a name does not reveal what it represents.
- **Duplicated Code**: the same logic shape appears in multiple changed locations.
- **Feature Envy**: behavior reaches into another object's data more than its own.
- **Data Clumps**: the same group of fields or parameters repeatedly travels together.
- **Primitive Obsession**: a primitive stands in for a domain concept needing its own type.
- **Repeated Switches**: repeated conditionals branch on the same type or discriminator.
- **Shotgun Surgery**: one logical change requires scattered edits across many files.
- **Divergent Change**: one module changes for several unrelated reasons.
- **Speculative Generality**: abstractions or hooks serve needs absent from the Spec.
- **Message Chains**: callers navigate a long chain of internal relationships.
- **Middle Man**: a layer mostly delegates without adding a useful boundary.
- **Refused Bequest**: an implementation ignores most of an inherited contract.

For each finding, cite the changed file/hunk and, for a hard violation, the governing standards
file and rule. Clearly label baseline smells `advisory`.

## Spec Axis

Use the selected `spec.md`, `plan.md`, and `tasks.md` as the source of intent. Report:

- missing or partially implemented requirements;
- changed behavior that was not requested;
- requirements that appear implemented incorrectly;
- incomplete required test or acceptance evidence.

Cite the feature artifact and requirement/task reference for every finding. If no attributable
Spec source exists, report the axis `incomplete`; never infer requirements from branch names or
commit prose alone.

## Aggregate Without Reranking

Return `## Standards` and `## Spec` separately. Do not merge, deduplicate across axes, select one
overall "worst" issue, or let a pass on one axis offset a failure on the other. End with finding
counts and the highest severity within each axis.
