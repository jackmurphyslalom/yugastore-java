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
    .slice(0, 80) || "slalom-html-deck";
}

function today() {
  return new Date().toISOString().slice(0, 10);
}

function copyDir(source, target) {
  fs.mkdirSync(target, { recursive: true });
  for (const entry of fs.readdirSync(source, { withFileTypes: true })) {
    const sourcePath = path.join(source, entry.name);
    const targetPath = path.join(target, entry.name);
    if (entry.isDirectory()) copyDir(sourcePath, targetPath);
    else fs.copyFileSync(sourcePath, targetPath);
  }
}

function writeIfMissing(filePath, content) {
  if (!fs.existsSync(filePath)) fs.writeFileSync(filePath, content);
}

const title = arg("title", "Slalom HTML Deck");
const explicitOut = arg("out", "");
const slug = arg("slug", slugify(title));
const dated = !["0", "false", "no"].includes(String(arg("date-prefix", "true")).toLowerCase());
const outRoot = path.resolve(explicitOut || "outputs");
const deckDir = path.join(outRoot, dated ? `${today()}-${slug}` : slug);
const skillDir = path.resolve(__dirname, "..");
const starterDir = path.join(skillDir, "assets", "slalom-html-deck-starter");

if (!fs.existsSync(starterDir)) {
  throw new Error(`Starter directory not found: ${starterDir}`);
}

fs.mkdirSync(deckDir, { recursive: true });
for (const folder of ["slides", "assets", "renders", "source", "support"]) {
  fs.mkdirSync(path.join(deckDir, folder), { recursive: true });
}

copyDir(path.join(starterDir, "components"), path.join(deckDir, "support", "components"));
copyDir(path.join(starterDir, "assets"), path.join(deckDir, "support", "assets"));
for (const file of ["base.css", "base-light.css", "deck.js"]) {
  fs.copyFileSync(path.join(starterDir, file), path.join(deckDir, "support", file));
}
for (const file of ["build-deck.js", "visual-qa.js"]) {
  fs.copyFileSync(path.join(skillDir, "scripts", file), path.join(deckDir, "support", file));
}

writeIfMissing(path.join(deckDir, "deck.css"), `/* Deck-specific styles. Keep reusable primitives in support/components/. */\n`);
writeIfMissing(path.join(deckDir, "source", "README.md"), `# ${title}\n\nSource notes, inputs, and generation context for this deck.\n`);
writeIfMissing(path.join(deckDir, "source", "story-brief.md"), `# Story Brief

- Audience / decision:
- Governing story frame:
- Executive concern:
- Claim spine:
- Source / proof:
- Caveats to keep out of client-facing slides:

`);
writeIfMissing(path.join(deckDir, "source", "visual-system.md"), `# Visual Meaning System

Record recurring concepts and their stable visual treatment.

| Concept | Label | Visual token | Notes |
|---|---|---|---|
|  |  |  |  |

`);
writeIfMissing(path.join(deckDir, "source", "visual-qa-ledger.md"), `# Visual QA Ledger

Generated entries are a review scaffold, not a completed semantic visual QA pass. Fill this after inspecting the live deck, contact sheets, and full-size changed/dense slide renders.

`);
writeIfMissing(path.join(deckDir, "slides", "01-cover.html"), `<section class="slide template-cover" aria-label="${title} cover" data-slide="1">
  <div class="cover-meta">
    <span>Deck type</span>
    <span>${today()}</span>
  </div>
  <img class="slalom-logo" src="support/assets/slalom-logo-black.svg" alt="Slalom">
  <h1>${title}</h1>
  <p class="cover-body">Replace this with the deck's purpose, audience, and decision or action.</p>
  <div class="cover-footer"><span>Copyright ${new Date().getFullYear()} Slalom. All Rights Reserved. Proprietary and Confidential.</span><span>1</span></div>
  <div class="color-bar" aria-hidden="true"><span></span><span></span><span></span><span></span><span></span></div>
</section>
`);
writeIfMissing(path.join(deckDir, "slides", "02-frame.html"), `<section class="slide" aria-label="Framing slide" data-slide="2">
  <div class="eyebrow">Frame</div>
  <h2>Use this slide to frame the decision, path, or working session.</h2>
  <div class="content-stack">
    <p>Replace this starter content with a visual argument, system map, progression, or decision structure.</p>
  </div>
  <div class="footer"><span>Copyright ${new Date().getFullYear()} Slalom. All Rights Reserved. Proprietary and Confidential.</span><span>2</span></div>
</section>
`);

console.log(`Deck package created: ${deckDir}`);
console.log(`Next: node ${path.join(skillDir, "scripts", "build-deck.js")} ${deckDir}`);
