#!/usr/bin/env python3
from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageFilter
import numpy as np


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate alpha-safe high resolution pet assets.")
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--output", type=Path, default=Path("resource_hd"))
    parser.add_argument("--scale", type=int, default=3)
    parser.add_argument("--limit", type=int, default=0, help="Only process this many files, for smoke tests.")
    parser.add_argument("--force", action="store_true", help="Regenerate files even when output exists.")
    args = parser.parse_args()

    if args.scale < 2:
        raise SystemExit("--scale must be 2 or greater")
    if not args.source.is_dir():
        raise SystemExit(f"Source directory does not exist: {args.source}")
    if args.source.resolve() == args.output.resolve():
        raise SystemExit("--source and --output must be different directories")

    files = sorted(args.source.rglob("*.png"))
    if args.limit:
        files = files[: args.limit]

    generated = 0
    skipped = 0
    for source_path in files:
        relative = source_path.relative_to(args.source)
        output_path = args.output / relative
        if output_path.exists() and not args.force:
            skipped += 1
            continue
        output_path.parent.mkdir(parents=True, exist_ok=True)
        upscale_png(source_path, output_path, args.scale)
        generated += 1

    print(f"HD assets: generated={generated} skipped={skipped} output={args.output}")
    return 0


def upscale_png(source_path: Path, output_path: Path, scale: int) -> None:
    image = Image.open(source_path).convert("RGBA")
    width, height = image.size
    target_size = (width * scale, height * scale)

    alpha = image.getchannel("A")
    source = np.asarray(image, dtype=np.uint16)
    source[..., :3] = source[..., :3] * source[..., 3:4] // 255
    premultiplied = Image.fromarray(source.astype(np.uint8), "RGBA")
    resized = premultiplied.resize(target_size, Image.Resampling.LANCZOS)
    resized_alpha = alpha.resize(target_size, Image.Resampling.LANCZOS)
    resized_arr = np.asarray(resized, dtype=np.float32)
    alpha_arr = np.asarray(resized_alpha, dtype=np.float32)
    output_arr = np.zeros((*alpha_arr.shape, 4), dtype=np.uint8)
    alpha_safe = np.maximum(alpha_arr[..., None], 1.0)
    rgb = np.clip(resized_arr[..., :3] * 255.0 / alpha_safe, 0, 255)
    output_arr[..., :3] = np.where(alpha_arr[..., None] > 0, rgb, 0).astype(np.uint8)
    output_arr[..., 3] = alpha_arr.astype(np.uint8)
    output = Image.fromarray(output_arr, "RGBA")
    sharpened = output.filter(ImageFilter.UnsharpMask(radius=0.8, percent=95, threshold=3))
    sharpened.putalpha(resized_alpha)
    sharpened.save(output_path, optimize=True)


if __name__ == "__main__":
    raise SystemExit(main())
