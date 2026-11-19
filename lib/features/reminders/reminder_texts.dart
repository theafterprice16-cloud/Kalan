import 'package:intl/intl.dart';

import '../../core/date/local_date.dart';
import '../../core/money/currency.dart';
import '../../core/money/money_format.dart';
import '../../core/reminders/reminder_models.dart';
import '../../l10n/generated/app_localizations.dart';

/// Notification text in the app language and the user's currency. Dates
/// come from intl ("14 Kasım Cuma", "Friday, November 14"), amounts from
/// the shared money formatter, sentences from the ARB files.
class L10nReminderTexts implements ReminderTexts {
  L10nReminderTexts({required this.l10n, required this.currency});

  final AppLocalizations l10n;
  final Currency currency;

  @override
  String get title => l10n.appTitle;

  @override
  String actionTitle(ReminderAction action) => switch (action) {
    ReminderAction.paid => l10n.reminderActionPaid,
    ReminderAction.allPaid => l10n.reminderActionAllPaid,
    ReminderAction.remindTonight => l10n.reminderActionRemindTonight,
    ReminderAction.remindTomorrow => l10n.reminderActionRemindTomorrow,
  };

  String _date(LocalDate date) =>
      DateFormat.MMMMEEEEd(l10n.localeName).format(date.toDateTime());

  /// Day and month only ("14 Kasım", "November 14").
  String _dayMonth(LocalDate date) =>
      DateFormat.MMMMd(l10n.localeName).format(date.toDateTime());

  String _money(int minor) =>
      formatMoney(minor, currency, localeName: l10n.localeName);

  @override
  ReminderText describe({
    required ReminderKind kind,
    required List<ReminderPayment> payments,
    required List<LocalDate> dueDates,
    required bool showAmounts,
    PaymentMethod? method,
  }) {
    final count = payments.length;
    final name = payments.first.name;
    final total = _money(payments.fold(0, (sum, p) => sum + p.amountMinor));
    final date = _date(dueDates.first);
    final due = dueDates.first;
    var body = switch ((kind, dueDates.length > 1, showAmounts)) {
      (ReminderKind.overdue, _, true) => l10n.reminderOverdue(
        count,
        _dayMonth(due),
        '${due.month}',
        name,
        total,
      ),
      (ReminderKind.overdue, _, false) => l10n.reminderOverdueHidden(
        count,
        _dayMonth(due),
        '${due.month}',
        name,
      ),
      (ReminderKind.onDay, _, true) => l10n.reminderToday(count, name, total),
      (ReminderKind.onDay, _, false) => l10n.reminderTodayHidden(count, name),
      (ReminderKind.ahead, false, true) => l10n.reminderAhead(
        count,
        date,
        name,
        total,
      ),
      (ReminderKind.ahead, false, false) => l10n.reminderAheadHidden(
        count,
        date,
        name,
      ),
      (ReminderKind.ahead, true, true) => l10n.reminderAheadMixed(
        count,
        date,
        total,
      ),
      (ReminderKind.ahead, true, false) => l10n.reminderAheadMixedHidden(
        count,
        date,
      ),
    };
    final note = switch (method) {
      PaymentMethod.automatic => l10n.reminderNoteAutomatic(count),
      PaymentMethod.manual => l10n.reminderNoteManual(count),
      null => null,
    };
    if (note != null) body = l10n.reminderWithNote(body, note);
    final expanded = count == 1
        ? body
        : l10n.reminderExpanded(
            body,
            payments.map((p) => p.name).join(l10n.reminderNameSeparator),
          );
    return ReminderText(body: body, expanded: expanded);
  }

  @override
  ReminderText payday(PaydaySummary summary, {required bool showAmounts}) {
    final count = summary.paymentCount;
    if (!showAmounts) {
      final body = l10n.reminderPaydayHidden(count);
      return ReminderText(body: body, expanded: body);
    }
    var body = l10n.reminderPayday(count, _money(summary.totalMinor));
    final left = summary.leftMinor;
    if (left != null) {
      body = left < 0
          ? l10n.reminderPaydayShort(body, _money(-left))
          : l10n.reminderPaydayLeft(body, _money(left));
    }
    return ReminderText(body: body, expanded: body);
  }

  @override
  String statementClosing({
    required String card,
    required int days,
    required LocalDate date,
    required LocalDate next,
  }) => l10n.reminderStatementClosing(
    days,
    card,
    _dayMonth(date),
    _dayMonth(next),
  );
}
