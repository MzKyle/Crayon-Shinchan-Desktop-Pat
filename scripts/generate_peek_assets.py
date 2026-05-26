#!/usr/bin/env python3
from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parent.parent
OUT_DIR = ROOT / "assets" / "character"
CANVAS = (112, 140)
TARGET_HEIGHT = 132


def remove_flat_background(image: Image.Image) -> Image.Image:
    image = image.convert("RGBA")
    pixels = image.load()
    width, height = image.size
    corners = [
        pixels[0, 0],
        pixels[width - 1, 0],
        pixels[0, height - 1],
        pixels[width - 1, height - 1],
    ]
    bg = tuple(sum(color[i] for color in corners) // len(corners) for i in range(3))

    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            if a == 0:
                continue
            distance = abs(r - bg[0]) + abs(g - bg[1]) + abs(b - bg[2])
            if distance < 42:
                pixels[x, y] = (r, g, b, 0)
    return image


def fit_to_height(image: Image.Image, height: int) -> Image.Image:
    ratio = height / image.height
    return image.resize((max(1, int(image.width * ratio)), height), Image.Resampling.LANCZOS)


def make_canvas(source: Image.Image, x: int, y: int) -> Image.Image:
    canvas = Image.new("RGBA", CANVAS, (0, 0, 0, 0))
    canvas.alpha_composite(source, (x, y))
    return canvas


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, required=True, help="Source character PNG.")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    source_path = args.source.expanduser().resolve()
    if not source_path.exists():
        raise SystemExit(f"Missing source image: {source_path}")

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    source = remove_flat_background(Image.open(source_path))
    bbox = source.getbbox()
    if bbox is None:
        raise SystemExit(f"Source image is fully transparent: {source_path}")
    body = source.crop(bbox)
    body = fit_to_height(body, TARGET_HEIGHT)
    body_left = body.transpose(Image.Transpose.FLIP_LEFT_RIGHT)

    # Names are from the screen edge where Shin-chan hides.
    outputs = {
        "peek_left.png": make_canvas(body, -42, 4),
        "peek_right.png": make_canvas(body_left, CANVAS[0] - body_left.width + 42, 4),
        "peek_top.png": make_canvas(body, (CANVAS[0] - body.width) // 2, -46),
        "peek_bottom.png": make_canvas(body, (CANVAS[0] - body.width) // 2, CANVAS[1] - body.height + 52),
    }
    for filename, image in outputs.items():
        path = OUT_DIR / filename
        image.save(path)
        print(f"Wrote {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
