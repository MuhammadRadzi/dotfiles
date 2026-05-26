#!/usr/bin/env bash
set -euo pipefail

WALLPAPER=${1:-"$HOME/.config/hypr/assets/wallpapers/default.jpg"}

if [ ! -f "$WALLPAPER" ]; then
  echo "Wallpaper not found: $WALLPAPER" >&2
  exit 1
fi

if command -v hyprpaper >/dev/null 2>&1; then
  hyprpaper --set "$WALLPAPER"
elif command -v swaybg >/dev/null 2>&1; then
  swaybg -i "$WALLPAPER" -m fill
else
  echo "No compatible wallpaper setter found. Install hyprpaper or swaybg." >&2
  exit 1
fi
