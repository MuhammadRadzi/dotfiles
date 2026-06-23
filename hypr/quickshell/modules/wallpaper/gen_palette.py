#!/usr/bin/env python3
# Extracts MD3 palette preview from a wallpaper via matugen, caches as hex lines.
import sys
import os
import json
import subprocess

if len(sys.argv) < 3:
    sys.exit(1)

img_path = sys.argv[1]
cache_dir = sys.argv[2]

os.makedirs(cache_dir, exist_ok=True)

filename = os.path.basename(img_path)
cache_file = os.path.join(cache_dir, filename + ".palette")

if os.path.exists(cache_file):
    with open(cache_file) as f:
        print(f.read().strip())
    sys.exit(0)

ROLES = [
    "surface",
    "surface_container",
    "primary",
    "secondary",
    "tertiary",
    "error",
    "success",
    "warning",
]

try:
    result = subprocess.run(
        [
            "matugen", "image", img_path,
            "--source-color-index", "0",
            "--json", "hex",
            "--config", os.path.expanduser("~/.config/matugen/preview-only.toml"),
        ],
        capture_output=True,
        text=True,
        timeout=15,
    )
    if result.returncode != 0:
        sys.exit(1)

    data = json.loads(result.stdout)
    colors_data = data.get("colors", {})

    colors = []
    for role in ROLES:
        entry = colors_data.get(role)
        if entry is None:
            continue
        scheme = entry.get("dark") or entry.get("light") or entry.get("default")
        if scheme and "color" in scheme:
            colors.append(scheme["color"])

    if not colors:
        sys.exit(1)

    out = "\n".join(colors)
    with open(cache_file, "w") as f:
        f.write(out + "\n")
    print(out)
except Exception:
    sys.exit(1)