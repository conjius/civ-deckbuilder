import { readFileSync, writeFileSync } from "fs";

const file = process.argv[2];
let html = readFileSync(file, "utf8");

// Replace Godot's loading screen with our custom one
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
  transition: opacity 0.2s;
  position: fixed !important;
  top: 50% !important; left: 50% !important;
  right: auto !important; bottom: auto !important;
  margin: 0 !important; padding: 0 !important;
  transform: translate(-50%, -60%) !important;
}
#status-progress {
  width: 210px; height: 36px;
  appearance: none; -webkit-appearance: none;
  border: none; background: #1a1a1a; border-radius: 18px;
  transition: none;
  position: fixed !important;
  top: 50% !important; left: 50% !important;
  transform: translate(-50%, 160px) !important;
  margin: 0 !important; padding: 0 !important;
}
#status-progress::-webkit-progress-bar { background: #1a1a1a; border-radius: 18px; }
#status-progress::-webkit-progress-value { background: #d9a633; border-radius: 18px; transition: width 0.3s; }
#status-progress::-moz-progress-bar { background: #d9a633; border-radius: 18px; }
#status-notice {
  color: #555; font-family: sans-serif; font-size: 12px;
  margin-top: 16px; letter-spacing: 1px;
}
canvas { background: #000 !important; }
</style>`;
html = html.replace("<head>", `<head><script src="coi-serviceworker.min.js"></script>${css}`);

// Download = 0-60%, initialization = 60-95%, first frame = 95-100%
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
					statusProgress.max = 1000;
					var v = Math.floor((current / total) * 600);
					statusProgress.value = v;
					var logo = document.getElementById('status-splash');
					if (logo) logo.style.opacity = v / 1000;
				}
			},`;

html = html.replace(oldProgress, newProgress);

// Inject a script that animates 60-95% during init and fades on first frame
const initScript = `<script>
(function() {
	var initStarted = false;
	var initInterval = null;
	var origStartGame = null;

	// Watch for download complete -> start fake progress 60-95%
	var observer = new MutationObserver(function() {
		var bar = document.getElementById('status-progress');
		if (bar && bar.value >= 600 && !initStarted) {
			initStarted = true;
			var fakeProgress = 600;
			var logo = document.getElementById('status-splash');
			initInterval = setInterval(function() {
				fakeProgress = Math.min(fakeProgress + 3, 950);
				bar.value = fakeProgress;
				if (logo) logo.style.opacity = fakeProgress / 1000;
			}, 50);
		}
	});
	observer.observe(document.body, { childList: true, subtree: true, attributes: true });

	// Detect first canvas frame -> complete bar and fade out
	var checkCanvas = setInterval(function() {
		var canvas = document.querySelector('canvas');
		if (canvas && canvas.width > 0 && canvas.height > 0) {
			try {
				var ctx = canvas.getContext('2d') || canvas.getContext('webgl') || canvas.getContext('webgl2');
				if (ctx) {
					clearInterval(checkCanvas);
					if (initInterval) clearInterval(initInterval);
					observer.disconnect();
					var bar = document.getElementById('status-progress');
					if (bar) { bar.max = 1000; bar.value = 1000; }
					var logo = document.getElementById('status-splash');
					if (logo) logo.style.opacity = 1;
					setTimeout(function() {
						var status = document.getElementById('status');
						if (status) {
							status.style.opacity = '0';
							setTimeout(function() { status.style.display = 'none'; }, 600);
						}
					}, 300);
				}
			} catch(e) {}
		}
	}, 100);
})();
</script>`;

html = html.replace("</head>", `${initScript}</head>`);

// Remove the onPrint-based fade (replaced by canvas detection above)
writeFileSync(file, html);
console.log("Patched loading screen:", file);
