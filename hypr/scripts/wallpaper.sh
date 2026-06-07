#!/usr/bin/env bash

WALLPAPER="$1"

# Fallback to default wallpaper if no argument is provided
if [ -z "$WALLPAPER" ]; then
    LAST_WALLPAPER="$HOME/.config/hypr/.last_wallpaper"
    if [ -f "$LAST_WALLPAPER" ]; then
        WALLPAPER=$(cat "$LAST_WALLPAPER")
    else
        WALLPAPER="$HOME/Pictures/Wallpapers/jr.jpg"
    fi
fi

# Save current wallpaper path for next startup
echo "$WALLPAPER" > "$HOME/.config/hypr/.last_wallpaper"

command -v convert &>/dev/null || {
    notify-send "wallpaper.sh" "Hey, it seems like you don't have ImageMagick installed."
    exit 1
}

awww img "$WALLPAPER" --transition-type random --transition-duration 1

mkdir -p ~/.cache/hypr/thumbnails
convert "$WALLPAPER" -resize 300x180^ -gravity Center -extent 300x180 \
    ~/.cache/hypr/thumbnails/$(basename "$WALLPAPER")

wallust run "$WALLPAPER" -q || true

pkill -SIGUSR1 cava || true
systemd-run --user --no-block bash -c 'sleep 0.3; cava'

sed 's/rgb(#/rgb(/g' ~/.config/hypr/hypr-colors.conf > ~/.config/hypr/hypr-colors-clean.conf

hex2rgb() {
    local hex="${1#\#}"
    printf "%d, %d, %d" "0x${hex:0:2}" "0x${hex:2:2}" "0x${hex:4:2}"
}

# Colors from hypr-colors.conf (HEX Format)
c0=$(grep "color0" ~/.config/hypr/hypr-colors.conf | grep -o '#[0-9a-fA-F]*')
c1=$(grep "color1" ~/.config/hypr/hypr-colors.conf | grep -o '#[0-9a-fA-F]*')
c2=$(grep "color2" ~/.config/hypr/hypr-colors.conf | grep -o '#[0-9a-fA-F]*')
c6=$(grep "color6" ~/.config/hypr/hypr-colors.conf | grep -o '#[0-9a-fA-F]*')
c7=$(grep "color7" ~/.config/hypr/hypr-colors.conf | grep -o '#[0-9a-fA-F]*')
fg=$(grep "color7" ~/.config/hypr/hypr-colors.conf | grep -o '#[0-9a-fA-F]*')

# Generate hyprlock.conf
cat > ~/.config/hypr/hyprlock.conf << EOF
general {
    disable_loading_bar = true
    hide_cursor = true
    grace = 2
}

background {
    monitor =
    path = screenshot
    blur_passes = 1
    blur_size = 8
    noise = 0.015
    brightness = 0.9
    contrast = 1.05
    vibrancy = 0.18
    vibrancy_darkness = 0.2
}

# Main card
shape {
    monitor =
    size = 420, 300
    position = 0, 10
    color = rgba($(hex2rgb $c0), 0.78)
    rounding = 24
    border_size = 1
    border_color = rgba(255,255,255,0.08)
    halign = center
    valign = center
}

# Battery — pojok kanan atas
label {
    monitor =
    text = cmd[update:30000] bash -c 'BAT=\$(ls /sys/class/power_supply | grep -m1 BAT); [ -z "\$BAT" ] && echo "No battery" && exit 0; echo "\$(cat /sys/class/power_supply/\$BAT/capacity)% \$(cat /sys/class/power_supply/\$BAT/status | sed \"s/Charging/[CHR]/;s/Discharging/[BAT]/;s/Full/[FULL]/;s/Not charging/[~]/\")"'
    color = rgba($(hex2rgb $fg), 0.8)
    font_size = 13
    font_family = JetBrainsMono Nerd Font
    position = -24, -24
    halign = right
    valign = top
}

# Avatar
image {
    monitor =
    path = ~/.face
    size = 82
    rounding = -1
    border_size = 2
    border_color = rgba(255,255,255,0.08)
    position = 0, 168
    halign = center
    valign = center
}

# Greeting
label {
    monitor =
    text = cmd[update:60000] echo "\$(hour=\$(date '+%H'); if [ \$hour -lt 12 ]; then echo 'Good Morning'; elif [ \$hour -lt 17 ]; then echo 'Good Afternoon'; else echo 'Good Evening'; fi), \$USER"
    color = rgba($(hex2rgb $fg), 0.7)
    font_size = 17
    font_family = JetBrainsMono Nerd Font
    position = 0, 90
    halign = center
    valign = center
}

# Jam
label {
    monitor =
    text = cmd[update:1000] echo "\$(date '+%H:%M')"
    color = rgba($(hex2rgb $fg), 1.0)
    font_size = 90
    font_family = JetBrainsMono Nerd Font Bold
    position = 0, 10
    halign = center
    valign = center
}

# Tanggal
label {
    monitor =
    text = cmd[update:60000] echo "\$(date '+%A, %d %B %Y')"
    color = rgba($(hex2rgb $fg), 0.7)
    font_size = 13
    font_family = JetBrainsMono Nerd Font
    position = 0, -61
    halign = center
    valign = center
}

# Input field shape
shape {
    monitor =
    size = 345, 60
    position = 0, -190
    color = rgba($(hex2rgb $c0), 0.78)
    rounding = 24
    border_size = 1
    border_color = rgba(255,255,255,0.08)
    halign = center
    valign = center
}

# Input field
input-field {
    monitor =
    size = 320, 54
    position = 0, -190
    outline_thickness = 0
    dots_size = 0.22
    dots_spacing = 0.5
    dots_center = true
    outer_color = rgba(0,0,0,0)
    inner_color = rgba(255, 255, 255, 0)
    font_color = rgb($(hex2rgb $fg))
    fade_on_empty = false
    placeholder_text = <span foreground="##$(echo $fg | tr -d '#')">Password...</span>
    rounding = 16
    check_color = rgba(255, 255, 255, 0)
    fail_color = rgba(255,80,80,0)
    fail_text = <span foreground="##FB4934">Wrong password</span>
    halign = center
    valign = center
}

# Locked
label {
    monitor =
    text = Locked
    color = rgba($(hex2rgb $fg), 0.55)
    font_size = 14
    font_family = JetBrainsMono Nerd Font
    position = 0, -104
    halign = center
    valign = center
}

# Animations
animations {
    enabled = true
    bezier = easeOut, 0.16, 1, 0.3, 1
    animation = fadeIn, 1, 3, easeOut
    animation = fadeOut, 1, 3, easeOut
    animation = inputFieldColors, 1, 3, easeOut
    animation = labelFadeIn, 1, 4, easeOut
    animation = imageFadeIn, 1, 4, easeOut
}
EOF

# Reload Hyprland
hyprctl reload

# Reload Quickshell
systemd-run --user --no-block bash -c 'sleep 0.5; pkill quickshell; sleep 0.5; quickshell -p ~/.config/hypr/quickshell'