# Slalom HTML Deck Design Refresh Plan

Date: 2026-05-29

## Intent

Improve the `slalom-html-slide-decks` skill so generated decks feel more distinctive, more visual, and more effective at conveying information. The current skill is brand-safe and operationally useful, but its default output can skew toward clean generic consulting slides: text blocks, simple columns, and restrained layouts. The refresh should add a stronger Slalom-native design grammar without turning the skill into a rigid template picker.

The target behavior is:

- Start from the slide or deck's business intent.
- Choose a cohesive deck-level design language.
- Use visual form to encode relationships, sequence, priority, contrast, systems, or movement.
- Use curated references as inspiration and critique material, not deterministic layout matches.
- Keep the skill package self-contained and shareable.

## Current Skill Context

The existing skill is a repo-local, self-contained HTML deck generator. It includes:

- `SKILL.md` for session workflow, brand workflow, authoring guardrails, rendering, and verification.
- `references/slalom-brand-reference.md` for palette, typography, logo rules, color bar behavior, iconography cautions, and PowerPoint template cues.
- `references/html-deck-requirements.md` for HTML deck structure, navigation, rendering, QA, and accessibility.
- `references/sources.md` for source provenance and refresh workflow.
- `assets/slalom-html-deck-starter/` for starter CSS, navigation, bundled logo asset, and starter slide layouts.
- `scripts/setup-deck.js`, `scripts/build-deck.js`, and `scripts/visual-qa.js` for package setup, live deck assembly, rendering, and QA.

The refresh should preserve that structure. It should deepen the design layer, not create a second competing deck system.

## Decisions Made

1. Use the large internal slide-reference source as **both inspiration and component input**, but inspiration comes first.
2. Do not map content types to fixed layouts. A comparison slide should not always look like the same comparison reference.
3. Organize the design reference layer primarily by **business/content intent**, with visual moves acting as the palette.
4. Default tactical brand choices to the existing Slalom brand contract: colors, fonts, logo behavior, footer language, sizing discipline, and approved asset rules.
5. Infer abstract design choices from context: density, structure family, visual rhythm, information shape, and polish level.
6. When context is missing, ask high-signal upfront questions rather than relying on a broad one-size-fits-all default.
7. Only ask when signal is missing and the answer would materially change the visual strategy.
8. Keep the packaged skill small, curated, derived, and self-contained.
9. Do not store the full source deck, a full-slide image archive, or local source paths in the packaged skill.
10. Store recognizable low-resolution reference thumbnail groups because the source material is already anonymized.
11. Use thumbnails for inspiration and critique, not direct copying or deterministic selection.
12. Integrate this into the existing `slalom-html-slide-decks` skill rather than creating a companion skill.

## Skill Design Principles

### Business Intent First

The skill should classify each slide by the job it needs to do before choosing a visual treatment. Useful intents include:

- Orient the audience.
- Make an executive claim.
- Compare options or states.
- Show a transformation path.
- Explain a system or ecosystem.
- Show sequence, workplan, or delivery rhythm.
- Prioritize capabilities or investments.
- Explain an operating model.
- Humanize a narrative through persona, quote, or story.
- Create a reset moment through a divider, visual cover, or background slide.

Visual moves should be available as choices within each intent, not as one-to-one templates.

### Deck-Level Cohesion

Each deck should establish a design language before individual slide production:

- Structure family: journey, layered system, modular blocks, ecosystem, evidence board, editorial narrative, or another context-fit family.
- Density level: executive-readable, working-session dense, sales-narrative polished, technical/detail-rich, or mixed.
- Visual rhythm: argument slides, reset slides, proof slides, and synthesis slides.
- Icon/illustration treatment: approved icons, abstract line diagrams, modular blocks, image-led moments, or minimal marks.

Brand details should remain governed by `slalom-brand-reference.md`. The refresh should not create alternate brand systems.

### Reference Use

Reference thumbnails should help future agents see composition, rhythm, density, and visual possibilities. They should not be used as exact slide recipes.

Every reference group should answer:

- What business/content intent does this support?
- What visual moves are visible?
- What information relationship is being encoded?
- What should be adapted versus avoided?

### Component Scope

Reusable code should encode primitives, not finished slides. Components should make it easier to build visually rich slides while still allowing variation.

Good component candidates:

- Intent maps: clusters, ecosystems, stakeholder rings.
- Progression paths: journeys, maturity paths, roadmap bands.
- Layer stacks: pyramids, platform layers, capability stacks.
- Decision compares: tradeoff panels, opposing forces, criteria matrices.
- Operating rhythms: swimlanes, workplan bands, delivery cadence.
- Metric callouts: number, implication, and supporting cue.
- Icon systems: sizing, color behavior, captioning, and alignment rules.
- Modular blocks: capability blocks and lego-like compositions.

Avoid finished-slide components such as "the comparison slide" or "the roadmap slide" that would make outputs samey across decks.

## Proposed File Structure

Keep `SKILL.md` short and leaf-shaped. Put detailed design guidance in references that are loaded only when needed.

```text
slalom-html-slide-decks/
├── SKILL.md
├── references/
│   ├── slalom-brand-reference.md
│   ├── html-deck-requirements.md
│   ├── sources.md
│   ├── design-refresh-plan.md
│   └── design-language/
│       ├── content-intents.md
│       ├── visual-moves.md
│       ├── design-critique.md
│       ├── thumbnail-index.md
│       └── thumbnails/
│           ├── orient-and-frame.png
│           ├── compare-and-decide.png
│           ├── explain-systems.png
│           ├── sequence-and-roadmap.png
│           ├── operate-and-deliver.png
│           ├── humanize-and-storytell.png
│           └── reset-and-cover.png
├── assets/
│   └── slalom-html-deck-starter/
│       ├── base.css
│       ├── base-light.css
│       ├── deck.js
│       ├── components/
│       │   ├── intent-map.css
│       │   ├── progression-path.css
│       │   ├── layer-stack.css
│       │   ├── decision-compare.css
│       │   ├── operating-rhythm.css
│       │   └── modular-blocks.css
│       └── slides/
└── scripts/
    ├── setup-deck.js
    ├── build-deck.js
    ├── render.js
    ├── visual-qa.js
    ├── refresh-harness-support.sh
    └── harness-sync.sh
```

This structure keeps the top-level skill simple while allowing agents to pull deeper design references only when building or refreshing a deck.

## Semantic Updates Needed Across The Skill

### `SKILL.md`

Add a compact design workflow:

1. Run a design signal check.
2. If audience, purpose, deck type, and source density are missing, ask 1-3 pointed questions.
3. Choose a deck-level design language.
4. Read the relevant intent reference and thumbnail index only for the intents in scope.
5. Draft slides using visual moves to encode meaning.
6. Run a design critique before rendering.
7. Render and verify as today.

Keep `SKILL.md` under roughly 100 lines if practical. Link out to `references/design-language/*` rather than embedding long principles.

### `slalom-brand-reference.md`

Keep it focused on brand contract. Add only a short note that the design-language references must still obey the brand contract. Do not mix design inspiration with logo, color, and typography rules.

### `html-deck-requirements.md`

Add a short requirement that visual slides should encode information relationships, not merely decorate text. The QA checklist should include a design-critique checkpoint in addition to blank/clipped/footer checks.

### `sources.md`

Add a source entry for the curated internal slide-reference distillation, without local paths. It should describe the derived packaged artifacts: low-resolution thumbnail groups, distilled principles, and component primitives.

### Starter CSS And Components

Move stable primitives into component CSS files only when they are reusable across many slide intents. Avoid adding a large library of one-off layouts. Update starter slides only where needed to demonstrate primitives without bloating the starter deck.

## Implementation Plan

### Phase 1: Planning Artifact

Create this plan and review it with the user before changing the skill behavior.

Deliverable:

- `references/design-refresh-plan.md`

### Phase 2: Source Distillation Pass

Inspect the internal slide source and categorize reusable patterns by business/content intent.

Outputs:

- Intent taxonomy.
- Visual move taxonomy.
- Candidate thumbnail groups.
- Candidate component primitives.
- Notes on what not to copy because it would cause sameness.

Packaging rules:

- No full source deck.
- No local source path.
- No full-slide archive.
- Only curated low-resolution derived references.

### Phase 3: Reference Layer

Create `references/design-language/` with concise, progressively disclosed files:

- `content-intents.md`: intent definitions, when to use them, and signals to infer from prompts.
- `visual-moves.md`: reusable visual move palette with multiple options per intent.
- `design-critique.md`: pre-final review questions and revision rules.
- `thumbnail-index.md`: maps thumbnail groups to intents and explains how to use them as inspiration.
- `thumbnails/*.png`: curated contact sheets grouped by intent.

Keep language operational and compact. Avoid generic design theory.

### Phase 4: Component Library

Add a small number of reusable CSS/HTML primitives under the starter support set. Components should be composable and parameterized through classes and CSS variables.

Initial candidates:

- Intent map.
- Progression path.
- Layer stack.
- Decision compare.
- Operating rhythm.
- Modular blocks.

Each component should support variation through scale, orientation, count, accent treatment, and density. The component should not imply a complete slide.

### Phase 5: Skill Workflow Update

Update `SKILL.md` to make the design layer part of normal generation:

- Add a design signal check.
- Add the upfront question rule.
- Add deck-level design language selection.
- Add reference-thumbnail use guidance.
- Add visual-move selection guidance.
- Add design critique before render.

The language should be cohesive with the current brand workflow and should not overload future agents. The skill should tell agents what to do next, not explain every design concept inline.

### Phase 6: QA And Validation

Validate the refreshed skill:

- Render the starter deck.
- Run `node build-deck.js <deck-package>`.
- Open the live top-level `index.html`.
- Inspect `renders/contact-sheet.png`.
- Inspect representative PNGs.
- Confirm no text clipping, missing assets, or footer regressions.
- Confirm the new references are one level deep from `SKILL.md`.
- Confirm the skill remains self-contained and does not depend on the original source deck.

## Future-Agent Mental Load Guardrails

- Keep `SKILL.md` as the decision router, not the full design manual.
- Use short references with clear names.
- Prefer lists of choices over long prose.
- Avoid one-off terminology that future agents must decode.
- Do not require reading every design-language file for every deck.
- For a small deck, read only the relevant intent file sections and the critique checklist.
- For a broad deck refresh, read the full design-language reference set.
- Keep component docs near the component code.

## Open Implementation Questions

1. How many thumbnail groups should be created initially?
2. What is the maximum useful thumbnail resolution for packaged references?
3. Should component examples live as standalone HTML snippets, starter slides, or comments near CSS?
4. Should the starter deck stay at 26 slides, shrink, or grow modestly to demonstrate new primitives?
5. Should `visual-qa.js` remain structural only, or should a separate design-review checklist script/report be added later?
