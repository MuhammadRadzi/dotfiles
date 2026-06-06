#!/usr/bin/env bash
# Reload Hyprland config
hyprctl reload

# Reload Quickshell
pkill quickshell
sleep 0.5
quickshell -p ~/.config/hypr/quickshell & disown