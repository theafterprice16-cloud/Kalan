"""Draws the Kalan mark (Gece & Nane) and writes its sources.

The mark is the K logo: an off-white stem and arm, the lower leg split into
three mint parts. Geometry was measured from the original artwork
(2048 x 2048) and is kept here so the SVG and the PNGs match exactly.

Writes:
  assets/brand/kalan_icon.svg           full icon (ink ground), source of truth
  assets/brand/kalan_mark.svg           mark only, clear ground
  assets/brand/icon_1024.png            input for flutter_launcher_icons
  assets/brand/icon_foreground.png      Android adaptive foreground (safe zone)
  launch marks for iOS and Android      on the #0B0F14 splash ground
  ic_stat_kalan (Android)               white notification icon

Then run:  dart run flutter_launcher_icons
and revert its edit to ios/Runner.xcodeproj/project.pbxproj (the tool
writes an invalid ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS).
Requires Pillow (development only; not part of the app).
"""
import math
import os

from PIL import Image, ImageDraw

# Gece & Nane tokens (docs/DESIGN_TOKENS.md).
BG = '#0B0F14'     # bg (dark)
TEXT = '#F2F5F7'   # text (dark): stem and arm
MINT = '#3DDC97'   # mint: the three leg parts

SIZE = 2048
RADIUS = 34  # corner rounding, in 2048 units

# Shapes in 2048 units, clockwise.
STEM = [(553, 512), (818, 512), (818, 1535), (553, 1535)]
# Starts inside the stem so its rounded joins stay hidden.
ARM = [(780, 979), (1195, 512), (1493, 512), (780, 1309)]
LEG = [
    [(1118, 1033), (1200, 1130), (1037, 1302), (955, 1205)],
    [(1246, 1185), (1328, 1282), (1165, 1454), (1083, 1357)],
    [(1373, 1337), (1494, 1480), (1470, 1535), (1215, 1535)],
]
SHAPES = [(STEM, TEXT), (ARM, TEXT)] + [(p, MINT) for p in LEG]


def _toward(a, b, d):
    length = math.dist(a, b)
    t = min(d / length, 0.5)
    return (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)


def _corners(points, r):
    """Each corner as (start, control, end) of a quadratic curve."""
    n = len(points)
    return [
        (
            _toward(points[i], points[i - 1], r),
            points[i],
            _toward(points[i], points[(i + 1) % n], r),
        )
        for i in range(n)
    ]


def svg_path(points, r=RADIUS):
    corners = _corners(points, r)
    parts = [f'M{corners[0][2][0]:.1f},{corners[0][2][1]:.1f}']
    for start, ctrl, end in corners[1:] + corners[:1]:
        parts.append(f'L{start[0]:.1f},{start[1]:.1f}')
        parts.append(f'Q{ctrl[0]:.1f},{ctrl[1]:.1f} {end[0]:.1f},{end[1]:.1f}')
    return ' '.join(parts) + ' Z'


def polygon(points, r=RADIUS, steps=12):
    """The same rounded outline as [svg_path], sampled for raster drawing."""
    out = []
    for start, ctrl, end in _corners(points, r):
        for i in range(steps + 1):
            t = i / steps
            x = (1 - t) ** 2 * start[0] + 2 * (1 - t) * t * ctrl[0] + t * t * end[0]
            y = (1 - t) ** 2 * start[1] + 2 * (1 - t) * t * ctrl[1] + t * t * end[1]
            out.append((x, y))
    return out


def write_svg(path, ground):
    body = '\n'.join(
        f'  <path fill="{color}" d="{svg_path(points)}"/>'
        for points, color in SHAPES
    )
    rect = f'  <rect width="{SIZE}" height="{SIZE}" fill="{BG}"/>\n' if ground else ''
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w') as f:
        f.write(
            f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {SIZE} {SIZE}">\n'
            f'{rect}{body}\n</svg>\n'
        )


def render(px, ground=True, scale=1.0):
    """Renders the mark at [px]; [scale] shrinks it around the center."""
    ss = 4
    big = px * ss
    img = Image.new('RGBA', (big, big), BG if ground else (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    k = big / SIZE * scale
    offset = big * (1 - scale) / 2
    for points, color in SHAPES:
        draw.polygon(
            [(x * k + offset, y * k + offset) for x, y in polygon(points)],
            fill=color,
        )
    return img.resize((px, px), Image.LANCZOS)


def render_silhouette(px):
    """Android status bar icon: the mark in white on a clear ground.

    The system tints it; the accent colour (#3DDC97) is set in code.
    """
    ss = 4
    big = px * ss
    img = Image.new('RGBA', (big, big), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # The mark (about 1023 units tall, centred at 1023) with a small margin,
    # as Android's 24 dp guide asks (content within ~20 dp).
    k = big / 1280
    dx = dy = big / 2 - 1023.5 * k
    for points, _ in SHAPES:
        draw.polygon(
            [(x * k + dx, y * k + dy) for x, y in polygon(points)],
            fill=(255, 255, 255, 255),
        )
    return img.resize((px, px), Image.LANCZOS)


def save(img, path, opaque=False):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    (img.convert('RGB') if opaque else img).save(path, optimize=True)


def main():
    write_svg('assets/brand/kalan_icon.svg', ground=True)
    write_svg('assets/brand/kalan_mark.svg', ground=False)
    save(render(1024), 'assets/brand/icon_1024.png', opaque=True)
    # flutter_launcher_icons insets the adaptive foreground by 16%, which
    # keeps the mark (about half the canvas) inside the visible safe zone.
    save(render(1024, ground=False), 'assets/brand/icon_foreground.png')

    launch = 'ios/Runner/Assets.xcassets/LaunchImage.imageset'
    for suffix, px in (('', 128), ('@2x', 256), ('@3x', 384)):
        save(render(px, ground=False), f'{launch}/LaunchImage{suffix}.png')
    save(render(384, ground=False),
         'android/app/src/main/res/drawable-nodpi/launch_mark.png')

    # Notification icon (24 dp), referenced as ic_stat_kalan.
    for folder, px in {'mdpi': 24, 'hdpi': 36, 'xhdpi': 48,
                       'xxhdpi': 72, 'xxxhdpi': 96}.items():
        save(render_silhouette(px),
             f'android/app/src/main/res/drawable-{folder}/ic_stat_kalan.png')


if __name__ == '__main__':
    main()
