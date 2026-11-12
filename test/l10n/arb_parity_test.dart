import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/money/currency.dart';

Map<String, dynamic> _load(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

void main() {
  final en = _load('lib/l10n/app_en.arb');
  final tr = _load('lib/l10n/app_tr.arb');
  Set<String> keys(Map<String, dynamic> m) =>
      m.keys.where((k) => !k.startsWith('@')).toSet();

  test('every message exists in both Turkish and English', () {
    expect(keys(tr).difference(keys(en)), isEmpty);
    expect(keys(en).difference(keys(tr)), isEmpty);
  });

  test('no message is empty', () {
    for (final m in [en, tr]) {
      for (final k in keys(m)) {
        expect((m[k] as String).trim(), isNotEmpty, reason: k);
      }
    }
  });

  test('placeholders match between languages', () {
    final pattern = RegExp(r'\{(\w+)[},]');
    for (final k in keys(en)) {
      final a = pattern.allMatches(en[k] as String).map((m) => m[1]).toSet();
      final b = pattern.allMatches(tr[k] as String).map((m) => m[1]).toSet();
      // A plural selector may skip the count in its branches.
      a.remove('count');
      b.remove('count');
      expect(b, a, reason: k);
    }
  });

  test('only Turkish and English ship', () {
    final files = Directory('lib/l10n')
        .listSync()
        .map((e) => e.uri.pathSegments.last)
        .where((n) => n.endsWith('.arb'))
        .toSet();
    expect(files, {'app_en.arb', 'app_tr.arb'});
  });

  test('every currency has a name in both languages', () {
    for (final m in [en, tr]) {
      final message = m['currencyName'] as String;
      for (final c in Currency.all) {
        expect(message, contains('${c.code}{'), reason: c.code);
      }
    }
  });

  test('tone rules: no exclamation marks or emoji', () {
    final emoji = RegExp(
      r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]',
      unicode: true,
    );
    for (final m in [en, tr]) {
      for (final k in keys(m)) {
        final v = m[k] as String;
        expect(v.contains('!'), isFalse, reason: k);
        expect(emoji.hasMatch(v), isFalse, reason: k);
      }
    }
  });
}
