---
name: slalom-html-slide-decks
description: Create portable Slalom-branded browser-native HTML deck packages with live index files, Slalom brand guardrails, design-language references, reusable visual primitives, and Playwright QA rendering. Use when the agent is asked to generate, iterate, screenshot, QA, or package a webpage slide deck, HTML presentation, scrollytelling deck, or slide-like web experience that should follow Slalom branding or Slalom PowerPoint template cues. Do not use for native PowerPoint, Google Slides, Keynote, or PDF decks unless the user explicitly wants an HTML implementation.
license: MIT
---

# Slalom HTML Slide Decks

This is the canonical skill body. Agent-specific wrappers (`.codex/SKILL.md`, `.agents/skills/slalom-html-slide-decks/SKILL.md`) delegate here. Scripts, references, and starter assets live alongside this file under `.shared/slalom-html-slide-decks/`.

## Core Contract
Build a portable deck folder. The user opens top-level `index.html` and sees the live HTML deck. `review.html` exposes the live slide DOM for annotation/review. `renders/` exists only for QA/export evidence.

Use `references/slalom-brand-reference.md`, `references/design-language/`, `references/html-deck-requirements.md`, and the packaged support files copied from `assets/slalom-html-deck-starter/`.

If the work includes net-new messaging, a major rewrite, client-facing executive framing, proposal/orals structure, slide-job design, or visual-story decisions, use a storytelling handoff first and consume its production handoff. Do not route through storytelling for isolated formatting, layout, or copy-position edits.

## Package Setup
1. Locate the user's project folder. Use the current working directory unless the user names another folder.
2. Set `SKILL_DIR` to `.shared/slalom-html-slide-decks/` (the folder containing this `SKILL.md`, resolved from the repo root).
3. Choose output placement:
   - Use an explicit user folder when provided.
   - Otherwise follow a clear project artifact/output convention when one exists.
   - Otherwise create `outputs/<YYYY-MM-DD>-<deck-slug>/`.
   - Ask if two plausible destinations would matter to the user.
4. Create the deck package:

```bash
node "$SKILL_DIR/scripts/setup-deck.js" --title "Deck Title" --out ./outputs
```

The package shape is:

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

Agents edit `slides/*.html` and `deck.css`. `support/` is copied for portability; do not depend on `.shared/slalom-html-slide-decks/...` or `.agents/skills/...` at runtime.

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

Every generated internal slide must include `Copyright [year] Slalom. All Rights Reserved. Proprietary and Confidential.` unless the user explicitly requests a public/non-confidential variant.
