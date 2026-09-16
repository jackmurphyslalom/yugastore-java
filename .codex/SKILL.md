---
name: slalom-html-slide-decks
description: Create portable Slalom-branded browser-native HTML deck packages with live index files, Slalom brand guardrails, design-language references, reusable visual primitives, and Playwright QA rendering. Use when Codex is asked to generate, iterate, screenshot, QA, or package a webpage slide deck, HTML presentation, scrollytelling deck, or slide-like web experience that should follow Slalom branding or Slalom PowerPoint template cues. Do not use for native PowerPoint, Google Slides, Keynote, or PDF decks unless the user explicitly wants an HTML implementation.
---

# Slalom HTML Slide Decks (Codex Wrapper)

The canonical skill body, scripts, references, and starter assets live at `.shared/slalom-html-slide-decks/`. Follow `.shared/slalom-html-slide-decks/SKILL.md` for all workflow steps, gates, and guardrails.

When the canonical body says to resolve `SKILL_DIR`, resolve it to `.shared/slalom-html-slide-decks/` (relative to the repo root), not this wrapper directory. Scripts are invoked as:

```bash
node ".shared/slalom-html-slide-decks/scripts/setup-deck.js" --title "Deck Title" --out ./outputs
node ".shared/slalom-html-slide-decks/scripts/build-deck.js" ./outputs/YYYY-MM-DD-deck-slug
```

References for brand, design language, and visual QA are under `.shared/slalom-html-slide-decks/references/`; the HTML deck starter is under `.shared/slalom-html-slide-decks/assets/slalom-html-deck-starter/`.
