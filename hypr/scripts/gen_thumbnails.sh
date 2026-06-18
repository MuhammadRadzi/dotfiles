#!/usr/bin/env bash
# Pre-generate thumbnails for all wallpapers.
# Run once at shell startup so WallpaperSelector.qml only ever reads
# existing thumbnails instead of generating them reactively on error.

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
THUMB_DIR="$HOME/.cache/hypr/thumbnails"

command -v convert &>/dev/null || {
    notify-send "gen_thumbnails.sh" "ImageMagick (convert) is not installed."
    exit 1
}

mkdir -p "$THUMB_DIR"

shopt -s nullglob nocaseglob
for wallpaper in "$WALLPAPER_DIR"/*.{jpg,jpeg,png,webp}; do
    [ -f "$wallpaper" ] || continue

    thumb="$THUMB_DIR/$(basename "$wallpaper")"

    # Skip if thumbnail already exists and is newer than the source wallpaper
    if [ -f "$thumb" ] && [ "$thumb" -nt "$wallpaper" ]; then
        continue
    fi

    convert "$wallpaper" -resize 300x180^ -gravity Center -extent 300x180 "$thumb"
done