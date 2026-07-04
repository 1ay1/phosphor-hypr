#!/usr/bin/env bash
# neowall shader picker — pick a shader from Rofi and apply it live.
# Usage: shader-switch.sh          (interactive Rofi menu)
#        shader-switch.sh <name>   (apply by filename, e.g. matrix_rain.glsl)

set -euo pipefail

SHADER_DIR="$HOME/.config/neowall/shaders"
CONFIG="$HOME/.config/neowall/config.vibe"

apply() {
    local shader="$1"
    # Rewrite the `shader <x>.glsl` directive (a line whose first non-space
    # token is literally `shader`), never a comment.
    sed -i -E "s|^([[:space:]]*)shader[[:space:]]+[^#[:space:]]+\.glsl|\1shader ${shader}|" "$CONFIG"
    # Reload the running daemon (or start it)
    if pgrep -x neowall >/dev/null; then
        neowall reload
    else
        neowall &
    fi
    command -v notify-send >/dev/null && notify-send "󱍕 neowall" "Shader → ${shader}"
}

if [ $# -ge 1 ]; then
    apply "$1"
    exit 0
fi

choice=$(ls "$SHADER_DIR"/*.glsl 2>/dev/null | xargs -n1 basename \
    | rofi -dmenu -i -p "󱍕 shader" -theme-str 'window {width: 480px;}')

[ -n "${choice:-}" ] && apply "$choice"
