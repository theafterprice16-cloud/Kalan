import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Platform setup the reminders depend on. Compiled in CI (Android) and in
/// Xcode (iOS); these checks keep the pieces from being lost.
void main() {
  final manifest = File('android/app/src/main/AndroidManifest.xml')
      .readAsStringSync();

  test('Android asks only for what local reminders need', () {
    expect(manifest, contains('android.permission.POST_NOTIFICATIONS'));
    expect(manifest, contains('android.permission.RECEIVE_BOOT_COMPLETED'));
    // Store policy: no exact alarms for this kind of app (inexact only).
    expect(manifest, isNot(contains('SCHEDULE_EXACT_ALARM')));
    expect(manifest, isNot(contains('USE_EXACT_ALARM')));
  });

  test('Android receivers: plugin and Kalan rescheduling', () {
    for (final receiver in [
      'ScheduledNotificationReceiver',
      'ScheduledNotificationBootReceiver',
      'ActionBroadcastReceiver',
      '.ReminderRescheduleReceiver',
    ]) {
      expect(manifest, contains(receiver), reason: receiver);
    }
    for (final action in [
      'android.intent.action.TIME_SET',
      'android.intent.action.TIMEZONE_CHANGED',
      'android.intent.action.BOOT_COMPLETED',
    ]) {
      expect(manifest, contains(action), reason: action);
    }
  });

  test('Android Gradle enables desugaring', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    expect(gradle, contains('isCoreLibraryDesugaringEnabled = true'));
    expect(gradle, contains('desugar_jdk_libs'));
  });

  test('Android compiles against SDK 37 or later', () {
    // flutter_local_notifications 23 and androidx.core 1.19 require it
    // (AAR metadata check); targetSdk stays Flutter's default.
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    final sdk = RegExp(r'compileSdk = (\d+)').firstMatch(gradle);
    expect(sdk, isNotNull, reason: 'compileSdk is pinned');
    expect(int.parse(sdk!.group(1)!), greaterThanOrEqualTo(37));
    expect(gradle, contains('targetSdk = flutter.targetSdkVersion'));
  });

  test('the Dart entry point the receiver starts exists', () {
    final receiver = File(
      'android/app/src/main/kotlin/app/kalan/mobile/'
      'ReminderRescheduleReceiver.kt',
    ).readAsStringSync();
    final main = File('lib/main.dart').readAsStringSync();
    expect(receiver, contains('"rescheduleRemindersInBackground"'));
    expect(main, contains("@pragma('vm:entry-point')"));
    expect(main, contains('rescheduleRemindersInBackground()'));
  });

  test('notification icon exists in every density', () {
    for (final d in ['mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi']) {
      final f = File('android/app/src/main/res/drawable-$d/ic_stat_kalan.png');
      expect(f.existsSync(), isTrue, reason: d);
    }
  });

  test('iOS registers plugins for the background "Paid" action', () {
    final delegate = File('ios/Runner/AppDelegate.swift').readAsStringSync();
    expect(delegate, contains('setPluginRegistrantCallback'));
    expect(delegate, contains('UNUserNotificationCenter.current().delegate'));
    expect(delegate, contains('"kalan/system"'));
  });
}
