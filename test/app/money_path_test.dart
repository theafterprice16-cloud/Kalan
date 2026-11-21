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

  // Roadmap 24: dates and numbers read the intl locale (intlLocaleOf),
  // never the generated localeName as is (zh_Hant would read zh's data).
  test('dates and amounts use the intl locale', () {
    final raw = RegExp(
      r'(?<!intlLocaleOf\()\b(l10n|AppLocalizations\.of\(\w+\))\.localeName\b',
    );
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll(r'\', '/');
      if (path.startsWith('lib/l10n/generated/')) continue;
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (raw.hasMatch(lines[i])) offenders.add('$path:${i + 1}');
      }
    }
    expect(offenders, isEmpty);
    expect(raw.hasMatch('DateFormat.E(l10n.localeName)'), isTrue);
    expect(raw.hasMatch('intlLocaleOf(l10n.localeName)'), isFalse);
  });
}
