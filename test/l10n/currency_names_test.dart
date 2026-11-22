import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/money/currency.dart';
import 'package:kalan/l10n/app_locales.dart';
import 'package:kalan/l10n/generated/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// Every currency has a Turkish and an English name (not the code).
void main() {
  for (final lang in ['tr', 'en']) {
    test('all 75 currencies are named in $lang', () {
      final l10n = lookupAppLocalizations(Locale(lang));
      final names = <String>{};
      for (final c in Currency.all) {
        final name = l10n.currencyName(c.code);
        expect(name, isNot(c.code), reason: '${c.code} has no $lang name');
        expect(name.trim(), isNotEmpty);
        names.add(name);
      }
      expect(Currency.all, hasLength(75));
      expect(names, hasLength(75), reason: 'names are unique');
    });
  }

  // Roadmap 24: every locale has a file, but only translated ones open.
  test('only Turkish and English are open', () {
    expect(openLocales().map((l) => l.code), ['tr', 'en']);
  });
}
