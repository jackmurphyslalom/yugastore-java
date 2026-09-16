import { createRequire } from "node:module";
const require = createRequire(import.meta.url);

const fs = require("fs");
const path = require("path");

const firstArg = path.resolve(process.argv[2] || ".");
const packageMode = fs.existsSync(path.join(firstArg, "slides")) && fs.existsSync(path.join(firstArg, "renders"));
const slidesDir = packageMode ? path.join(firstArg, "slides") : path.resolve(process.argv[2] || "slides");
const rendersDir = packageMode ? path.join(firstArg, "renders") : path.resolve(process.argv[3] || "renders");
const expectedWidth = Number(process.env.SLIDE_WIDTH || 1920);
const expectedHeight = Number(process.env.SLIDE_HEIGHT || 1080);
const minPngBytes = Number(process.env.MIN_RENDER_BYTES || 12000);
const requireFooter = !["1", "true", "yes"].includes(String(process.env.PUBLIC_DECK || "").toLowerCase());

function fail(message, failures) {
  failures.push(message);
  console.error(`FAIL ${message}`);
}

function readPngSize(filePath) {
  const buffer = fs.readFileSync(filePath);
  const signature = buffer.subarray(0, 8).toString("hex");
  if (signature !== "89504e470d0a1a0a") {
    throw new Error("not a PNG file");
  }
  return {
    width: buffer.readUInt32BE(16),
    height: buffer.readUInt32BE(20),
    bytes: buffer.length,
  };
}

function main() {
  const failures = [];

  if (!fs.existsSync(slidesDir)) {
    throw new Error(`Slides directory not found: ${slidesDir}`);
  }
  if (!fs.existsSync(rendersDir)) {
    throw new Error(`Renders directory not found: ${rendersDir}`);
  }

  const slideFiles = fs.readdirSync(slidesDir)
    .filter((file) => file.endsWith(".html"))
    .sort((a, b) => a.localeCompare(b, undefined, { numeric: true }));

  if (!slideFiles.length) {
    throw new Error(`No .html slides found in ${slidesDir}`);
  }

  for (const slideFile of slideFiles) {
    const slidePath = path.join(slidesDir, slideFile);
    const html = fs.readFileSync(slidePath, "utf8");
    const pngFile = slideFile.replace(/\.html$/i, ".png");
    const pngPath = path.join(rendersDir, pngFile);

    if (requireFooter && !html.includes("Copyright") && !html.includes("All Rights Reserved")) {
      fail(`${slideFile} is missing the required Slalom footer text`, failures);
    }

    if (!fs.existsSync(pngPath)) {
      fail(`${pngFile} is missing`, failures);
      continue;
    }

    try {
      const size = readPngSize(pngPath);
      if (size.width !== expectedWidth || size.height !== expectedHeight) {
        fail(`${pngFile} is ${size.width}x${size.height}; expected ${expectedWidth}x${expectedHeight}`, failures);
      }
      if (size.bytes < minPngBytes) {
        fail(`${pngFile} is suspiciously small (${size.bytes} bytes)`, failures);
      }
    } catch (error) {
      fail(`${pngFile} could not be inspected: ${error.message}`, failures);
    }
  }

  const indexPath = packageMode ? path.join(firstArg, "index.html") : path.join(rendersDir, "index.html");
  if (!fs.existsSync(indexPath)) {
    fail(packageMode ? "index.html live deck is missing" : "renders/index.html preview deck is missing", failures);
  }

  if (failures.length) {
    console.error(`Structural QA found ${failures.length} issue(s).`);
    process.exit(1);
  }

  console.log(`Structural QA passed for ${slideFiles.length} slide(s). Semantic visual inspection is still required before delivery.`);
}

main();
