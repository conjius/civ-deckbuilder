import { createServer } from "http";
import { readFile } from "fs/promises";
import { join, extname } from "path";

const PORT = 8060;
const DIR = join(import.meta.dirname, "../../build/web");

const MIME = {
  ".html": "text/html",
  ".js": "application/javascript",
  ".mjs": "application/javascript",
  ".wasm": "application/wasm",
  ".pck": "application/octet-stream",
  ".png": "image/png",
  ".svg": "image/svg+xml",
  ".ico": "image/x-icon",
  ".css": "text/css",
  ".json": "application/json",
};

const server = createServer(async (req, res) => {
  const url = req.url === "/" ? "/index.html" : req.url.split("?")[0];
  const filePath = join(DIR, url);

  // COOP/COEP headers for Godot WASM — skip on Safari (breaks require-corp)
  const ua = req.headers["user-agent"] || "";
  const isSafari = ua.includes("Safari") && !ua.includes("Chrome");
  if (!isSafari) {
    res.setHeader("Cross-Origin-Opener-Policy", "same-origin");
    res.setHeader("Cross-Origin-Embedder-Policy", "require-corp");
  }
  res.setHeader("Cross-Origin-Resource-Policy", "cross-origin");

  try {
    const data = await readFile(filePath);
    const ext = extname(filePath);
    res.writeHead(200, { "Content-Type": MIME[ext] || "application/octet-stream" });
    res.end(data);
  } catch {
    res.writeHead(404);
    res.end("Not found");
  }
});

server.listen(PORT, "0.0.0.0", () => {
  console.log(`LAN server: http://0.0.0.0:${PORT}`);
});
