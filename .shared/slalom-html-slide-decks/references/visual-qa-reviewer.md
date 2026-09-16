# Fresh-Eye Visual QA Reviewer

Use this reference when a substantial/new client-facing HTML deck, major visual rebuild, or user-caught visual miss needs semantic visual QA.

## Reviewer Inputs

Give the reviewer:

- `source/story-brief.md` or the claim spine
- `source/visual-system.md` when present
- full-size slide screenshots for changed, dense, text-heavy, or user-flagged slides
- `renders/contact-sheet.png` and `renders/contact-sheet-detailed.png` for deck rhythm
- `review.html` for DOM-level inspection when annotation or element targeting matters

Do not ask the reviewer to inspect implementation code first. The reviewer should judge communication quality from the story and rendered/live slide evidence.

## Review Questions

For each reviewed slide:

- What is the slide's one job and claim?
- Does the visual form make that claim easier to understand?
- Are density, whitespace, hierarchy, and focal point appropriate?
- Is any text clipped, overlapping, too small, or fighting another element?
- Are recurring concepts using the same labels, colors, lanes, breadcrumbs, icons, or hierarchy as the rest of the deck?
- Are there repeated but meaningless shapes, arrows, markers, badges, or decorative objects?
- Does the slide imply something the story brief does not support?
- Would an executive understand the point before reading every word?

## Output Format

Return a concise ledger:

```markdown
## Fresh-Eye Visual QA

| Slide | Status | Issue | Required fix |
|---|---|---|---|
| 03 | fail | Boxes are visually equal-weight, but the claim needs one dominant risk mechanism. | Add hierarchy and reduce parallel callouts. |
| 04 | pass | Visual sequence matches the lifecycle claim. | None. |
```

Status values are `pass`, `fix`, or `not reviewed`. A deck is not visually ready while any substantial or user-flagged slide is `fix`.
