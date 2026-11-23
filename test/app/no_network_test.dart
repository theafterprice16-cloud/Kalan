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
    // `timezone` (required by flutter_local_notifications) lists `http`
    // only for its web loader, timezone/browser.dart. Kalan uses the
    // bundled database instead, so `http` is allowed only while timezone is
    // its sole dependent and no app code imports either (checked below).
    final output = result.stdout as String;
    final dependents = RegExp(r'^- (\S+) \S+ \[([^\]]*)\]', multiLine: true)
        .allMatches(output)
        .where((m) => m[2]!.split(' ').contains('http'))
        .map((m) => m[1])
        .toSet();
    if (dependents.length == 1 && dependents.single == 'timezone') {
      found.remove('http');
    }
    expect(found, isEmpty, reason: 'http dependents: $dependents');
  });

  test('app code never loads anything over the network', () {
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = entity.readAsStringSync();
      if (source.contains('package:http/') ||
          source.contains('package:timezone/browser.dart')) {
        offenders.add(entity.path);
      }
    }
    expect(offenders, isEmpty);
  });

  test('app code does not open sockets or HTTP clients', () {
    // dart:io only where a file is written, and then only its file
    // classes: the export file for the share sheet (Roadmap 29).
    const fileOnly = {
      'lib/features/export/export_service.dart':
          "import 'dart:io' show Directory, File, FileSystemException;",
    };
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll(r'\', '/');
      final source = entity.readAsStringSync();
      if (RegExp(r'HttpClient|HttpServer|Socket|WebSocket').hasMatch(source)) {
        offenders.add(path);
      }
      final io = RegExp(r'''import\s+['"]dart:io['"][^;]*;''')
          .allMatches(source)
          .map((m) => m[0])
          .toList();
      if (io.isNotEmpty && (io.length > 1 || io.single != fileOnly[path])) {
        offenders.add('$path: ${io.join(' ')}');
      }
    }
    expect(offenders, isEmpty);
  });
}
