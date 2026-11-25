import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Kalan keeps data on the device and makes no network requests.
void main() {
  test('release manifest requests no network permission', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    expect(manifest, isNot(contains('android.permission.INTERNET')));
    // Named only to take it out of what libraries merge in (WorkManager
    // through home_widget, Roadmap 31).
    final asked = manifest.replaceAll(
      '<uses-permission\n'
          '        android:name="android.permission.ACCESS_NETWORK_STATE"\n'
          '        tools:node="remove" />',
      '',
    );
    expect(asked, isNot(contains('ACCESS_NETWORK_STATE')));
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
    // `http` is listed by two packages that never send anything from the
    // app: `timezone` (required by flutter_local_notifications) uses it
    // only in its web loader, timezone/browser.dart (Kalan uses the
    // bundled database; no app code imports either, checked below), and
    // `file_selector_platform_interface` (Roadmap 30) lists it without
    // importing it anywhere (checked in its sources below). Any other
    // package that needs `http` fails here.
    final output = result.stdout as String;
    final dependents = RegExp(r'^- (\S+) \S+ \[([^\]]*)\]', multiLine: true)
        .allMatches(output)
        .where((m) => m[2]!.split(' ').contains('http'))
        .map((m) => m[1]!)
        .toSet();
    const allowed = {
      // Package: files that may import package:http.
      'timezone': {'browser.dart'},
      'file_selector_platform_interface': <String>{},
    };
    if (dependents.every(allowed.containsKey)) {
      for (final name in dependents) {
        final imports = httpImportsIn(name);
        expect(
          imports.difference(allowed[name]!),
          isEmpty,
          reason: '$name imports package:http',
        );
      }
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
    // classes: the export file for the share sheet (Roadmap 29); and the
    // system version (Platform), which opens nothing.
    const fileOnly = {
      // The restore's safety copy, in the app's own folder (Roadmap 30).
      'lib/features/restore/restore_undo.dart':
          "import 'dart:io' show Directory, File, FileSystemException;",
      'lib/features/export/export_service.dart':
          "import 'dart:io' show Directory, File, FileSystemException;",
      // The iOS version only, for the Lock Screen widget (Roadmap 32).
      'lib/app/phone_platform.dart': "import 'dart:io' show Platform;",
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

/// The files of package [name]'s lib/ that import package:http, by path
/// under lib/ (from the resolved package config).
Set<String> httpImportsIn(String name) {
  final config = jsonDecode(
    File('.dart_tool/package_config.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final package = (config['packages'] as List<dynamic>)
      .cast<Map<String, dynamic>>()
      .singleWhere((p) => p['name'] == name);
  final rootUri = package['rootUri'] as String;
  final root = File('.dart_tool/package_config.json').absolute.uri
      .resolve(rootUri.endsWith('/') ? rootUri : '$rootUri/');
  final lib = Directory.fromUri(
    root.resolve('${package['packageUri'] ?? 'lib/'}'),
  );
  final out = <String>{};
  for (final entity in lib.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    if (entity.readAsStringSync().contains('package:http/')) {
      out.add(entity.path.substring(lib.path.length).replaceAll(r'\', '/'));
    }
  }
  return out;
}
