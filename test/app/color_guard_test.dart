import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Colors live only in lib/core/theme (KalanColors). Anything else that
/// writes Color(0x…), Colors.* or a hex color code fails here.
void main() {
  test('no colors outside lib/core/theme', () {
    final banned = RegExp(
      r'Color\(0x|\bColors\.|#[0-9A-Fa-f]{6}\b|\.withOpacity\(|\.withValues\(|\.withAlpha\(',
    );
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll(r'\', '/');
      if (path.startsWith('lib/core/theme/') ||
          path.startsWith('lib/l10n/generated/')) {
        continue;
      }
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (banned.hasMatch(lines[i])) offenders.add('$path:${i + 1}');
      }
    }
    expect(offenders, isEmpty);
  });
}
