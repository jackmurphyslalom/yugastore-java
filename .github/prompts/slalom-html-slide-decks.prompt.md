---
description: Generate, iterate, or QA a Slalom-branded browser-native HTML slide deck package with live index, review page, Playwright renders, and visual QA notes.
---

## Deck Brief

```text
$ARGUMENTS
```

Interpret the block above as the deck brief. Extract (asking 1-3 pointed questions only if genuinely missing):

- **Title** — the deck's working title.
- **Audience & purpose** — who is reviewing it and what decision or outcome it drives.
- **Output folder** — where the deck package should be created; default to `outputs/<YYYY-MM-DD>-<deck-slug>/` when unspecified.
- **Content brief / sources** — key messages, structure, or source docs to draw from.
- **Style lens (optional)** — executive, solution-oriented, high-energy, tactical, redesign/audit.

Then follow `.agents/skills/slalom-html-slide-decks/SKILL.md`, which delegates to the canonical body at `.shared/slalom-html-slide-decks/SKILL.md`. Resolve `SKILL_DIR` to `.shared/slalom-html-slide-decks/` when invoking `setup-deck.js` or `build-deck.js`.

Deliverables to report back:

1. Path to the created deck package (`<out>/<YYYY-MM-DD>-<deck-slug>/`).
2. Confirmation that `index.html`, `review.html`, `slides/*.html`, `deck.css`, and `renders/contact-sheet.png` exist and were regenerated in the last build.
3. Compact deck language sentence (story frame, structure family, density, rhythm, visual treatment) and, if applicable, the chosen style lens.
4. State of the local gates: Storyline, Messaging, Visual Meaning System, Style Lens, Final Handoff.
5. Any unresolved items in `source/visual-qa-ledger.md` the user should look at in the live `index.html` / `review.html`.

Do not use this prompt for native PowerPoint, Google Slides, Keynote, or PDF decks unless the user explicitly wants an HTML implementation.
