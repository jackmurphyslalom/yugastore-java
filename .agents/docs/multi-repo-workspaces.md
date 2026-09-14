# Multi-Repo Workspaces

> **Advanced feature** — use the [Getting Started Guide](getting-started.md) for a single repository.

AI-SDLC supports two workspace profiles:

- `standard` preserves the existing multi-repository behavior.
- `context-hub` makes the workspace root the owner of durable docs, specifications, plans, tasks, and analysis while routing production changes to a declared implementation repository.

## Create a standard workspace

```bash
aisdlc workspace init my-workspace --repos frontend,backend
```

## Create a context hub

```bash
aisdlc workspace init product-hub \
  --profile context-hub \
  --repos service,portal \
  --default-target service \
  --bootstrap-mode guided
```

`workspace.yaml` is canonical:

```yaml
name: product-hub
profile: context-hub
framework:
  version: installed-version
execution:
  default_target: service
repos:
  service:
    path: ./service
    git: https://example.test/service.git
    branch: main
    role: implementation
    type: service
    tech_stack: []
  handbook:
    path: ./handbook
    git: https://example.test/handbook.git
    branch: main
    role: reference
    type: documentation
    tech_stack: []
```

Add repositories with explicit roles:

```bash
aisdlc workspace add-repo ./handbook --role reference
aisdlc workspace add-repo ./portal --role implementation --default-target
```

Reference repositories are read-only evidence sources. Production changes are allowed only in a resolved implementation repository.

## Target resolution

Planning and implementation resolve a target in this order:

1. one-run `/speckit.plan --target <repo-key>` or `/speckit.implement --target <repo-key>`;
2. current feature `implementation_repository`;
3. workspace `execution.default_target`;
4. the sole implementation repository;
5. otherwise stop and ask.

The result is persisted in `.specify/feature.json`. CLI workspace commands do not automatically
switch branches, fetch, pull, commit, or orchestrate commits across repositories. Agent session sync
is separate: it may only fast-forward a clean checkout after fetch and otherwise pauses for user
recovery.

## Status and freshness

`aisdlc workspace status` reports roles, missing repositories, unresolved targets, context-manifest state, branch, dirty state, and ahead/behind using existing local tracking refs. It never fetches or mutates refs, so remote freshness may be unknown.

Session-start sync uses a different, guarded policy: fetch, classify, and only then allow
`git pull --ff-only` for a clean branch that is strictly behind its upstream. It never resolves
dirty, ahead, diverged, detached, or missing prerequisite states automatically.

## Agent integrations and skills

Choose agents interactively or pass `--agents`. `aisdlc init` installs:

```text
.agents/skills/aisdlc-skill-authoring
.agents/skills/aisdlc-grilling
.agents/skills/aisdlc-domain-modeling
```

Only initialize AI-SDLC inside an individual repository when that repository is regularly opened standalone.

## Setup

After editing Git URLs in `workspace.yaml`:

```bash
cd product-hub
aisdlc workspace setup
```
