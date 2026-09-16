---
name: slalom-html-slide-decks
description: Create portable Slalom-branded slide decks in either browser-native HTML (live index files, reusable visual primitives, Playwright QA) or Marp Markdown (single deck.md rendered via @marp-team/marp-cli, styled by the shared Slalom Marp theme). Use when the agent is asked to generate, iterate, screenshot, QA, or package a webpage/HTML deck, Marp deck, scrollytelling deck, or slide-like web experience that should follow Slalom branding or Slalom PowerPoint template cues. Do not use for native PowerPoint, Google Slides, or Keynote decks unless the user explicitly wants an HTML or Marp implementation.
license: MIT
---

# Slalom HTML Slide Decks

This is the canonical skill body. Agent-specific wrappers (`.codex/SKILL.md`, `.agents/skills/slalom-html-slide-decks/SKILL.md`) delegate here. Scripts, references, and starter assets live alongside this file under `.shared/slalom-html-slide-decks/`.

## Core Contract
Build a portable deck folder. Two output formats are supported and share the same Slalom brand rules:

- **HTML** (default): the user opens top-level `index.html` and sees the live deck. `review.html` exposes the live slide DOM for annotation. `renders/` holds QA/export evidence.
- **Marp**: a single `deck.md` Marp source that renders to `deck.html`/`deck.pdf` via `@marp-team/marp-cli`, styled by the shared Slalom Marp theme at `docs/slides/themes/slalom.css`.

Choose HTML when the deck needs custom visual composition, per-slide layout primitives, or Playwright-driven visual QA. Choose Marp when the deck is markdown-authored, benefits from a single-file source, or needs quick PDF export. Both formats obey the same `references/slalom-brand-reference.md` rules and require the standard Slalom footer copyright on internal slides.

Use `references/slalom-brand-reference.md`, `references/design-language/`, `references/html-deck-requirements.md`, and the packaged support files copied from `assets/slalom-html-deck-starter/`.

If the work includes net-new messaging, a major rewrite, client-facing executive framing, proposal/orals structure, slide-job design, or visual-story decisions, use a storytelling handoff first and consume its production handoff. Do not route through storytelling for isolated formatting, layout, or copy-position edits.

## Package Setup
1. Locate the user's project folder. Use the current working directory unless the user names another folder.
2. Set `SKILL_DIR` to `.shared/slalom-html-slide-decks/` (the folder containing this `SKILL.md`, resolved from the repo root).
3. Choose output placement:
   - Use an explicit user folder when provided.
   - Otherwise follow a clear project artifact/output convention when one exists.
   - Otherwise create `outputs/<YYYY-MM-DD>-<deck-slug>/` for HTML and `outputs-marp/<YYYY-MM-DD>-<deck-slug>/` for Marp.
   - Ask if two plausible destinations would matter to the user.
4. Create the deck package. Pick the setup script that matches the requested format:

```bash
# HTML deck (default)
node "$SKILL_DIR/scripts/setup-deck.js" --title "Deck Title" --out ./outputs

# Marp deck
node "$SKILL_DIR/scripts/setup-deck-marp.js" --title "Deck Title" --out ./outputs-marp
```

`setup-deck-marp.js` resolves the Slalom Marp theme in this order: `--theme=<path>` when provided, then repo-local `docs/slides/themes/slalom.css`, then `assets/marp/slalom.css` under the skill. If none resolve, it warns and falls back to Marp's default theme.

The HTML package shape is:

```text
<deck-slug>/
├── index.html
├── review.html
├── deck.css
├── slides/
├── assets/
├── renders/
├── source/
└── support/
```

The Marp package shape is:

```text
<deck-slug>/
├── deck.md
├── README.md
└── source/
    ├── README.md
    ├── story-brief.md
    └── visual-qa-ledger.md
```

Agents edit `slides/*.html` and `deck.css` (HTML) or `deck.md` (Marp). For HTML, `support/` is copied for portability; do not depend on `.shared/slalom-html-slide-decks/...` or `.agents/skills/...` at runtime. For Marp, the theme is referenced by relative path from the deck folder; keep the deck and theme in the same repo or vendor the theme alongside `deck.md`.

## Design Workflow
1. If a storytelling handoff exists, read `source/story-brief.md` and `source/visual-system.md`; otherwise derive a compact Storyline Gate before authoring.
2. Read only the needed parts of `references/slalom-brand-reference.md` and `references/design-language/content-intents.md`.
3. If audience, purpose, deck type, source density, or recurring concepts are missing and would change the story or visual meaning system, ask 1-3 pointed questions.
4. State the compact deck language in one sentence: story frame, structure family, density, rhythm, and visual treatment.
5. Consult `visual-moves.md` and `thumbnail-index.md` only for relevant intents; thumbnails are inspiration and critique material, not exact layout recipes.
6. Draft slides before optional deep research. Visual form should encode sequence, contrast, hierarchy, system relationships, priority, rhythm, or emotion.
7. Run `design-critique.md` before final delivery.

## Reference Routing

Always read `references/slalom-brand-reference.md` for brand rules and `references/design-language/content-intents.md` for slide jobs. Read `references/slalom-deck-brandkit/README.md` when the user asks for visual refinement, more design energy, less generic output, minimalist/executive style, solution-oriented style, high-energy HTML, tactical/operational style, redesign, refresh, or audit.

When using `slalom-deck-brandkit/`, choose at most one primary style lens unless the user explicitly asks to compare directions. State the selected lens, any design dials, and the compact deck language before authoring. The style lens is a presentation mode; Slalom brand rules remain authoritative.

In final QA, mention whether the chosen lens changed layout, hierarchy, density, motion, or visual rhythm. If it did not materially change the output, revise before calling the deck ready.

Local gates:

- Storyline Gate: each slide has one job, one claim, support, and visual mode.
- Messaging Gate: governing frame, executive-risk language, source-grounding, human agency, and client-facing caveats are checked.
- Visual Meaning System Gate: recurring concepts keep stable labels, colors, lanes, breadcrumbs, icons, hierarchy, or other tokens without forcing samey layouts.
- Style Lens Gate: requested visual modes are routed through `slalom-deck-brandkit/`, applied visibly, and kept subordinate to Slalom brand rules. For high-energy/high-visual-variety requests, no layout primitive (card grid, table) repeats on adjacent slides or appears more than twice; each slide's form is chosen from its job while keeping the deck's stable visual tokens.
- Final Handoff Gate: live deck, review page, renders, structural QA, and manual visual QA status are named.

## Artifact Fast Path
- Use `setup-deck.js`, then write or replace `slides/*.html` and `deck.css`.
- Prefer 5-7 strong slides for an initial deck.
- Keep `slides/` non-empty while authoring.
- Use copied support CSS and primitives before writing deck-specific replacements.
- Build/QA the package before presenting it as ready.

## Authoring Guardrails
- Make the live deck the first screen. Do not create a marketing landing page around it.
- Keep headlines concise and outcome-oriented.
- Use Slalom Blue as the anchor. Pair it with at most one secondary color family unless using the official color bar.
- Use `.color-bar` in Slalom Blue, Cyan, Coral Red, Purple, Chartreuse order.
- For covers, start from the PowerPoint template geometry in `slalom-brand-reference.md`.
- Use approved logos/assets when supplied. Do not redraw Slalom marks, fake partner lockups, or invent sub-brand marks.
- Keep text in real HTML. Avoid baking editable text into images.
- Prefer support primitives for common structures. Vary scale, orientation, count, density, emphasis, annotations, and placement.
- Avoid nested cards and generic app chrome unless the slide content requires them.

## Build And QA

### HTML

Build the live `index.html`, render QA screenshots, generate a contact sheet, and run checks:

```bash
node "$SKILL_DIR/scripts/build-deck.js" ./outputs/YYYY-MM-DD-deck-slug
```

`build-deck.js` operates on the deck package. It assembles `index.html` from `slides/*.html`, writes `review.html` for DOM-level review, screenshots each slide into `renders/`, checks dimensions, missing assets, footer text, page errors, obvious clipping/overflow, writes `renders/contact-sheet.png` and `renders/contact-sheet-detailed.png`, and creates or extends `source/visual-qa-ledger.md`.

For preflight without writing deck artifacts:

```bash
node "$SKILL_DIR/scripts/build-deck.js" --doctor ./outputs/YYYY-MM-DD-deck-slug
```

Open the live top-level `index.html`, `review.html`, the contact sheet, and full-size changed/dense slide renders. Structural QA is not enough: check title scale, spacing, overcrowding, repeated geometry, semantic overlap, hierarchy, and whether important visuals actually explain the point. Fill `source/visual-qa-ledger.md`; the generated ledger skeleton is not a completed visual QA pass.

Fresh-eye semantic visual QA is mandatory for substantial/new client-facing decks, major visual rebuilds, and any deck where the reviewer has already caught a visual miss. Use `references/visual-qa-reviewer.md` for the reviewer prompt. It is optional for tiny formatting edits.

If Playwright's managed browser is missing, run `npx playwright install chromium`. If Chromium fails on macOS with sandbox or crash errors, rerun the exact build command with escalated approval instead of changing slide code.

### Marp

Marp has no Playwright-driven build step. Render the deck directly with the Slalom theme:

```bash
cd ./outputs-marp/YYYY-MM-DD-deck-slug
# Command shape is written into the deck's README.md at setup time.
npx @marp-team/marp-cli deck.md --theme-set "<relative-path-to>/docs/slides/themes/slalom.css" -o deck.html
```

For PDF export add `--pdf --allow-local-files`. First run downloads the Marp CLI via `npx`; later runs reuse the cache.

Manual QA for Marp decks: open `deck.html` in a browser, walk every slide, and confirm each slide's headline, body, and any table fits within the slide box without clipping. Marp does not auto-shrink content — overflowing slides must be shortened, split, or restructured. Record findings in `source/visual-qa-ledger.md`.

Every generated internal slide must include `Copyright [year] Slalom. All Rights Reserved. Proprietary and Confidential.` unless the user explicitly requests a public/non-confidential variant.
