#!/usr/bin/env python3
"""Generate the BillsNow app icon set (navy + red monogram)."""
import os
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "BillsNow", "Assets.xcassets", "AppIcon.appiconset")
os.makedirs(OUT, exist_ok=True)

NAVY = (0x00, 0x33, 0x8D, 255)
RED = (0xC8, 0x10, 0x2E, 255)
WHITE = (255, 255, 255, 255)

SIZE = 1024


def master() -> Image.Image:
    img = Image.new("RGB", (SIZE, SIZE), NAVY[:3])
    d = ImageDraw.Draw(img)

    # Deep navy vignette at the bottom for depth.
    for i in range(SIZE // 3):
        alpha = int(60 * (1 - i / (SIZE // 3)))
        shade = (0, 20, 60)
        d.line([(0, SIZE - i), (SIZE, SIZE - i)], fill=(shade[0], shade[1], shade[2], alpha))

    # White "BUF" monogram, nudged left to balance the red band.
    font_path = "/usr/share/fonts/liberation/LiberationSans-Bold.ttf"
    if not os.path.exists(font_path):
        font_path = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
    # Fit text width ~ 470 px.
    size = 320
    font = ImageFont.truetype(font_path, size)
    while d.textlength("BUF", font=font) > 470 and size > 120:
        size -= 4
        font = ImageFont.truetype(font_path, size)

    text = "BUF"
    bbox = d.textbbox((0, 0), text, font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    tx = (SIZE - tw) // 2 - 55
    ty = (SIZE - th) // 2 - bbox[1] - 10
    d.text((tx, ty), text, font=font, fill=WHITE)

    # Red rounded band down the right edge (nod to the logo's red swoosh).
    band_w = 92
    inset = 26
    d.rounded_rectangle(
        [SIZE - band_w - inset, inset - 40, SIZE - inset, SIZE - inset + 40],
        radius=46, fill=RED,
    )

    # Thin red underline under the text.
    ul_y = ty + th + 24
    d.rounded_rectangle([tx - 6, ul_y, tx + tw + 6, ul_y + 22], radius=11, fill=RED)

    return img.convert("RGB")


def write(m: Image.Image, name: str, px: int) -> None:
    m.resize((px, px), Image.LANCZOS).save(os.path.join(OUT, name), "PNG")
    print(f"  {name:26s} {px}x{px}")


def main() -> None:
    print("Generating app icons in", OUT)
    m = master()
    targets = [
        # (filename, pixels)
        ("icon-20-1x.png", 20),
        ("icon-20-2x.png", 40),
        ("icon-20-3x.png", 60),
        ("icon-29-1x.png", 29),
        ("icon-29-2x.png", 58),
        ("icon-29-3x.png", 87),
        ("icon-40-1x.png", 40),
        ("icon-40-2x.png", 80),
        ("icon-40-3x.png", 120),
        ("icon-60-2x.png", 120),
        ("icon-60-3x.png", 180),
        ("icon-76-1x.png", 76),
        ("icon-76-2x.png", 152),
        ("icon-83.5-2x.png", 167),
        ("icon-1024.png", 1024),
    ]
    for name, px in targets:
        write(m, name, px)
    print("Done.")


if __name__ == "__main__":
    main()
