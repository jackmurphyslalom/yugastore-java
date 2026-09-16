# Slalom Brand Reference For HTML Decks

This reference summarizes source material from the Slalom Gear Brand Guidelines SharePoint page and the user-provided `Slalom_PowerPoint_16x9_Aug2025.potx` template. Use it as practical guidance for webpage slide decks. See `sources.md` for source provenance and refresh workflow. When a current official asset or linked internal brand page is available, prefer that source over this summary.

The design-language references in `references/design-language/` expand the visual vocabulary for generated decks, but they do not create a second brand system. When design inspiration and brand guidance appear to conflict, follow this brand reference unless the user explicitly asks for a non-standard internal concept draft.

## Palette

Anchor every composition with a Slalom blue. The PowerPoint theme exposes these core colors:

| Role | Name | Hex |
| --- | --- | --- |
| Accent 1 | Slalom Blue | `#0C62FB` |
| Accent 2 | Slalom Dark Blue | `#002FAF` |
| Accent 3 | Cyan | `#1BE1F2` |
| Accent 4 | Coral Red | `#FF4D5F` |
| Accent 5 | Purple | `#C7B9FF` |
| Accent 6 | Chartreuse | `#DEFF4D` |
| Text | Black | `#000000` |
| Neutral | Dark Gray | `#666666` |
| Neutral | Light Gray | `#E6E6E6` |
| Background | White | `#FFFFFF` |

The August 2025 template also includes an older `Slalom 2022` theme where Slalom Blue and Slalom Dark Blue appear with the first two accent roles swapped. For HTML decks, use the semantic CSS tokens (`--slalom-blue` and `--slalom-dark-blue`) rather than assuming Office accent order. Slalom Blue remains the required anchor color in every composition.

Custom tint families from the theme:

- Cyan: `#00BAD6`, `#05C4DE`, `#0ED3EB`, `#60EAF5`, `#8CF0F9`, `#D1F9FD`
- Coral Red: `#E6154A`, `#F1214B`, `#F53958`, `#FF5F6F`, `#FF7F8C`, `#FFDBDF`
- Purple: `#9488F0`, `#A099F8`, `#B6ACF9`, `#CCBFFF`, `#D3C7FF`, `#EEE9FF`
- Chartreuse: `#B3CC3E`, `#BDDD07`, `#CBEB0F`, `#E7FF80`, `#EFFFAA`, `#F7FFD6`

Use one secondary color family at a time with Slalom Blue, Slalom Dark Blue, white, and/or black. Avoid using all brand colors at once unless using approved graphic elements. If using the official color bar, keep this order: Slalom Blue, Cyan, Coral Red, Purple, Chartreuse.

## Typography

Brand guidance references Slalom Sans and Lora. The August 2025 PowerPoint template uses Avenir Next LT Pro and embedded Slalom Sans variants. For HTML decks:

- Use supplied webfont files when available.
- Default to `Slalom Sans` for headings and body.
- Use `Lora` for selective editorial contrast such as pull quotes, client-story moments, or a deliberately more human closing slide.
- Use `Avenir Next LT Pro` only as a fallback when Slalom Sans is unavailable or when matching a template-exported artifact that visibly relies on it.
- Sans fallback stack: `Slalom Sans`, `Avenir Next LT Pro`, `Avenir Next`, `Avenir`, `Inter`, `Arial`, sans-serif.
- Serif contrast stack: `Lora`, `Georgia`, `Times New Roman`, serif.
- Titles should be bold, black, sentence case, and usually one to three lines.
- Use Slalom Blue for selective emphasis in headlines.
- Use all caps sparingly for small content headers or labels.
- Keep the smallest deck text at or above an accessible equivalent of 10 pt.

## Logo Rules

- Use the approved Slalom logo asset only.
- Do not redraw, recolor, rotate, skew, apply effects to, or otherwise alter the logo.
- Logo colors are limited to Slalom Blue, Slalom Dark Blue, white, or black.
- Do not create new logos or unofficial artwork.
- Do not create partner lockups, alliance marks, or sub-brand logos in HTML/CSS. Use only approved supplied lockup artwork.
- If a client or partner logo is requested but no approved asset is supplied, create a neutral placeholder slot and ask for the asset rather than approximating the mark.
- Treat partner and sub-brand marks as approval-sensitive. Some approved digital lockups may not be approved for every use case.
- Do not use the word "Slalom" as decorative artwork.
- Maintain clear space. Merchandise guidance calls for keeping the logo about 30% away from artwork; for decks, keep generous spacing around the mark and avoid visual crowding.

## Graphic Elements

- Color bars reinforce the brand palette. Use them as framing devices for layouts and images, or as thin headline underlines.
- The color bar order is Slalom Blue, Cyan, Coral Red, Purple, Chartreuse.
- Organic single-line shapes can add brand character on light slides with minimal text or over images. When placed over images, use about 50% transparency.
- Large line elements can use the lightest tint of any brand color.
- Keep these elements precise and minimal. They should support the slide architecture, not decorate every corner.

## Iconography And Illustrations

- Use the custom Slalom icon set when available. Do not mix in generic external icons unless the user explicitly approves and they harmonize with the deck.
- Do not reverse icons or illustrations to white on a color field.
- Recolor icons through approved palette colors, with black, Slalom Blue, or Slalom Dark Blue as safest defaults.
- Use approved Creative Library illustrations when available. Do not invent unofficial Slalom-style illustrations for brand-critical work.

## Presentation Cues

The PowerPoint template is widescreen, with slide size `12192000 x 6858000` EMUs, equivalent to 16:9. It includes covers, contents, agendas, overview slides, section dividers, team slides, process/timeline/chart slides, device frames, storytelling templates, SPRO-style response pages, thank-you slides, and visual design system slides. For HTML decks, recreate the intent and proportions of these patterns in CSS rather than generating Office slides.

### Cover And Title Slides

The template has several cover variants. The default cover, `Cover Slide`, uses a quiet white canvas with content aligned to the PowerPoint placeholder grid, not a web-style hero panel. At 1920 x 1080, use these approximate positions:

| Element | Position And Scale |
| --- | --- |
| Deck type | `left: 238px; top: 154px; width: 1296px; height: 54px`; all caps, bold, about `16px` |
| Date | `left: 238px; top: 193px; width: 1296px; height: 54px`; all caps, bold, about `16px` |
| Title | `left: 238px; top: 360px; width: 1296px; height: 288px`; bold, about `88px`, black unless using a blue title cover variant |
| Body copy | `left: 238px; top: 724px; width: 1296px; height: 79px`; about `19px` |
| Client logo slot | `left: 238px; top: 886px; width: 477px; height: 104px` |
| Slalom logo slot | top right, about `204px x 53px`, near `left: 1626px; top: 77px` when an approved logo asset is available |
| Color bar | full width at the bottom, `22px` tall, split into five equal segments |

The partner-logo cover variants move the text block lower: deck type/date near `top: 276px/315px`, title near `top: 432px`, subtitle/body near `top: 837px/886px`, Slalom logo near `left: 1119px; top: 77px`, and partner logo slot near `left: 1456px; top: 62px`. Use this variant only when a partner/client mark is part of the actual slide.

In the starter CSS, use `.template-cover` for the default black-title cover, `.template-cover.title-blue` for the blue-title cover variant, and `.template-cover.partner-cover` when a partner or prominent client logo belongs in the top-right partner slot. For a smaller client logo on the default cover, use `.cover-logo-slot.has-logo` and place the supplied logo image inside it.

If the user asks for a different title color, stay inside template-supported color behavior first: black or Slalom Blue. Do not recolor the Slalom logo or client logos. Do not use arbitrary accent colors for cover headlines unless the user explicitly asks for a custom departure from the PowerPoint template.

Do not invent right-side color panels, large decorative rings, or extra metadata systems on cover slides unless the source template variant calls for them. Keep title covers sparse: deck type, date, title, optional body/subtitle, optional client or partner logo, footer, and the official color bar.

Common footer language in the template: `Slalom. All Rights Reserved. Proprietary and Confidential.` For generated internal decks, include a copyright footer on every slide: `Copyright [year] Slalom. All Rights Reserved. Proprietary and Confidential.` Use the deck year, or the current year if no deck year is specified. Omit or adapt the confidentiality language only when the user explicitly asks for a public/non-confidential deck variant.
