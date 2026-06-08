#!/usr/bin/env bash

SCREENSHOT_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$SCREENSHOT_DIR"

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
FILE="$SCREENSHOT_DIR/$TIMESTAMP.png"

MODE="$1"
GEOMETRY="$2"

case "$MODE" in
    geometry)
        grim -g "$GEOMETRY" "$FILE"
        ;;
    full)
        grim "$FILE"
        ;;
    window)
        GEOM=$(hyprctl clients -j | python3 -c "
import json, sys
clients = json.load(sys.stdin)
for c in clients:
    x, y = c['at']
    w, h = c['size']
    print(f'{x},{y} {w}x{h}')
" | slurp -r 2>/dev/null)
        if [ -z "$GEOM" ]; then
            exit 1
        fi
        grim -g "$GEOM" "$FILE"
        ;;
    *)
        exit 1
        ;;
esac

if [ ! -f "$FILE" ] || [ ! -s "$FILE" ]; then
    exit 1
fi

# Copy to clipboard
wl-copy < "$FILE"

# Notification
notify-send "Screenshot" "Saved & copied to clipboard" -i "$FILE" -t 3000