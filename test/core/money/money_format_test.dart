import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:kalan/core/money/currency.dart';
import 'package:kalan/core/money/money_format.dart';

Currency c(String code) => Currency.byCode(code)!;

/// The product table: code, symbol, distinctive symbol, digits in daily
/// use (which Kalan stores, shows and accepts).
const table = <(String, String, String, int)>[
  ('TRY', '₺', '₺', 2),
  ('USD', r'$', r'US$', 2),
  ('EUR', '€', '€', 2),
  ('GBP', '£', '£', 2),
  ('BRL', r'R$', r'R$', 2),
  ('MXN', r'$', r'MX$', 2),
  ('COP', r'$', r'COL$', 0),
  ('CLP', r'$', r'CLP$', 0),
  ('RUB', '₽', '₽', 2),
  ('KZT', '₸', '₸', 2),
  ('CNY', '¥', 'CN¥', 2),
  ('SGD', r'$', r'S$', 2),
  ('MYR', 'RM', 'RM', 2),
  ('IDR', 'Rp', 'Rp', 0),
  ('CAD', r'$', r'CA$', 2),
  ('AUD', r'$', r'A$', 2),
  ('CHF', 'CHF', 'CHF', 2),
  ('NZD', r'$', r'NZ$', 2),
  ('ZAR', 'R', 'R', 2),
  ('ARS', r'$', r'AR$', 2),
  ('PEN', 'S/', 'S/', 2),
  ('UYU', r'$', r'$U', 2),
  ('PYG', '₲', '₲', 0),
  ('BOB', 'Bs', 'Bs', 2),
  ('VES', 'Bs.', 'Bs.S', 2),
  ('CRC', '₡', '₡', 0),
  ('GTQ', 'Q', 'Q', 2),
  ('HNL', 'L', 'L', 2),
  ('NIO', r'C$', r'C$', 2),
  ('DOP', r'$', r'RD$', 2),
  ('PAB', 'B/.', 'B/.', 2),
  ('AOA', 'Kz', 'Kz', 2),
  ('MZN', 'MT', 'MT', 2),
  ('XOF', 'CFA', 'F CFA', 0),
  ('XAF', 'FCFA', 'FCFA', 0),
  ('BYN', 'Br', 'Br', 2),
  ('KGS', 'с', 'сом', 2),
  ('UZS', 'soʻm', 'soʻm', 0),
  ('TWD', r'$', r'NT$', 0),
  ('HKD', r'$', r'HK$', 2),
  ('MOP', r'MOP$', r'MOP$', 2),
  ('SAR', 'ر.س', 'SAR', 2),
  ('AED', 'د.إ', 'AED', 2),
  ('QAR', 'ر.ق', 'QAR', 2),
  ('KWD', 'د.ك', 'KWD', 3),
  ('BHD', 'د.ب', 'BHD', 3),
  ('OMR', 'ر.ع.', 'OMR', 3),
  ('EGP', 'ج.م', 'E£', 2),
  ('JOD', 'د.أ', 'JOD', 3),
  ('IQD', 'د.ع', 'IQD', 0),
  ('MAD', 'د.م.', 'DH', 2),
  ('DZD', 'د.ج', 'DA', 2),
  ('TND', 'د.ت', 'DT', 3),
  ('LBP', 'ل.ل', 'LL', 0),
  ('LYD', 'د.ل', 'LD', 3),
  ('INR', '₹', '₹', 2),
  ('PKR', 'Rs', 'PKR', 0),
  ('NGN', '₦', '₦', 2),
  ('PHP', '₱', '₱', 2),
  ('KES', 'KSh', 'KSh', 2),
  ('CDF', 'FC', 'FC', 2),
  ('GNF', 'FG', 'FG', 0),
  ('HTG', 'G', 'G', 2),
  ('MGA', 'Ar', 'Ar', 0),
  ('SRD', r'$', r'Sr$', 2),
  ('TJS', 'SM', 'SM', 2),
  ('SDG', 'ج.س.', 'SDG', 2),
  ('YER', 'ر.ي.', 'YER', 0),
  ('SYP', 'ل.س', 'SYP', 0),
  ('MRU', 'UM', 'UM', 2),
  ('ILS', '₪', '₪', 2),
  ('PLN', 'zł', 'zł', 2),
  ('SEK', 'kr', 'kr', 2),
  ('JPY', '¥', 'JP¥', 0),
  ('VND', '₫', '₫', 0),
];

/// What intl makes of [minor] in [lang]: the expected text is generated,
/// not written by hand. Whole amounts drop their minor digits.
String intlText(int minor, Currency cur, String lang) {
  final whole = minor % cur.minorPerMajor == 0;
  return NumberFormat.currency(
    locale: lang,
    name: cur.code,
    symbol: isolateRtl(cur.symbol),
    decimalDigits: whole ? 0 : cur.decimals,
  ).format(minor / cur.minorPerMajor);
}

void main() {
  group('registry', () {
    test('has the 75 currencies of the table, each once', () {
      final codes = Currency.all.map((c) => c.code).toList();
      expect(codes, table.map((e) => e.$1));
      expect(codes.toSet(), hasLength(75));
    });

    for (final (code, symbol, distinctive, decimals) in table) {
      test('$code: $symbol, $distinctive, $decimals digits', () {
        final cur = c(code);
        expect(cur.symbol, symbol);
        expect(cur.distinctiveSymbol, distinctive);
        expect(cur.decimals, decimals);
        expect(cur.minorPerMajor, [1, 10, 100, 1000][decimals]);
        expect(cur.locales, isNotEmpty);
        expect(Currency.fromCode(code), cur);
        expect(Currency.fromCode(code.toLowerCase()), cur);
      });
    }

    test('the 17 earlier currencies keep their stored scale', () {
      // Stored amounts are minor units at these digits (schema v1 and v2).
      // They are unchanged, so no data migration is needed.
      const before = {
        'TRY': 2, 'USD': 2, 'EUR': 2, 'GBP': 2, 'BRL': 2, 'MXN': 2, //
        'COP': 0, 'CLP': 0, 'RUB': 2, 'KZT': 2, 'CNY': 2, 'SGD': 2,
        'MYR': 2, 'IDR': 0, 'CAD': 2, 'AUD': 2, 'CHF': 2,
      };
      for (final MapEntry(:key, :value) in before.entries) {
        expect(c(key).decimals, value, reason: key);
      }
    });

    test('digits are 0, 2 or 3 only', () {
      expect(Currency.all.map((c) => c.decimals).toSet(), {0, 2, 3});
    });

    test('picker label tells shared symbols apart', () {
      expect(c('COP').pickerLabel, r'COL$ · COP');
      expect(c('JPY').pickerLabel, 'JP¥ · JPY');
      expect(c('CNY').pickerLabel, 'CN¥ · CNY');
      expect(c('KWD').pickerLabel, 'KWD');
      expect(c('TRY').pickerLabel, '₺ · TRY');
    });

    test('unknown codes fall back to USD', () {
      expect(Currency.byCode('XYZ'), isNull);
      expect(Currency.fromCode('XYZ').code, 'USD');
    });
  });

  group('default currency by device region', () {
    final cases = <(String?, String)>[
      ('TR', 'TRY'),
      ('US', 'USD'),
      ('DE', 'EUR'),
      ('GB', 'GBP'),
      ('MX', 'MXN'),
      ('PA', 'PAB'),
      ('JP', 'JPY'),
      ('KW', 'KWD'),
      ('SN', 'XOF'),
      ('EC', 'USD'),
      ('AQ', 'USD'),
      (null, 'USD'),
      ('de', 'EUR'),
    ];
    for (final (region, code) in cases) {
      test('$region -> $code', () {
        expect(Currency.forRegion(region).code, code);
      });
    }
  });

  group('suggested currencies', () {
    final cases = <(String?, String, List<String>)>[
      ('MX', 'tr', ['MXN']),
      ('PA', 'en', ['PAB', 'USD']),
      ('PS', 'en', ['JOD', 'ILS']),
      ('TR', 'en', ['TRY']),
      ('AQ', 'tr', ['TRY']), // unknown region: by language
      (null, 'tr', ['TRY']),
      (null, 'en', ['USD']),
    ];
    for (final (region, lang, codes) in cases) {
      test('$region, $lang -> $codes', () {
        expect(
          Currency.suggested(
            region: region,
            languageCode: lang,
          ).map((c) => c.code),
          codes,
        );
      });
    }
  });

  group('formatting comes from intl', () {
    for (final lang in ['tr', 'en']) {
      test('every currency in $lang', () {
        for (final cur in Currency.all) {
          for (final minor in [
            0,
            7,
            1234567,
            cur.minorPerMajor * 4200,
            -1234567,
          ]) {
            expect(
              formatMoney(minor, cur, localeName: lang),
              intlText(minor, cur, lang),
              reason: '${cur.code} $minor',
            );
          }
        }
      });
    }

    test('the product examples (Turkish)', () {
      // Digits are fixed by the currency; the layout is intl's.
      final cases = <(String, int, String)>[
        ('TRY', 1250000, '12.500'),
        ('TRY', 1250050, '12.500,50'),
        ('JPY', 12500, '12.500'),
        ('IDR', 1250000, '1.250.000'),
        ('COP', 350000, '350.000'),
        ('KWD', 12500, '12,500'), // 12 dinars 500 fils
        ('CLP', 45990, '45.990'),
      ];
      for (final (code, minor, digits) in cases) {
        final text = formatMoney(minor, c(code), localeName: 'tr');
        expect(text, intlText(minor, c(code), 'tr'));
        expect(text, contains(digits));
        expect(text, contains(c(code).symbol));
      }
    });

    test('shared symbols show plainly inside the app', () {
      expect(formatMoney(350000, c('COP'), localeName: 'tr'), startsWith(r'$'));
      expect(formatMoney(12500, c('JPY'), localeName: 'en'), startsWith('¥'));
      expect(formatMoney(100, c('SEK'), localeName: 'en'), contains('kr'));
    });

    test('right-to-left symbols stay intact and isolated', () {
      for (final code in ['SAR', 'AED', 'KWD', 'OMR', 'SDG', 'YER', 'SYP']) {
        final cur = c(code);
        final text = formatMoney(1234567, cur, localeName: 'tr');
        expect(text, contains('\u2068${cur.symbol}\u2069'), reason: code);
      }
      expect(isolateRtl(r'$'), r'$');
      expect(isolateRtl('₪'), '₪');
    });

    test('minor digits always fill the currency digits', () {
      expect(formatMoney(5, c('USD'), localeName: 'en'), r'$0.05');
      expect(formatMoney(1005, c('KWD'), localeName: 'en'), endsWith('1.005'));
      expect(formatMoney(1050, c('KWD'), localeName: 'en'), endsWith('1.050'));
      expect(formatMoney(325000, c('TRY'), localeName: 'tr'), '₺3.250');
    });

    test('negative amounts', () {
      expect(formatMoney(-50, c('TRY'), localeName: 'tr'), '-₺0,50');
      expect(formatMoney(-520000, c('TRY'), localeName: 'tr'), '-₺5.200');
      expect(formatMoney(-1234, c('JPY'), localeName: 'tr'), '-¥1.234');
      expect(formatMoney(-12, c('VND'), localeName: 'en'), '-₫12');
      expect(
        formatMoney(-1250500, c('BHD'), localeName: 'en'),
        intlText(-1250500, c('BHD'), 'en'),
      );
      expect(formatMoney(-1, c('OMR'), localeName: 'en'), contains('-'));
      expect(formatMoney(-1, c('OMR'), localeName: 'en'), endsWith('0.001'));
    });

    test('zero-digit currencies never show decimals', () {
      for (final cur in Currency.all.where((c) => c.decimals == 0)) {
        for (final lang in ['tr', 'en']) {
          final text = formatMoney(1234567, cur, localeName: lang);
          expect(text, isNot(matches(RegExp(r'[.,]\d{1,2}(\D|$)'))));
        }
      }
    });

    test('other app languages keep their own layout', () {
      expect(
        formatMoney(123456, c('EUR'), localeName: 'de'),
        '1.234,56\u00a0€',
      );
      expect(
        formatMoney(123456, c('RUB'), localeName: 'ru'),
        '1\u00a0234,56\u00a0₽',
      );
    });
  });

  test('formatted amounts parse back to the same minor units', () {
    for (final cur in Currency.all) {
      for (final lang in ['tr', 'en']) {
        for (final minor in [1, 7, 1234567, cur.minorPerMajor * 42]) {
          final text = formatMoney(minor, cur, localeName: lang);
          expect(
            parseAmount(text, cur, localeName: lang),
            minor,
            reason: '${cur.code} $lang "$text"',
          );
        }
      }
    }
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
      ('1,250.500', 'KWD', 'en', 1250500),
      ('1.250,5', 'KWD', 'tr', 1250500),
      ('1,250.5005', 'KWD', 'en', null), // four digits
      ('12500', 'JPY', 'en', 12500),
      ('12500.5', 'JPY', 'en', null),
      ('12,345.678', 'OMR', 'en', 12345678),
      ('\u2068د.ك\u20691,250.500', 'KWD', 'en', 1250500),
      ('B/.12.50', 'PAB', 'en', 1250),
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
    expect(amountInputExample(c('KWD'), localeName: 'en'), '1250.500');
    expect(amountInputExample(c('JPY'), localeName: 'tr'), '1250');
  });

  group('amount fields accept only what the currency allows', () {
    // text, currency, language, accepted
    final cases = <(String, String, String, bool)>[
      ('12500', 'JPY', 'en', true),
      ('12500.', 'JPY', 'en', false), // no decimal key, no separator
      ('12500,', 'JPY', 'tr', false),
      ('12.500', 'JPY', 'tr', true), // grouping in Turkish
      ('1250.5', 'KWD', 'en', true),
      ('1250.500', 'KWD', 'en', true),
      ('1250.5001', 'KWD', 'en', false),
      ('1250,500', 'KWD', 'tr', true),
      ('1250.50', 'USD', 'en', true),
      ('1250.505', 'USD', 'en', false),
      ('12a', 'USD', 'en', false),
      ('', 'USD', 'en', true),
    ];
    for (final (text, code, lang, ok) in cases) {
      test('"$text" $code $lang -> $ok', () {
        expect(acceptsAmountInput(text, c(code), localeName: lang), ok);
      });
    }
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
