import { createRequire } from "node:module";
const require = createRequire(import.meta.url);

const fs = require("fs");
const path = require("path");
const { fileURLToPath } = require("url");

const __dirname = path.dirname(fileURLToPath(import.meta.url));

function arg(name, fallback = "") {
  const index = process.argv.indexOf(`--${name}`);
  return index >= 0 ? process.argv[index + 1] || fallback : fallback;
}

function slugify(value) {
  return String(value)
    .toLowerCase()
    .replace(/&/g, " and ")
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 80) || "slalom-marp-deck";
}

function today() {
  return new Date().toISOString().slice(0, 10);
}

function writeIfMissing(filePath, content) {
  if (!fs.existsSync(filePath)) fs.writeFileSync(filePath, content);
}

// Resolve the canonical Slalom Marp theme. Prefer a repo-local
// docs/slides/themes/slalom.css when present (that path is authoritative for
// this workspace). Callers can override with --theme=<path>.
function resolveMarpTheme(explicit) {
  if (explicit) return path.resolve(explicit);
  const repoTheme = path.resolve(process.cwd(), "docs/slides/themes/slalom.css");
  if (fs.existsSync(repoTheme)) return repoTheme;
  const skillTheme = path.resolve(__dirname, "..", "assets", "marp", "slalom.css");
  if (fs.existsSync(skillTheme)) return skillTheme;
  return null;
}

const title = arg("title", "Slalom Marp Deck");
const explicitOut = arg("out", "");
const slug = arg("slug", slugify(title));
const dated = !["0", "false", "no"].includes(String(arg("date-prefix", "true")).toLowerCase());
const outRoot = path.resolve(explicitOut || "outputs-marp");
const deckDir = path.join(outRoot, dated ? `${today()}-${slug}` : slug);
const themePath = resolveMarpTheme(arg("theme", ""));
const themeRel = themePath ? path.relative(deckDir, themePath) : null;

fs.mkdirSync(deckDir, { recursive: true });
fs.mkdirSync(path.join(deckDir, "source"), { recursive: true });

const renderCmd = themeRel
  ? `npx @marp-team/marp-cli deck.md --theme-set "${themeRel}" -o deck.html`
  : `npx @marp-team/marp-cli deck.md -o deck.html`;
const pdfCmd = themeRel
  ? `npx @marp-team/marp-cli deck.md --theme-set "${themeRel}" --pdf --allow-local-files`
  : `npx @marp-team/marp-cli deck.md --pdf --allow-local-files`;

writeIfMissing(
  path.join(deckDir, "deck.md"),
  `---
marp: true
theme: slalom
paginate: true
title: ${title}
---

<!-- _class: lead -->

# ${title}

*Replace this with the deck's audience, purpose, and decision.*

---

## Frame

- Replace with the framing claim.
- Support with a short list, table, or lane.

*Copyright ${new Date().getFullYear()} Slalom. All Rights Reserved. Proprietary and Confidential.*
`
);

writeIfMissing(
  path.join(deckDir, "README.md"),
  `# ${title} (Marp)

Marp source: [deck.md](deck.md).${themePath ? `\nTheme: \`${path.basename(themePath)}\` (${themeRel}).` : "\nTheme: default (no Slalom theme resolved at setup time)."}

## Render to HTML

\`\`\`bash
cd ${path.relative(process.cwd(), deckDir) || "."}
${renderCmd}
\`\`\`

## Export to PDF

\`\`\`bash
cd ${path.relative(process.cwd(), deckDir) || "."}
${pdfCmd}
\`\`\`

Both commands require the Slalom Marp theme to be reachable from the deck folder. If you move the deck, re-resolve the \`--theme-set\` path.
`
);

writeIfMissing(
  path.join(deckDir, "source", "README.md"),
  `# ${title}\n\nSource notes, inputs, and generation context for this Marp deck.\n`
);

writeIfMissing(
  path.join(deckDir, "source", "story-brief.md"),
  `# Story Brief

- Audience / decision:
- Governing story frame:
- Executive concern:
- Claim spine:
- Source / proof:
- Caveats to keep out of client-facing slides:
`
);

writeIfMissing(
  path.join(deckDir, "source", "visual-qa-ledger.md"),
  `# Visual QA Ledger (Marp)

Marp decks do not have Playwright-driven visual QA. Record here:

- Slide count and story-frame status.
- Theme resolution (path used for \`--theme-set\`).
- Any slides that overflowed at render time and how they were shortened.
- Whether the standard Slalom footer copyright is present on internal slides.
`
);

console.log(`Marp deck package created: ${deckDir}`);
if (!themePath) {
  console.log("Warning: could not resolve a Slalom Marp theme. Render will fall back to Marp's default theme.");
}
console.log(`Next: cd ${path.relative(process.cwd(), deckDir) || "."} && ${renderCmd}`);
