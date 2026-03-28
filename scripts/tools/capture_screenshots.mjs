import puppeteer from "puppeteer";
import { createServer } from "http";
import { readFileSync, existsSync, statSync } from "fs";
import { join, extname } from "path";

const MIME_TYPES = {
  ".html": "text/html",
  ".js": "application/javascript",
  ".wasm": "application/wasm",
  ".pck": "application/octet-stream",
  ".png": "image/png",
  ".svg": "image/svg+xml",
};

const WEB_DIR = process.argv[2] || "build/web";
const OUT_DIR = process.argv[3] || "screenshots";
const LOAD_TIMEOUT = 30000;
const RENDER_WAIT = 8000;
const GALLERY_WAIT = 3000;

function serve(dir, port) {
  return new Promise((resolve) => {
    const server = createServer((req, res) => {
      const filePath = join(dir, req.url === "/" ? "index.html" : req.url);
      if (!existsSync(filePath) || statSync(filePath).isDirectory()) {
        res.writeHead(404);
        res.end();
        return;
      }
      const ext = extname(filePath);
      const mime = MIME_TYPES[ext] || "application/octet-stream";
      const headers = { "Content-Type": mime };
      if (ext === ".wasm") {
        headers["Cross-Origin-Opener-Policy"] = "same-origin";
        headers["Cross-Origin-Embedder-Policy"] = "require-corp";
      }
      res.writeHead(200, headers);
      res.end(readFileSync(filePath));
    });
    server.listen(port, () => resolve(server));
  });
}

async function run() {
  const port = 8060;
  const server = await serve(WEB_DIR, port);
  console.log(`Serving ${WEB_DIR} on :${port}`);

  const browser = await puppeteer.launch({
    headless: true,
    args: [
      "--no-sandbox",
      "--disable-setuid-sandbox",
      "--use-gl=swiftshader",
      "--enable-webgl",
    ],
  });

  const page = await browser.newPage();
  await page.setViewport({ width: 1920, height: 1080 });

  console.log("Loading game...");
  await page.goto(`http://localhost:${port}`, {
    waitUntil: "networkidle0",
    timeout: LOAD_TIMEOUT,
  });

  console.log(`Waiting ${RENDER_WAIT / 1000}s for game to render...`);
  await new Promise((r) => setTimeout(r, RENDER_WAIT));

  console.log("Capturing main screenshot...");
  await page.screenshot({ path: join(OUT_DIR, "screenshot-main.jpg"), type: "jpeg", quality: 85 });

  console.log("Opening gallery (right-click)...");
  await page.mouse.click(960, 900, { button: "right" });

  console.log(`Waiting ${GALLERY_WAIT / 1000}s for gallery animation...`);
  await new Promise((r) => setTimeout(r, GALLERY_WAIT));

  console.log("Capturing gallery screenshot...");
  await page.screenshot({ path: join(OUT_DIR, "screenshot-gallery.jpg"), type: "jpeg", quality: 85 });

  await browser.close();
  server.close();
  console.log("Done.");
}

run().catch((err) => {
  console.error(err);
  process.exit(1);
});
