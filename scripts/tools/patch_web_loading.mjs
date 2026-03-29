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
img#status-splash, img#status-splash.fullsize--true {
  width: 950px !important; height: auto !important;
  max-width: 950px !important; max-height: none !important;
  object-fit: contain !important;
  image-rendering: auto !important; opacity: 0;
  position: fixed !important;
  top: 50% !important; left: 50% !important;
  right: auto !important; bottom: auto !important;
  margin: 0 !important; padding: 0 !important;
  transform: translate(-50%, -60%) !important;
}
#status-progress {
  width: 300px !important; height: 12px !important;
  appearance: none; -webkit-appearance: none;
  border: none; background: #1a1a1a; border-radius: 6px;
  position: fixed !important;
  top: 50% !important; left: 50% !important;
  transform: translate(-50%, 210px) !important;
  margin: 0 !important; padding: 0 !important;
}
#status-progress::-webkit-progress-bar { background: #1a1a1a; border-radius: 6px; }
#status-progress::-webkit-progress-value { background: #e8c055; border-radius: 6px; }
#status-progress::-moz-progress-bar { background: #e8c055; border-radius: 6px; }
#status-notice { display: none !important; }
canvas { background: #000 !important; }
</style>`;
html = html.replace("<head>", `<head><script src="coi-serviceworker.min.js"></script>${css}`);

// Disable the default progress handler — our script handles everything
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
				if (window.__civdecksProgress && current > 0 && total > 0) {
					window.__civdecksProgress.target = current / total;
				}
			},`;

html = html.replace(oldProgress, newProgress);

const initScript = `<script>
(function() {
	var state = {
		target: 0,
		displayed: 0,
		done: false
	};
	window.__civdecksProgress = state;

	var bar = null;
	var logo = null;

	function tick() {
		if (state.done) return;

		if (!bar) bar = document.getElementById('status-progress');
		if (!logo) logo = document.getElementById('status-splash');

		// Smooth lerp toward target
		if (state.target > 0) {
			var gap = state.target - state.displayed;
			if (gap > 0.01) {
				// Move at 0.8% of remaining gap per frame (slow, smooth)
				state.displayed += gap * 0.008;
			}
			// Always creep forward so bar never looks stuck
			state.displayed += 0.0015;
			state.displayed = Math.min(state.displayed, 0.98);
		}

		if (bar) {
			bar.max = 1000;
			bar.value = Math.floor(state.displayed * 1000);
		}
		if (logo) {
			logo.style.opacity = state.displayed;
		}

		requestAnimationFrame(tick);
	}
	requestAnimationFrame(tick);

	// Detect game ready -> snap to 100% and fade out
	// Wait for download to actually start before checking canvas
	var canvasFrames = 0;
	var checkCanvas = setInterval(function() {
		if (state.target < 0.1) return; // download hasn't started
		var canvas = document.querySelector('canvas');
		if (canvas && canvas.width > 100 && canvas.height > 100) {
			canvasFrames++;
			// Require 10 consecutive checks (~1s) to confirm game is rendering
			if (canvasFrames >= 10) {
				clearInterval(checkCanvas);
				state.done = true;
				if (bar) { bar.max = 1000; bar.value = 1000; }
				if (logo) logo.style.opacity = 1;
				setTimeout(function() {
					var status = document.getElementById('status');
					if (status) {
						status.style.opacity = '0';
						setTimeout(function() { status.style.display = 'none'; }, 600);
					}
				}, 400);
			}
		} else {
			canvasFrames = 0;
		}
	}, 100);
})();
</script>`;

html = html.replace("</head>", `${initScript}</head>`);

writeFileSync(file, html);
console.log("Patched loading screen:", file);
