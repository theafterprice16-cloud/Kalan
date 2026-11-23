import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('brand sources and generated icons exist', () {
    const files = [
      'assets/brand/kalan_icon.svg',
      'assets/brand/kalan_mark.svg',
      'assets/brand/kalan_icon_dark.svg',
      'assets/brand/kalan_mark_dark.svg',
      'assets/brand/icon_1024_dark.png',
      'docs/kimlik/ikon-60px-acik.png',
      'docs/kimlik/ikon-60px-koyu.png',
      'assets/brand/icon_1024.png',
      'assets/brand/icon_foreground.png',
      'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png',
      'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png',
      'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png',
      'android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml',
      'android/app/src/main/res/drawable-xxxhdpi/ic_launcher_foreground.png',
      'android/app/src/main/res/drawable-nodpi/launch_mark.png',
      // Lock screen and app switcher cover (27).
      'assets/brand/mark/kalan_mark.png',
      'assets/brand/mark/3.0x/kalan_mark.png',
      'assets/brand/mark/kalan_mark_dark.png',
      'assets/brand/mark/3.0x/kalan_mark_dark.png',
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

  test('icon SVGs use only Mürekkep ve Safran colors', () {
    Set<String> colorsIn(String path) =>
        RegExp('#[0-9A-Fa-f]{6}')
            .allMatches(File(path).readAsStringSync())
            .map((m) => m[0]!.toUpperCase())
            .toSet();
    // ground (bg), K (text), two parts (chartCommitted), last part (accent)
    expect(colorsIn('assets/brand/kalan_icon.svg'), {
      '#F5F0E6',
      '#1A2330',
      '#B87A0A',
      '#1D4E89',
    });
    expect(colorsIn('assets/brand/kalan_icon_dark.svg'), {
      '#11161D',
      '#EFE9DD',
      '#C98F24',
      '#8FB8F2',
    });
  });

  test('light and dark icons share one shape', () {
    List<String> paths(String file) =>
        RegExp('d="([^"]*)"')
            .allMatches(File(file).readAsStringSync())
            .map((m) => m[1]!)
            .toList();
    expect(paths('assets/brand/kalan_icon.svg'), hasLength(5));
    expect(
      paths('assets/brand/kalan_icon_dark.svg'),
      paths('assets/brand/kalan_icon.svg'),
    );
    expect(
      paths('assets/brand/kalan_mark_dark.svg'),
      paths('assets/brand/kalan_icon.svg'),
    );
  });

  test('splash grounds follow the theme bg', () {
    String read(String path) => File(path).readAsStringSync();
    final light = read('android/app/src/main/res/values/colors.xml');
    expect(light, contains('<color name="launch_background">#F5F0E6</color>'));
    expect(
      light,
      contains('<color name="ic_launcher_background">#F5F0E6</color>'),
    );
    expect(
      read('android/app/src/main/res/values-night/colors.xml'),
      contains('<color name="launch_background">#11161D</color>'),
    );
    expect(
      File('android/app/src/main/res/drawable-night-nodpi/launch_mark.png')
          .existsSync(),
      isTrue,
    );
    expect(
      read('ios/Runner/Base.lproj/LaunchScreen.storyboard'),
      contains('<color key="backgroundColor" name="LaunchBackground"/>'),
    );
    final named = read(
      'ios/Runner/Assets.xcassets/LaunchBackground.colorset/Contents.json',
    );
    // F5F0E6 for light, 11161D for the dark appearance.
    for (final part in ['0xF5', '0xF0', '0xE6', '0x11', '0x16', '0x1D']) {
      expect(named, contains(part));
    }
    expect(named, contains('"dark"'));
    expect(
      read('ios/Runner/Assets.xcassets/LaunchImage.imageset/Contents.json'),
      contains('LaunchImageDark@3x.png'),
    );
  });

  test('iOS has a dark app icon', () {
    final contents = File(
      'ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json',
    ).readAsStringSync();
    expect(contents, contains('Icon-App-Dark-1024x1024@1x.png'));
    expect(contents, contains('"luminosity"'));
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
