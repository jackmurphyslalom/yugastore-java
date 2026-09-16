---
name: rabbit-deck-gen
description: Generate a Slalom-branded slide deck — HTML, Marp, or both — that recaps team Rabbit Mode's work on the brownfield YugaStore Java project. Covers an intro, the team, the project, the agentic skills and tools in use, and a data-driven progress recap derived from recent git history. Use when the user asks to build, refresh, or QA the "team Rabbit Mode" YugaStore recap deck.
license: MIT
---

# Rabbit Deck Gen

Generate the team Rabbit Mode YugaStore recap deck by delegating deck creation, brand rules, and rendering to `slalom-html-slide-decks`. This skill is the content brief and orchestration layer; it does not reimplement setup, build, or QA.

## When to Use

- The user asks to build or refresh the team Rabbit Mode deck for YugaStore.
- The user wants a progress recap deck driven by recent git activity on this repo.
- Near miss: the user wants a generic Slalom deck (HTML or Marp) unrelated to team Rabbit Mode or YugaStore — call `slalom-html-slide-decks` directly instead of this skill.

## Inputs

Parse `$ARGUMENTS` (if any) for these optional fields; ask 1-3 pointed questions only when a missing input would materially change the deck:

- `--format=<html|marp|both>` — output format. Defaults to `marp`.
- `--max-slides=<N>` — soft cap on the generated slide count. Defaults to unlimited (10 generated slides). Applied per format; if `--format=both`, both packages honor the same cap. See "Fixed Slide Sequence and Priority" below for the drop order when the fixed sequence exceeds `N`.
- `--since=<ref-or-date>` — git anchor for the progress recap. Accepts a ref (branch, commit, tag), an ISO date, or a natural-language phrase like `"3 days ago"`. Defaults to `"3 days ago"`.
- `--out=<path>` — output root. Defaults to `./outputs` for HTML and `./outputs-marp` for Marp. When `--format=both`, `--out` overrides only the HTML root; Marp still goes under `./outputs-marp` unless `--out-marp=<path>` is also provided.
- `--out-marp=<path>` — Marp-specific output root (only meaningful with `--format=marp` or `--format=both`). Defaults to `./outputs-marp`.
- `--style-lens=<lens>` — HTML-only; passed through to `slalom-html-slide-decks`. Defaults to `high-energy`. Ignored for Marp (Marp uses the theme as-is).
- `--additional-content=<path>` — HTML-only; folder of raw `*.html` slide fragments to append after the generated deck. Defaults to `additional-deck-content/` at the repo root. Ignored for Marp.
- `--audience=<text>` — free-text audience/purpose hint (e.g. "internal readout", "client demo"). Defaults to internal readout.

## Fixed Content

These are the source of truth for the intro, team, and project slides regardless of `$ARGUMENTS`:

- **Deck title:** `Team Rabbit Mode — YugaStore Recap`
- **Team members:** Young Chul Kim, Jack Murphy, Michael Apfelbeck
- **Project:** brownfield YugaStore (this repo, `yugastore-java`)
- **Style lens default (HTML only):** high-energy (fits a rapid-sprint recap; still subordinate to Slalom brand rules per `slalom-html-slide-decks`)

## Fixed Slide Sequence and Priority

The full generated sequence is 10 slides. When `--max-slides=N` is smaller than the current sequence length, drop slides from the bottom of the priority list first, then re-check. Never drop slides 1-3 (intro, team, project) or slide 10 (close); if `N < 4` refuse and report the 4-slide minimum.

Full sequence:

1. Intro / Cover — **required**
2. Meet the team — **required**
3. The project (brownfield YugaStore) — **required**
4. Agentic skills inventory
5. Copilot prompts and MCP servers — **lowest priority, drop 3rd**
6. Progress at a glance
7. What we shipped — themes
8. Where we worked — **lowest priority, drop 2nd**
9. Spec Kit artifacts created — **lowest priority, drop 1st**
10. What's next / close — **required**

Drop order for `--max-slides`:

- N ≥ 10: keep all slides.
- N = 9: drop slide 9 (Spec Kit artifacts).
- N = 8: also drop slide 8 (Where we worked).
- N = 7: also drop slide 5 (Prompts + MCP).
- N < 7: report to the user which slides were dropped and confirm the resulting sequence in the completion report. If `N < 4`, refuse and state the 4-slide minimum (cover + team + project + close).

When a slide is dropped, do not silently merge its content into another slide; the recap intentionally omits it. Renumber the remaining slides sequentially.

## Content Style

Apply these rules to every generated slide. They override any "punchy" impulse from the style lens.

- No eyebrows, kickers, motivational closers, or manufactured subtitles. Slide titles are literal (e.g., "Meet the team", not "Three humans in the loop").
- No headline numbers. Counts appear in the body only when the count is the claim (e.g., "38 no-merge commits landed on Sep 15"). Do not title a slide with a number (`42 skills, five families`, `51 commits, one team, three days`).
- No decorative aggregates. Do not report totals that combine unrelated things (e.g., a sum of file-touches across agent-mirror folders) unless the sum answers a specific question on the slide.
- No metaphorical framing (`three days built the runway`, `the sprint's spike day`, `carried the load`). State what happened.
- One claim per slide. If a bucket, theme, or list has no signal for the window, omit it — do not list "0" for completeness.
- Prefer verbs and nouns over adjectives. Cut every word that does not carry the claim.

## Steps

1. **Resolve inputs.** Determine `FORMAT`, `MAX_SLIDES`, `SINCE`, `OUT`, `OUT_MARP`, `STYLE_LENS`, `ADDITIONAL_CONTENT`, and `AUDIENCE` from `$ARGUMENTS` and the defaults above. Do not ask about anything already defaulted.

2. **Compute the effective slide list.** Start from the 10-slide fixed sequence, apply the `--max-slides` drop order, and record which slides (if any) were dropped. This applies to both formats when `--format=both`.

3. **Gather agentic-tooling inventory.** Build a compact table with:
   - Skills: enumerate `.agents/skills/*/SKILL.md`, capturing `name` and `description` from each file's YAML frontmatter. Skip anything without a `name` field.
   - Copilot prompts: enumerate `.github/prompts/*.prompt.md`, capturing filename and the `description` field.
   - MCP servers: read `.vscode/mcp.json` if present, listing each server key and its command/URL summary. If the file is missing, note "no workspace MCP config detected".
   Keep the raw inventory in memory; do not write a scratch file.

4. **Gather git progress signal.** Using `SINCE`:
   - Total commits: `git log --oneline --since="$SINCE" | wc -l` (or `--since <REF>..HEAD` if SINCE resolves to a ref).
   - Commits per day: `git log --since="$SINCE" --format='%ad' --date=short | sort | uniq -c`.
   - Notable commit messages: `git log --since="$SINCE" --format='%h %s' --no-merges` — group into themes (features, docs, specs, infra, tests). Drop noise like typo/lint-only commits.
   - Files/areas touched: `git log --since="$SINCE" --name-only --format= | sort -u`, then bucket into `services/` (e.g. `products-microservice/`, `cart-microservice/`, `checkout-microservice/`, `api-gateway-microservice/`, `login-microservice/`, `eureka-server-local/`, `react-ui/`), `specs/`, `docs/`, `meta/`, `.agents/` or `.github/` (tooling), `perf-tests/`, `tools/`, other.
   - Spec Kit artifacts created: `git log --since="$SINCE" --name-only --diff-filter=A --format= | grep -E '^specs/[^/]+/(spec|plan|tasks|research|data-model|quickstart)\.md$' | sort -u`.
   Never invent numbers. If a bucket is empty for the window, state it as empty rather than fabricating.

5. **Choose an output slug and destination(s).**
   - Slug: `team-rabbit-mode-yugastore`
   - HTML lands under `<OUT>/<YYYY-MM-DD>-team-rabbit-mode-yugastore/`.
   - Marp lands under `<OUT_MARP>/<YYYY-MM-DD>-team-rabbit-mode-yugastore/`.
   - Do not hand-create these paths — the slalom `setup-deck.js` and `setup-deck-marp.js` scripts own creation.

6. **Delegate to `slalom-html-slide-decks`.** Follow its canonical body at `.shared/slalom-html-slide-decks/SKILL.md`. Set `SKILL_DIR=.shared/slalom-html-slide-decks/`.

   For each requested format, run the matching setup script:

   ```bash
   # HTML (when FORMAT is html or both)
   node ".shared/slalom-html-slide-decks/scripts/setup-deck.js" \
     --title "Team Rabbit Mode — YugaStore Recap" \
     --out "$OUT"

   # Marp (when FORMAT is marp or both)
   node ".shared/slalom-html-slide-decks/scripts/setup-deck-marp.js" \
     --title "Team Rabbit Mode — YugaStore Recap" \
     --out "$OUT_MARP"
   ```

   Then author the effective slide list in the package(s). Slalom brand rules from the slalom skill remain authoritative, and the Content Style rules above apply to every slide. The below is only the content brief:

   1. **Cover.** Title: "Team Rabbit Mode — YugaStore Recap". Include the window (`SINCE`). HTML: use Slalom cover geometry per `references/slalom-brand-reference.md`. Marp: use `<!-- _class: lead -->` on the first slide.
   2. **Meet the team.** Young Chul Kim, Jack Murphy, Michael Apfelbeck. One line per member describing what they actually touched in the window (derived from git author + file paths). If the git signal does not support a role, name the member and stop.
   3. **The project.** One sentence: brownfield Spring Boot microservices reference app. List the tiers (`eureka-server-local`, `products-microservice`, `checkout-microservice`, `cart-microservice`, `api-gateway-microservice`, `login-microservice`, `react-ui`). No metaphor for "brownfield".
   4. **Agentic skills inventory.** Group by prefix (`rabbit-*`, `speckit-*`, `aisdlc-*`, other). Show the count per group and name only the skills that were added or materially changed in the window (from git). Do not list every skill.
   5. **Copilot prompts and MCP servers.** Configured MCP servers by name. Copilot prompts grouped by prefix with counts. HTML: two columns. Marp: two adjacent sections.
   6. **Progress at a glance.** Total no-merge commits in the window and the commits-per-day breakdown. State the `SINCE` value on the slide. No narrative around the numbers.
   7. **What shipped.** Grouped notable commit messages by theme (features / docs / specs / infra / tests). Drop themes with no commits.
   8. **Where we worked.** Files/areas buckets from step 4, showing only buckets with a non-trivial signal for the window. Do not report every bucket; do not sum unrelated buckets into a headline.
   9. **Spec Kit artifacts created.** List new `specs/*/{spec,plan,tasks}.md` files from step 4, grouped by feature slug. If none were added in the window, drop this slide (do not substitute a filler slide).
   10. **Close.** 2-3 follow-through items grounded in the git recap (open feature branches, unmerged PRs, referenced-but-not-implemented specs). No motivational sign-off. Include the standard Slalom internal footer copyright unless the user asked for a public variant.

   Every generated internal slide must include `Copyright [year] Slalom. All Rights Reserved. Proprietary and Confidential.` unless the user explicitly requests a public/non-confidential variant. For Marp, put the footer as an italic line at the bottom of each slide; for HTML, use the slide template's footer.

7. **Append additional content (HTML only).** If `FORMAT` includes HTML and `ADDITIONAL_CONTENT` (default `additional-deck-content/`) exists at the repo root and contains `*.html` files:
   - Copy each file into the HTML deck's `slides/` directory, preserving order (sort by filename).
   - Prefix copied filenames so they sort after the generated slides (e.g. `99-<original-name>.html`).
   - Do not modify their contents beyond adding the standard Slalom footer if it is missing.
   - Copied slides do not count toward `--max-slides`; the cap governs only the 10 generated slides.
   If the folder is absent or empty, skip this step silently and note it in the completion report. If `FORMAT=marp`, skip this step entirely.

8. **Build and QA.**
   - **HTML** (`FORMAT` includes html): run the slalom build and gates:

     ```bash
     node ".shared/slalom-html-slide-decks/scripts/build-deck.js" "$OUT/<YYYY-MM-DD>-team-rabbit-mode-yugastore"
     ```

     Then run the local gates from `slalom-html-slide-decks` (Storyline, Messaging, Visual Meaning System, Style Lens, Final Handoff) and fill `source/visual-qa-ledger.md`.
   - **Marp** (`FORMAT` includes marp): render `deck.md` using the command written into the deck's `README.md` at setup time. Walk every slide in the browser to confirm no content overflows the slide box, then fill `source/visual-qa-ledger.md`.

## Completion Report

Return in this order:

1. Deck package path(s) — one per requested format.
2. Resolved inputs (`FORMAT`, `MAX_SLIDES`, `SINCE`, `OUT`, `OUT_MARP`, `STYLE_LENS`, `ADDITIONAL_CONTENT`, `AUDIENCE`).
3. Effective slide list (numbered) and which slides (if any) were dropped by `--max-slides`.
4. Slide count per package (generated + copied from `additional-deck-content/` for HTML).
5. Compact deck language sentence (story frame, structure family, density, rhythm, visual treatment) and — for HTML — the applied style lens.
6. Git recap numbers used on the "Progress at a glance" and "Where we worked" slides — so the user can spot-check them.
7. Status of build/QA per format: slalom local gates and open items in `source/visual-qa-ledger.md` (HTML); render command success and overflow findings (Marp).

## Guardrails

- Do not fabricate git numbers, commit messages, contributor breakdowns, or skill descriptions. If a data source is missing, say so on the slide rather than making something up.
- Do not add flavor text, eyebrows, kickers, metaphors, or motivational closers. See Content Style above.
- Do not headline slides with counts or list decorative aggregates (see Content Style).
- Do not create either deck package by hand — always invoke `slalom-html-slide-decks`'s `setup-deck.js` or `setup-deck-marp.js` so the copied `support/` primitives, starter styles, and Marp theme wiring land correctly.
- Do not edit application code or spec artifacts from this skill. It writes only to the deck package(s) under `$OUT/` and `$OUT_MARP/`.
- Do not push the deck, open a PR, or delete anything from `additional-deck-content/`.
- Do not silently exceed `--max-slides` by squeezing dropped content into other slides. The drop is intentional and must be reported.
