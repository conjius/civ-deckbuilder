#!/bin/bash
set -e

GODOT="/Applications/Godot.app/Contents/MacOS/Godot"
PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
SS_DIR="$HOME/Library/Application Support/Godot/app_userdata/civ-deckbuilder/screenshots"

cd "$PROJECT_DIR"

cleanup() {
    if [ -f project.godot.bak ]; then
        mv project.godot.bak project.godot
    fi
}
trap cleanup EXIT

echo "==> Injecting screenshot autoload..."
cp project.godot project.godot.bak
echo -e '\n[autoload]\nScreenshotCapture="*res://scripts/tools/screenshot_capture.gd"' >> project.godot
sed -i '' 's/\[display\]/[display]\nwindow\/size\/initial_position_type=0\nwindow\/size\/initial_position=Vector2i(-4000, -4000)/' project.godot

echo "==> Importing project..."
$GODOT --headless --editor --quit 2>/dev/null || true

echo "==> Launching game hidden (will auto-quit after screenshots)..."
CIV_SCREENSHOTS=1 $GODOT --path . --resolution 1920x1080 2>/dev/null &
PID=$!
sleep 10
kill $PID 2>/dev/null; wait $PID 2>/dev/null || true

echo "==> Restoring project.godot..."
cleanup

echo "==> Checking screenshots..."
if [ ! -f "$SS_DIR/screenshot-main.jpg" ] || [ ! -f "$SS_DIR/screenshot-gallery.jpg" ]; then
    echo "FAIL: Screenshots not captured"
    ls -la "$SS_DIR/" 2>/dev/null
    exit 1
fi

echo "==> Pushing to gh-pages..."
TMPDIR=$(mktemp -d)
git clone --branch gh-pages --depth 1 "$(git remote get-url origin)" "$TMPDIR"
cp "$SS_DIR/screenshot-main.jpg" "$TMPDIR/"
cp "$SS_DIR/screenshot-gallery.jpg" "$TMPDIR/"
cp scripts/tools/gh-pages-index.html "$TMPDIR/index.html"
cd "$TMPDIR"
git add screenshot-main.jpg screenshot-gallery.jpg index.html
git commit -m "Update screenshots from local machine" || true
git push
rm -rf "$TMPDIR"

echo "==> Done! Screenshots pushed to gh-pages."
