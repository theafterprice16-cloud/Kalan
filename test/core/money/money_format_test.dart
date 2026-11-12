import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/money/currency.dart';
import 'package:kalan/core/money/money_format.dart';

Currency c(String code) => Currency.byCode(code)!;

void main() {
  group('registry', () {
    // code, symbol, distinctive symbol, decimals
    final expected = <(String, String, String, int)>[
      ('TRY', '₺', '₺', 2),
      ('USD', r'$', r'$', 2),
      ('EUR', '€', '€', 2),
      ('GBP', '£', '£', 2),
      ('BRL', r'R$', r'R$', 2),
      ('MXN', r'$', r'MX$', 2),
      ('COP', r'$', r'COL$', 0),
      ('CLP', r'$', r'CLP$', 0),
      ('RUB', '₽', '₽', 2),
      ('KZT', '₸', '₸', 2),
      ('CNY', '¥', '¥', 2),
      ('SGD', r'$', r'S$', 2),
      ('MYR', 'RM', 'RM', 2),
      ('IDR', 'Rp', 'Rp', 0),
      ('CAD', r'$', r'CA$', 2),
      ('AUD', r'$', r'A$', 2),
      ('CHF', 'CHF', 'CHF', 2),
    ];

    test('has exactly the 17 supported currencies', () {
      expect(Currency.all.map((c) => c.code), expected.map((e) => e.$1));
    });

    for (final (code, symbol, distinctive, decimals) in expected) {
      test(code, () {
        final cur = c(code);
        expect(cur.symbol, symbol);
        expect(cur.distinctiveSymbol, distinctive);
        expect(cur.decimals, decimals);
        expect(Currency.fromCode(code), cur);
        expect(Currency.fromCode(code.toLowerCase()), cur);
      });
    }

    test('unknown codes fall back to USD', () {
      expect(Currency.byCode('XYZ'), isNull);
      expect(Currency.fromCode('XYZ').code, 'USD');
    });
  });

  group('suggested currency by device region', () {
    final cases = <(String?, String)>[
      ('TR', 'TRY'),
      ('US', 'USD'),
      ('DE', 'EUR'),
      ('FR', 'EUR'),
      ('ES', 'EUR'),
      ('IT', 'EUR'),
      ('NL', 'EUR'),
      ('GB', 'GBP'),
      ('BR', 'BRL'),
      ('MX', 'MXN'),
      ('CO', 'COP'),
      ('CL', 'CLP'),
      ('RU', 'RUB'),
      ('KZ', 'KZT'),
      ('CN', 'CNY'),
      ('SG', 'SGD'),
      ('MY', 'MYR'),
      ('ID', 'IDR'),
      ('CA', 'CAD'),
      ('AU', 'AUD'),
      ('CH', 'CHF'),
      ('JP', 'USD'),
      ('AR', 'USD'),
      (null, 'USD'),
      ('de', 'EUR'),
    ];
    for (final (region, code) in cases) {
      test('$region -> $code', () {
        expect(Currency.forRegion(region).code, code);
      });
    }
  });

  group('dollar sign is plain only at home', () {
    final cases = <(String, String?, String)>[
      ('MXN', 'MX', r'$'),
      ('MXN', 'US', r'MX$'),
      ('MXN', null, r'MX$'),
      ('COP', 'CO', r'$'),
      ('COP', 'MX', r'COL$'),
      ('CLP', 'CL', r'$'),
      ('CLP', 'US', r'CLP$'),
      ('CAD', 'CA', r'$'),
      ('CAD', 'US', r'CA$'),
      ('AUD', 'AU', r'$'),
      ('AUD', 'GB', r'A$'),
      ('SGD', 'SG', r'$'),
      ('SGD', 'MY', r'S$'),
      ('USD', 'MX', r'$'),
      ('TRY', 'US', '₺'),
    ];
    for (final (code, region, symbol) in cases) {
      test('$code in $region -> $symbol', () {
        expect(c(code).symbolFor(region), symbol);
      });
    }
  });

  group('every currency formats (English, no region)', () {
    final cases = <(String, int, String)>[
      ('TRY', 123456, '₺1,234.56'),
      ('USD', 123456, r'$1,234.56'),
      ('EUR', 123456, '€1,234.56'),
      ('GBP', 123456, '£1,234.56'),
      ('BRL', 123456, r'R$1,234.56'),
      ('MXN', 123456, r'MX$1,234.56'),
      ('COP', 1234567, r'COL$1,234,567'),
      ('CLP', 1234567, r'CLP$1,234,567'),
      ('RUB', 123456, '₽1,234.56'),
      ('KZT', 123456, '₸1,234.56'),
      ('CNY', 123456, '¥1,234.56'),
      ('SGD', 123456, r'S$1,234.56'),
      ('MYR', 123456, 'RM1,234.56'),
      ('IDR', 1234567, 'Rp1,234,567'),
      ('CAD', 123456, r'CA$1,234.56'),
      ('AUD', 123456, r'A$1,234.56'),
      ('CHF', 123456, 'CHF1,234.56'),
    ];
    for (final (code, minor, text) in cases) {
      test('$code $minor -> $text', () {
        expect(formatMoney(minor, c(code), localeName: 'en'), text);
      });
    }
  });

  group('every app language formats', () {
    // language, currency, region, minor, expected (intl output)
    final cases = <(String, String, String?, int, String)>[
      ('tr', 'TRY', 'TR', 123456, '₺1.234,56'),
      ('en', 'USD', 'US', 123456, r'$1,234.56'),
      ('es', 'EUR', 'ES', 123456, '1.234,56\u00a0€'),
      ('es', 'MXN', 'MX', 123456, '1.234,56\u00a0\$'),
      ('fr', 'EUR', 'FR', 123456, '1\u202f234,56\u00a0€'),
      ('de', 'EUR', 'DE', 123456, '1.234,56\u00a0€'),
      ('pt', 'BRL', 'BR', 123456, 'R\$\u00a01.234,56'),
      ('ru', 'RUB', 'RU', 123456, '1\u00a0234,56\u00a0₽'),
      ('zh', 'CNY', 'CN', 123456, '¥1,234.56'),
      ('it', 'EUR', 'IT', 123456, '1.234,56\u00a0€'),
      ('id', 'IDR', 'ID', 1234567, 'Rp1.234.567'),
      ('en', 'MXN', 'US', 123456, r'MX$1,234.56'),
    ];
    for (final (lang, code, region, minor, text) in cases) {
      test('$lang $code $region -> $text', () {
        expect(
          formatMoney(minor, c(code), localeName: lang, region: region),
          text,
        );
      });
    }
  });

  group('minor digits', () {
    test('whole amounts drop their decimals', () {
      expect(formatMoney(325000, c('TRY'), localeName: 'tr'), '₺3.250');
      expect(formatMoney(100, c('EUR'), localeName: 'de'), '1\u00a0€');
    });
    test('small and negative amounts', () {
      expect(formatMoney(5, c('USD'), localeName: 'en'), r'$0.05');
      expect(formatMoney(-50, c('TRY'), localeName: 'tr'), '-₺0,50');
      expect(formatMoney(-520000, c('TRY'), localeName: 'tr'), '-₺5.200');
      expect(
        formatMoney(-123456, c('EUR'), localeName: 'de'),
        '-1.234,56\u00a0€',
      );
      expect(formatMoney(0, c('USD'), localeName: 'en'), r'$0');
    });
    test('zero-decimal currencies never show decimals', () {
      for (final code in ['IDR', 'COP', 'CLP']) {
        for (final lang in ['en', 'id', 'es', 'de']) {
          final text = formatMoney(1234567, c(code), localeName: lang);
          expect(text, isNot(matches(RegExp(r'[.,]\d{1,2}(\D|$)'))));
        }
      }
    });
  });

  group('parseAmount follows the app language', () {
    // input, currency, language, expected minor (null = rejected)
    final cases = <(String, String, String, int?)>[
      ('3250', 'TRY', 'tr', 325000),
      ('3.250', 'TRY', 'tr', 325000),
      ('3.250,50', 'TRY', 'tr', 325050),
      ('1250,5', 'TRY', 'tr', 125050),
      ('62.5', 'TRY', 'tr', null), // "." is grouping in Turkish
      ('3,250.50', 'USD', 'en', 325050),
      ('62.05', 'USD', 'en', 6205),
      ('62,05', 'USD', 'en', null), // "," is grouping in English
      ('1,234,567', 'USD', 'en', 123456700),
      ('1 234,56', 'EUR', 'fr', 123456),
      ('1\u202f234,56', 'EUR', 'fr', 123456),
      ('1\u00a0234,56', 'RUB', 'ru', 123456),
      ('1.234,56', 'EUR', 'de', 123456),
      ('R\$ 1.234,56', 'BRL', 'pt', 123456),
      ('1,234.56', 'CNY', 'zh', 123456),
      ('1.234.567', 'IDR', 'id', 1234567),
      ('1234567', 'IDR', 'id', 1234567),
      ('1234,5', 'IDR', 'id', null), // no minor digits
      ('1.234,56', 'COP', 'es', null),
      ('25000', 'CLP', 'es', 25000),
      ('1,234', 'USD', 'en', 123400),
      ('12,345.678', 'USD', 'en', null), // three decimals
      ('1.23.456', 'TRY', 'tr', null), // bad grouping
      ('abc', 'USD', 'en', null),
      ('', 'USD', 'en', null),
      ('-5', 'USD', 'en', null),
      ('12345678901234', 'USD', 'en', null),
    ];
    for (final (input, code, lang, minor) in cases) {
      test('"$input" $code $lang -> $minor', () {
        expect(parseAmount(input, c(code), localeName: lang), minor);
      });
    }
  });

  test('input text round-trips for every currency and language', () {
    for (final cur in Currency.all) {
      for (final lang in [
        'tr', 'en', 'es', 'fr', 'de', 'pt', 'ru', 'zh', 'it', 'id', //
      ]) {
        for (final minor in [1, 5, 1234567, cur.minorPerMajor * 42]) {
          final text = formatMinorForInput(minor, cur, localeName: lang);
          expect(parseAmount(text, cur, localeName: lang), minor);
        }
      }
    }
  });

  test('input examples match the currency', () {
    expect(amountInputExample(c('TRY'), localeName: 'tr'), '1250,50');
    expect(amountInputExample(c('USD'), localeName: 'en'), '1250.50');
    expect(amountInputExample(c('IDR'), localeName: 'id'), '1250');
  });

  group('scaleMinor', () {
    final cases = <(int, int, int, int)>[
      // value, from, to, expected
      (123456, 2, 0, 1235), // ₺1.234,56 -> Rp1.235
      (123449, 2, 0, 1234),
      (123450, 2, 0, 1235), // half rounds up
      (50, 2, 0, 1),
      (49, 2, 0, 0),
      (1235, 0, 2, 123500),
      (0, 0, 2, 0),
      (777, 2, 2, 777),
    ];
    for (final (value, from, to, expected) in cases) {
      test('$value ($from) -> $expected ($to)', () {
        expect(scaleMinor(value, fromDecimals: from, toDecimals: to), expected);
      });
    }
    test('rejects negative values', () {
      expect(
        () => scaleMinor(-1, fromDecimals: 2, toDecimals: 0),
        throwsArgumentError,
      );
    });
  });
}
