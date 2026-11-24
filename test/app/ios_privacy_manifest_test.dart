import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Apple asks every app bundle to declare why it uses "required reason"
/// APIs (App Store check ITMS-91053). Plugins with their own manifest
/// declare theirs; Kalan's bundle declares what its own code and the
/// plugins without one use, and that it tracks and collects nothing
/// (data stays on the device).
void main() {
  const path = 'ios/Runner/PrivacyInfo.xcprivacy';

  test('the app bundle has a privacy manifest in its resources', () {
    expect(File(path).existsSync(), isTrue);
    final project = File('ios/Runner.xcodeproj/project.pbxproj')
        .readAsStringSync();
    final runner = project.substring(
      project.indexOf('97C146EC1CF9000F007C117D /* Resources */ = {'),
    );
    final files = runner.substring(0, runner.indexOf(');'));
    expect(files, contains('PrivacyInfo.xcprivacy in Resources'));
  });

  test('no tracking, nothing collected, reasons for what is used', () {
    final manifest = File(path).readAsStringSync();
    expect(manifest, contains('<key>NSPrivacyTracking</key>\n\t<false/>'));
    expect(
      manifest,
      contains('<key>NSPrivacyTrackingDomains</key>\n\t<array/>'),
    );
    expect(
      manifest,
      contains('<key>NSPrivacyCollectedDataTypes</key>\n\t<array/>'),
    );
    // Settings on this device (CA92.1) and the App Group the home screen
    // widget reads (1C8F.1, Roadmap 31): home_widget and
    // flutter_local_notifications ship no manifest of their own.
    expect(manifest, contains('NSPrivacyAccessedAPICategoryUserDefaults'));
    expect(manifest, contains('<string>CA92.1</string>'));
    expect(manifest, contains('<string>1C8F.1</string>'));
    // The database file in the app's own container (SQLite reads its
    // timestamps).
    expect(manifest, contains('NSPrivacyAccessedAPICategoryFileTimestamp'));
    expect(manifest, contains('<string>C617.1</string>'));
  });
}
