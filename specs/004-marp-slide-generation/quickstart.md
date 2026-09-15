# Quickstart: Validating Marp Slide Generation

Use this guide to prove the feature works end-to-end. No build step, install, or CI job is
required — everything runs through `npx` on demand.

## Prerequisites

- Node.js installed locally (provides `npx`); no repo-level Node setup or `package.json` needed.
- Internet access on first run so `npx` can fetch `@marp-team/marp-cli` (subsequent runs may use
  npx's local cache).

## Scenario 1: Render the sample deck (User Story 2 / SC-002)

```bash
npx @marp-team/marp-cli docs/slides/ai-sdlc-bootstrap-overview.md --theme-set docs/slides/themes/slalom.css -o /tmp/ai-sdlc-bootstrap-overview.html
```

**Expected outcome**: Command completes without error; the generated HTML, when opened, shows one
slide/section per each of the 12 themes listed in [spec.md](./spec.md#functional-requirements)
FR-004. Cross-check against the theme list — no theme should require consulting git history to
understand.

## Scenario 2: Author and render a new deck (User Story 1 / SC-001)

1. Follow `docs/slides/README.md` to create `docs/slides/<your-deck>.md` with Marp front matter
   and at least two slides.
2. Render it:

   ```bash
   npx @marp-team/marp-cli docs/slides/<your-deck>.md -o /tmp/<your-deck>.html
   ```

   Add `--theme-set docs/slides/themes/slalom.css` if the deck's front matter sets `theme: slalom`.

**Expected outcome**: A contributor with no prior Marp experience can go from a blank file to a
viewable deck in under 5 minutes using only `docs/slides/README.md` and this command.

## Scenario 3: Export to PDF and HTML (User Story 3 / SC-003)

```bash
npx @marp-team/marp-cli docs/slides/ai-sdlc-bootstrap-overview.md --theme-set docs/slides/themes/slalom.css --pdf
npx @marp-team/marp-cli docs/slides/ai-sdlc-bootstrap-overview.md --theme-set docs/slides/themes/slalom.css --html
```

**Expected outcome**: A `.pdf` and a `.html` file are produced alongside the source Markdown
(or at the `-o` path if specified), with no manual troubleshooting beyond the documented commands.

## Validation checklist

- [X] Scenario 1 renders without error and shows all 12 themes as distinct slides/sections.
- [X] Scenario 2 is completable by following only `docs/slides/README.md`.
- [X] Scenario 3 produces both a PDF and an HTML export.
- [X] `docs/slides/README.md` explicitly states deck content is hand-authored, not auto-generated
      from git history/diffs (FR-005 / spec Edge Cases).

See [data-model.md](./data-model.md) for the Slide Deck / Deck Export file conventions and
[research.md](./research.md) for the tooling decisions behind these commands.
