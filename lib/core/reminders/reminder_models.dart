import 'package:timezone/timezone.dart' as tz;

import '../date/local_date.dart';

/// The two notifications every payment gets.
enum ReminderKind {
  /// Some days before the due date ("lead days").
  ahead,

  /// On the due date itself.
  onDay,
}

/// "How many days before" choices offered in Settings and per plan.
const leadDayChoices = [1, 2, 3, 5, 7];

/// The initial global "days before". Some providers take the money a day
/// early, so two days leaves room.
const initialLeadDays = 2;

/// A plan's (or recurring payment's) own reminder choice.
class ReminderChoice {
  /// Its own "days before"; the time still comes from the global setting.
  factory ReminderChoice.days(int leadDays) {
    assert(leadDayChoices.contains(leadDays), 'unsupported: $leadDays');
    return ReminderChoice._(off: false, leadDays: leadDays);
  }

  const ReminderChoice._({required this.off, this.leadDays});

  /// Follows the global setting (the default).
  static const general = ReminderChoice._(off: false);

  /// No reminders at all for this plan.
  static const disabled = ReminderChoice._(off: true);

  final bool off;

  /// Null when the global setting applies.
  final int? leadDays;

  bool get isGeneral => !off && leadDays == null;

  @override
  bool operator ==(Object other) =>
      other is ReminderChoice && other.off == off && other.leadDays == leadDays;

  @override
  int get hashCode => Object.hash(off, leadDays);

  @override
  String toString() => off
      ? 'ReminderChoice.disabled'
      : leadDays == null
      ? 'ReminderChoice.general'
      : 'ReminderChoice.days($leadDays)';
}

/// A payment as the planner sees it. [date] is the effective due date the
/// calculation engine stored (statement, due day and weekend shift already
/// applied), the same day the screens show. The planner never computes
/// payment dates.
class ReminderPayment {
  const ReminderPayment({
    required this.name,
    required this.date,
    required this.amountMinor,
    this.isPaid = false,
    this.choice = ReminderChoice.general,
  });

  final String name;
  final LocalDate date;
  final int amountMinor;
  final bool isPaid;
  final ReminderChoice choice;
}

/// The user's global reminder settings.
class ReminderSettings {
  const ReminderSettings({
    this.enabled = true,
    this.leadDays = initialLeadDays,
    this.minuteOfDay = 9 * 60,
    this.showAmounts = true,
  });

  /// Master switch; off cancels every pending reminder.
  final bool enabled;

  /// Global "days before" (one of [leadDayChoices]).
  final int leadDays;

  /// Local wall-clock time, minutes after midnight (09:00 = 540).
  final int minuteOfDay;

  /// Amounts in notification text (off for lock-screen privacy).
  final bool showAmounts;
}

/// "Days before" for a payment that follows the global setting.
///
/// The one place that decides it: when manual and automatic payments get
/// their own defaults (backlog), only this function changes.
int defaultLeadDaysFor(ReminderPayment payment, ReminderSettings settings) =>
    settings.leadDays;

/// "Days before" that applies to [payment].
int leadDaysFor(ReminderPayment payment, ReminderSettings settings) {
  final days = payment.choice.leadDays ?? defaultLeadDaysFor(payment, settings);
  // Never on the due day itself: that is the on-day reminder.
  return days < 1 ? 1 : days;
}

/// Notification text in the app language. Implemented next to the
/// localizations; the planner stays pure Dart.
abstract interface class ReminderTexts {
  /// The notification title (the app name).
  String get title;

  /// Text for [payments] due on [dueDates] (one date unless an "ahead"
  /// notification gathers payments with different lead days).
  ReminderText describe({
    required ReminderKind kind,
    required List<ReminderPayment> payments,
    required List<LocalDate> dueDates,
    required bool showAmounts,
  });
}

/// The short body and the expanded body (body plus the names).
class ReminderText {
  const ReminderText({required this.body, required this.expanded});

  final String body;
  final String expanded;
}

/// What a tapped reminder opens: the home screen.
const reminderPayload = 'home';

/// One notification to schedule.
class PlannedReminder {
  const PlannedReminder({
    required this.id,
    required this.kind,
    required this.fireDate,
    required this.fireAt,
    required this.payments,
    required this.dueDates,
    required this.title,
    required this.body,
    required this.expandedBody,
    this.payload = reminderPayload,
  });

  /// Stable per fire day and kind, so rescheduling replaces a reminder
  /// instead of adding a second one.
  final int id;
  final ReminderKind kind;
  final LocalDate fireDate;

  /// The real moment: [fireDate] at the chosen local time.
  final tz.TZDateTime fireAt;
  final List<ReminderPayment> payments;

  /// Distinct due dates of [payments], earliest first.
  final List<LocalDate> dueDates;
  final String title;
  final String body;
  final String expandedBody;
  final String payload;

  int get totalMinor => payments.fold(0, (sum, p) => sum + p.amountMinor);

  static int idFor(LocalDate fireDate, ReminderKind kind) =>
      fireDate.epochDay * ReminderKind.values.length + kind.index;
}
