#!/usr/bin/env bash

SCRATCHPAD_CLASS="scratchpad-kitty"

# Cek apakah scratchpad udah ada
if hyprctl clients -j | python3 -c "
import json, sys
clients = json.load(sys.stdin)
found = any(c['class'] == '$SCRATCHPAD_CLASS' for c in clients)
sys.exit(0 if found else 1)
"; then
    # Udah ada — toggle visibility
    hyprctl dispatch togglespecialworkspace scratchpad
else
    # Belum ada — spawn baru
    kitty --class $SCRATCHPAD_CLASS &
    sleep 0.3
    hyprctl dispatch movetoworkspacesilent special:scratchpad,class:$SCRATCHPAD_CLASS
    hyprctl dispatch togglespecialworkspace scratchpad
fi