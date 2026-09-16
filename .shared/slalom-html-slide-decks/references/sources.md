# Slalom HTML Deck Skill Sources

This file tracks which source materials influenced the skill and how to refresh them. The skill is a snapshot, not a live link. When the user asks for the latest Slalom brand guidance or a newer PowerPoint template, re-check the relevant source and update this file alongside `slalom-brand-reference.md`, `html-deck-requirements.md`, starter CSS, starter slides, and bundled assets.

## Current Source Snapshot

| Source | Status | Skill Usage |
| --- | --- | --- |
| Slalom Gear Brand Guidelines SharePoint page | Summarized from the user-provided internal page URL: `https://twodegrees1.sharepoint.com/teams/SlalomGear/SitePages/Brand%20Guidelines.aspx` | High-level brand guardrails: approved-logo behavior, typography references, color-use principles, icon/illustration cautions, and general brand conduct |
| `Slalom_PowerPoint_16x9_Aug2025.potx` | Parsed from the source repository's captured template analysis | Concrete slide-deck implementation details: theme palette, tint families, 16:9 dimensions, cover/title geometry, layout names, color-bar construction, footer language, and extracted Slalom logo SVG |
| Creative Library | Linked from SharePoint/template: `https://twodegrees1.sharepoint.com/teams/marketing/SitePages/Creative-Library.aspx` | Preferred source for approved illustrations, design assets, and reusable brand elements when the user asks for a source refresh or supplies assets |
| Creative Library Brand Guide | Linked from template: `https://twodegrees1.sharepoint.com/teams/marketing/SitePages/Creative-Library-Brand-Guide.aspx` | Use as a higher-specificity source for current brand rules when accessible |
| Creative Library Designer Tools | Linked from SharePoint: `https://twodegrees1.sharepoint.com/teams/marketing/SitePages/Creative-Library-Designer-Tools.aspx` | Source for approved type lockups and design tools; do not recreate lockups manually |
| Creative Library Icons | Linked from template: `https://twodegrees1.sharepoint.com/teams/marketing/SitePages/Creative-Library-Icons.aspx` | Preferred source for Slalom iconography; avoid mixing generic icon systems into brand-critical decks |
| Brand Hub / Templates | Linked from template: `https://twodegrees1.sharepoint.com/teams/marketing/SitePages/Brand-Hub.aspx` and `https://twodegrees1.sharepoint.com/teams/marketing/SitePages/Templates.aspx` | Use when refreshing presentation-template conventions, boilerplate, and approved deck artifacts |
| Slalom Stories guidance | Linked from template: `https://twodegrees1.sharepoint.com/sites/SlalomStories/SitePages/Telling-client-stories-publicly.aspx` | Use before creating public client-story slides or client-identifiable narratives |
| Curated internal slide-reference distillation | Packaged as derived, low-resolution thumbnail boards and markdown principles under `references/design-language/`; no full source deck or local source path is required | Broader visual vocabulary: business/content intent taxonomy, visual move palette, critique workflow, and reusable component inspiration |
| Generated HTML deck workflow | Authored specifically for this skill | Portable deck package setup, live `index.html` assembly, copied support files, Playwright QA renders, contact sheets, and browser-native slide implementation rules |

## Source Weighting

For brand-specific decisions, prefer the most specific current source:

1. Current official SharePoint brand page or linked internal brand asset pages, when the user asks for a refresh or provides access.
2. Current user-provided Slalom PowerPoint template, when translating deck layout, spacing, theme colors, logos, and slide proportions.
3. Existing skill references, when no newer source is available.

The PowerPoint template currently drives most concrete HTML/CSS implementation because it exposes exact geometry and theme values. The SharePoint page currently drives broader brand rules and asset-use cautions.

## Refresh Workflow

When the user asks to update the skill with latest SharePoint guidance:

1. Re-fetch or inspect the SharePoint Brand Guidelines page.
2. Inspect linked Creative Library, Brand Guide, Designer Tools, Icons, Brand Hub/Templates, and Slalom Stories pages only when the request needs those topics or the user asks for a broad refresh.
3. Compare changes against `slalom-brand-reference.md`, especially palette, typography, logo rules, partner/sub-brand lockups, iconography, illustration rules, client-story rules, and asset-use restrictions.
4. Update `slalom-brand-reference.md` and starter CSS/assets only where the guidance has changed.
5. Record what changed in this file under "Refresh Log".

When the user provides a newer PowerPoint template:

1. Unpack the `.potx` or `.pptx` as Open XML.
2. Inspect theme colors, font references, slide size, slide layout names, cover/title layouts, footer placeholders, logo assets, and key reusable layout geometry.
3. Update `slalom-brand-reference.md`, `html-deck-requirements.md`, starter CSS, starter slides, and bundled logo/assets as needed.
4. Render the starter deck and inspect representative PNGs before considering the refresh complete.
5. Record what changed in this file under "Refresh Log".

When refreshing the packaged design-language references:

1. Inspect the current approved source material outside the packaged skill.
2. Distill reusable principles by business/content intent and visual move.
3. Export only curated low-resolution reference boards into `references/design-language/thumbnails/`.
4. Keep the skill self-contained: do not store full source decks, full slide archives, or local source paths.
5. Update `content-intents.md`, `visual-moves.md`, `design-critique.md`, `thumbnail-index.md`, starter component primitives, and this file together when the design language changes.

## Refresh Log

| Date | Source | Notes |
| --- | --- | --- |
| 2026-05-06 | SharePoint Brand Guidelines page | Initial summarized guidance incorporated: logo restrictions, typography references, palette behavior, icon/illustration cautions, and brand conduct. |
| 2026-05-06 | `Slalom_PowerPoint_16x9_Aug2025.potx` | Initial template-derived values incorporated: theme colors, tint families, slide size, cover/title layouts, color bar, footer language, and Slalom logo SVG. |
| 2026-05-06 | Deep source audit | Added linked internal source inventory, theme-variant note, Slalom Sans/Lora font precedence, partner/sub-brand guardrails, additional compact starter slides, and visual QA fixture guidance. |
| 2026-05-29 | Curated internal slide-reference distillation | Added intent-led design-language plan, low-resolution reference boards, visual move guidance, design critique workflow, and reusable component primitive direction. |
