---
description: Generate the team Rabbit Mode YugaStore recap deck — intro, team, project, agentic skills and tools inventory, and a git-history progress recap — using the slalom-html-slide-decks skill.
---

## Deck Brief

```text
$ARGUMENTS
```

Interpret the block above as optional inputs. Recognized keys (all optional):

- `--since=<ref-or-date>` — git anchor for the progress recap. Default: `"3 days ago"`.
- `--out=<path>` — deck output folder passed to `setup-deck.js`. Default: `./outputs`.
- `--style-lens=<lens>` — Slalom style lens. Default: `high-energy`.
- `--additional-content=<path>` — folder of raw `*.html` slide fragments to append. Default: `additional-deck-content/`.
- `--audience=<text>` — audience/purpose hint. Default: internal readout.

Then follow `.agents/skills/rabbit-deck-gen/SKILL.md`, which orchestrates `slalom-html-slide-decks` (canonical body at `.shared/slalom-html-slide-decks/SKILL.md`) to generate the deck.

Fixed content the skill will use regardless of arguments:

- Team members: Young Chul Kim, Jack Murphy, Michael Apfelbeck
- Project: brownfield YugaStore (`yugastore-java`)
- Deck title: `Team Rabbit Mode — YugaStore Recap`

Report back the deck path, resolved inputs, slide count, git recap numbers used, and the state of the slalom skill's local gates and `source/visual-qa-ledger.md`.
