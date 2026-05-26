#!/usr/bin/env bash
set -euo pipefail

OUTPUT_DIR=${1:-"$HOME/Pictures/Screenshots"}
mkdir -p "$OUTPUT_DIR"
OUTPUT_FILE="$OUTPUT_DIR/screenshot-$(date +%Y%m%d-%H%M%S).png"

if command -v grim >/dev/null 2>&1; then
  grim "$OUTPUT_FILE"
elif command -v maim >/dev/null 2>&1; then
  maim "$OUTPUT_FILE"
else
  echo "No screenshot utility found. Install grim or maim." >&2
  exit 1
fi

echo "Saved screenshot to $OUTPUT_FILE"
