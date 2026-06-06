#!/usr/bin/env bash

# Check all required dependencies for this Hyprland config
DEPS=(
    hyprland
    quickshell
    kitty
    fish
    starship
    dunst
    awww
    wallust
    cliphist
    wl-copy
    wl-paste
    grim
    slurp
    brightnessctl
    playerctl
    cava
    convert        # ImageMagick
    curl
    python3
    hyprlock
    hypridle
)

MISSING=()

for dep in "${DEPS[@]}"; do
    if ! command -v "$dep" &>/dev/null; then
        MISSING+=("$dep")
    fi
done

if [ ${#MISSING[@]} -eq 0 ]; then
    echo "All dependencies are installed."
else
    echo "Missing dependencies:"
    for m in "${MISSING[@]}"; do
        echo "  - $m"
    done
    echo ""
    echo "Install missing packages with: yay -S ${MISSING[*]}"
fi