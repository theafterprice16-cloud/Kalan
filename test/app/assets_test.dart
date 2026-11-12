import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('brand sources and generated icons exist', () {
    const files = [
      'assets/brand/kalan_icon.svg',
      'assets/brand/kalan_mark.svg',
      'assets/brand/icon_1024.png',
      'assets/brand/icon_foreground.png',
      'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png',
      'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png',
      'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png',
      'android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml',
      'android/app/src/main/res/drawable-xxxhdpi/ic_launcher_foreground.png',
      'android/app/src/main/res/drawable-nodpi/launch_mark.png',
    ];
    for (final f in files) {
      expect(File(f).existsSync(), isTrue, reason: f);
    }
  });

  test('App Store icon has no alpha channel', () {
    final bytes = File(
      'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png',
    ).readAsBytesSync();
    // PNG IHDR color type at byte 25: 2 = RGB (no alpha).
    expect(bytes[25], 2);
  });

  test('icon SVG uses only Gece & Nane colors', () {
    final svg = File('assets/brand/kalan_icon.svg').readAsStringSync();
    final colors = RegExp('#[0-9A-Fa-f]{6}')
        .allMatches(svg)
        .map((m) => m[0]!.toUpperCase())
        .toSet();
    expect(colors, {'#0B0F14', '#F2F5F7', '#3DDC97'});
  });

  test('splash and adaptive icon grounds are #0B0F14', () {
    for (final path in [
      'android/app/src/main/res/values/colors.xml',
      'android/app/src/main/res/values-night/colors.xml',
    ]) {
      expect(
        File(path).readAsStringSync(),
        contains('<color name="launch_background">#0B0F14</color>'),
        reason: path,
      );
    }
    expect(
      File('android/app/src/main/res/values/colors.xml').readAsStringSync(),
      contains('<color name="ic_launcher_background">#0B0F14</color>'),
    );
    // 0x0B / 255, 0x0F / 255, 0x14 / 255
    expect(
      File('ios/Runner/Base.lproj/LaunchScreen.storyboard').readAsStringSync(),
      contains(
        'red="0.043137254901960784" green="0.058823529411764705" '
        'blue="0.078431372549019607"',
      ),
    );
  });

  test('the Xcode project was not altered by the icon tool', () {
    final project = File('ios/Runner.xcodeproj/project.pbxproj')
        .readAsStringSync();
    expect(
      project,
      isNot(contains('GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = AppIcon')),
    );
  });
}
