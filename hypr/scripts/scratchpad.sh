#!/usr/bin/env bash

SCRATCHPAD_CLASS="scratchpad-kitty"

if hyprctl clients -j | python3 -c "
import json, sys
clients = json.load(sys.stdin)
found = any(c['class'] == '$SCRATCHPAD_CLASS' for c in clients)
sys.exit(0 if found else 1)
"; then
    hyprctl dispatch togglespecialworkspace scratchpad
else
    kitty --class $SCRATCHPAD_CLASS &
    # Poll until window appears instead of fixed sleep
    for i in $(seq 1 30); do
        sleep 0.1
        if hyprctl clients -j | python3 -c "
import json, sys
clients = json.load(sys.stdin)
sys.exit(0 if any(c['class'] == '$SCRATCHPAD_CLASS' for c in clients) else 1)
"; then
            break
        fi
    done
    hyprctl dispatch movetoworkspacesilent special:scratchpad,class:$SCRATCHPAD_CLASS
    hyprctl dispatch togglespecialworkspace scratchpad
fi