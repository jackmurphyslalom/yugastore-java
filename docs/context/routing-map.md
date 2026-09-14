# Context Routing Map

Use this map to build the smallest evidence-backed context set for the current command or skill.
When a workflow creates a durable document that should become baseline context, propose the
corresponding command or skill row update in the same change.

## Exact-file baseline rules

1. Select one stable route ID from the command or skill matrix.
2. Read the authority baseline first, followed by the selected row's artifact inputs and baseline
   documents.
3. Omit a missing exact file and report it. Do not replace it with a directory scan, glob, or
   similarly named file.
4. Run triggered expansion only for a concrete unresolved question.
5. Record why each file was selected, including the route ID or expansion trigger.

## Authority baseline

Read these exact files when they exist:

- `.specify/memory/constitution.md`
- the exact project agent-instruction file already selected by the active agent platform
- `docs/context/index.yaml`

The active platform supplies its instruction file before this map runs; do not search for additional
agent files. The routing map is a control file, not an additional source of project facts.

## Command routing matrix

Resolve `<feature_directory>` from `.specify/feature.json` or the command's prerequisite script.
`—` means that the route intentionally adds no file in that column.

| Route ID | Artifact inputs | Baseline docs | Required skills |
|---|---|---|---|
| `command:speckit.specify` | — | `docs/product/overview.md`; `docs/product/glossary.md` | — |
| `command:speckit.clarify` | `<feature_directory>/spec.md` | — | — |
| `command:speckit.plan` | `<feature_directory>/spec.md` | `docs/architecture/overview.md`; `docs/decisions/README.md`; `docs/patterns/README.md` | — |
| `command:speckit.tasks` | `<feature_directory>/spec.md`; `<feature_directory>/plan.md` | `docs/architecture/overview.md`; `docs/patterns/README.md` | — |
| `command:speckit.implement` | `<feature_directory>/spec.md`; `<feature_directory>/plan.md`; `<feature_directory>/tasks.md` | `docs/architecture/overview.md`; `docs/decisions/README.md`; `docs/patterns/README.md` | — |
| `command:speckit.analyze` | `<feature_directory>/spec.md`; `<feature_directory>/plan.md`; `<feature_directory>/tasks.md` | `docs/product/overview.md`; `docs/architecture/overview.md`; `docs/patterns/README.md` | — |
| `command:speckit.checklist` | `<feature_directory>/spec.md` | `docs/product/overview.md`; `docs/patterns/README.md` | — |
| `command:speckit.constitution` | — | `docs/product/overview.md`; `docs/product/glossary.md`; `docs/architecture/overview.md` | — |
| `command:speckit.converge` | `<feature_directory>/spec.md`; `<feature_directory>/plan.md`; `<feature_directory>/tasks.md` | `docs/architecture/overview.md`; `docs/patterns/README.md` | — |
| `command:speckit.taskstoissues` | `<feature_directory>/tasks.md` | `docs/product/overview.md` | — |
| `command:speckit.aisdlc.bootstrap` | — | `docs/context/gaps.md`; `docs/context/repo-map.md` | `aisdlc-domain-modeling`; guided mode also uses `aisdlc-grilling` |
| `command:speckit.aisdlc.preflight` | selected upcoming command's artifact inputs | selected upcoming command's baseline docs | selected upcoming command's required skills |
| `command:speckit.aisdlc.promote` | `<feature_directory>/spec.md`; `<feature_directory>/plan.md`; `<feature_directory>/tasks.md`; `<feature_directory>/context/promotion-log.md` | `docs/decisions/README.md`; `docs/patterns/README.md` | — |
| `command:speckit.aisdlc.mockup` | `<feature_directory>/spec.md` | `docs/product/overview.md`; `docs/product/glossary.md` | — |
| `command:speckit.aisdlc.triage` | `<feature_directory>/spec.md` | `docs/context/gaps.md`; `docs/product/overview.md`; `docs/architecture/overview.md` | — |
| `command:speckit.aisdlc.pr` | `<feature_directory>/spec.md`; `<feature_directory>/plan.md`; `<feature_directory>/tasks.md` | `CONTRIBUTING.md`; `docs/process/pr-process.md`; `docs/patterns/README.md` | `aisdlc-pr` |
| `command:speckit.git.initialize` | — | `docs/context/repo-map.md` | — |
| `command:speckit.git.remote` | — | `docs/context/repo-map.md` | — |
| `command:speckit.git.validate` | — | `docs/context/repo-map.md`; `docs/architecture/overview.md` | — |
| `command:speckit.git.feature` | — | `docs/product/overview.md`; `docs/product/glossary.md` | — |
| `command:speckit.git.commit` | `<feature_directory>/plan.md`; `<feature_directory>/tasks.md` | `docs/decisions/README.md`; `docs/patterns/README.md` | — |

## Skill routing matrix

The listed skills may not be installed in projects created by older framework versions. Missing
skill rows or files use the compatibility fallback below.

| Route ID | Baseline docs | Expansion rule |
|---|---|---|
| `skill:aisdlc-knowledge-ingestion` | `docs/context/README.md`; `docs/product/glossary.md` | After classifying the approved source, inspect only exact candidate documents in the selected taxonomy category to detect overlap. |
| `skill:aisdlc-pr` | `CONTRIBUTING.md`; `docs/process/pr-process.md`; `docs/patterns/README.md` | For `ready`, add exact standards documents selected by the index and exact feature artifacts selected by `.specify/feature.json`. For `feedback`, add only files named by collected review threads. |
| `skill:<name>` | `<exact/project/path.md>` | `<concrete trigger and exact target>` |

## Triggered expansion

Expand beyond the selected exact-file row only when one of these triggers is present:

| Trigger | Expansion |
|---|---|
| A manifest entry directly matches the task | Read that entry's exact `path` and declared `source_paths`. |
| A selected document links a relevant decision or pattern | Follow only the exact linked file. |
| An active feature needs more feature evidence | Read the exact feature file under the resolved `<feature_directory>`; do not enumerate the feature directory. |
| The request names a product module | Resolve `<module>` from that name, then try `docs/product/modules/<module>.md`. |
| The request names an implementation subsystem or symbol | Search for that exact name, then read only the owning implementation and tests. |
| Selected context is missing, stale, or contradicted | Inspect the smallest current source-of-truth set needed to resolve the stated gap. |

Directories, globs, ownership expansion, dependency traversal, and implementation-code reads are
not baseline context. They are permitted only after a trigger records why that broader discovery is
necessary.

## Compatibility fallback

For a command or skill with no matching row, read only the authority baseline plus these exact files
when they exist:

- `docs/context/gaps.md`
- `docs/product/glossary.md`
- `docs/product/overview.md`
- `docs/architecture/overview.md`
- `docs/context/repo-map.md`
- `docs/decisions/README.md`
- `docs/patterns/README.md`

Do not infer a missing row from a nearby row. Report `route ID: compatibility-fallback` and propose
a stable row when the workflow should be supported permanently.

## Routing result

Report:

- selected route ID and why it matches;
- authority files read;
- artifact inputs and baseline documents read, with the reason for each;
- triggered files read, paired with their trigger;
- missing or stale context;
- source paths consulted directly;
- files deliberately excluded because no route selected them.
