import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../core/date/local_date.dart';
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

extension MoneyRefX on WidgetRef {
  /// Formats minor units in the user's currency and the app's locale.
  String money(BuildContext context, int minor) =>
      formatMoney(minor, watch(currencyProvider), context.localeName);
}
