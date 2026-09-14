# Maintenance & Updates

Keep your framework assets fresh and up to date.

---

## Refreshing Framework Assets

Run `aisdlc init --here --force` to refresh framework-managed assets (`.agents/`) and integration files.

```bash
aisdlc init --here --force
```

This updates:
- `.agents/` directory (framework-managed context and command sources)
- Agent integration files (e.g., `CLAUDE.md`, `.clinerules/`, etc.)
- `.specify/` templates and scripts

**Important**: By default, `.specify/memory/constitution.md` is **always preserved**.
The installed constitution template receives the current marker-delimited AI-SDLC routing clause,
while an existing project constitution remains project-owned and unchanged.

---

## Resetting Spec Kit Templates

If you want to reset `.specify/` templates and scripts to their default state, add `--reset-specify`:

```bash
aisdlc init --here --force --reset-specify
```

This resets:
- `.specify/templates/` (spec templates)
- `.specify/scripts/` (helper scripts)

**Preserved**:
- `.specify/memory/constitution.md` (never overwritten)
- Your existing specs in `specs/` (never touched)

---

## Checking Status

Verify your setup and see what's configured:

```bash
aisdlc status
```

This shows:
- Framework version
- Enabled agent integrations
- Directory structure status

---

## What AISDLC Does Not Manage

AISDLC does **not** manage:
- Additional external skills installed via `npx skills`
- Your project code and tests
- Your `docs/` directory (project-owned)
- Your `specs/` directory (project-owned)
- Your constitution (`.specify/memory/constitution.md`)

---

## Framework-Managed and External Skills

`aisdlc init` installs `aisdlc-skill-authoring`, `aisdlc-grilling`, `aisdlc-domain-modeling`, `aisdlc-knowledge-ingestion`, and `aisdlc-pr` under `.agents/skills/`.

Additional skills are installed and managed separately using the `skills` CLI:

```bash
# Install a skill
npx skills add https://github.com/anthropics/skills --skill <skill-name>

# List installed skills
npx skills list

# Update skills
npx skills update
```

See: https://skills.sh/

---

## Troubleshooting

### "Framework version mismatch" warning

Update your global CLI:
```bash
npm install -g aisdlc
```

Then refresh assets:
```bash
aisdlc init --here --force
```

### Integration files not generated

Re-run init and select agents interactively:
```bash
aisdlc init --here
```

### Lost your constitution

If you accidentally reset your constitution, check git history:
```bash
git log .specify/memory/constitution.md
git checkout HEAD~1 .specify/memory/constitution.md
```

---

## Update Frequency

**Recommended**:
- Run `aisdlc init --force` monthly or when upgrading the CLI
- Check for CLI updates quarterly: `npm outdated -g aisdlc`

**When to force update**:
- After upgrading the CLI version
- When new agent integrations are released
- When framework docs or commands are improved

---

**Questions?** See the [Getting Started Guide](getting-started.md) or file an issue on GitHub.
