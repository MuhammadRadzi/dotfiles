#!/usr/bin/env bash

WALLPAPER="$1"

if [ -z "$WALLPAPER" ]; then
    LAST_WALLPAPER="$HOME/.config/hypr/.last_wallpaper"
    if [ -f "$LAST_WALLPAPER" ]; then
        WALLPAPER=$(cat "$LAST_WALLPAPER")
    else
        WALLPAPER="$HOME/Pictures/Wallpapers/jr.jpg"
    fi
fi

echo "$WALLPAPER" > "$HOME/.config/hypr/.last_wallpaper"

command -v convert &>/dev/null || {
    notify-send "wallpaper.sh" "Hey, it seems like you don't have ImageMagick installed."
    exit 1
}

awww img "$WALLPAPER" --transition-type random --transition-duration 1

mkdir -p ~/.cache/hypr/thumbnails
convert "$WALLPAPER" -resize 300x180^ -gravity Center -extent 300x180 \
    ~/.cache/hypr/thumbnails/$(basename "$WALLPAPER")

matugen image "$WALLPAPER" --source-color-index 0 || true
cp ~/.config/hypr/quickshell/theme/Colors.qml ~/.config/hypr/quickshell/lock/Colors.qml

for sock in /tmp/kitty-*; do
    [ -S "$sock" ] && kitty @ --to "unix:$sock" set-colors -a -c ~/.config/kitty/kitty-colors.conf 2>/dev/null
done
true

pkill -SIGUSR1 cava || cava &

hyprctl reload

# Reload Quickshell internally (no kill/restart, keeps layer-shell surfaces alive)
quickshell ipc -p ~/.config/hypr/quickshell call reload-shell handle false