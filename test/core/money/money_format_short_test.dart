import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:kalan/core/money/currency.dart';
import 'package:kalan/core/money/money_format.dart';

Currency c(String code) => Currency.byCode(code)!;

/// The expected compact text, from intl itself (never typed by hand).
String compact(String locale, Currency currency, int whole) =>
    NumberFormat.compactCurrency(
      locale: locale,
      name: currency.code,
      symbol: isolateRtl(currency.symbol),
    ).format(whole);

void main() {
  group('formatMoneyShort', () {
    test('below 1,000 whole units it is exactly formatMoney', () {
      for (final (code, minor) in [
        ('TRY', 99950),
        ('USD', 12345),
        ('IDR', 999),
        ('JPY', 999),
        ('KWD', 999999),
        ('KWD', 1500),
      ]) {
        for (final locale in ['tr', 'en']) {
          expect(
            formatMoneyShort(minor, c(code), localeName: locale),
            formatMoney(minor, c(code), localeName: locale),
            reason: '$code $minor $locale',
          );
        }
      }
    });

    test('from 1,000 on it is intl compact of the whole units', () {
      // TRY 12.400,00 · USD 1,234,567.89 · IDR 1.250.000 · JPY 8.300 ·
      // KWD 12,400.500 (three digits).
      for (final (code, minor, whole) in [
        ('TRY', 1240000, 12400),
        ('USD', 123456789, 1234567),
        ('IDR', 1250000, 1250000),
        ('JPY', 8300, 8300),
        ('KWD', 12400500, 12400),
      ]) {
        for (final locale in ['tr', 'en']) {
          expect(
            formatMoneyShort(minor, c(code), localeName: locale),
            compact(locale, c(code), whole),
            reason: '$code $minor $locale',
          );
        }
      }
    });

    test('reads as expected in Turkish and English', () {
      // intl puts a no-break space before the Turkish unit.
      expect(
        formatMoneyShort(1240000, c('TRY'), localeName: 'tr'),
        '₺12,4\u00a0B',
      );
      expect(formatMoneyShort(1240000, c('USD'), localeName: 'en'), r'$12.4K');
      expect(formatMoneyShort(120000000, c('IDR'), localeName: 'en'), 'Rp120M');
      // No minor digits ever appear in the compact form.
      expect(
        formatMoneyShort(12345678, c('KWD'), localeName: 'en'),
        isNot(contains('.678')),
      );
    });

    test('keeps the minus sign', () {
      final text = formatMoneyShort(-1240000, c('TRY'), localeName: 'tr');
      expect(text, compact('tr', c('TRY'), -12400));
      expect(text, startsWith('-'));
    });
  });
}
