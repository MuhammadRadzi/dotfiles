#!/usr/bin/env bash

WALLPAPER_DIR="$HOME/.config/hypr/assets/wallpapers"
THUMB_DIR="$HOME/.config/hypr/assets/thumbnails"

# Cek ImageMagick
command -v convert &>/dev/null || {
    notify-send "wallpaper.sh" "ImageMagick not found"
    exit 1
}

mkdir -p "$THUMB_DIR"

# Generate thumbnail untuk semua wallpaper
find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | while read -r wp; do
    filename=$(basename "$wp")
    thumb="$THUMB_DIR/$filename"
    if [ ! -f "$thumb" ]; then
        convert "$wp" -resize 400x225^ -gravity Center -extent 400x225 "$thumb"
    fi
done