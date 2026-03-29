import { readFileSync, writeFileSync } from "fs";

const file = process.argv[2];
let html = readFileSync(file, "utf8");

// Hide the entire Godot HTML loading screen — just black until custom loads
const css = `<style>
body { background: #000 !important; margin: 0; }
#status, #status-splash, #status-progress, #status-notice,
#status-splash img { display: none !important; }
canvas { background: #000 !important; }
</style>`;
html = html.replace("<head>", `<head><script src="coi-serviceworker.min.js"></script>${css}`);

writeFileSync(file, html);
console.log("Patched loading screen:", file);
