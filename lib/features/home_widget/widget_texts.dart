import 'package:intl/intl.dart';

import '../../core/date/local_date.dart';
import '../../core/money/currency.dart';
import '../../core/money/money_format.dart';
import '../../core/widget/widget_snapshot.dart';
import '../../l10n/app_locales.dart';
import '../../l10n/generated/app_localizations.dart';

/// The widget's text in the app language and the user's currency: dates
/// from intl ("14 Ara", "Dec 14"), amounts from the shared money
/// formatter, sentences from the ARB files. The snapshot builder decides
/// whether an amount is formatted at all (masked: never).
class L10nWidgetTexts implements WidgetTexts {
  L10nWidgetTexts({required this.l10n, required this.currency});

  final AppLocalizations l10n;
  final Currency currency;

  /// Dates and numbers in the app language's intl data (Roadmap 24).
  String get _locale => intlLocaleOf(l10n.localeName);

  @override
  String get leftTitle => l10n.widgetLeft;

  @override
  String get paymentsTitle => l10n.widgetPaymentsThisPeriod;

  @override
  String until(LocalDate lastDay) => l10n.widgetUntil(shortDate(lastDay));

  @override
  String shortDate(LocalDate date) =>
      DateFormat.MMMd(_locale).format(date.toDateTime());

  @override
  String money(int minor) => formatMoney(minor, currency, localeName: _locale);

  @override
  String moneyShort(int minor) =>
      formatMoneyShort(minor, currency, localeName: _locale);

  @override
  String get amountHidden => l10n.amountHidden;

  @override
  String get noPayments => l10n.widgetNoPayments;

  @override
  String get noUpcoming => l10n.widgetNoUpcoming;

  @override
  String get setup => l10n.widgetSetup;

  @override
  String get stale => l10n.widgetStale;

  @override
  String spokenSummary({
    required String title,
    required String amount,
    required String date,
  }) => l10n.widgetSpokenSummary(title, amount, date);

  @override
  String spokenPayment({
    required String name,
    required String date,
    required String amount,
  }) => l10n.widgetSpokenPayment(name, date, amount);

  @override
  bool get rightToLeft => Bidi.isRtlLanguage(_locale);
}
