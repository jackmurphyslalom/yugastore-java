import { createRequire } from "node:module";
const require = createRequire(import.meta.url);

const fs = require("fs");
const path = require("path");
const { pathToFileURL } = require("url");
let chromium;

try {
  ({ chromium } = require("playwright"));
} catch (error) {
  if (error && error.code === "MODULE_NOT_FOUND") {
    console.error("Playwright is not available. Use bundled Codex runtime or install playwright in the project.");
    process.exit(1);
  }
  throw error;
}

const rawArgs = process.argv.slice(2);
const doctorMode = rawArgs.includes("--doctor");
const deckArg = rawArgs.find((arg) => arg !== "--doctor") || ".";
const deckDir = path.resolve(deckArg);
const width = Number(process.env.SLIDE_WIDTH || 1920);
const height = Number(process.env.SLIDE_HEIGHT || 1080);
const requireFooter = !["1", "true", "yes"].includes(String(process.env.PUBLIC_DECK || "").toLowerCase());
const minPngBytes = Number(process.env.MIN_RENDER_BYTES || 12000);

function htmlEscape(value) {
  return String(value).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
}

function listSlides() {
  const slidesDir = path.join(deckDir, "slides");
  if (!fs.existsSync(slidesDir)) throw new Error(`Slides directory not found: ${slidesDir}`);
  const files = fs.readdirSync(slidesDir).filter((file) => file.endsWith(".html")).sort((a, b) => a.localeCompare(b, undefined, { numeric: true }));
  if (!files.length) throw new Error(`No .html slides found in ${slidesDir}`);
  return files;
}

function extractSlide(html, file) {
  const match = html.match(/<section\b[\s\S]*?class=["'][^"']*\bslide\b[^"']*["'][\s\S]*?<\/section>/i);
  if (match) return match[0];
  const body = html.match(/<body[^>]*>([\s\S]*?)<\/body>/i);
  if (body) return body[1];
  throw new Error(`No <section class="slide"> found in ${file}`);
}

function assembleIndex(files) {
  const frames = files.map((file, index) => {
    const html = fs.readFileSync(path.join(deckDir, "slides", file), "utf8");
    return `    <article class="slide-frame" aria-label="Slide ${index + 1}"${index === 0 ? "" : " hidden"}>\n${extractSlide(html, file)}\n    </article>`;
  }).join("\n");

  const title = path.basename(deckDir).replace(/^\d{4}-\d{2}-\d{2}-/, "").replace(/-/g, " ");
  const indexHtml = `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${htmlEscape(title)}</title>
  <link rel="stylesheet" href="support/base.css">
  <link rel="stylesheet" href="support/base-light.css">
  <link rel="stylesheet" href="deck.css">
  <style>
    .deck-shell { min-height: 100vh; display: grid; place-items: center; background: #000; }
    .slide-frame { width: 1920px; height: 1080px; transform-origin: center; }
    .deck-controls { position: fixed; right: 24px; bottom: 24px; display: flex; align-items: center; gap: 10px; color: #fff; font: 14px Arial, sans-serif; z-index: 10; }
    .deck-controls button { width: 40px; height: 40px; border: 1px solid rgba(255,255,255,.45); border-radius: 999px; background: rgba(255,255,255,.12); color: #fff; font: inherit; cursor: pointer; }
    .deck-controls button:focus-visible { outline: 3px solid #0c62fb; outline-offset: 3px; }
  </style>
</head>
<body>
  <main class="deck-shell" aria-label="Slide deck">
${frames}
  </main>
  <nav class="deck-controls" aria-label="Slide controls">
    <button type="button" data-prev aria-label="Previous slide">‹</button>
    <span data-slide-count>1 / ${files.length}</span>
    <button type="button" data-next aria-label="Next slide">›</button>
  </nav>
  <script src="support/deck.js"></script>
</body>
</html>
`;
  fs.writeFileSync(path.join(deckDir, "index.html"), indexHtml);
}

function assembleReview(files) {
  const frames = files.map((file, index) => {
    const html = fs.readFileSync(path.join(deckDir, "slides", file), "utf8");
    return `    <article class="review-slide" id="slide-${index + 1}" aria-label="Slide ${index + 1}" data-slide-file="${htmlEscape(file)}">
      <header><span>Slide ${index + 1}</span><a href="slides/${htmlEscape(file)}">${htmlEscape(file)}</a><a href="renders/${htmlEscape(file.replace(/\.html$/i, ".png"))}">render</a></header>
${extractSlide(html, file)}
    </article>`;
  }).join("\n");

  const title = path.basename(deckDir).replace(/^\d{4}-\d{2}-\d{2}-/, "").replace(/-/g, " ");
  const reviewHtml = `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${htmlEscape(title)} review</title>
  <link rel="stylesheet" href="support/base.css">
  <link rel="stylesheet" href="support/base-light.css">
  <link rel="stylesheet" href="deck.css">
  <style>
    body { margin: 0; background: #f4f5f7; color: #111; font-family: Arial, sans-serif; }
    .review-shell { display: grid; gap: 40px; padding: 32px; }
    .review-note { max-width: 960px; font-size: 16px; line-height: 1.5; }
    .review-slide { display: grid; gap: 12px; justify-items: start; }
    .review-slide > header { display: flex; gap: 16px; align-items: baseline; font-size: 16px; }
    .review-slide > header span { font-weight: 700; }
    .review-slide > .slide { width: 1920px; height: 1080px; transform-origin: top left; box-shadow: 0 16px 44px rgba(0,0,0,.18); }
    @media (max-width: 2100px) { .review-slide > .slide { transform: scale(.5); margin-bottom: -540px; } }
  </style>
</head>
<body>
  <main class="review-shell">
    <section class="review-note">
      <h1>${htmlEscape(title)} review</h1>
      <p>This page exposes every slide as live HTML DOM for annotation and semantic visual QA. It is not the final presentation surface; use <a href="index.html">index.html</a> for the live deck.</p>
    </section>
${frames}
  </main>
</body>
</html>
`;
  fs.writeFileSync(path.join(deckDir, "review.html"), reviewHtml);
}

function readPngSize(filePath) {
  const buffer = fs.readFileSync(filePath);
  if (buffer.subarray(0, 8).toString("hex") !== "89504e470d0a1a0a") throw new Error("not a PNG file");
  return { width: buffer.readUInt32BE(16), height: buffer.readUInt32BE(20), bytes: buffer.length };
}

async function writeContactSheet(browser, renderedFiles) {
  const rows = renderedFiles.map((file) => {
    return `<figure><img src="${htmlEscape(file)}" alt="${htmlEscape(file)}"><figcaption>${htmlEscape(file)}</figcaption></figure>`;
  }).join("");
  const page = await browser.newPage({ viewport: { width: 1400, height: 1000 }, deviceScaleFactor: 1 });
  const contactHtml = path.join(deckDir, "renders", "contact-sheet.html");
  fs.writeFileSync(contactHtml, `<!doctype html><html><head><meta charset="utf-8"><style>
    body { margin: 0; padding: 28px; background: #fff; font-family: Arial, sans-serif; }
    main { display: grid; grid-template-columns: repeat(2, 1fr); gap: 28px; }
    figure { margin: 0; }
    img { width: 100%; display: block; border: 1px solid #ddd; }
    figcaption { margin-top: 8px; font-size: 16px; color: #333; }
  </style></head><body><main>${rows}</main></body></html>`);
  await page.goto(pathToFileURL(contactHtml).href, { waitUntil: "load" });
  await page.evaluate(async () => {
    await Promise.all([...document.images].map((img) => img.complete ? true : new Promise((resolve, reject) => {
      img.onload = resolve;
      img.onerror = reject;
    })));
  });
  await page.screenshot({ path: path.join(deckDir, "renders", "contact-sheet.png"), fullPage: true });
  await page.close();

  const detailedRows = renderedFiles.map((file) => {
    return `<figure><img src="${htmlEscape(file)}" alt="${htmlEscape(file)}"><figcaption>${htmlEscape(file)}</figcaption></figure>`;
  }).join("");
  const detailedPage = await browser.newPage({ viewport: { width: 2200, height: 1400 }, deviceScaleFactor: 1 });
  const detailedHtml = path.join(deckDir, "renders", "contact-sheet-detailed.html");
  fs.writeFileSync(detailedHtml, `<!doctype html><html><head><meta charset="utf-8"><style>
    body { margin: 0; padding: 48px; background: #fff; font-family: Arial, sans-serif; }
    main { display: grid; grid-template-columns: 1fr; gap: 56px; }
    figure { margin: 0; }
    img { width: 1920px; max-width: 100%; display: block; border: 1px solid #d4d7dd; }
    figcaption { margin-top: 12px; font-size: 20px; color: #222; font-weight: 700; }
  </style></head><body><main>${detailedRows}</main></body></html>`);
  await detailedPage.goto(pathToFileURL(detailedHtml).href, { waitUntil: "load" });
  await detailedPage.evaluate(async () => {
    await Promise.all([...document.images].map((img) => img.complete ? true : new Promise((resolve, reject) => {
      img.onload = resolve;
      img.onerror = reject;
    })));
  });
  await detailedPage.screenshot({ path: path.join(deckDir, "renders", "contact-sheet-detailed.png"), fullPage: true });
  await detailedPage.close();
}

function writeQaLedgerSkeleton(files) {
  const sourceDir = path.join(deckDir, "source");
  fs.mkdirSync(sourceDir, { recursive: true });
  const ledgerPath = path.join(sourceDir, "visual-qa-ledger.md");
  let ledger = "";
  if (fs.existsSync(ledgerPath)) ledger = fs.readFileSync(ledgerPath, "utf8");
  if (!ledger.trim()) {
    ledger = `# Visual QA Ledger

Generated entries are a review scaffold, not a completed semantic visual QA pass. Fill this after inspecting the live deck, contact sheets, and full-size changed/dense slide renders.

`;
  }
  for (let index = 0; index < files.length; index++) {
    const file = files[index];
    const render = `renders/${file.replace(/\.html$/i, ".png")}`;
    if (!ledger.includes(`## Slide ${index + 1}: ${file}`)) {
      ledger += `\n## Slide ${index + 1}: ${file}

- Render: ${render}
- Review status: not reviewed
- Slide job / claim:
- Density / whitespace:
- Hierarchy / focal point:
- Overlap / clipping:
- Visual meaning system consistency:
- Required fixes:

`;
    }
  }
  fs.writeFileSync(ledgerPath, ledger);
}

function runDoctor() {
  const checks = [];
  const add = (ok, message) => checks.push({ ok, message });
  add(fs.existsSync(deckDir), `deck directory exists: ${deckDir}`);
  add(fs.existsSync(path.join(deckDir, "slides")), "slides/ directory exists");
  add(fs.existsSync(path.join(deckDir, "deck.css")), "deck.css exists");
  add(fs.existsSync(path.join(deckDir, "support", "base.css")), "support/base.css exists");
  add(fs.existsSync(path.join(deckDir, "support", "deck.js")), "support/deck.js exists");
  let files = [];
  try {
    files = listSlides();
    add(true, `${files.length} slide html file(s) found`);
  } catch (error) {
    add(false, error.message);
  }
  add(Boolean(chromium), "playwright chromium module is available");
  checks.forEach((check) => console.log(`${check.ok ? "PASS" : "FAIL"} ${check.message}`));
  const failures = checks.filter((check) => !check.ok);
  if (failures.length) process.exit(1);
  console.log("Doctor passed. No deck artifacts were written.");
}

async function inspectSlide(page, index) {
  await page.goto(`${pathToFileURL(path.join(deckDir, "index.html")).href}#slide-${index + 1}`, { waitUntil: "load" });
  await page.evaluate(async () => { if (document.fonts && document.fonts.ready) await document.fonts.ready; });
  await page.evaluate((activeIndex) => {
    const frames = [...document.querySelectorAll(".slide-frame")];
    frames.forEach((frame, frameIndex) => { frame.hidden = frameIndex !== activeIndex; });
    document.querySelector("[data-slide-count]") && (document.querySelector("[data-slide-count]").textContent = `${activeIndex + 1} / ${frames.length}`);
  }, index);
  await page.waitForTimeout(100);
  return page.evaluate(() => {
    const active = [...document.querySelectorAll(".slide-frame")].find((slide) => !slide.hidden);
    const slide = active?.querySelector(".slide");
    const failures = [];
    if (!active || !slide) failures.push("active slide frame missing");
    const slideRect = slide?.getBoundingClientRect();
    const elements = slide ? [...slide.querySelectorAll("*")] : [];
    for (const el of elements) {
      const rect = el.getBoundingClientRect();
      const style = getComputedStyle(el);
      if (rect.width <= 0 || rect.height <= 0 || style.visibility === "hidden" || style.display === "none") continue;
      if (slideRect && (rect.left < slideRect.left - 2 || rect.top < slideRect.top - 2 || rect.right > slideRect.right + 2 || rect.bottom > slideRect.bottom + 2)) {
        failures.push(`element outside slide bounds: ${el.tagName.toLowerCase()} "${(el.textContent || el.alt || "").trim().slice(0, 40)}"`);
      }
      if ((el.matches("h1,h2,h3,p,li") || el.textContent.trim()) && rect.width > 0 && rect.height > 0) {
        const clipsOverflow = ["hidden", "clip"].includes(style.overflowX) || ["hidden", "clip"].includes(style.overflowY);
        if (clipsOverflow && (el.scrollWidth > el.clientWidth + 2 || el.scrollHeight > el.clientHeight + 2)) {
          failures.push(`text may be clipped: ${el.tagName.toLowerCase()} "${el.textContent.trim().slice(0, 40)}"`);
        }
        const fontSize = Number.parseFloat(style.fontSize);
        if (fontSize && fontSize < 12) failures.push(`text too small: ${Math.round(fontSize)}px`);
      }
    }
    for (const img of slide ? [...slide.querySelectorAll("img")] : []) {
      if (!img.complete || img.naturalWidth === 0) failures.push(`image failed to load: ${img.getAttribute("src")}`);
    }
    return failures;
  });
}

async function main() {
  if (doctorMode) {
    runDoctor();
    return;
  }
  const files = listSlides();
  assembleIndex(files);
  assembleReview(files);
  fs.mkdirSync(path.join(deckDir, "renders"), { recursive: true });

  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width, height }, deviceScaleFactor: 1 });
  const failures = [];
  const renderedFiles = [];
  page.on("console", (msg) => { if (msg.type() === "error") failures.push(`console error: ${msg.text()}`); });
  page.on("pageerror", (error) => failures.push(`page error: ${error.message}`));

  for (let index = 0; index < files.length; index++) {
    const html = fs.readFileSync(path.join(deckDir, "slides", files[index]), "utf8");
    if (requireFooter && !html.includes("Copyright") && !html.includes("All Rights Reserved")) failures.push(`${files[index]} is missing footer text`);
    const slideFailures = await inspectSlide(page, index);
    failures.push(...slideFailures.map((failure) => `${files[index]}: ${failure}`));
    const pngFile = files[index].replace(/\.html$/i, ".png");
    const outPath = path.join(deckDir, "renders", pngFile);
    const activeFrame = await page.$(".slide-frame:not([hidden])");
    if (!activeFrame) throw new Error("Active slide frame not found for screenshot");
    // Hide live-deck chrome (nav controls) so it never bleeds into QA/export renders.
    // Each iteration re-navigates via inspectSlide's page.goto, so no restore is needed.
    await page.evaluate(() => {
      const controls = document.querySelector(".deck-controls");
      if (controls) controls.style.visibility = "hidden";
    });
    await activeFrame.screenshot({ path: outPath });
    renderedFiles.push(pngFile);
    const size = readPngSize(outPath);
    if (size.width !== width || size.height !== height) failures.push(`${pngFile} is ${size.width}x${size.height}; expected ${width}x${height}`);
    if (size.bytes < minPngBytes) failures.push(`${pngFile} is suspiciously small (${size.bytes} bytes)`);
    console.log(`Rendered ${files[index]} -> ${path.relative(deckDir, outPath)}`);
  }

  await writeContactSheet(browser, renderedFiles);
  writeQaLedgerSkeleton(files);
  await browser.close();
  if (failures.length) {
    console.error(`Deck QA found ${failures.length} issue(s):`);
    failures.forEach((failure) => console.error(`FAIL ${failure}`));
    process.exit(1);
  }
  console.log(`Deck package built: ${pathToFileURL(path.join(deckDir, "index.html")).href}`);
  console.log(`Review page built: ${pathToFileURL(path.join(deckDir, "review.html")).href}`);
  console.log(`Structural QA passed for ${files.length} slide(s). Semantic visual inspection is still required before delivery.`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
