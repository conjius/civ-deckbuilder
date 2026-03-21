#!/usr/bin/env python3
"""Build a labeled composite image from 3D model preview screenshots.

Usage: python3 build_model_preview.py <previews_dir> <output_path>

Expects image files (PNG/JPG) in previews_dir. Each image is labeled
with its filename and arranged in a vertical list.
"""

import os
import sys
from PIL import Image, ImageDraw, ImageFont


def build_preview(previews_dir: str, output_path: str) -> None:
    files = sorted(
        f
        for f in os.listdir(previews_dir)
        if f.lower().endswith((".png", ".jpg", ".jpeg"))
        and os.path.getsize(os.path.join(previews_dir, f)) > 1000
    )

    try:
        font = ImageFont.truetype(
            "/System/Library/Fonts/Helvetica.ttc", 24
        )
    except OSError:
        font = ImageFont.load_default()

    tw = 900
    padding = 20
    img_h = 350
    gap = 10

    total_h = padding
    for _ in files:
        total_h += img_h + 40 + gap
    total_h += padding

    img = Image.new("RGB", (tw + padding * 2, total_h), (40, 30, 25))
    draw = ImageDraw.Draw(img)

    y = padding
    for fname in files:
        path = os.path.join(previews_dir, fname)
        try:
            preview = Image.open(path).convert("RGB")
            ratio = min(tw / preview.width, img_h / preview.height)
            new_w = int(preview.width * ratio)
            new_h = int(preview.height * ratio)
            preview = preview.resize((new_w, new_h), Image.LANCZOS)
            px = padding + (tw - new_w) // 2
            img.paste(preview, (px, y))
        except Exception as e:
            draw.text((padding, y), f"Error: {e}", fill=(255, 0, 0), font=font)

        y += img_h
        label = fname.rsplit(".", 1)[0].replace("_", " ").title()
        draw.text((padding + 10, y + 5), label, fill=(255, 255, 255), font=font)
        y += 40 + gap

    img.save(output_path)
    print(f"Saved: {output_path} ({img.size[0]}x{img.size[1]})")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <previews_dir> <output_path>")
        sys.exit(1)
    build_preview(sys.argv[1], sys.argv[2])
