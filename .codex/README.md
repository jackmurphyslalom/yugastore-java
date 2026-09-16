# Slalom HTML Slide Decks Skill

This repository contains a Codex skill for creating Slalom-branded slide decks as editable HTML packages. The output is a browser-native deck that opens from `index.html`, with rendered screenshots and QA artifacts for review.

This is not a PowerPoint template. It is for teams who want Codex to generate, refine, render, and package webpage-based slide decks that follow Slalom presentation cues.

## What It Creates

When Codex uses this skill, it creates a portable deck package like this:

```text
my-deck/
├── index.html
├── review.html
├── deck.css
├── slides/
├── assets/
├── renders/
├── source/
└── support/
```

What each part is for:

- `index.html` is the live deck you present or review in a browser.
- `review.html` shows all slides as live HTML for easier review and annotation.
- `slides/` contains one editable HTML file per slide.
- `deck.css` contains deck-specific styling.
- `assets/` is for project-specific images, logos, data, or other deck files.
- `renders/` contains generated PNG screenshots, contact sheets, and render evidence.
- `source/` stores the story brief, visual system notes, source notes, and visual QA ledger.
- `support/` contains copied skill support files so the deck package can travel without depending on the skill folder.

In short: the skill is the reusable tool; each deck package is the working deck.

## What The Skill Helps With

- Slalom-branded HTML decks with editable text and source files.
- Starter slides and reusable visual primitives.
- Slalom color, typography, logo, footer, and partner/client asset guardrails.
- Design-language guidance for different slide jobs, such as framing, comparing, sequencing, explaining systems, and storytelling.
- Optional style lenses for executive, solution-oriented, tactical, high-energy, or redesign/audit use cases.
- Browser rendering with Playwright.
- QA outputs including PNG renders, contact sheets, review pages, and a visual QA ledger.

## Install The Skill

### Option 1: Ask Codex To Install It

Ask Codex:

```text
Install the Slalom HTML slide decks skill from https://github.com/Slalom/slalom-html-slide-decks.git
```

Codex should copy the skill into your local Codex skills folder.

### Option 2: Install It Manually On Mac

Clone or download this repository, then place the folder here:

```text
~/.codex/skills/slalom-html-slide-decks
```

The final folder should look like this:

```text
~/.codex/skills/slalom-html-slide-decks/SKILL.md
~/.codex/skills/slalom-html-slide-decks/assets/
~/.codex/skills/slalom-html-slide-decks/references/
~/.codex/skills/slalom-html-slide-decks/scripts/
```

### Option 3: Install It Manually On Windows

Clone or download this repository, then place the folder here:

```text
%USERPROFILE%\.codex\skills\slalom-html-slide-decks
```

Make sure `SKILL.md` is directly inside the `slalom-html-slide-decks` folder.

## How To Ask Codex To Use It

Examples:

```text
Use the Slalom HTML slide decks skill to create a 6-slide client-facing deck about our Salesforce implementation plan.
```

```text
Create a Slalom-branded HTML deck for an executive readout. Make it concise, visual, and suitable for client leadership.
```

```text
Refresh this generated deck with more visual energy and run QA.
```

Codex will choose a deck package location. If you care where the deck should be saved, say so:

```text
Create the deck in /Users/me/Documents/ClientDecks.
```

## Typical Workflow

You usually do not need to run commands yourself. Codex should handle these steps.

1. Codex creates a deck package.
2. Codex writes or updates slide HTML files in `slides/`.
3. Codex edits `deck.css` for deck-specific visual treatment.
4. Codex builds the live deck and review page.
5. Codex renders PNG screenshots into `renders/`.
6. Codex checks the output and records visual QA notes.
7. You open `index.html` or `review.html` to inspect the result.

## Useful Commands

Create a new deck package:

```bash
node /path/to/slalom-html-slide-decks/scripts/setup-deck.js --title "Deck Title" --out ./outputs
```

Build and QA a deck package:

```bash
node /path/to/slalom-html-slide-decks/scripts/build-deck.js ./outputs/YYYY-MM-DD-deck-title
```

Run a setup check without writing build artifacts:

```bash
node /path/to/slalom-html-slide-decks/scripts/build-deck.js --doctor ./outputs/YYYY-MM-DD-deck-title
```

The build step creates or updates:

- `index.html`
- `review.html`
- `renders/*.png`
- `renders/contact-sheet.png`
- `renders/contact-sheet-detailed.png`
- `source/visual-qa-ledger.md`

## How To Review A Deck

Open these files in a browser:

- `index.html` for the live slide deck.
- `review.html` for a scrollable review page with every slide visible.
- `renders/contact-sheet.png` for a quick thumbnail view.
- `renders/contact-sheet-detailed.png` for a larger visual QA view.

For real review, do not rely only on automated checks. Look for:

- unclear slide purpose
- crowded content
- repeated layouts that feel generic
- text that overlaps or feels too small
- visuals that decorate rather than explain
- missing or incorrect footer text
- brand or logo issues

The generated `source/visual-qa-ledger.md` is a starting checklist. It still needs a human or Codex reviewer to fill it in.

## Playwright And Rendering

The skill uses Playwright to render browser screenshots.

If Playwright is missing, install it in the project or use the Codex bundled runtime.

If Playwright exists but Chromium is missing, run:

```bash
npx playwright install chromium
```

On some Macs, Chromium may need permission to run outside the Codex sandbox. If Codex asks for approval to render with Playwright or Chromium, approve it when you are ready to generate screenshots.

## Brand And Asset Rules

- Use Slalom Blue as the anchor color.
- Use the Slalom color bar only in the approved order.
- Use approved Slalom logos and brand assets.
- Do not redraw, recolor, distort, or recreate the Slalom logo.
- Do not create fake partner logos, alliance marks, or sub-brand lockups.
- Use supplied client or partner logos only when they are approved for the deck.
- If an approved logo is missing, use a neutral placeholder and ask for the asset.
- Internal slides should include `Copyright [year] Slalom. All Rights Reserved. Proprietary and Confidential.` unless a public/non-confidential version is requested.

## Design Guidance Included

The skill includes references that Codex can use when the deck needs more than a basic layout:

- `references/design-language/content-intents.md` helps decide what each slide is trying to do.
- `references/design-language/visual-moves.md` suggests visual treatments for different slide jobs.
- `references/design-language/design-critique.md` guides final visual review.
- `references/slalom-deck-brandkit/` provides optional style lenses for stronger visual direction.
- `references/slalom-brand-reference.md` remains the authority for Slalom brand rules.

The style lenses are optional. They help with requests like:

- make it more executive
- make it more solution-oriented
- make it more high-energy
- make it more tactical or operational
- audit or redesign this deck

They do not replace Slalom brand rules.

## Updating The Skill

Use this repository as the source of truth.

Recommended update flow:

1. Pull the latest repository version.
2. Update files in this repository.
3. Validate the skill.
4. Sync the updated skill into your local Codex skills folder.
5. Commit and push the repository changes.

Validation command:

```bash
python3 /path/to/quick_validate.py /path/to/slalom-html-slide-decks
```

You can also ask Codex:

```text
Update the Slalom HTML slide decks skill, validate it, sync it to my installed skills folder, and push the repo changes.
```

## What This Skill Is Not

This skill does not create native `.pptx` files. It creates HTML decks and browser-rendered QA/export images.

If you need a native PowerPoint deck, ask for a PowerPoint workflow separately.
