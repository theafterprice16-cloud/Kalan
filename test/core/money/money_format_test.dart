import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/money/currency.dart';
import 'package:kalan/core/money/money_format.dart';

void main() {
  group('formatMoney', () {
    final cases = <(int, Currency, String, String)>[
      (325000, Currency.lira, 'tr', '3.250 TL'),
      (325050, Currency.lira, 'tr', '3.250,50 TL'),
      (6200, Currency.dollar, 'en', r'$62'),
      (6205, Currency.dollar, 'en', r'$62.05'),
      (123456789, Currency.pound, 'en', '£1,234,567.89'),
      (100, Currency.euro, 'tr', '1 €'),
      (325000, Currency.lira, 'en', '₺3,250'),
      (-40000, Currency.lira, 'tr', '−400 TL'),
      (0, Currency.dollar, 'en', r'$0'),
      (5, Currency.dollar, 'en', r'$0.05'),
    ];
    for (final (minor, currency, locale, expected) in cases) {
      test('$minor ${currency.code} $locale -> $expected', () {
        expect(formatMoney(minor, currency, locale), expected);
      });
    }
  });

  group('parseMinorUnits', () {
    final cases = <(String, int?)>[
      ('3250', 325000),
      ('3.250', 325000),
      ('3,250', 325000),
      ('3.250,50', 325050),
      ('3,250.50', 325050),
      ('62.5', 6250),
      ('62,05', 6205),
      ('0,99', 99),
      (',5', 50),
      ('1 250 TL', 125000),
      (r'$62', 6200),
      ('12,', 1200),
      ('1,2345', null),
      ('abc', null),
      ('', null),
      ('-5', null),
      ('1234567890123', null),
    ];
    for (final (input, expected) in cases) {
      test('"$input" -> $expected', () {
        expect(parseMinorUnits(input), expected);
      });
    }
  });

  test('input format round-trips', () {
    for (final minor in [0, 5, 100, 325050, 99999999]) {
      for (final locale in ['tr', 'en']) {
        expect(parseMinorUnits(formatMinorForInput(minor, locale)), minor);
      }
    }
  });

  test('currency codes round-trip', () {
    for (final c in Currency.values) {
      expect(Currency.fromCode(c.code), c);
    }
  });
}
