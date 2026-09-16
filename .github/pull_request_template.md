## Summary

<!-- What does this PR change and why? -->

## Related issue

Closes #

## Major change? Update or regenerate the slide deck

If this PR introduces a **major** change (new feature, architecture decision, significant
refactor, or anything worth calling out in a demo/retro), add a slide to
[`docs/slides/ai-sdlc-bootstrap-overview.md`](../docs/slides/ai-sdlc-bootstrap-overview.md)
(or start a new deck under `docs/slides/`) summarizing it, so the deck keeps showing the
project's change progress over time. See [`docs/slides/README.md`](../docs/slides/README.md)
for the full authoring guide.

- [ ] Not a major change — no deck update needed
- [ ] Deck updated with a slide summarizing this change
- [ ] Regenerate the slide deck

Check `Regenerate the slide deck` when you want the deck-creating agent to open a follow-up pull
request that reruns `rabbit-deck-gen` and refreshes the Team Rabbit Mode recap deck for review.

**Render the deck to check your slide:**

```bash
npx @marp-team/marp-cli docs/slides/ai-sdlc-bootstrap-overview.md --theme-set docs/slides/themes/slalom.css --html -o /tmp/deck.html && open /tmp/deck.html
```

For live preview while authoring, install the
[Marp for VS Code](https://marketplace.visualstudio.com/items?itemName=marp-team.marp-vscode)
extension and open the deck's Markdown file.

## Checklist

- [ ] Tests added/updated and passing
- [ ] Docs updated if public behavior changed
- [ ] Self-reviewed the diff
