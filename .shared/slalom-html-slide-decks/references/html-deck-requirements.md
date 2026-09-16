# HTML Deck Requirements

Use this reference for implementation and QA of Slalom-branded webpage slide decks.

## Deck Structure

- Make the deck the primary page experience.
- Use a 16:9 slide stage by default.
- Keep each slide as a semantic `<section class="slide">`.
- Add `aria-label` or clear headings so assistive technology can identify each slide.
- Keep content as HTML text wherever possible instead of baking text into images.
- Use CSS custom properties for brand tokens.

Deck package shape:

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

Users open top-level `index.html`. Agents edit `slides/*.html` and `deck.css`; `build-deck.js` assembles the live deck shell and `review.html`.

## Layout Patterns

Prefer a small set of reusable slide patterns:

- Cover: match the template cover grid before adding content. Use separate deck type and date lines, a large title block, optional body/subtitle, optional client or partner logo slot, a copyright footer, and the bottom five-segment color bar. Use `.template-cover`, `.template-cover.title-blue`, or `.template-cover.partner-cover` for supported cover variations. Avoid generic web-hero side panels on title slides.
- Title-only: use for section framing or a single decisive claim; navy variants are acceptable when the story needs a heavier divider moment.
- Contents/agenda: structured list with page/section markers.
- Section divider: large section number, short section name, strong color field or precise color bar.
- Headline + body: large headline, concise paragraphs or bullets, optional proof point.
- Four-column/icons: use only when the items are genuinely parallel; use approved Slalom icons when available or simple numeric marks as placeholders.
- Two-column comparison: mirrored structure with one clear contrast.
- Mixed media: pair a concise text block with an approved image, UI mock, diagram, or media placeholder using stable 16:9-safe geometry.
- Photo split: covers half-photo and third-photo layouts; use approved imagery or a clearly labeled placeholder until supplied.
- Metric or insight: one key number, short implication, supporting evidence.
- Process/timeline: 3 to 6 steps with consistent spacing.
- Chart slide: chart first, headline that states the insight, labels large enough to read.
- Table: use sparse rows and columns for comparison or decisions; avoid dense spreadsheet dumps.
- Client story/profile: use only with approved client/person details and imagery; for public stories, check the current Slalom Stories guidance.
- Closing: thank-you or next-step slide with contact/action details.
- Copyright/legal notice: use only when a standalone legal slide is requested; otherwise keep the copyright/confidentiality footer on every slide.

Important slides should encode meaning visually, not merely place text into boxes. Use visual form to show sequence, contrast, hierarchy, systems, priority, rhythm, or emotion. Reference `design-language/content-intents.md`, `visual-moves.md`, and `design-critique.md` when the deck needs richer visual communication.

## CSS Baseline

- Use `aspect-ratio: 16 / 9` for slides.
- Use `box-sizing: border-box` globally.
- Avoid viewport-width font scaling. Use fixed/rem sizes with responsive constraints.
- Define stable grid tracks and min/max constraints so text and controls do not reflow unpredictably.
- Avoid nested cards and marketing-style hero/card composition.
- Ensure contrast is readable for every text/color combination.

## Navigation

Implement at least:

- Previous/next controls.
- Keyboard support for ArrowLeft, ArrowRight, PageUp, PageDown, Home, and End.
- Progress indicator or slide count.
- URL hash updates or another shareable slide state when useful.

Scrolling decks can use scroll snap; click-through decks can hide inactive slides. Choose the pattern that best fits the user's requested delivery.

## Live Deck And Renders

The primary artifact is the live top-level `index.html`. It should show the actual HTML deck, not screenshots of slides.

The build step should also produce individual PNGs in `renders/`, `renders/contact-sheet.png`, and `renders/contact-sheet-detailed.png` for QA/export support. Renders are evidence and export material, not the main deck experience.

The live deck must support previous/next controls, keyboard navigation, a slide count, and URL hashes like `#slide-3`.

`review.html` must expose all slides as live HTML DOM, not screenshots. Use it for annotation, full-deck scan, and element-level review without changing the final deck experience.

## Visual QA

Before final delivery:

- Run the deck in a browser or app dev server.
- Open the live top-level `index.html`.
- Open `review.html` when annotation, full-deck scan, or element-level review matters.
- Inspect `renders/contact-sheet.png` after build.
- Inspect full-size changed, dense, text-heavy, or user-flagged slide PNGs. The contact sheet is a scan artifact, not final QA proof.
- Check all slides at desktop size, tablet-ish width, and mobile width.
- Verify no slide is blank.
- Verify text is not clipped, overlapping, or too small.
- Verify images and brand assets load.
- Verify navigation does not trap keyboard focus.
- Verify print CSS if printable output was requested.
- Verify every slide includes the copyright/footer text unless the user explicitly requested a public/non-confidential variant.
- Run the design critique for important slides: confirm visual form carries meaning and repeated primitives are varied intentionally.
- Fill `source/visual-qa-ledger.md` with manual findings. A generated ledger skeleton is not a completed visual QA pass.
- Use `references/visual-qa-reviewer.md` for fresh-eye semantic visual QA on substantial/new client-facing decks, major visual rebuilds, or user-caught visual misses.
- Run `node build-deck.js <deck-package>` for assembly, renders, contact sheets, review page, structural QA, and ledger skeleton.
- Run `node build-deck.js --doctor <deck-package>` for preflight checks before authoring or debugging.

## Accessibility

- Keep headings in logical order.
- Provide alt text for meaningful images.
- Treat decorative graphic lines, bars, and shapes as CSS backgrounds or `aria-hidden` elements.
- Do not rely on color alone to explain meaning.
- Support reduced-motion preferences if transitions or animations are added.
