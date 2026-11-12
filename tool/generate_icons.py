"""Draws the Kalan mark and writes app icons and launch images.

The mark follows the identity file (Logo Promptları, ana prompt): one
thick ring cut into four equal arcs with rounded ends; three muted slate
segments and one green segment in the upper right, on solid ink.

Run from the repository root:  python3 tool/generate_icons.py
Requires Pillow (development only; not part of the app).
"""
import json
import math
import os

from PIL import Image, ImageDraw

INK = (0x14, 0x21, 0x3D)
GREEN = (0x23, 0xB5, 0x8E)
SLATE = (0x3A, 0x4A, 0x6B)
SS = 4  # supersampling factor


def ring(size, ring_ratio=0.58, background=INK):
    """Returns a square RGBA image of the ring on [background] (or clear)."""
    big = size * SS
    img = Image.new('RGBA', (big, big), background + (255,) if background else (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    diameter = big * ring_ratio
    stroke = diameter / 5
    r_mid = (diameter - stroke) / 2
    cx = cy = big / 2
    gap = math.degrees(stroke * 0.22 / r_mid)
    cap = math.degrees((stroke / 2) / r_mid)
    box = [cx - r_mid - stroke / 2, cy - r_mid - stroke / 2,
           cx + r_mid + stroke / 2, cy + r_mid + stroke / 2]
    # PIL angles: degrees clockwise from 3 o'clock. Upper right = -90..0.
    for start, color in ((-90, GREEN), (0, SLATE), (90, SLATE), (180, SLATE)):
        a = start + gap / 2 + cap
        b = start + 90 - gap / 2 - cap
        draw.arc(box, a, b, fill=color + (255,), width=round(stroke))
        for ang in (a, b):
            x = cx + r_mid * math.cos(math.radians(ang))
            y = cy + r_mid * math.sin(math.radians(ang))
            s = stroke / 2
            draw.ellipse([x - s, y - s, x + s, y + s], fill=color + (255,))
    return img.resize((size, size), Image.LANCZOS)


def save(img, path, opaque):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    (img.convert('RGB') if opaque else img).save(path, optimize=True)


def main():
    # Android launcher icons.
    for folder, px in {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96,
                       'xxhdpi': 144, 'xxxhdpi': 192}.items():
        save(ring(px), f'android/app/src/main/res/mipmap-{folder}/ic_launcher.png', True)

    # iOS app icons (no alpha; the store rejects transparency).
    iconset = 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
    with open(f'{iconset}/Contents.json') as f:
        images = json.load(f)['images']
    for entry in images:
        points = float(entry['size'].split('x')[0])
        scale = int(entry['scale'][0])
        save(ring(round(points * scale)), f"{iconset}/{entry['filename']}", True)

    # Launch marks: the ring alone on a clear ground.
    launch = 'ios/Runner/Assets.xcassets/LaunchImage.imageset'
    for suffix, px in (('', 96), ('@2x', 192), ('@3x', 288)):
        save(ring(px, ring_ratio=1.0, background=None), f'{launch}/LaunchImage{suffix}.png', False)
    save(ring(288, ring_ratio=1.0, background=None),
         'android/app/src/main/res/drawable-nodpi/launch_mark.png', False)


if __name__ == '__main__':
    main()
