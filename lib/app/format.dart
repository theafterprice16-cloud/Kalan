import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../core/date/local_date.dart';
import '../core/money/currency.dart';
import '../core/money/money_format.dart';
import '../data/models.dart';
import '../features/privacy/amounts_hidden.dart';
import '../l10n/app_locales.dart';
import '../l10n/generated/app_localizations.dart';
import 'providers.dart';

/// "Pay later · Dec 14": the name of a "Pay later" plan saved without
/// one, from its due date, in [l10n]'s language (it follows a language
/// change; nothing is stored).
String payLaterAutoName(AppLocalizations l10n, LocalDate due) =>
    l10n.payLaterAutoName(
      DateFormat.MMMd(intlLocaleOf(l10n.localeName)).format(due.toDateTime()),
    );

/// A plan's name in [l10n]'s language: its own name, or the automatic one.
String planNameIn(AppLocalizations l10n, PlanWithPayments plan) =>
    plan.ownName ?? payLaterAutoName(l10n, plan.allPayments.first.date);

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  /// A plan's name, or "Pay later · Dec 14" for an untitled one.
  String planName(PlanWithPayments plan) => planNameIn(l10n, plan);

  /// The intl locale for dates and numbers: the app language's
  /// ([intlLocaleOf]; zh_Hant reads zh_TW's data).
  String get localeName => intlLocaleOf(AppLocalizations.of(this).localeName);

  /// "14 Kas" / "Nov 14".
  String shortDate(LocalDate date) =>
      DateFormat.MMMd(localeName).format(date.toDateTime());

  /// "14 Kas 2026" / "Nov 14, 2026".
  String longDate(LocalDate date) =>
      DateFormat.yMMMd(localeName).format(date.toDateTime());

  /// "28 Ekim" / "October 28".
  String dayMonth(LocalDate date) =>
      DateFormat.MMMMd(localeName).format(date.toDateTime());

  /// A short span of days: "17–21 Ara" / "Dec 17–21" in one month,
  /// "29 Ara – 2 Oca" / "Dec 29 – Jan 2" across months, "17 Ara" for one
  /// day.
  String dayRange(LocalDate first, LocalDate last) {
    if (first == last) return shortDate(first);
    if (first.year == last.year && first.month == last.month) {
      final day = DateFormat.d(localeName);
      return l10n.busyWeekRangeSameMonth(
        DateFormat.MMM(localeName).format(first.toDateTime()),
        day.format(first.toDateTime()),
        day.format(last.toDateTime()),
      );
    }
    return l10n.periodRange(shortDate(first), shortDate(last));
  }

  /// "Ağustos 2027" / "August 2027".
  String monthYear(int year, int month) =>
      DateFormat.yMMMM(localeName).format(DateTime(year, month));

  /// "Kas 2026" / "Nov 2026", kept on one line (no-break space).
  String shortMonthYear(LocalDate date) =>
      DateFormat.yMMM(localeName)
          .format(date.toDateTime())
          .replaceAll(' ', '\u00A0');

  /// "14 Kasım Cumartesi" / "Saturday, November 14".
  String dayMonthWeekday(LocalDate date) =>
      DateFormat.MMMMEEEEd(localeName).format(date.toDateTime());

  /// "Cum" / "Fri".
  String shortWeekdayName(LocalDate date) =>
      DateFormat.E(localeName).format(date.toDateTime());

  /// "Cuma" / "Friday".
  String weekdayName(LocalDate date) =>
      DateFormat.EEEE(localeName).format(date.toDateTime());

  /// What a screen reader says for [text] while amounts are hidden (28):
  /// each masked amount as "Amount hidden", never the dots. Null when
  /// [text] has no masked amount, so the text reads as itself (and an
  /// app with amounts shown is exactly as before). For a `Text`'s or an
  /// `AmountText`'s `semanticsLabel`.
  String? spoken(String text) =>
      text.contains(amountMask) &&
          // A name the user typed with dots is never "hidden" while
          // amounts show.
          ProviderScope.containerOf(
            this,
            listen: false,
          ).read(amountsHiddenProvider)
      ? text.replaceAll(amountMask, l10n.amountHidden)
      : null;

  /// [spoken], or [text] itself: for labels that must be set.
  String spokenLabel(String text) => spoken(text) ?? text;

  /// A plain [Text] of [text] whose hidden amounts (28) a screen reader
  /// says as "Amount hidden"; exactly `Text(text)` while amounts show.
  Text spokenText(
    String text, {
    Key? key,
    TextStyle? style,
    TextAlign? textAlign,
  }) => Text(
    text,
    key: key,
    style: style,
    textAlign: textAlign,
    semanticsLabel: spoken(text),
  );
}

/// Every screen formats, parses and edits amounts through these helpers,
/// which all go through lib/core/money with the current currency.
///
/// "Hide amounts" (Roadmap 28) is applied here and nowhere else: while it
/// is on, [money] and [moneyShort] give [amountMask] for every amount
/// (no symbol, no sign, always the same length). Only the flow where the
/// user types or edits an amount uses [draftMoney]
/// (test/app/money_path_test.dart keeps that list).
extension MoneyRefX on WidgetRef {
  Currency get currency => watch(currencyProvider);

  /// Whether amounts on screen are masked; follows the switch.
  bool get amountsHidden => watch(amountsHiddenProvider);

  /// Formats minor units in the user's currency and the app's language;
  /// [amountMask] while amounts are hidden.
  String money(BuildContext context, int minor) => amountsHidden
      ? amountMask
      : formatMoney(minor, currency, localeName: context.localeName);

  /// A short amount for narrow labels (12,4 B); see [formatMoneyShort].
  /// [amountMask] while amounts are hidden.
  String moneyShort(BuildContext context, int minor) => amountsHidden
      ? amountMask
      : formatMoneyShort(minor, currency, localeName: context.localeName);

  /// An amount in the flow where the user is typing or editing one right
  /// now (the form and its draft preview): never masked, the user needs
  /// to see what they enter. Anywhere else: [money].
  String draftMoney(BuildContext context, int minor) =>
      formatMoney(minor, currency, localeName: context.localeName);

  /// Parses typed text; null when invalid.
  int? parseMoney(BuildContext context, String text) =>
      parseAmount(text, currency, localeName: context.localeName);

  /// The largest amount an amount field takes, in minor units.
  int get maxAmountMinor => maxTypedAmountMinor(currency);

  /// Text to prefill an amount field with.
  String moneyInput(BuildContext context, int minor) =>
      formatMinorForInput(minor, currency, localeName: context.localeName);

  /// Validation message with an example in the current currency.
  /// With the typed [text], a well-formed amount that is only too long
  /// gets "too large" instead.
  String amountError(BuildContext context, [String? text]) =>
      text != null &&
          amountTooLarge(text, currency, localeName: context.localeName)
      ? context.l10n.errorAmountTooLarge
      : context.l10n.errorAmountInvalid(
          amountInputExample(currency, localeName: context.localeName),
        );

  /// No decimal key for currencies without minor digits.
  TextInputType get amountKeyboard =>
      TextInputType.numberWithOptions(decimal: currency.decimals > 0);

  /// Keeps amount fields to what the current currency allows.
  List<TextInputFormatter> amountFormatters(BuildContext context) =>
      amountInputFormatters(currency, localeName: context.localeName);
}

/// No separator for zero-digit currencies (JPY), at most three minor
/// digits for KWD and two for TRY; see [acceptsAmountInput].
List<TextInputFormatter> amountInputFormatters(
  Currency currency, {
  required String localeName,
}) => [
  TextInputFormatter.withFunction((oldValue, newValue) {
    // An Arabic keyboard's ٤ shows as 4 (Western digits everywhere).
    final text = westernDigits(newValue.text, localeName: localeName);
    final value = text == newValue.text
        ? newValue
        : text.length == newValue.text.length
        ? newValue.copyWith(text: text)
        : TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: text.length),
          );
    return acceptsAmountInput(text, currency, localeName: localeName)
        ? value
        : oldValue;
  }),
];
