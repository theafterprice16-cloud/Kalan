import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../core/date/local_date.dart';
import '../core/money/currency.dart';
import '../core/money/money_format.dart';
import '../data/models.dart';
import '../l10n/generated/app_localizations.dart';
import 'providers.dart';

/// "Pay later · Dec 14": the name of a "Pay later" plan saved without
/// one, from its due date, in [l10n]'s language (it follows a language
/// change; nothing is stored).
String payLaterAutoName(AppLocalizations l10n, LocalDate due) =>
    l10n.payLaterAutoName(
      DateFormat.MMMd(l10n.localeName).format(due.toDateTime()),
    );

/// A plan's name in [l10n]'s language: its own name, or the automatic one.
String planNameIn(AppLocalizations l10n, PlanWithPayments plan) =>
    plan.ownName ?? payLaterAutoName(l10n, plan.payments.first.date);

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  /// A plan's name, or "Pay later · Dec 14" for an untitled one.
  String planName(PlanWithPayments plan) => planNameIn(l10n, plan);
  String get localeName => AppLocalizations.of(this).localeName;

  /// "14 Kas" / "Nov 14".
  String shortDate(LocalDate date) =>
      DateFormat.MMMd(localeName).format(date.toDateTime());

  /// "14 Kas 2026" / "Nov 14, 2026".
  String longDate(LocalDate date) =>
      DateFormat.yMMMd(localeName).format(date.toDateTime());

  /// "28 Ekim" / "October 28".
  String dayMonth(LocalDate date) =>
      DateFormat.MMMMd(localeName).format(date.toDateTime());

  /// "Ağustos 2027" / "August 2027".
  String monthYear(int year, int month) =>
      DateFormat.yMMMM(localeName).format(DateTime(year, month));

  /// "Cuma" / "Friday".
  String weekdayName(LocalDate date) =>
      DateFormat.EEEE(localeName).format(date.toDateTime());
}

/// Every screen formats, parses and edits amounts through these helpers,
/// which all go through lib/core/money with the current currency.
extension MoneyRefX on WidgetRef {
  Currency get currency => watch(currencyProvider);

  /// Formats minor units in the user's currency and the app's language.
  String money(BuildContext context, int minor) =>
      formatMoney(minor, currency, localeName: context.localeName);

  /// A short amount for narrow labels (12,4 B); see [formatMoneyShort].
  String moneyShort(BuildContext context, int minor) =>
      formatMoneyShort(minor, currency, localeName: context.localeName);

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
  TextInputFormatter.withFunction(
    (oldValue, newValue) =>
        acceptsAmountInput(newValue.text, currency, localeName: localeName)
        ? newValue
        : oldValue,
  ),
];
