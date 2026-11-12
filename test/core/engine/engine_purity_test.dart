import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The engine, date and money code must stay plain Dart so it can be tested
/// and reused without Flutter.
void main() {
  test('core engine, date and money do not import Flutter', () {
    final offenders = <String>[];
    for (final dir in ['lib/core/engine', 'lib/core/date', 'lib/core/money']) {
      for (final entity in Directory(dir).listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final source = entity.readAsStringSync();
        if (RegExp(r'''import\s+['"]package:(flutter|material_ui)''')
            .hasMatch(source)) {
          offenders.add(entity.path);
        }
        if (RegExp(r'\bdouble\b').hasMatch(source)) {
          offenders.add('${entity.path} (uses double)');
        }
      }
    }
    expect(offenders, isEmpty);
  });
}
