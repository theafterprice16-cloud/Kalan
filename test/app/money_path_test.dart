import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Amounts are formatted only in lib/core/money; nothing else hard-codes a
/// currency symbol, minor-unit size or number format.
void main() {
  test('only lib/core/money formats money', () {
    final banned = <String, RegExp>{
      'NumberFormat': RegExp(r'\bNumberFormat\b'),
      'currency symbol': RegExp(
        r'''['"][^'"]*(₺|€|£|₽|₸|¥|R\$|Rp|RM|CHF|\bTL\b)''',
      ),
      'fixed minor units': RegExp(r'(~/|%)\s*100\b'),
      'decimalDigits': RegExp(r'\bdecimalDigits\b'),
    };
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll(r'\', '/');
      if (path.startsWith('lib/core/money/') ||
          path.startsWith('lib/l10n/generated/')) {
        continue;
      }
      final source = entity.readAsStringSync();
      for (final MapEntry(key: what, value: pattern) in banned.entries) {
        if (pattern.hasMatch(source)) offenders.add('$path: $what');
      }
    }
    expect(offenders, isEmpty);
  });
}
