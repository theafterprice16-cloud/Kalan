"""Writes app icons and launch marks from the master logo.

Master: docs/kimlik/logo.png (square, full-bleed, opaque). Replace that
file and run from the repository root:

    python3 tool/generate_icons.py

Requires Pillow (development only; not part of the app).
"""
import json
import os

from PIL import Image

MASTER = 'docs/kimlik/logo.png'


def save(img, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path, optimize=True)


def main():
    logo = Image.open(MASTER).convert('RGB')  # no alpha: the App Store rejects it

    def sized(px):
        return logo.resize((px, px), Image.LANCZOS)

    for folder, px in {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96,
                       'xxhdpi': 144, 'xxxhdpi': 192}.items():
        save(sized(px), f'android/app/src/main/res/mipmap-{folder}/ic_launcher.png')

    iconset = 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
    with open(f'{iconset}/Contents.json') as f:
        images = json.load(f)['images']
    for entry in images:
        points = float(entry['size'].split('x')[0])
        scale = int(entry['scale'][0])
        save(sized(round(points * scale)), f"{iconset}/{entry['filename']}")

    # Launch marks sit on the logo's own ground color, so they blend in.
    launch = 'ios/Runner/Assets.xcassets/LaunchImage.imageset'
    for suffix, px in (('', 128), ('@2x', 256), ('@3x', 384)):
        save(sized(px), f'{launch}/LaunchImage{suffix}.png')
    save(sized(384), 'android/app/src/main/res/drawable-nodpi/launch_mark.png')


if __name__ == '__main__':
    main()
