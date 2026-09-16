# Team Rabbit Mode — 3-day recap (Marp)

Marp port of the Slalom-branded HTML deck at
[outputs/2026-09-16-team-rabbit-mode-yugastore/](../../outputs/2026-09-16-team-rabbit-mode-yugastore/).

- Source: [deck.md](deck.md)
- Theme: `slalom` (see [docs/slides/README.md](../../docs/slides/README.md))

## Render

```bash
npx @marp-team/marp-cli outputs-marp/2026-09-16-team-rabbit-mode-yugastore/deck.md \
  --theme-set docs/slides/themes/slalom.css \
  -o outputs-marp/2026-09-16-team-rabbit-mode-yugastore/deck.html
```

## Export to PDF

```bash
npx @marp-team/marp-cli outputs-marp/2026-09-16-team-rabbit-mode-yugastore/deck.md \
  --theme-set docs/slides/themes/slalom.css \
  --pdf \
  --allow-local-files
```

The Marp deck is a hand-authored port of the 10-slide HTML deck. Content is a snapshot as
of 2026-09-16; keeping it in sync with later edits to the HTML source is a manual
authoring responsibility.
