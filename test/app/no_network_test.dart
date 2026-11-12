import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Kalan keeps data on the device and makes no network requests.
void main() {
  test('release manifest requests no network permission', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    expect(manifest, isNot(contains('android.permission.INTERNET')));
    expect(manifest, isNot(contains('ACCESS_NETWORK_STATE')));
  });

  test('no networking, analytics or crash reporting packages ship', () {
    // Runtime closure only; dev tools such as build_runner may use sockets.
    final result = Process.runSync('dart', [
      'pub',
      'deps',
      '--no-dev',
      '--style=compact',
    ]);
    expect(result.exitCode, 0, reason: '${result.stderr}');
    final shipped = RegExp(
      r'^- (\S+) ',
      multiLine: true,
    ).allMatches(result.stdout as String).map((m) => m[1]!).toSet();
    expect(shipped, contains('drift'));
    const banned = [
      'http',
      'dio',
      'chopper',
      'retrofit',
      'web_socket_channel',
      'grpc',
      'firebase_core',
      'firebase_analytics',
      'firebase_crashlytics',
      'sentry',
      'sentry_flutter',
      'amplitude_flutter',
      'mixpanel_flutter',
      'google_mobile_ads',
      'appsflyer_sdk',
      'datadog_flutter_plugin',
    ];
    final found = banned.where(shipped.contains).toList();
    expect(found, isEmpty);
  });

  test('app code does not open sockets or HTTP clients', () {
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = entity.readAsStringSync();
      if (RegExp(r'HttpClient|Socket\.|WebSocket|dart:io').hasMatch(source)) {
        offenders.add(entity.path);
      }
    }
    expect(offenders, isEmpty);
  });
}
