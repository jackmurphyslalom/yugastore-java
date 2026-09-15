# Marp Slide Decks

This directory is the canonical location for Marp slide decks that summarize significant
repo history (decisions, ADRs, specs) for demos, retros, or stakeholder updates.

No prior Marp knowledge is required. Read this page top to bottom and you can author and
render a deck.

## What is Marp?

[Marp](https://marp.app/) turns a single Markdown file into a slide deck. Slides are plain
Markdown, separated by `---`, with a small front-matter block at the top that tells Marp
this file is a deck.

## Authoring a new deck

1. Create a new file directly under `docs/slides/`, e.g. `docs/slides/my-deck.md`.
2. Start the file with Marp front matter:

   ```markdown
   ---
   marp: true
   theme: slalom
   paginate: true
   ---
   ```

   - `marp: true` — required; tells the Marp CLI to treat this file as a deck.
   - `theme` — `slalom` (this repo's branded theme, see below), a built-in theme name
     (`default`, `gaia`, `uncover`), or another custom one.
   - `paginate: true` — shows slide numbers; optional but recommended.

3. Write your first slide as normal Markdown (heading, bullets, etc.) right after the front
   matter.
4. Add more slides by separating each one with a line containing only `---`:

   ```markdown
   # Slide one title

   - point one
   - point two

   ---

   # Slide two title

   More content here.
   ```

5. Base each slide's content on the decision, ADR, or spec you're summarizing — write it by
   hand. See [Content is hand-authored, not generated](#content-is-hand-authored-not-generated)
   below.

## The `slalom` theme

[docs/slides/themes/slalom.css](themes/slalom.css) is a custom Marp theme built on Marp's
`default` theme, using brand colors and the wordmark extracted from the Slalom Slide Master
Deck (May 2026) PowerPoint theme:

- Brand colors as CSS custom properties (`--slalom-blue`, `--slalom-blue-dark`, etc.), applied
  to headings and links.
- The Slalom logo rendered in the bottom-right corner of every slide, embedded as a base64
  data URI so exported decks remain self-contained (a plain relative file path breaks once Marp
  inlines the theme into a single portable HTML/PDF file placed elsewhere).
- A `lead` slide class (`<!-- _class: lead -->`) with a solid brand-blue background and white
  text, for title/section-break slides.

The source logo asset lives at [docs/slides/assets/slalom-logo.svg](assets/slalom-logo.svg).
Use `theme: slalom` in a deck's front matter and pass `--theme-set docs/slides/themes/slalom.css`
to every `marp-cli` invocation (rendering and exporting) — see below.

## Rendering a deck

No repo-level Node.js setup or `package.json` is required. Render any deck on demand with:

```bash
npx @marp-team/marp-cli docs/slides/<your-deck>.md --theme-set docs/slides/themes/slalom.css -o /tmp/<your-deck>.html
```

The first run downloads the Marp CLI via `npx`; later runs reuse `npx`'s local cache. Open the
generated `.html` file in a browser to view the deck. Omit `--theme-set` if a deck doesn't use
the `slalom` theme.

## Content is hand-authored, not generated

Deck content — including the sample deck in this directory — is written and curated by hand
from existing docs (`docs/decisions/`, `docs/architecture/adr/`, specs, etc.). Automatically
generating slides from git history or diffs is explicitly out of scope for this convention.
Keeping a deck in sync with later changes to the material it summarizes is a manual authoring
responsibility, not something this tooling automates.

## Exporting decks

To share a deck with people who don't run Marp tooling themselves, export it to a static PDF
or HTML file. Both are manual, on-demand commands — there is no Maven plugin, npm script, or
CI wiring for exports:

```bash
npx @marp-team/marp-cli docs/slides/<deck>.md --theme-set docs/slides/themes/slalom.css --pdf
npx @marp-team/marp-cli docs/slides/<deck>.md --theme-set docs/slides/themes/slalom.css --html
```

Each command produces a file (`<deck>.pdf` or `<deck>.html`) alongside the source Markdown.
Use `-o <path>` (as shown in [Rendering a deck](#rendering-a-deck)) to write the export
somewhere else instead.
