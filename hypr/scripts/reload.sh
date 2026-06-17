#!/usr/bin/env bash
# Reload Hyprland config
# hyprctl reload

# Reload Quickshell internally (no kill/restart, keeps layer-shell surfaces alive)
quickshell ipc -p ~/.config/hypr/quickshell call reload-shell handle true