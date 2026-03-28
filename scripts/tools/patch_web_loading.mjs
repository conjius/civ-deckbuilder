import { readFileSync, writeFileSync } from "fs";

const file = process.argv[2];
let html = readFileSync(file, "utf8");

const css = `<style>
body, #status { background: #000 !important; }
#status-splash { animation: pulse 2s ease-in-out infinite !important; }
@keyframes pulse { 0%,100%{opacity:1} 50%{opacity:0.3} }
#status-progress { transition: none !important; }
</style>`;
html = html.replace("<head>", `<head><script src="coi-serviceworker.min.js"></script>${css}`);

const oldProgress = `'onProgress': function (current, total) {
				if (current > 0 && total > 0) {
					statusProgress.value = current;
					statusProgress.max = total;
				} else {
					statusProgress.removeAttribute('value');
					statusProgress.removeAttribute('max');
				}
			},`;

const newProgress = `'onProgress': function (current, total) {
				if (current > 0 && total > 0) {
					statusProgress.max = total * 2;
					statusProgress.value = current;
					if (current >= total) {
						statusProgress.removeAttribute('value');
						statusProgress.removeAttribute('max');
						document.getElementById('status-notice').textContent = 'Initializing...';
					}
				} else {
					statusProgress.removeAttribute('value');
					statusProgress.removeAttribute('max');
				}
			},`;

html = html.replace(oldProgress, newProgress);

writeFileSync(file, html);
console.log("Patched loading screen:", file);
