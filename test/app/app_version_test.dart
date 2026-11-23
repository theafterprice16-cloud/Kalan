import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/app/app_version.dart';

void main() {
  test('the version in backups is the one in pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final version = RegExp(
      r'^version:\s*(\S+)',
      multiLine: true,
    ).firstMatch(pubspec)![1];
    expect(appVersion, version);
  });
}
