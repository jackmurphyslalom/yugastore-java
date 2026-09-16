---
description: Generate the team Rabbit Mode YugaStore recap deck — intro, team, project, agentic skills and tools inventory, and a git-history progress recap — as HTML, Marp, or both, using the slalom-html-slide-decks skill.
---

## Deck Brief

```text
$ARGUMENTS
```

Interpret the block above as optional inputs. Recognized keys (all optional):

- `--format=<html|marp|both>` — output format. Default: `marp`.
- `--max-slides=<N>` — soft cap on the 10-slide generated sequence. Default: unlimited. Drop order when exceeded: slide 9 (Spec Kit artifacts) → 8 (Where we worked) → 5 (Prompts + MCP). Slides 1-3 and 10 are required; `N < 4` is refused.
- `--since=<ref-or-date>` — git anchor for the progress recap. Default: `"3 days ago"`.
- `--out=<path>` — HTML deck output root passed to `setup-deck.js`. Default: `./outputs`.
- `--out-marp=<path>` — Marp deck output root passed to `setup-deck-marp.js`. Default: `./outputs-marp`.
- `--style-lens=<lens>` — Slalom style lens (HTML only). Default: `high-energy`.
- `--additional-content=<path>` — folder of raw `*.html` slide fragments to append (HTML only). Default: `additional-deck-content/`.
- `--audience=<text>` — audience/purpose hint. Default: internal readout.

Then follow `.agents/skills/rabbit-deck-gen/SKILL.md`, which orchestrates `slalom-html-slide-decks` (canonical body at `.shared/slalom-html-slide-decks/SKILL.md`) to generate the deck.

Fixed content the skill will use regardless of arguments:

- Team members: Young Chul Kim, Jack Murphy, Michael Apfelbeck
- Project: brownfield YugaStore (`yugastore-java`)
- Deck title: `Team Rabbit Mode — YugaStore Recap`

Content style (enforced by the skill):

- No eyebrows, kickers, metaphors, or motivational closers.
- No headline numbers. Counts appear in the body only when the count is the claim.
- No decorative aggregates (e.g., summed file-touches across unrelated buckets).
- Drop slides or bullets that have no signal for the window — do not pad.

Report back the deck path(s), resolved inputs, effective slide list (with any dropped by `--max-slides`), slide count per package, git recap numbers used, and per-format build/QA status (slalom local gates and `source/visual-qa-ledger.md` for HTML; render command + overflow findings for Marp).

