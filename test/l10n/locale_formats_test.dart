// Dates and numbers of the 22 locales (Roadmap 24, decision 12): intl's
// own data, through the app's date helpers and the one money path;
// Western digits everywhere, Arabic included (product owner's decision).
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:kalan/app/format.dart';
import 'package:kalan/app/locale.dart';
import 'package:kalan/core/date/local_date.dart';
import 'package:kalan/core/money/currency.dart';
import 'package:kalan/core/money/money_format.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump.dart';

final easternDigits = RegExp('[٠-٩۰-۹]');
final notWestern = RegExp(r'\p{Nd}', unicode: true);

/// Digits that are not 0-9.
bool hasOtherDigits(String s) =>
    s.split('').any((c) => notWestern.hasMatch(c) && !'0123456789'.contains(c));

/// Thursday 12 November 2026.
final day = LocalDate(2026, 11, 12);

/// The app's date helpers in [locale], read from a built widget.
Future<Map<String, String>> datesIn(WidgetTester tester, Locale locale) async {
  late Map<String, String> out;
  await pumpLocalized(
    tester,
    Builder(
      builder: (context) {
        out = {
          'locale': context.localeName,
          'long': context.longDate(day),
          'short': context.shortDate(day),
          'weekday': context.shortWeekdayName(day),
          'full': context.dayMonthWeekday(day),
          'month': context.monthYear(2026, 11),
        };
        return const SizedBox();
      },
    ),
    locale: locale,
  );
  return out;
}

void main() {
  setUpAll(loadLocaleData);

  test('intl has date data for every locale', () {
    for (final l in appLocales) {
      expect(DateFormat.localeExists(l.intlLocale), isTrue, reason: l.code);
      expect(NumberFormat.localeExists(l.intlLocale), isTrue, reason: l.code);
    }
  });

  test('every locale writes dates and amounts with 0-9', () {
    final eur = Currency.fromCode('EUR');
    for (final l in appLocales) {
      final date = DateFormat.yMMMMEEEEd(l.intlLocale).format(day.toDateTime());
      final money = formatMoney(123456, eur, localeName: l.intlLocale);
      expect(hasOtherDigits(date), isFalse, reason: '${l.code}: $date');
      expect(hasOtherDigits(money), isFalse, reason: '${l.code}: $money');
      expect(money.replaceAll(RegExp('[^0-9]'), ''), '123456', reason: l.code);
    }
  });

  testWidgets('Japanese dates', (tester) async {
    final d = await datesIn(tester, const Locale('ja'));
    expect(d['locale'], 'ja');
    expect(d['long'], DateFormat.yMMMd('ja').format(day.toDateTime()));
    expect(d['long'], '2026年11月12日');
    expect(d['full'], '11月12日木曜日');
    expect(d['month'], '2026年11月');
    expect(d['weekday'], '木');
  });

  testWidgets('Chinese dates: Simplified and Traditional', (tester) async {
    final hans = await datesIn(tester, const Locale('zh'));
    expect(hans['locale'], 'zh');
    expect(hans['long'], '2026年11月12日');
    expect(hans['weekday'], '周四');

    final hant = await datesIn(
      tester,
      const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
    );
    // Traditional reads Taiwan's data (intl has no zh_Hant).
    expect(hant['locale'], 'zh_TW');
    expect(hant['long'], '2026年11月12日');
    expect(hant['weekday'], '週四');
  });

  testWidgets('Arabic dates: Arabic month names, digits 0-9', (tester) async {
    final d = await datesIn(tester, const Locale('ar'));
    expect(d['locale'], 'ar');
    for (final text in d.values) {
      expect(easternDigits.hasMatch(text), isFalse, reason: text);
    }
    expect(d['long'], contains('نوفمبر'));
    expect(d['long'], contains('12'));
    expect(d['long'], contains('2026'));
    expect(d['month'], contains('2026'));
  });

  // Example 4: 1.234,56 EGP in Arabic is written with 0-9.
  test('Arabic amounts: 0-9, the digits in order', () {
    final egp = Currency.fromCode('EGP');
    final text = formatMoney(123456, egp, localeName: intlLocaleOf('ar'));
    expect(easternDigits.hasMatch(text), isFalse, reason: text);
    expect(text, contains('1,234.56'));
    expect(text.contains('٫') || text.contains('٬'), isFalse);
    // The same through the short form under the bars.
    final short = formatMoneyShort(
      123456789,
      egp,
      localeName: intlLocaleOf('ar'),
    );
    expect(easternDigits.hasMatch(short), isFalse, reason: short);
  });

  test('Japanese yen: no minor digits', () {
    final jpy = Currency.fromCode('JPY');
    final text = formatMoney(1250, jpy, localeName: 'ja');
    expect(text, contains('1,250'));
    expect(text, isNot(contains('.')));
  });

  test('every locale separates with one character (the cursor stays)', () {
    for (final l in appLocales) {
      final symbols = NumberFormat.decimalPattern(l.intlLocale).symbols;
      expect(symbols.DECIMAL_SEP, hasLength(1), reason: l.code);
      expect(symbols.GROUP_SEP, hasLength(1), reason: l.code);
      expect(
        westernDigits('١٢٣٤٫٥٦', localeName: l.intlLocale),
        hasLength(7),
        reason: l.code,
      );
    }
  });

  test('an Arabic keyboard types amounts too', () {
    final egp = Currency.fromCode('EGP');
    final tr = Currency.fromCode('TRY');
    expect(parseAmount('١٢٣٤٫٥٦', egp, localeName: 'ar'), 123456);
    expect(parseAmount('١٬٢٣٤٫٥٦', egp, localeName: 'ar'), 123456);
    expect(parseAmount('۱۲۵۰', egp, localeName: 'ar'), 125000);
    // In Turkish the Arabic decimal sign is the comma.
    expect(parseAmount('١٢٫٥', tr, localeName: 'tr'), 1250);
    expect(acceptsAmountInput('٤٥٫٥', tr, localeName: 'tr'), isTrue);
    expect(acceptsAmountInput('٤٥٫٥٥٥', tr, localeName: 'tr'), isFalse);
    // Same length, so the cursor stays where it was.
    expect(westernDigits('١٢٣٤٫٥٦', localeName: 'ar'), '1234.56');
    expect(westernDigits('٤٥٫٥', localeName: 'tr'), '45,5');
    expect(westernDigits('12,5', localeName: 'tr'), '12,5');
  });

  testWidgets('the amount field shows typed Arabic digits as 0-9', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await pumpLocalized(
      tester,
      TextField(
        controller: controller,
        inputFormatters: amountInputFormatters(
          Currency.fromCode('TRY'),
          localeName: 'tr',
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), '١٢٣٫٤٥');
    expect(controller.text, '123,45');
  });
}
