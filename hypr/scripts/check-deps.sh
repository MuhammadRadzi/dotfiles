#!/usr/bin/env bash

# Check all required dependencies for this Hyprland config
DEPS=(
    hyprland
    hypridle
    quickshell
    kitty
    fish
    starship
    awww
    matugen
    cliphist
    wl-copy
    wl-paste
    grim
    slurp
    wf-recorder
    brightnessctl
    playerctl
    wpctl
    pactl
    cava
    curl
    python3
    jq
    bluetoothctl
    nmcli
)

# Python modules (checked separately)
PY_MODULES=(
    PIL
)

MISSING=()
MISSING_PY=()

# Some binaries don't share a name with their package
declare -A PKG_MAP=(
    [wpctl]="wireplumber"
    [pactl]="libpulse"
    [nmcli]="networkmanager"
    [bluetoothctl]="bluez-utils"
)

for dep in "${DEPS[@]}"; do
    if ! command -v "$dep" &>/dev/null; then
        MISSING+=("${PKG_MAP[$dep]:-$dep}")
    fi
done

for mod in "${PY_MODULES[@]}"; do
    if ! python3 -c "import $mod" &>/dev/null; then
        MISSING_PY+=("$mod")
    fi
done

if [ ${#MISSING[@]} -eq 0 ] && [ ${#MISSING_PY[@]} -eq 0 ]; then
    echo "All dependencies are installed."
else
    if [ ${#MISSING[@]} -gt 0 ]; then
        echo "Missing system dependencies:"
        for m in "${MISSING[@]}"; do
            echo "  - $m"
        done
        echo ""
        echo "Install with: yay -S ${MISSING[*]}"
        echo ""
    fi

    if [ ${#MISSING_PY[@]} -gt 0 ]; then
        echo "Missing Python modules:"
        for m in "${MISSING_PY[@]}"; do
            echo "  - $m"
        done
        echo ""
        echo "Install with: sudo pacman -S python-pillow"
    fi
fi
