#!/bin/bash
set -e

GODOT="/Applications/Godot.app/Contents/MacOS/Godot"
PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build/web"

cd "$PROJECT_DIR"

TEMPLATES_DIR="$HOME/Library/Application Support/Godot/export_templates/4.6.1.stable"
if [ ! -f "$TEMPLATES_DIR/web_nothreads_release.zip" ]; then
    echo "==> Downloading web export templates..."
    mkdir -p "$TEMPLATES_DIR"
    TMPFILE=$(mktemp)
    curl -sL "https://github.com/godotengine/godot-builds/releases/download/4.6.1-stable/Godot_v4.6.1-stable_export_templates.tpz" -o "$TMPFILE"
    unzip -qo "$TMPFILE" "templates/web_*" -d /tmp/godot_tpl
    cp /tmp/godot_tpl/templates/web_* "$TEMPLATES_DIR/"
    rm -rf "$TMPFILE" /tmp/godot_tpl
    echo "==> Templates installed."
fi

echo "==> Exporting web build..."
mkdir -p "$BUILD_DIR"
cat > export_presets.cfg << 'PRESETS'
[preset.0]
name="Web"
platform="Web"
runnable=true
dedicated_server=false
custom_features=""
export_filter="all_resources"
include_filter=""
exclude_filter=""
export_path="build/web/index.html"
[preset.0.options]
variant/thread_support=false
html/export_icon=true
progressive_web_app/enabled=false
PRESETS
$GODOT --headless --editor --quit 2>/dev/null || true
$GODOT --headless --export-release "Web" "$BUILD_DIR/index.html" 2>&1

echo ""
echo "==> Game ready at: http://localhost:8060"
echo ""
npx -y serve "$BUILD_DIR" -l 8060 --no-clipboard 2>&1 | grep -v "Accepting connections"
