# Slalom Deck Brandkit

Use this package when a deck needs stronger visual direction than the base brand reference and content-intent catalog provide.

This package is Slalom-native. It distills practical slide language from real local deck examples and high-quality design-review principles, but it does not create a second brand system.

## Authority Order

1. `../slalom-brand-reference.md` is authoritative for Slalom palette, typography, logo behavior, footer language, cover geometry, and approved asset handling.
2. `visual-world.md` and `pattern-gallery.md` distill practical visual grammar and slide patterns from real Slalom decks into reusable deck guidance.
3. `style-lenses/` are optional presentation modes for emphasis, not standalone brands.
4. Reference boards or contact sheets are inspiration and critique material only. They are not official brand assets.

When a lens and the brand reference conflict, follow the brand reference.

## When To Use

Read this package when the user asks for:

- more design energy or visual refinement
- less generic output
- a minimalist, executive, or editorial feel
- more solution-oriented or architecture-oriented slides
- a higher-energy HTML presentation, microsite, or scrollytelling feel
- a tactical, operational, risk, governance, or control-tower feel
- a redesign, refresh, audit, or critique of generated slides

Do not use this package for routine copy edits, small formatting fixes, or mechanical deck rebuilds unless the user is explicitly asking about visual quality.

## Workflow

1. Start with the slide's business job in `../design-language/content-intents.md`.
2. Choose one optional style lens from `style-lenses/` only if it fits the prompt.
3. State the selected lens and compact design language before authoring.
4. Choose visual moves from `../design-language/visual-moves.md` and `pattern-gallery.md`.
5. Build under the normal HTML deck package workflow.
6. During QA, state whether the lens actually changed layout, hierarchy, density, or motion.

## Lens Index

| User Intent | Lens |
|---|---|
| Sparse, leadership-ready, editorial, understated | `style-lenses/minimalist-executive.md` |
| Concrete solution, architecture, lifecycle, offering, operating model | `style-lenses/solution-oriented.md` |
| More visual energy, HTML-native, microsite, light motion, scrollytelling | `style-lenses/high-energy-html.md` |
| Delivery control, risk, governance, status, PMO, operating telemetry | `style-lenses/tactical-operational.md` |
| Existing deck refresh, less generic, quality audit, sameyness check | `style-lenses/redesign-audit.md` |
| Need to set variance, motion, or density explicitly | `style-lenses/design-dials.md` |

## Guardrails

- Do not invent Slalom logos, sub-brands, partner lockups, palettes, or fonts.
- Do not import web-app chrome into a slide deck unless the slide content requires a UI artifact.
- Do not use decorative fake dashboards, terminals, HUDs, status dots, mesh gradients, or AI imagery.
- Do not let a style lens weaken the story spine. Visual form should make the claim easier to understand.
- Do not treat real deck examples as templates to copy blindly. Extract the pattern, then adapt it to the new slide job.
