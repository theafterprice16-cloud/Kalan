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

  test('declared placeholders appear in both languages', () {
    for (final k in keys(en)) {
      final meta = en['@$k'] as Map<String, dynamic>?;
      final names =
          (meta?['placeholders'] as Map<String, dynamic>?)?.keys ??
          const <String>[];
      for (final name in names) {
        expect(en[k] as String, contains('{$name'), reason: 'en.$k.$name');
        expect(tr[k] as String, contains('{$name'), reason: 'tr.$k.$name');
      }
    }
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
