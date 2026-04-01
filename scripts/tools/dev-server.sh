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

export_web() {
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
exclude_filter="*.fbx, *.obj, *.glb, boots.res, Tcuer.png, Tfbot.png, Tibot.png, Tlbot.png, Trcuer.png, Tsuel.png, Ttbot.png, scout.glb, scout_rogue_texture.png, tests/*, social-preview.png, build/*"
export_path="build/web/index.html"
[preset.0.options]
variant/thread_support=false
html/export_icon=true
progressive_web_app/enabled=false
PRESETS
    $GODOT --headless --editor --quit 2>/dev/null || true
    $GODOT --headless --export-release "Web" "$BUILD_DIR/index.html" 2>&1
    cp "$PROJECT_DIR/scripts/tools/coi-serviceworker.min.js" "$BUILD_DIR/"
    cp "$PROJECT_DIR/assets/boot_logo.png" "$BUILD_DIR/index.png"
    node "$PROJECT_DIR/scripts/tools/patch_web_loading.mjs" "$BUILD_DIR/index.html"
    echo "==> Build ready."
    touch "$PROJECT_DIR/build/.reload"
}

# Initial build
export_web

LOCAL_IP=$(ipconfig getifaddr en0 2>/dev/null || echo "unknown")

echo ""
echo "==> Game ready at:"
echo "    Local:   http://localhost:8060"
echo "    Network: http://$LOCAL_IP:8060"

# Start LAN server
node "$PROJECT_DIR/scripts/tools/lan-server.mjs" &
SERVER_PID=$!
sleep 1

# Open browser only if no existing tab is on this URL
osascript -e '
tell application "System Events"
    set browserOpen to false
    try
        tell application "Google Chrome"
            repeat with w in windows
                repeat with t in tabs of w
                    if URL of t starts with "http://localhost:8060" then
                        set browserOpen to true
                        reload t
                        exit repeat
                    end if
                end repeat
                if browserOpen then exit repeat
            end repeat
        end tell
    end try
    if not browserOpen then
        try
            tell application "Safari"
                repeat with w in windows
                    repeat with t in tabs of w
                        if URL of t starts with "http://localhost:8060" then
                            set browserOpen to true
                            do JavaScript "location.reload()" in t
                            exit repeat
                        end if
                    end repeat
                    if browserOpen then exit repeat
                end repeat
            end tell
        end try
    end if
    if not browserOpen then
        do shell script "open http://localhost:8060/"
    end if
end tell
' 2>/dev/null &

# Start HTTPS tunnel for iOS Safari
TUNNEL_PID=""
if command -v cloudflared &>/dev/null; then
    TUNNEL_LOG=$(mktemp)
    cloudflared tunnel --url http://localhost:8060 > "$TUNNEL_LOG" 2>&1 &
    TUNNEL_PID=$!
    sleep 5
    TUNNEL_URL=$(grep -o 'https://[^ ]*\.trycloudflare\.com' "$TUNNEL_LOG" | head -1)
    if [ -n "$TUNNEL_URL" ]; then
        echo "    iOS Safari: $TUNNEL_URL"
    else
        echo "    (cloudflared tunnel failed to start)"
    fi
    rm -f "$TUNNEL_LOG"
else
    echo "    (install cloudflared for iOS Safari HTTPS support)"
fi

cleanup() {
    kill $SERVER_PID 2>/dev/null
    [ -n "$TUNNEL_PID" ] && kill $TUNNEL_PID 2>/dev/null
    [ -n "$WATCH_PID" ] && kill $WATCH_PID 2>/dev/null
    exit 0
}
trap cleanup EXIT INT TERM

echo ""
echo "==> Watching for changes... (auto-rebuild on save)"
echo ""

# Watch for file changes and re-export on each diff
REBUILDING=false
fswatch -o -e "build/" -e ".godot/" -e ".git/" \
    --include="\.gd$" --include="\.tres$" --include="\.tscn$" \
    --include="\.svg$" --include="\.png$" --include="\.cfg$" \
    "$PROJECT_DIR/scripts" "$PROJECT_DIR/resources" \
    "$PROJECT_DIR/scenes" "$PROJECT_DIR/assets" | while read -r _; do
    # Debounce: drain queued events
    while read -r -t 0.5 _; do :; done
    if [ "$REBUILDING" = true ]; then
        continue
    fi
    REBUILDING=true
    echo ""
    echo "==> Change detected, rebuilding..."
    export_web
    echo "==> Reload your browser."
    echo ""
    REBUILDING=false
done &
WATCH_PID=$!

wait $SERVER_PID
