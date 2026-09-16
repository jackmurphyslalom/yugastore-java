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
    console.error("Playwright is not available to this Node process.");
    console.error("Install it in the harness/project with: npm install --save-dev playwright");
    console.error("Then install the managed browser with: npx playwright install chromium");
    console.error("In Codex Desktop, you can also run with the bundled Node dependencies when available.");
    process.exit(1);
  }
  throw error;
}

const slidesDir = path.resolve(process.argv[2] || "slides");
const outDir = path.resolve(process.argv[3] || "renders");
const width = Number(process.env.SLIDE_WIDTH || 1920);
const height = Number(process.env.SLIDE_HEIGHT || 1080);

function htmlEscape(value) {
  return String(value)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

function writePreview(renderedFiles) {
  const slidesMarkup = renderedFiles.map((file, index) => {
    const activeClass = index === 0 ? " is-active" : "";
    return `      <section class="slide${activeClass}" aria-label="Slide ${index + 1}">\n        <img src="${htmlEscape(file)}" alt="Rendered slide ${index + 1}">\n      </section>`;
  }).join("\n");

  const previewHtml = `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Rendered Slide Deck</title>
  <style>
    * { box-sizing: border-box; }
    html, body { margin: 0; min-height: 100%; background: #000; font-family: Arial, sans-serif; }
    body { display: grid; place-items: center; padding: 24px; }
    .deck { width: min(100%, calc(100vh * 16 / 9 - 48px)); max-width: ${width}px; aspect-ratio: 16 / 9; position: relative; }
    .slide { display: none; width: 100%; height: 100%; margin: 0; background: #fff; }
    .slide.is-active { display: block; }
    .slide img { display: block; width: 100%; height: 100%; object-fit: contain; }
    .controls {
      position: fixed;
      right: 24px;
      bottom: 24px;
      display: flex;
      align-items: center;
      gap: 10px;
      color: #fff;
      font-size: 14px;
    }
    button {
      width: 40px;
      height: 40px;
      border: 1px solid rgba(255,255,255,.45);
      border-radius: 999px;
      background: rgba(255,255,255,.12);
      color: #fff;
      font: inherit;
      cursor: pointer;
    }
    button:focus-visible { outline: 3px solid #0c62fb; outline-offset: 3px; }
    @media (max-width: 760px) {
      body { padding: 12px; }
      .deck { width: min(100%, calc(100vh * 16 / 9 - 24px)); }
      .controls { right: 12px; bottom: 12px; }
    }
  </style>
</head>
<body>
  <main class="deck" aria-label="Rendered slide deck">
${slidesMarkup}
  </main>
  <nav class="controls" aria-label="Slide controls">
    <button type="button" data-prev aria-label="Previous slide">‹</button>
    <span data-count>1 / ${renderedFiles.length}</span>
    <button type="button" data-next aria-label="Next slide">›</button>
  </nav>
  <script>
    const slides = [...document.querySelectorAll(".slide")];
    const count = document.querySelector("[data-count]");
    let active = 0;

    function showSlide(index) {
      active = Math.max(0, Math.min(slides.length - 1, index));
      slides.forEach((slide, i) => slide.classList.toggle("is-active", i === active));
      count.textContent = \`\${active + 1} / \${slides.length}\`;
      history.replaceState(null, "", \`#slide-\${active + 1}\`);
    }

    document.querySelector("[data-prev]").addEventListener("click", () => showSlide(active - 1));
    document.querySelector("[data-next]").addEventListener("click", () => showSlide(active + 1));
    window.addEventListener("keydown", (event) => {
      if (["ArrowRight", "PageDown", " "].includes(event.key)) showSlide(active + 1);
      if (["ArrowLeft", "PageUp"].includes(event.key)) showSlide(active - 1);
      if (event.key === "Home") showSlide(0);
      if (event.key === "End") showSlide(slides.length - 1);
    });

    const hashSlide = Number((location.hash.match(/slide-(\\d+)/) || [])[1]);
    if (hashSlide) showSlide(hashSlide - 1);
  </script>
</body>
</html>
`;

  const previewPath = path.join(outDir, "index.html");
  fs.writeFileSync(previewPath, previewHtml);
  return previewPath;
}

async function main() {
  if (!fs.existsSync(slidesDir)) {
    throw new Error(`Slides directory not found: ${slidesDir}`);
  }

  fs.mkdirSync(outDir, { recursive: true });
  const files = fs.readdirSync(slidesDir)
    .filter((file) => file.endsWith(".html"))
    .sort((a, b) => a.localeCompare(b, undefined, { numeric: true }));

  if (!files.length) {
    throw new Error(`No .html slides found in ${slidesDir}`);
  }

  const launchOptions = {};
  if (process.env.PLAYWRIGHT_EXECUTABLE_PATH) {
    launchOptions.executablePath = process.env.PLAYWRIGHT_EXECUTABLE_PATH;
  }
  if (process.env.PLAYWRIGHT_CHANNEL) {
    launchOptions.channel = process.env.PLAYWRIGHT_CHANNEL;
  }

  const browser = await chromium.launch(launchOptions);
  const page = await browser.newPage({ viewport: { width, height }, deviceScaleFactor: 1 });
  const renderedFiles = [];

  for (const file of files) {
    const filePath = path.join(slidesDir, file);
    const url = pathToFileURL(filePath).href;
    await page.goto(url, { waitUntil: "load" });
    await page.evaluate(async () => {
      if (document.fonts && document.fonts.ready) await document.fonts.ready;
    });
    await page.waitForTimeout(100);
    const renderedFile = file.replace(/\.html$/i, ".png");
    const outPath = path.join(outDir, renderedFile);
    await page.screenshot({ path: outPath, fullPage: false });
    renderedFiles.push(renderedFile);
    console.log(`Rendered ${file} -> ${path.relative(process.cwd(), outPath)}`);
  }

  await browser.close();
  const previewPath = writePreview(renderedFiles);
  console.log(`Preview deck -> ${pathToFileURL(previewPath).href}`);
}

main().catch((error) => {
  const message = String(error && (error.stack || error.message || error));
  if (message.includes("Executable doesn't exist") || message.includes("playwright install")) {
    console.error("Playwright is installed, but its managed browser binary is missing.");
    console.error("Install the managed Chromium browser with: npx playwright install chromium");
    console.error("Using system Chrome via PLAYWRIGHT_EXECUTABLE_PATH is only a temporary fallback and may trigger OS crash popups in restricted environments.");
  }
  if (message.includes("MachPortRendezvousServer") || message.includes("Permission denied (1100)")) {
    console.error("Chromium launched but macOS blocked it from the current sandbox.");
    console.error("Rerun the same render command with escalated approval/outside-sandbox browser launch permissions.");
  }
  console.error(error);
  process.exit(1);
});
