import 'dart:convert';
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

  test('iOS shows reminders in the foreground; buttons run in background', () {
    final delegate = File('ios/Runner/AppDelegate.swift').readAsStringSync();
    expect(delegate, contains('UNUserNotificationCenter.current().delegate'));
    expect(delegate, contains('"kalan/system"'));
    // "Paid" from a notification: the background engine gets the plugins
    // on iOS, and Android has the plugin's action receiver.
    expect(delegate, contains('setPluginRegistrantCallback'));
    expect(
      manifest,
      contains(
        'android:name="com.dexterous.flutterlocalnotifications.'
        'ActionBroadcastReceiver"',
      ),
    );
  });

  group('app lock (27)', () {
    final activity = File(
      'android/app/src/main/kotlin/app/kalan/mobile/MainActivity.kt',
    ).readAsStringSync();
    final delegate = File('ios/Runner/AppDelegate.swift').readAsStringSync();
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    final project = File('ios/Runner.xcodeproj/project.pbxproj')
        .readAsStringSync();

    test('Android hosts the system dialog (FragmentActivity, AppCompat)', () {
      // local_auth needs a FragmentActivity: otherwise the check cannot
      // show at all.
      expect(
        activity,
        contains('class MainActivity : FlutterFragmentActivity'),
      );
      for (final night in ['', '-night']) {
        final styles = File('android/app/src/main/res/values$night/styles.xml')
            .readAsStringSync();
        expect(
          RegExp(r'parent="Theme\.AppCompat').allMatches(styles),
          hasLength(2),
          reason: 'values$night: both themes',
        );
        expect(styles, contains('@color/launch_background'));
      }
    });

    test('app switcher: no recents screenshot, screenshots stay allowed', () {
      expect(activity, contains('setRecentsScreenshotEnabled'));
      expect(activity, contains('"setAppSwitcherCover"'));
      expect(activity, isNot(contains('FLAG_SECURE')));
      expect(delegate, contains('"setAppSwitcherCover"'));
      expect(delegate, contains('addSceneDelegate'));
      expect(delegate, contains('sceneDidEnterBackground'));
      expect(delegate, contains('"LaunchScreen"'));
      // Flutter's own scene delegate stays as it is.
      final scene = File('ios/Runner/SceneDelegate.swift').readAsStringSync();
      expect(scene, isNot(contains('override')));
    });

    test('iOS asks for Face ID with the ARB text, Turkish and English', () {
      expect(plist, contains('<key>NSFaceIDUsageDescription</key>'));
      for (final locale in ['en', 'tr']) {
        final arb = jsonDecode(
          File('lib/l10n/app_$locale.arb').readAsStringSync(),
        ) as Map<String, Object?>;
        final text = arb['appLockFaceIdUsage']! as String;
        final strings = File('ios/Runner/$locale.lproj/InfoPlist.strings')
            .readAsStringSync();
        expect(
          strings,
          contains('"NSFaceIDUsageDescription" = "$text";'),
          reason: locale,
        );
        expect(project, contains('path = $locale.lproj/InfoPlist.strings;'));
      }
      expect(
        plist,
        contains(
          '<string>${(jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync()) as Map)['appLockFaceIdUsage']}</string>',
        ),
      );
      expect(project, contains('InfoPlist.strings in Resources'));
    });
  });
}
