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

const DEV_SCRIPTS = `<script>
(function(){
  function connect() {
    var es = new EventSource("/__reload");
    es.onmessage = function(e) {
      if (e.data === "reload") location.reload();
    };
    es.onerror = function() {
      es.close();
      setTimeout(connect, 2000);
    };
  }
  if (document.readyState === "complete") connect();
  else window.addEventListener("load", connect);
})();
</script>`;

// --- SSE live reload ---

let reloadClients = [];
let lastReloadMtime = 0;

function handleSSE(req, res) {
  res.writeHead(200, {
    "Content-Type": "text/event-stream",
    "Cache-Control": "no-cache",
    "Connection": "keep-alive",
    "Cross-Origin-Resource-Policy": "same-origin",
  });
  res.write("data: connected\n\n");
  reloadClients.push(res);
  req.on("close", () => {
    reloadClients = reloadClients.filter(c => c !== res);
  });
}

// --- ETag caching ---

async function getETag(filePath) {
  const s = await stat(filePath);
  return `"${s.mtimeMs.toString(36)}-${s.size.toString(36)}"`;
}

// --- COOP/COEP headers ---

function setCrossOriginHeaders(req, res) {
  const ua = req.headers["user-agent"] || "";
  const isSafari = ua.includes("Safari") && !ua.includes("Chrome");
  if (!isSafari) {
    res.setHeader("Cross-Origin-Opener-Policy", "same-origin");
    res.setHeader("Cross-Origin-Embedder-Policy", "require-corp");
  }
  res.setHeader("Cross-Origin-Resource-Policy", "cross-origin");
}

// --- In-memory file cache ---

const fileCache = new Map();

async function getCachedFile(filePath) {
  const s = await stat(filePath);
  const mtime = s.mtimeMs;
  const cached = fileCache.get(filePath);
  if (cached && cached.mtime === mtime) return cached;
  let data = await readFile(filePath);
  const ext = extname(filePath);
  const etag = `"${mtime.toString(36)}-${s.size.toString(36)}"`;
  if (ext === ".html") {
    data = Buffer.from(
      data.toString().replace("</head>", DEV_SCRIPTS + "</head>")
    );
  }
  const entry = { data, etag, mtime, ext };
  fileCache.set(filePath, entry);
  return entry;
}

// Invalidate cache when rebuild triggers
setInterval(async () => {
  try {
    const s = await stat(RELOAD_FILE);
    const mtime = s.mtimeMs;
    if (mtime > lastReloadMtime && lastReloadMtime > 0) {
      fileCache.clear();
      reloadClients.forEach(r => r.write("data: reload\n\n"));
    }
    lastReloadMtime = mtime;
  } catch {}
}, 500);

// --- Request handler ---

const server = createServer(async (req, res) => {
  if (req.url === "/__reload") return handleSSE(req, res);

  const url = req.url === "/" ? "/index.html" : req.url.split("?")[0];
  const filePath = join(DIR, url);

  setCrossOriginHeaders(req, res);

  try {
    const entry = await getCachedFile(filePath);

    if (req.headers["if-none-match"] === entry.etag) {
      res.writeHead(304);
      res.end();
      return;
    }

    if (entry.ext === ".html") {
      res.writeHead(200, {
        "Content-Type": "text/html",
        "Cache-Control": "no-cache",
      });
    } else {
      res.writeHead(200, {
        "Content-Type": MIME[entry.ext] || "application/octet-stream",
        "ETag": entry.etag,
        "Cache-Control": "max-age=31536000, immutable",
      });
    }
    res.end(entry.data);
  } catch {
    res.writeHead(404);
    res.end("Not found");
  }
});

server.listen(PORT, "0.0.0.0", () => {
  console.log(`LAN server: http://0.0.0.0:${PORT} (live reload + cache)`);
});
