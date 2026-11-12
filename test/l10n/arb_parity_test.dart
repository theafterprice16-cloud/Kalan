import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/app/app.dart';
import 'package:kalan/core/money/currency.dart';

Map<String, dynamic> _load(String lang) =>
    jsonDecode(File('lib/l10n/app_$lang.arb').readAsStringSync())
        as Map<String, dynamic>;

Set<String> _keys(Map<String, dynamic> m) =>
    m.keys.where((k) => !k.startsWith('@')).toSet();

void main() {
  final en = _load('en');

  test('there is one ARB file per app language', () {
    final files = Directory('lib/l10n')
        .listSync()
        .map((e) => e.path.split('/').last)
        .where((n) => n.endsWith('.arb'))
        .map((n) => n.substring(4, n.length - 4))
        .toSet();
    expect(files, appLanguageCodes.toSet());
  });

  for (final lang in appLanguageCodes) {
    group(lang, () {
      final arb = _load(lang);

      test('has exactly the English keys', () {
        expect(_keys(arb).difference(_keys(en)), isEmpty);
        expect(_keys(en).difference(_keys(arb)), isEmpty);
      });

      test('no message is empty', () {
        for (final k in _keys(arb)) {
          expect((arb[k] as String).trim(), isNotEmpty, reason: k);
        }
      });

      test('keeps every placeholder', () {
        for (final k in _keys(en)) {
          final meta = en['@$k'] as Map<String, dynamic>?;
          final names =
              (meta?['placeholders'] as Map<String, dynamic>?)?.keys ??
              const <String>[];
          for (final name in names) {
            expect(arb[k] as String, contains('{$name'), reason: '$k.$name');
          }
        }
      });

      test('names every currency', () {
        final message = arb['currencyName'] as String;
        for (final c in Currency.all) {
          expect(message, contains('${c.code}{'), reason: c.code);
        }
      });

      test('tone rules: no exclamation marks or emoji', () {
        final emoji = RegExp(
          r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]',
          unicode: true,
        );
        for (final k in _keys(arb)) {
          final v = arb[k] as String;
          expect(v.contains('!'), isFalse, reason: '$lang.$k');
          expect(v.contains('¡'), isFalse, reason: '$lang.$k');
          expect(emoji.hasMatch(v), isFalse, reason: '$lang.$k');
        }
      });
    });
  }
}
