import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('app icons and launch marks exist for both platforms', () {
    const files = [
      'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png',
      'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png',
      'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png',
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

  test('launch background matches the logo ground in both modes', () {
    final day = File('android/app/src/main/res/values/colors.xml')
        .readAsStringSync();
    final night = File('android/app/src/main/res/values-night/colors.xml')
        .readAsStringSync();
    expect(day, contains('#172643'));
    expect(night, contains('#172643'));
  });
}
