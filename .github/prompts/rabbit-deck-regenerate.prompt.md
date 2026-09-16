---
description: Regenerate the Team Rabbit Mode YugaStore recap deck from a pull request that checks `Regenerate the slide deck`, then open a follow-up PR for the refreshed slides.
---

## Triggering pull request

Use the active pull request as the source of truth.

1. Inspect the pull request body.
2. Continue only if the checklist item `- [x] Regenerate the slide deck` is checked.
3. If the box is unchecked, stop and report that no slide-deck regeneration was requested.

## Required outcome

- Create a new branch dedicated to the deck refresh instead of reusing the triggering pull request branch.
- Run the `rabbit-deck-gen` skill to regenerate the Team Rabbit Mode YugaStore recap deck.
- Keep the deck update isolated to the generated slide-deck artifacts.
- Open a follow-up pull request with the refreshed slides.
- Include the human team members for review: Young Chul Kim, Jack Murphy, Michael Apfelbeck.

## Deck generation brief

Pass the triggering pull request context into `rabbit-deck-gen` when it helps choose inputs such as
the recap window or audience. Otherwise, use the skill defaults and follow
`.agents/skills/rabbit-deck-gen/SKILL.md`.

## Pull request handoff

- Reference the triggering pull request in the follow-up PR summary.
- State that the PR contains regenerated Team Rabbit Mode deck artifacts only.
- If exact GitHub reviewer handles are not available from the current context, mention the three
  reviewers by name in the PR body and say that reviewer assignment still needs a human with the
  correct handles.
