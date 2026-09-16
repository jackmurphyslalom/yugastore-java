# Style Lens: High-Energy HTML

Use this lens when the user wants an HTML-native presentation with more visual energy than a standard slide deck.

Best for:

- HTML microsite-style decks
- visual explainers
- demos and interactive narratives
- high-energy pursuit leave-behinds
- scrollytelling-lite experiences

## Design Read

This lens reads as a polished Slalom HTML presentation: bolder section rhythm, stronger visual sequencing, and light motion or interaction where it helps the message.

## Visual Rules

- Keep the slide deck as the primary experience. Do not add a marketing landing page around it.
- Use stronger reset slides to create chapter rhythm.
- Use scale shifts: one sparse claim slide, one dense proof slide, one visual synthesis slide.
- Consider subtle motion only when it clarifies sequence, reveal, or focus.
- Keep motion restrained and presentation-safe.
- Use full-bleed or image-led moments only when approved assets or generated neutral visuals are appropriate.

## HTML-Native Moves

- staged reveal across a lifecycle path
- scroll or keyboard sequence that builds a model step-by-step
- animated emphasis line or highlighted path
- chapter reset with dark blue field
- contact-sheet-like evidence board
- side-by-side comparison with progressive highlight

## Motion Rules

- Animate transform and opacity only.
- Avoid continuous busy loops.
- Respect `prefers-reduced-motion` when custom motion is added.
- Do not animate critical text into unreadability.
- Do not use motion to compensate for weak structure.

## Primitive Variety

High energy fails when every slide is the same card grid or table with different text. Keep the semantic rigor (one job, one claim, stable visual tokens) but force structural variety:

- Do not repeat the same primitive (equal-card grid, three-column cards, generic table) on back-to-back slides, and use any single primitive at most twice in the deck.
- For each slide, pick the form from the slide's job, not from the previous slide: sequence rail, lane/swimlane, matrix, annotated diagram, comparison split, proof strip, hub-and-spoke, before/after, or a full-bleed statement. Reach for cards/tables only when the content is genuinely a flat set or a true row/column grid.
- Vary the structural axis between adjacent slides: scale (sparse vs dense), orientation (horizontal flow vs vertical stack vs radial), and anchor (text-led vs diagram-led vs evidence-led).
- If two slides would otherwise share a layout, change the one whose claim is better served by a different encoding, or merge them.

This is a structural-variety rule, not a decoration rule. Variety must come from the slide's job, never from restyling the same box.

## Avoid

- repeated card-grid or table primitives used as the default layout instead of a job-fit visual
- floating web navs, pill CTAs, pricing-page tropes, or SaaS landing-page sections
- custom mouse cursors
- decorative mesh gradients
- generic "AI" hero visuals
- motion-heavy effects that make renders or review pages unstable
- fake browser/app chrome unless the slide explains a digital experience

## QA

Before finalizing, ask:

- Does the HTML-native treatment clarify the story?
- Is any layout primitive (card grid, table) repeated on adjacent slides or used more than twice? If so, rework it into a job-fit visual.
- Does the deck still render clean static slide images?
- Is motion optional rather than required to understand the content?
- Did the stronger energy stay inside Slalom brand rules?

