#!/bin/bash
set -e

GODOT="/Applications/Godot.app/Contents/MacOS/Godot"
PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build/web"
GODOT_VERSION="4.6.1"
SERVER_PID=""
TUNNEL_PID=""
WATCH_PID=""

cd "$PROJECT_DIR"

# --- Functions ---

ensure_templates() {
    local dir="$HOME/Library/Application Support/Godot/export_templates/$GODOT_VERSION.stable"
    [ -f "$dir/web_nothreads_release.zip" ] && return
    echo "==> Downloading web export templates..."
    mkdir -p "$dir"
    local tmp=$(mktemp)
    curl -sL "https://github.com/godotengine/godot-builds/releases/download/$GODOT_VERSION-stable/Godot_v${GODOT_VERSION}-stable_export_templates.tpz" -o "$tmp"
    unzip -qo "$tmp" "templates/web_*" -d /tmp/godot_tpl
    cp /tmp/godot_tpl/templates/web_* "$dir/"
    rm -rf "$tmp" /tmp/godot_tpl
    echo "==> Templates installed."
}

write_export_presets() {
    cat > export_presets.cfg << 'PRESETS'
[preset.0]
name="Web"
platform="Web"
runnable=true
dedicated_server=false
custom_features=""
export_filter="all_resources"
include_filter=""
exclude_filter="*.fbx, *.obj, *.glb, boots.res, Tcuer.png, Tfbot.png, Tibot.png, Tlbot.png, Trcuer.png, Tsuel.png, Ttbot.png, scout.glb, scout_rogue_texture.png, tests/*, social-preview.png, build/*"
export_path="build/web/index.html"
[preset.0.options]
variant/thread_support=false
html/export_icon=true
progressive_web_app/enabled=false
PRESETS
}

export_web() {
    echo "==> Exporting web build..."
    mkdir -p "$BUILD_DIR"
    write_export_presets
    $GODOT --headless --editor --quit 2>/dev/null || true
    $GODOT --headless --export-release "Web" "$BUILD_DIR/index.html" 2>&1
    cp "$PROJECT_DIR/scripts/tools/coi-serviceworker.min.js" "$BUILD_DIR/"
    cp "$PROJECT_DIR/assets/boot_logo.png" "$BUILD_DIR/index.png"
    node "$PROJECT_DIR/scripts/tools/patch_web_loading.mjs" "$BUILD_DIR/index.html"
    touch "$PROJECT_DIR/build/.reload"
    echo "==> Build ready."
}

start_server() {
    node "$PROJECT_DIR/scripts/tools/lan-server.mjs" &
    SERVER_PID=$!
    sleep 1
}

open_browser() {
    osascript "$PROJECT_DIR/scripts/tools/open-or-refresh.applescript" 2>/dev/null &
}

start_tunnel() {
    command -v cloudflared &>/dev/null || { echo "    (install cloudflared for iOS Safari HTTPS support)"; return; }
    local log=$(mktemp)
    cloudflared tunnel --url http://localhost:8060 > "$log" 2>&1 &
    TUNNEL_PID=$!
    sleep 5
    local url=$(grep -o 'https://[^ ]*\.trycloudflare\.com' "$log" | head -1)
    [ -n "$url" ] && echo "    iOS Safari: $url" || echo "    (cloudflared tunnel failed to start)"
    rm -f "$log"
}

start_watcher() {
    fswatch -o -e "build/" -e ".godot/" -e ".git/" \
        --include="\.gd$" --include="\.tres$" --include="\.tscn$" \
        --include="\.svg$" --include="\.png$" --include="\.cfg$" \
        "$PROJECT_DIR/scripts" "$PROJECT_DIR/resources" \
        "$PROJECT_DIR/scenes" "$PROJECT_DIR/assets" | while read -r _; do
        while read -r -t 0.5 _; do :; done
        echo ""
        echo "==> Change detected, rebuilding..."
        export_web
    done &
    WATCH_PID=$!
}

cleanup() {
    [ -n "$SERVER_PID" ] && kill $SERVER_PID 2>/dev/null
    [ -n "$TUNNEL_PID" ] && kill $TUNNEL_PID 2>/dev/null
    [ -n "$WATCH_PID" ] && kill $WATCH_PID 2>/dev/null
    exit 0
}

print_urls() {
    local ip=$(ipconfig getifaddr en0 2>/dev/null || echo "unknown")
    echo ""
    echo "==> Game ready at:"
    echo "    Local:   http://localhost:8060"
    echo "    Network: http://$ip:8060"
}

# --- Main ---

trap cleanup EXIT INT TERM

ensure_templates
export_web
print_urls
start_server
open_browser
start_tunnel

echo ""
echo "==> Watching for changes... (auto-rebuild on save)"
echo ""

start_watcher
wait $SERVER_PID
