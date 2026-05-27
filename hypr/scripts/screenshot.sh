#!/usr/bin/env bash

SCREENSHOT_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$SCREENSHOT_DIR"

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
FILE="$SCREENSHOT_DIR/$TIMESTAMP.png"

MODE="$1"

case "$MODE" in
    area)
        # Area select
        SELECTION=$(slurp 2>/dev/null)
        if [ -z "$SELECTION" ]; then
            exit 0  # User cancel
        fi
        grim -g "$SELECTION" "$FILE"
        ;;
    full)
        # Fullscreen
        grim "$FILE"
        ;;
    *)
        echo "Usage: screenshot.sh [area|full]"
        exit 1
        ;;
esac

# Check if screenshot was successful
if [ ! -f "$FILE" ]; then
    notify-send -u critical "Screenshot" "Failed to take screenshot" -i error
    exit 1
fi

# Copy to clipboard
wl-copy < "$FILE"

# Notification with preview
notify-send "Screenshot" "Saved to $FILE\nCopied to clipboard" \
    -i "$FILE" \
    -t 4000 \
    --action="open=Open Folder" &

# Capture notification action
NOTIF_PID=$!
ACTION=$(wait $NOTIF_PID && dunstctl history | python3 -c "
import json, sys
d = json.load(sys.stdin)
" 2>/dev/null)

# Open folder if user clicks notification
if [ "$ACTION" = "open" ]; then
    xdg-open "$SCREENSHOT_DIR"
fi