---
name: rabbit-deck-gen
description: Generate a Slalom-branded HTML slide deck that recaps team Rabbit Mode's work on the brownfield YugaStore Java project — an intro, the team, the project, the agentic skills and tools in use, and a data-driven progress recap derived from recent git history. Use when the user asks to build, refresh, or QA the "team Rabbit Mode" YugaStore recap deck.
license: MIT
---

# Rabbit Deck Gen

Generate the team Rabbit Mode YugaStore recap deck by delegating deck creation, brand rules, and rendering to `slalom-html-slide-decks`. This skill is the content brief and orchestration layer; it does not reimplement setup, build, or QA.

## When to Use

- The user asks to build or refresh the team Rabbit Mode deck for YugaStore.
- The user wants a progress recap deck driven by recent git activity on this repo.
- Near miss: the user wants a generic Slalom HTML deck unrelated to team Rabbit Mode or YugaStore — call `slalom-html-slide-decks` directly instead of this skill.

## Inputs

Parse `$ARGUMENTS` (if any) for these optional fields; ask 1-3 pointed questions only when a missing input would materially change the deck:

- `--since=<ref-or-date>` — git anchor for the progress recap. Accepts a ref (branch, commit, tag), an ISO date, or a natural-language phrase like `"3 days ago"`. Defaults to `"3 days ago"`.
- `--out=<path>` — output folder passed through to `setup-deck.js`. Defaults to `./outputs` (slalom skill then places the deck under `<out>/<YYYY-MM-DD>-team-rabbit-mode-yugastore/`).
- `--style-lens=<lens>` — passed through to `slalom-html-slide-decks`. Defaults to `high-energy`.
- `--additional-content=<path>` — folder of raw `*.html` slide fragments to append after the generated deck. Defaults to `additional-deck-content/` at the repo root.
- `--audience=<text>` — free-text audience/purpose hint (e.g. "internal readout", "client demo"). Defaults to internal readout.

## Fixed Content

These are the source of truth for the intro, team, and project slides regardless of `$ARGUMENTS`:

- **Deck title:** `Team Rabbit Mode — YugaStore Recap`
- **Team members:** Young Chul Kim, Jack Murphy, Michael Apfelbeck
- **Project:** brownfield YugaStore (this repo, `yugastore-java`)
- **Style lens default:** high-energy (fits a rapid-sprint recap; still subordinate to Slalom brand rules per `slalom-html-slide-decks`)

## Steps

1. **Resolve inputs.** Determine `SINCE`, `OUT`, `STYLE_LENS`, `ADDITIONAL_CONTENT`, and `AUDIENCE` from `$ARGUMENTS` and the defaults above. Do not ask about anything already defaulted.

2. **Gather agentic-tooling inventory.** Build a compact table with:
   - Skills: enumerate `.agents/skills/*/SKILL.md`, capturing `name` and `description` from each file's YAML frontmatter. Skip anything without a `name` field.
   - Copilot prompts: enumerate `.github/prompts/*.prompt.md`, capturing filename and the `description` field.
   - MCP servers: read `.vscode/mcp.json` if present, listing each server key and its command/URL summary. If the file is missing, note "no workspace MCP config detected".
   Keep the raw inventory in memory; do not write a scratch file.

3. **Gather git progress signal.** Using `SINCE`:
   - Total commits: `git log --oneline --since="$SINCE" | wc -l` (or `--since <REF>..HEAD` if SINCE resolves to a ref).
   - Commits per day: `git log --since="$SINCE" --format='%ad' --date=short | sort | uniq -c`.
   - Notable commit messages: `git log --since="$SINCE" --format='%h %s' --no-merges` — group into themes (features, docs, specs, infra, tests). Drop noise like typo/lint-only commits.
   - Files/areas touched: `git log --since="$SINCE" --name-only --format= | sort -u`, then bucket into `services/` (e.g. `products-microservice/`, `cart-microservice/`, `checkout-microservice/`, `api-gateway-microservice/`, `login-microservice/`, `eureka-server-local/`, `react-ui/`), `specs/`, `docs/`, `meta/`, `.agents/` or `.github/` (tooling), `perf-tests/`, `tools/`, other.
   - Spec Kit artifacts created: `git log --since="$SINCE" --name-only --diff-filter=A --format= | grep -E '^specs/[^/]+/(spec|plan|tasks|research|data-model|quickstart)\.md$' | sort -u`.
   Never invent numbers. If a bucket is empty for the window, state it as empty rather than fabricating.

4. **Choose an output slug and destination.**
   - Slug: `team-rabbit-mode-yugastore`
   - The slalom `setup-deck.js` will create `<OUT>/<YYYY-MM-DD>-team-rabbit-mode-yugastore/`. Do not hand-create this path.

5. **Delegate to `slalom-html-slide-decks`.** Follow its canonical body at `.shared/slalom-html-slide-decks/SKILL.md`. Set `SKILL_DIR=.shared/slalom-html-slide-decks/`.

   ```bash
   node ".shared/slalom-html-slide-decks/scripts/setup-deck.js" \
     --title "Team Rabbit Mode — YugaStore Recap" \
     --out "$OUT"
   ```

   Then write these slides under the package's `slides/` (Slalom brand rules from the slalom skill remain authoritative — the below is only the content brief for each slide):

   1. **Intro / Cover.** "Team Rabbit Mode" as the anchor headline. Subhead: "YugaStore Recap". Slalom cover geometry per `references/slalom-brand-reference.md`.
   2. **Meet the team.** Young Chul Kim, Jack Murphy, Michael Apfelbeck. One line per member (roles inferred from git author distribution when possible; otherwise omit roles).
   3. **The project — brownfield YugaStore.** One-sentence project frame (Spring Boot microservices commerce reference app), the tiers (`eureka-server-local`, `products-microservice`, `checkout-microservice`, `cart-microservice`, `api-gateway-microservice`, `login-microservice`, `react-ui`), and a single visual that encodes "brownfield" (existing system + our recent additions).
   4. **Agentic skills inventory.** From step 2's `.agents/skills/*` enumeration. Prefer grouping by prefix (`rabbit-*`, `speckit-*`, `aisdlc-*`, other) with counts and 1-line descriptions for headline skills only. Do not dump every description.
   5. **Copilot prompts and MCP servers.** Two-column or lane-based layout: prompts on one side, MCP servers on the other. Show configured servers by name; call out Context7 and github if present.
   6. **Progress at a glance.** Total commits and commits-per-day chart/table from step 3. Include the window (`SINCE` value) in the slide.
   7. **What we shipped — themes.** Grouped notable commit messages by theme (features / docs / specs / infra / tests). Use a lane layout, not a raw commit list.
   8. **Where we worked.** Files/areas bucket totals from step 3. Highlight top 3 buckets by count; smaller buckets can share a "Also touched" line.
   9. **Spec Kit artifacts created.** List new `specs/*/{spec,plan,tasks}.md` files from step 3. If none, replace this slide with a "Spec Kit activity" slide summarizing edits to existing spec artifacts instead.
   10. **What's next / close.** One outcome-oriented headline plus 2-3 follow-through items grounded in the git recap (e.g. open feature branches like `feature/slide-deck-gen`, unmerged PRs). Include the standard Slalom internal footer copyright unless the user asked for a public variant.

   Every generated internal slide must include `Copyright [year] Slalom. All Rights Reserved. Proprietary and Confidential.` unless the user explicitly requests a public/non-confidential variant.

6. **Append additional content if provided.** If `ADDITIONAL_CONTENT` (default `additional-deck-content/`) exists at the repo root and contains `*.html` files:
   - Copy each file into the deck's `slides/` directory, preserving order (sort by filename).
   - Prefix copied filenames so they sort after the generated slides (e.g. `99-<original-name>.html`).
   - Do not modify their contents beyond adding the standard Slalom footer if it is missing.
   If the folder is absent or empty, skip this step silently and note it in the completion report.

7. **Build and QA.** Run the slalom build:

   ```bash
   node ".shared/slalom-html-slide-decks/scripts/build-deck.js" "$OUT/<YYYY-MM-DD>-team-rabbit-mode-yugastore"
   ```

   Then run the local gates from `slalom-html-slide-decks` (Storyline, Messaging, Visual Meaning System, Style Lens, Final Handoff) and fill `source/visual-qa-ledger.md`.

## Completion Report

Return in this order:

1. Deck package path.
2. Resolved inputs (`SINCE`, `OUT`, `STYLE_LENS`, `ADDITIONAL_CONTENT`, `AUDIENCE`).
3. Slide count (generated + copied from `additional-deck-content/`).
4. Compact deck language sentence (story frame, structure family, density, rhythm, visual treatment) and the applied style lens.
5. Git recap numbers used on the "Progress at a glance" and "Where we worked" slides — so the user can spot-check them.
6. Status of the slalom skill's local gates and any items still open in `source/visual-qa-ledger.md`.

## Guardrails

- Do not fabricate git numbers, commit messages, contributor breakdowns, or skill descriptions. If a data source is missing, say so on the slide rather than making something up.
- Do not create the deck package by hand — always invoke `slalom-html-slide-decks`'s `setup-deck.js` so the copied `support/` primitives and starter styles land correctly.
- Do not edit application code or spec artifacts from this skill. It writes only to the deck package under `$OUT/`.
- Do not push the deck, open a PR, or delete anything from `additional-deck-content/`.
