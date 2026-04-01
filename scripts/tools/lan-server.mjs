import { createServer } from "http";
import { readFile, stat } from "fs/promises";
import { join, extname } from "path";

const PORT = 8060;
const DIR = join(import.meta.dirname, "../../build/web");
const RELOAD_FILE = join(import.meta.dirname, "../../build/.reload");

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

const RELOAD_SCRIPT = `<script>
(function(){
  var es = new EventSource("/__reload");
  es.onmessage = function() { location.reload(); };
})();
</script>`;

let reloadClients = [];
let lastReloadMtime = 0;

// Poll the reload trigger file
setInterval(async () => {
  try {
    const s = await stat(RELOAD_FILE);
    const mtime = s.mtimeMs;
    if (mtime > lastReloadMtime && lastReloadMtime > 0) {
      reloadClients.forEach(res => {
        res.write("data: reload\n\n");
      });
    }
    lastReloadMtime = mtime;
  } catch {}
}, 500);

const server = createServer(async (req, res) => {
  // SSE endpoint for live reload
  if (req.url === "/__reload") {
    res.writeHead(200, {
      "Content-Type": "text/event-stream",
      "Cache-Control": "no-cache",
      "Connection": "keep-alive",
    });
    res.write("data: connected\n\n");
    reloadClients.push(res);
    req.on("close", () => {
      reloadClients = reloadClients.filter(c => c !== res);
    });
    return;
  }

  const url = req.url === "/" ? "/index.html" : req.url.split("?")[0];
  const filePath = join(DIR, url);

  const ua = req.headers["user-agent"] || "";
  const isSafari = ua.includes("Safari") && !ua.includes("Chrome");
  if (!isSafari) {
    res.setHeader("Cross-Origin-Opener-Policy", "same-origin");
    res.setHeader("Cross-Origin-Embedder-Policy", "require-corp");
  }
  res.setHeader("Cross-Origin-Resource-Policy", "cross-origin");

  try {
    let data = await readFile(filePath);
    const ext = extname(filePath);
    // Inject reload script into HTML
    if (ext === ".html") {
      data = Buffer.from(
        data.toString().replace("</head>", RELOAD_SCRIPT + "</head>")
      );
    }
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
