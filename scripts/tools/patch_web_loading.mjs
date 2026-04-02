import { readFileSync, writeFileSync } from "fs";

const file = process.argv[2];
let html = readFileSync(file, "utf8");

const css = `<style>
body { background: #000 !important; margin: 0; overflow: hidden; }
#status {
  position: absolute; top: 0; left: 0; width: 100%; height: 100%;
  display: flex; flex-direction: column; align-items: center;
  justify-content: center; background: #000; z-index: 10;
  transition: opacity 0.5s;
}
img#status-splash {
  width: min(80vw, 950px) !important; height: auto !important;
  max-width: min(80vw, 950px) !important; max-height: none !important;
  object-fit: contain !important;
  image-rendering: auto !important;
  position: fixed !important;
  top: 0 !important; left: 0 !important; right: 0 !important;
  bottom: clamp(4px, 6vh, 140px) !important;
  margin: auto !important; padding: 0 !important;
  opacity: 0;
  animation: logoFadeIn 14s cubic-bezier(0.4, 0, 1, 1) both !important;
}
@keyframes logoFadeIn {
  from { opacity: 0; transform: scale(0.56); }
  to { opacity: 1; transform: scale(0.68); }
}
#status-progress {
  width: 20vw !important; height: 6px !important;
  appearance: none; -webkit-appearance: none;
  border: none; background: #1a1a1a; border-radius: 2px;
  position: fixed !important;
  top: calc(50% + clamp(2px, 2vh, 60px)) !important; left: 50% !important;
  transform: translate(-50%, 0) !important;
  margin: 0 !important; padding: 0 !important;
  overflow: hidden;
}
#status-progress::-webkit-progress-bar { background: #1a1a1a; border-radius: 2px; }
#status-progress::-webkit-progress-value { background: #e8c055; border-radius: 2px; }
#status-progress::-moz-progress-bar { background: #e8c055; border-radius: 2px; }
#status-notice { display: none !important; }
canvas { background: #000 !important; }
.progress-fill {
  position: fixed; left: 50%;
  top: calc(50% + clamp(2px, 2vh, 60px));
  transform: translate(-50%, 0);
  width: 20vw; height: 6px;
  background: #1a1a1a;
  border-radius: 2px; overflow: hidden;
  z-index: 999; pointer-events: none;
}
.progress-fill-inner {
  width: 100%; height: 100%;
  background: #e8c055; border-radius: 2px;
  transform-origin: left center;
  transform: scaleX(0);
  animation: fillBar 14s linear forwards;
  will-change: transform;
}
@keyframes fillBar {
  0% { transform: scaleX(0); }
  100% { transform: scaleX(0.98); }
}
</style>`;
html = html.replace("<head>", `<head>${css}`);

// Disable default progress handler
const oldProgress = `'onProgress': function (current, total) {
				if (current > 0 && total > 0) {
					statusProgress.value = current;
					statusProgress.max = total;
				} else {
					statusProgress.removeAttribute('value');
					statusProgress.removeAttribute('max');
				}
			},`;

const newProgress = `'onProgress': function () {},`;

html = html.replace(oldProgress, newProgress);

// Hide the native progress element and add our CSS-animated one
// Also detect game ready to fade out
const initScript = `<script>
(function() {
	// Hide native progress bar, use CSS animated one instead
	var ready = setInterval(function() {
		var bar = document.getElementById('status-progress');
		if (bar) {
			bar.style.display = 'none';
			clearInterval(ready);
		}
	}, 10);

	// On cached loads, snap logo to full brightness immediately
	var cacheCheck = setInterval(function() {
		var entries = performance.getEntriesByType('resource');
		var wasm = entries.find(function(e) {
			return e.name.indexOf('.wasm') !== -1;
		});
		if (!wasm) return;
		clearInterval(cacheCheck);
		if (wasm.transferSize === 0) {
			var logo = document.getElementById('status-splash');
			if (logo) {
				logo.style.animation = 'none';
				logo.style.opacity = '1';
				logo.style.transform = 'scale(0.68)';
			}
		}
	}, 200);

	// Detect game ready -> snap to 100% and fade out
	var canvasFrames = 0;
	var checkCanvas = setInterval(function() {
		var canvas = document.querySelector('canvas');
		if (canvas && canvas.width > 100 && canvas.height > 100) {
			// Check if canvas has actual rendered content (not just blank)
			try {
				var gl = canvas.getContext('webgl2') || canvas.getContext('webgl');
				if (!gl) { return; }
				var pixel = new Uint8Array(4);
				gl.readPixels(
					Math.floor(canvas.width / 2), Math.floor(canvas.height / 2),
					1, 1, gl.RGBA, gl.UNSIGNED_BYTE, pixel
				);
				// Skip if pixel is black/empty (game not rendering yet)
				if (pixel[0] === 0 && pixel[1] === 0 && pixel[2] === 0) { return; }
			} catch(e) { return; }
			canvasFrames++;
			if (canvasFrames >= 1) {
				clearInterval(checkCanvas);
				var inner = document.querySelector('.progress-fill-inner');
				if (inner) {
					inner.style.animation = 'none';
					inner.style.transform = 'scaleX(1)';
				}
				var logo = document.getElementById('status-splash');
				if (logo) {
					logo.style.animation = 'none';
					logo.style.opacity = '1';
					logo.style.transform = 'scale(0.85)';
				}
				var status = document.getElementById('status');
				var fillEl = document.querySelector('.progress-fill');
				if (status) {
					status.style.transition = 'none';
					status.style.opacity = '0';
					status.style.display = 'none';
				}
				if (fillEl) {
					fillEl.style.transition = 'none';
					fillEl.style.opacity = '0';
					fillEl.style.display = 'none';
				}
			}
		} else {
			canvasFrames = 0;
		}
	}, 100);
})();
</script>`;

html = html.replace("</head>", `${initScript}</head>`);

// Inject progress bar inside #status (after the native progress element)
html = html.replace(
	'<div id="status-notice">',
	'<div class="progress-fill"><div class="progress-fill-inner"></div></div><div id="status-notice">'
);

// Keyboard fix
html = html.replace("<body>", `<body><script>
window.addEventListener('keydown', function(e) {
	if ((e.metaKey || e.ctrlKey) && (e.key === 'r' || e.key === 'R')) {
		e.stopImmediatePropagation();
	}
}, true);
</script>`);

// Remove fullsize class so Godot doesn't force 100% width/height
html = html.replaceAll('fullsize--true', 'fullsize--false');

// Disable cross-origin isolation check — not needed for single-threaded export
// Prevents Godot from trying to install a service worker that breaks iOS WebKit
html = html.replace(
	'"ensureCrossOriginIsolationHeaders":true',
	'"ensureCrossOriginIsolationHeaders":false'
);

writeFileSync(file, html);
console.log("Patched loading screen:", file);
