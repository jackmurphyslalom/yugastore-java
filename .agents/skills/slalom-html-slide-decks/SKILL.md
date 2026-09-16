---
name: slalom-html-slide-decks
description: Create portable Slalom-branded browser-native HTML deck packages with live index files, Slalom brand guardrails, design-language references, reusable visual primitives, and Playwright QA rendering. Use when the user asks to generate, iterate, screenshot, QA, or package a webpage slide deck, HTML presentation, scrollytelling deck, or slide-like web experience that should follow Slalom branding or Slalom PowerPoint template cues. Do not use for native PowerPoint, Google Slides, Keynote, or PDF decks unless the user explicitly wants an HTML implementation.
license: MIT
---

# Slalom HTML Slide Decks (Copilot Wrapper)

The canonical skill body, scripts, references, and starter assets live at `.shared/slalom-html-slide-decks/`. Follow `.shared/slalom-html-slide-decks/SKILL.md` for all workflow steps, gates, and guardrails.

## Resolving Paths

When the canonical body refers to `SKILL_DIR`, `references/`, or `assets/`, resolve them under `.shared/slalom-html-slide-decks/` (relative to the repo root), not under this wrapper directory.

Concretely:

- Scripts: `.shared/slalom-html-slide-decks/scripts/setup-deck.js`, `build-deck.js`, `render.js`, `visual-qa.js`
- References: `.shared/slalom-html-slide-decks/references/slalom-brand-reference.md`, `.shared/slalom-html-slide-decks/references/design-language/`, `.shared/slalom-html-slide-decks/references/html-deck-requirements.md`, `.shared/slalom-html-slide-decks/references/visual-qa-reviewer.md`, `.shared/slalom-html-slide-decks/references/slalom-deck-brandkit/`
- Starter assets copied into each deck package: `.shared/slalom-html-slide-decks/assets/slalom-html-deck-starter/`

## Typical Invocations

```bash
node ".shared/slalom-html-slide-decks/scripts/setup-deck.js" --title "Deck Title" --out ./outputs
node ".shared/slalom-html-slide-decks/scripts/build-deck.js" ./outputs/YYYY-MM-DD-deck-slug
node ".shared/slalom-html-slide-decks/scripts/build-deck.js" --doctor ./outputs/YYYY-MM-DD-deck-slug
```

## Copilot Notes

- This skill is exposed to Copilot users via `/slalom-html-slide-decks` (see `.github/prompts/slalom-html-slide-decks.prompt.md`).
- The user-facing prompt accepts free-text `$ARGUMENTS` describing deck title, audience, output folder, and brief.
- Prefer VS Code editing tools (`create_file`, `replace_string_in_file`) when writing `slides/*.html`, `deck.css`, and files under `source/`. Only shell out to the Node scripts above for setup, build, and QA passes.
- Playwright + Chromium may prompt for permission on macOS. If build renders fail with sandbox errors, ask the user to approve and rerun the same `build-deck.js` invocation instead of editing slides to work around it.
