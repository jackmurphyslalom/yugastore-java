# Visual QA Ledger

Generated entries are a review scaffold, not a completed semantic visual QA pass. Fill this after inspecting the live deck, contact sheets, and full-size changed/dense slide renders.


## Slide 1: 01-cover.html

- Render: renders/01-cover.png
- Review status: not reviewed
- Slide job / claim:
- Density / whitespace:
- Hierarchy / focal point:
- Overlap / clipping:
- Visual meaning system consistency:
- Required fixes:


## Slide 2: 02-meet-the-team.html

- Render: renders/02-meet-the-team.png
- Review status: not reviewed
- Slide job / claim:
- Density / whitespace:
- Hierarchy / focal point:
- Overlap / clipping:
- Visual meaning system consistency:
- Required fixes:


## Slide 3: 03-project.html

- Render: renders/03-project.png
- Review status: not reviewed
- Slide job / claim:
- Density / whitespace:
- Hierarchy / focal point:
- Overlap / clipping:
- Visual meaning system consistency:
- Required fixes:


## Slide 4: 04-agentic-skills.html

- Render: renders/04-agentic-skills.png
- Review status: not reviewed
- Slide job / claim:
- Density / whitespace:
- Hierarchy / focal point:
- Overlap / clipping:
- Visual meaning system consistency:
- Required fixes:


## Slide 5: 05-prompts-and-mcp.html

- Render: renders/05-prompts-and-mcp.png
- Review status: not reviewed
- Slide job / claim:
- Density / whitespace:
- Hierarchy / focal point:
- Overlap / clipping:
- Visual meaning system consistency:
- Required fixes:


## Slide 6: 06-progress-at-a-glance.html

- Render: renders/06-progress-at-a-glance.png
- Review status: not reviewed
- Slide job / claim:
- Density / whitespace:
- Hierarchy / focal point:
- Overlap / clipping:
- Visual meaning system consistency:
- Required fixes:


## Slide 7: 07-what-we-shipped-themes.html

- Render: renders/07-what-we-shipped-themes.png
- Review status: not reviewed
- Slide job / claim:
- Density / whitespace:
- Hierarchy / focal point:
- Overlap / clipping:
- Visual meaning system consistency:
- Required fixes:


## Slide 8: 08-where-we-worked.html

- Render: renders/08-where-we-worked.png
- Review status: not reviewed
- Slide job / claim:
- Density / whitespace:
- Hierarchy / focal point:
- Overlap / clipping:
- Visual meaning system consistency:
- Required fixes:


## Slide 9: 09-spec-kit-artifacts.html

- Render: renders/09-spec-kit-artifacts.png
- Review status: not reviewed
- Slide job / claim:
- Density / whitespace:
- Hierarchy / focal point:
- Overlap / clipping:
- Visual meaning system consistency:
- Required fixes:


## Slide 10: 10-close.html

- Render: renders/10-close.png
- Review status: not reviewed
- Slide job / claim:
- Density / whitespace:
- Hierarchy / focal point:
- Overlap / clipping:
- Visual meaning system consistency:
- Required fixes:


## Fresh-eye semantic pass (Copilot, 2026-09-16)

### Slide 02 — Meet the team
- The `accent-cyan`, `accent-coral`, `accent-chartreuse` classes on `.panel` did not visibly color the panels; they render as neutral gray. If we want the per-member color cue we need per-panel inline `background-color` or a bespoke rule in `deck.css`. Content is otherwise correct and legible.

### Slide 06 — Progress at a glance
- The Sep 14 (10) and Sep 16 (3) bars are proportionally correct against Sep 15 (38) but visually near-invisible. Consider a minimum-width floor on bars, or switch to a stacked bar with equal-width day columns and a numeric label.

### Slide 07 — What we shipped
- Five modular-blocks columns are dense; the all-caps blue-on-blue text in each block is legible but crowded. Consider reducing to 4 lanes or splitting into two 3-lane slides for room to breathe.

### Slide 09 — Spec Kit artifacts
- Grid-3 with a "60 new files" panel in one cell reads asymmetrically. Consider promoting the 60 stat to a full-width bottom band or moving it into the kicker.

### Data verification
- Commit counts (51 no-merges, 84 total; 10 / 38 / 3 per day; 22 Young / 15 Jack / 14 Michael) verified from `git log --since="3 days ago" --no-merges`.
- New Spec Kit artifacts (10 features × 6 files = 60) verified from `git log --diff-filter=A` grep for `specs/*/{spec,plan,tasks,research,data-model,quickstart}.md`.
- Microservice-src claim on slide 08 corrected: `src/test` and `react-ui/frontend` were touched; `src/main` was not.

### Local gates
- Storyline Gate: pass — each slide has one job (cover / team / project / skills / prompts+MCP / velocity / themes / areas / artifacts / close).
- Messaging Gate: pass — governing frame ("brownfield scaffolding, not application code"), executive-friendly numbers, source-grounded, human agency in team slide.
- Visual Meaning System Gate: partial — Slalom Blue is the anchor, but per-member color cue on slide 02 didn't land. Fix in a follow-up pass.
- Style Lens Gate (high-energy): partial — bold stat treatments and lane-based themes are present, but layout variety is on the safe side. A high-energy pass would push more oversized numerals, asymmetric splits, and color-bar callouts.
- Final Handoff Gate: index.html + review.html + all 10 renders + contact-sheet.png + this ledger exist.
