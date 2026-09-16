---
name: slalom-html-slide-decks
description: Create portable Slalom-branded browser-native HTML deck packages with live index files, Slalom brand guardrails, design-language references, reusable visual primitives, and Playwright QA rendering — or Marp Markdown decks styled by the shared Slalom Marp theme. Use when the user asks to generate, iterate, screenshot, QA, or package a webpage slide deck, HTML presentation, Marp deck, scrollytelling deck, or slide-like web experience that should follow Slalom branding or Slalom PowerPoint template cues. Do not use for native PowerPoint, Google Slides, or Keynote decks unless the user explicitly wants an HTML or Marp implementation.
license: MIT
---

# Slalom HTML Slide Decks (Copilot Wrapper)

The canonical skill body, scripts, references, and starter assets live at `.shared/slalom-html-slide-decks/`. Follow `.shared/slalom-html-slide-decks/SKILL.md` for all workflow steps, gates, and guardrails.

## Resolving Paths

When the canonical body refers to `SKILL_DIR`, `references/`, or `assets/`, resolve them under `.shared/slalom-html-slide-decks/` (relative to the repo root), not under this wrapper directory.

Concretely:

- Scripts: `.shared/slalom-html-slide-decks/scripts/setup-deck.js`, `setup-deck-marp.js`, `build-deck.js`, `render.js`, `visual-qa.js`
- References: `.shared/slalom-html-slide-decks/references/slalom-brand-reference.md`, `.shared/slalom-html-slide-decks/references/design-language/`, `.shared/slalom-html-slide-decks/references/html-deck-requirements.md`, `.shared/slalom-html-slide-decks/references/visual-qa-reviewer.md`, `.shared/slalom-html-slide-decks/references/slalom-deck-brandkit/`
- Starter assets copied into each HTML deck package: `.shared/slalom-html-slide-decks/assets/slalom-html-deck-starter/`
- Marp theme: repo-local `docs/slides/themes/slalom.css` (authoritative for this workspace)

## Typical Invocations

```bash
# HTML deck
node ".shared/slalom-html-slide-decks/scripts/setup-deck.js" --title "Deck Title" --out ./outputs
node ".shared/slalom-html-slide-decks/scripts/build-deck.js" ./outputs/YYYY-MM-DD-deck-slug
node ".shared/slalom-html-slide-decks/scripts/build-deck.js" --doctor ./outputs/YYYY-MM-DD-deck-slug

# Marp deck
node ".shared/slalom-html-slide-decks/scripts/setup-deck-marp.js" --title "Deck Title" --out ./outputs-marp
# Render command is written into the scaffolded README.md at setup time.
```

## Copilot Notes

- This skill is exposed to Copilot users via `/slalom-html-slide-decks` (see `.github/prompts/slalom-html-slide-decks.prompt.md`).
- The user-facing prompt accepts free-text `$ARGUMENTS` describing deck title, audience, output folder, and brief.
- Prefer VS Code editing tools (`create_file`, `replace_string_in_file`) when writing `slides/*.html`, `deck.css`, `deck.md`, and files under `source/`. Only shell out to the Node scripts above for setup, build, and QA passes.
- Playwright + Chromium may prompt for permission on macOS. If HTML build renders fail with sandbox errors, ask the user to approve and rerun the same `build-deck.js` invocation instead of editing slides to work around it.
- Marp rendering uses `npx @marp-team/marp-cli`; the first run downloads the CLI and later runs reuse the cache.
