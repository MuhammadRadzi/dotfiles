#!/usr/bin/env python3
"""
Pixelate one or more rectangular regions of an image in place.

Usage:
    pixelate.py <image_path> <x,y,w,h> [<x,y,w,h> ...]

Coordinates are in the image's own pixel space (not screen space), integers,
top-left origin. The image is overwritten with the result.
"""
import sys

from PIL import Image


def pixelate_region(img, x, y, w, h):
    x = max(0, int(x))
    y = max(0, int(y))
    w = max(1, int(w))
    h = max(1, int(h))
    x2 = min(img.width, x + w)
    y2 = min(img.height, y + h)
    w = x2 - x
    h = y2 - y
    if w < 2 or h < 2:
        return

    block = max(4, round(min(w, h) / 12))
    small_w = max(1, w // block)
    small_h = max(1, h // block)

    region = img.crop((x, y, x2, y2))
    region_small = region.resize((small_w, small_h), Image.BILINEAR)
    region_pixelated = region_small.resize((w, h), Image.NEAREST)
    img.paste(region_pixelated, (x, y))


def main():
    if len(sys.argv) < 3:
        sys.exit(1)

    path = sys.argv[1]
    regions = sys.argv[2:]

    img = Image.open(path).convert("RGBA")
    for region_str in regions:
        try:
            x, y, w, h = (float(v) for v in region_str.split(","))
        except ValueError:
            continue
        pixelate_region(img, x, y, w, h)

    img.save(path, "PNG")


if __name__ == "__main__":
    main()