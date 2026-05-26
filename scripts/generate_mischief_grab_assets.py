#!/usr/bin/env python3
from __future__ import annotations

import argparse
from collections import deque
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parent.parent
OUT_DIR = ROOT / "resource_hd" / "mischief_grab"
CANVAS = (260, 220)
TARGET_HEIGHT = 188
MAX_WIDTH = 232


def remove_edge_background(image: Image.Image) -> Image.Image:
    image = image.convert("RGBA")
    pixels = image.load()
    width, height = image.size
    visited: set[tuple[int, int]] = set()
    queue: deque[tuple[int, int]] = deque()

    def is_background(x: int, y: int) -> bool:
        r, g, b, a = pixels[x, y]
        return a == 0 or (r > 232 and g > 232 and b > 232)

    for x in range(width):
        for y in (0, height - 1):
            if is_background(x, y):
                queue.append((x, y))
    for y in range(height):
        for x in (0, width - 1):
            if is_background(x, y):
                queue.append((x, y))

    while queue:
        x, y = queue.popleft()
        if (x, y) in visited or x < 0 or y < 0 or x >= width or y >= height:
            continue
        if not is_background(x, y):
            continue
        visited.add((x, y))
        r, g, b, _a = pixels[x, y]
        pixels[x, y] = (r, g, b, 0)
        queue.extend(((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)))
    return image


def fit_body(image: Image.Image) -> Image.Image:
    bbox = image.getbbox()
    if bbox is None:
        raise SystemExit("Source image is fully transparent.")
    body = image.crop(bbox)
    ratio = TARGET_HEIGHT / body.height
    if body.width * ratio > MAX_WIDTH:
        ratio = MAX_WIDTH / body.width
    size = (max(1, int(body.width * ratio)), max(1, int(body.height * ratio)))
    return body.resize(size, Image.Resampling.LANCZOS)


def make_frame(body: Image.Image, angle: float, scale: float, dx: int, dy: int) -> Image.Image:
    scaled = body.resize(
        (max(1, int(body.width * scale)), max(1, int(body.height * scale))),
        Image.Resampling.LANCZOS,
    )
    rotated = scaled.rotate(angle, resample=Image.Resampling.BICUBIC, expand=True)
    canvas = Image.new("RGBA", CANVAS, (0, 0, 0, 0))
    x = (CANVAS[0] - rotated.width) // 2 - 12 + dx
    y = (CANVAS[1] - rotated.height) // 2 + 8 + dy
    canvas.alpha_composite(rotated, (x, y))
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
    body = fit_body(remove_edge_background(Image.open(source_path)))
    frames = [
        make_frame(body, -4.0, 1.00, -1, 1),
        make_frame(body, 3.5, 1.02, 3, -2),
        make_frame(body, -2.5, 0.99, -3, 2),
        make_frame(body, 4.5, 1.01, 4, -1),
    ]
    for index, frame in enumerate(frames, start=1):
        path = OUT_DIR / f"grab_{index:02d}.png"
        frame.save(path, optimize=True)
        print(f"Wrote {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
