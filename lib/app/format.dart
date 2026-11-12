import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../core/date/local_date.dart';
import '../core/money/currency.dart';
import '../core/money/money_format.dart';
import '../l10n/generated/app_localizations.dart';
import 'providers.dart';

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
  String get localeName => AppLocalizations.of(this).localeName;

  /// "14 Kas" / "Nov 14".
  String shortDate(LocalDate date) =>
      DateFormat.MMMd(localeName).format(date.toDateTime());

  /// "14 Kas 2026" / "Nov 14, 2026".
  String longDate(LocalDate date) =>
      DateFormat.yMMMd(localeName).format(date.toDateTime());

  /// "Cuma" / "Friday".
  String weekdayName(LocalDate date) =>
      DateFormat.EEEE(localeName).format(date.toDateTime());
}

/// Every screen formats, parses and edits amounts through these helpers,
/// which all go through lib/core/money with the current currency.
extension MoneyRefX on WidgetRef {
  Currency get currency => watch(currencyProvider);

  /// Formats minor units in the user's currency and the app's language.
  String money(BuildContext context, int minor) => formatMoney(
    minor,
    currency,
    localeName: context.localeName,
    region: watch(deviceRegionProvider),
  );

  /// Parses typed text; null when invalid.
  int? parseMoney(BuildContext context, String text) =>
      parseAmount(text, currency, localeName: context.localeName);

  /// Text to prefill an amount field with.
  String moneyInput(BuildContext context, int minor) =>
      formatMinorForInput(minor, currency, localeName: context.localeName);

  /// Validation message with an example in the current currency.
  String amountError(BuildContext context) => context.l10n.errorAmountInvalid(
    amountInputExample(currency, localeName: context.localeName),
  );

  /// No decimal key for currencies without minor digits.
  TextInputType get amountKeyboard =>
      TextInputType.numberWithOptions(decimal: currency.decimals > 0);
}
