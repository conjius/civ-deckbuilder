#!/usr/bin/env python3
"""Build a labeled grid image from icon PNG/SVG files for visual comparison.

Usage: python3 build_icon_grid.py <icons_dir> <output_path>

Expects PNG thumbnails in icons_dir named like 01_name.svg.png.
Groups icons by number ranges into categories and renders a grid.
"""

import os
import sys
from PIL import Image, ImageDraw, ImageFont


def build_grid(icons_dir: str, output_path: str) -> None:
    files = sorted(
        f for f in os.listdir(icons_dir) if f.endswith(".svg.png")
    )

    labels = {}
    for f in files:
        prefix = f[:2]
        name = f[3:].replace(".svg.png", "").replace("_", " ").title()
        labels[prefix] = f"{prefix}. {name}"

    cell_w, cell_h = 150, 175
    icon_size = 110
    padding = 15
    header_h = 45
    max_cols = 8

    rows_needed = (len(files) + max_cols - 1) // max_cols
    total_w = max_cols * cell_w + padding * 2
    total_h = padding + header_h + rows_needed * cell_h + padding

    img = Image.new("RGB", (total_w, total_h), (40, 30, 25))
    draw = ImageDraw.Draw(img)

    try:
        font = ImageFont.truetype(
            "/System/Library/Fonts/Helvetica.ttc", 15
        )
        font_header = ImageFont.truetype(
            "/System/Library/Fonts/Helvetica.ttc", 22
        )
    except OSError:
        font = ImageFont.load_default()
        font_header = font

    draw.text(
        (padding + 5, padding + 8),
        "ICON OPTIONS",
        fill=(255, 200, 100),
        font=font_header,
    )
    y_offset = padding + header_h

    for i, f in enumerate(files):
        prefix = f[:2]
        col = i % max_cols
        row = i // max_cols
        x = padding + col * cell_w
        y = y_offset + row * cell_h

        path = os.path.join(icons_dir, f)
        icon = Image.open(path).convert("RGBA")
        icon = icon.resize((icon_size, icon_size), Image.LANCZOS)

        ix = x + (cell_w - icon_size) // 2
        iy = y + 5
        bg = Image.new("RGBA", (icon_size, icon_size), (40, 30, 25, 255))
        bg.paste(icon, (0, 0), icon)
        img.paste(bg.convert("RGB"), (ix, iy))

        label = labels.get(prefix, prefix)
        bbox = draw.textbbox((0, 0), label, font=font)
        tw = bbox[2] - bbox[0]
        tx = x + (cell_w - tw) // 2
        draw.text(
            (tx, iy + icon_size + 5), label, fill=(255, 255, 255), font=font
        )

    img.save(output_path)
    print(f"Saved: {output_path} ({img.size[0]}x{img.size[1]})")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <icons_dir> <output_path>")
        sys.exit(1)
    build_grid(sys.argv[1], sys.argv[2])
