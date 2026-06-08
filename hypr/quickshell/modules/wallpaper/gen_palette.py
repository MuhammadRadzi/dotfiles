#!/usr/bin/env python3
# Extracts 8 dominant colors from a wallpaper and caches as hex lines
import sys
import os
from PIL import Image

if len(sys.argv) < 3:
    sys.exit(1)

img_path = sys.argv[1]
cache_dir = sys.argv[2]

os.makedirs(cache_dir, exist_ok=True)

filename = os.path.basename(img_path)
cache_file = os.path.join(cache_dir, filename + ".palette")

# Skip if already cached
if os.path.exists(cache_file):
    with open(cache_file) as f:
        print(f.read().strip())
    sys.exit(0)

try:
    img = Image.open(img_path).convert("RGB")
    img.thumbnail((200, 200))
    quantized = img.quantize(colors=8, method=Image.Quantize.FASTOCTREE)
    palette_data = quantized.getpalette()[:8*3]
    colors = []
    for i in range(8):
        r = palette_data[i*3]
        g = palette_data[i*3 + 1]
        b = palette_data[i*3 + 2]
        colors.append("#{:02x}{:02x}{:02x}".format(r, g, b))
    result = "\n".join(colors)
    with open(cache_file, "w") as f:
        f.write(result + "\n")
    print(result)
except Exception:
    sys.exit(1)