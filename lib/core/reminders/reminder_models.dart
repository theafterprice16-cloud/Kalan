import 'dart:convert';

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
    this.ref,
  });

  final String name;
  final LocalDate date;
  final int amountMinor;
  final bool isPaid;
  final ReminderChoice choice;

  /// Which stored payment this is, so a notification action can mark it.
  /// Without one the reminder carries no actions.
  final PaymentRef? ref;
}

/// A stored payment a notification points at: a plan payment by id, or a
/// recurring payment's occurrence on a day. Written into the
/// notification's payload as a short key ("p12", "r3.20406").
sealed class PaymentRef {
  const PaymentRef();

  /// Null for anything that is not a key [key] produced.
  static PaymentRef? parse(String key) {
    if (key.startsWith('p')) {
      final id = int.tryParse(key.substring(1));
      return id == null || id < 0 ? null : PlanPaymentRef(id);
    }
    if (key.startsWith('r')) {
      final parts = key.substring(1).split('.');
      if (parts.length != 2) return null;
      final id = int.tryParse(parts[0]);
      final day = int.tryParse(parts[1]);
      if (id == null || day == null || id < 0) return null;
      return RecurringRef(id, LocalDate.fromEpochDay(day));
    }
    return null;
  }

  String get key;

  @override
  bool operator ==(Object other) => other is PaymentRef && other.key == key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => key;
}

final class PlanPaymentRef extends PaymentRef {
  const PlanPaymentRef(this.paymentId);

  final int paymentId;

  @override
  String get key => 'p$paymentId';
}

final class RecurringRef extends PaymentRef {
  const RecurringRef(this.recurringId, this.date);

  final int recurringId;
  final LocalDate date;

  @override
  String get key => 'r$recurringId.${date.epochDay}';
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

  /// The short button name of [action] ("Paid", "Remind tonight").
  String actionTitle(ReminderAction action);

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

/// Buttons on a reminder. At most two per notification.
enum ReminderAction {
  /// Marks the one payment in the notification as paid.
  paid,

  /// Marks every payment in a merged notification as paid.
  allPaid,

  /// "On the day" only: the same notification again at 20:00.
  remindTonight,

  /// "Ahead" only: the same notification again the next day, same time.
  remindTomorrow;

  bool get marksPaid => this == paid || this == allPaid;
}

/// "Remind tonight" fires at 20:00 ...
const remindTonightMinute = 20 * 60;

/// ... and is offered only when the reminder time is 18:00 or earlier.
const latestMinuteForRemindTonight = 18 * 60;

/// A button with its name in the app language.
class ReminderButton {
  const ReminderButton(this.action, this.title);

  final ReminderAction action;
  final String title;

  @override
  bool operator ==(Object other) =>
      other is ReminderButton && other.action == action && other.title == title;

  @override
  int get hashCode => Object.hash(action, title);

  @override
  String toString() => 'ReminderButton($action, $title)';
}

/// A "remind me later" the user chose from a notification, stored so a
/// full reschedule keeps it. It fires once, with the text of the
/// notification it came from ([kind]) and only a "paid" button.
class ReminderSnooze {
  const ReminderSnooze({
    required this.id,
    required this.kind,
    required this.fireDate,
    required this.minuteOfDay,
    required this.refs,
  });

  final int id;

  /// The kind of the notification it was snoozed from (its text).
  final ReminderKind kind;
  final LocalDate fireDate;
  final int minuteOfDay;
  final List<PaymentRef> refs;
}

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
    this.buttons = const [],
    this.data,
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

  /// What a tap opens (always the home screen).
  final String payload;

  /// Its buttons, at most two; empty when a payment has no [PaymentRef].
  final List<ReminderButton> buttons;

  /// What the buttons act on; written into the notification's payload.
  /// Null when there are no buttons.
  final ReminderPayload? data;

  bool get isSnoozed => data?.snoozed ?? false;

  int get totalMinor => payments.fold(0, (sum, p) => sum + p.amountMinor);

  static int idFor(LocalDate fireDate, ReminderKind kind) =>
      fireDate.epochDay * ReminderKind.values.length + kind.index;

  /// Snoozed reminders: far from [idFor] (fire day × 2 + kind, about
  /// 40,000 today) and from the debug test notification.
  static int idForSnooze(int snoozeId) => snoozeIdBase + snoozeId;

  static const snoozeIdBase = 1 << 30;
}

/// What a notification's buttons act on, carried in its payload: the
/// notification's kind, whether it is a snoozed one, when it fired and
/// the payments in it. Decoding never throws: anything unreadable (an old
/// "home" payload, a damaged string) is null and the action does nothing.
class ReminderPayload {
  const ReminderPayload({
    required this.kind,
    required this.fireDate,
    required this.minuteOfDay,
    required this.refs,
    this.snoozed = false,
  });

  /// The text's kind; for a snoozed reminder, the kind it came from.
  final ReminderKind kind;
  final bool snoozed;
  final LocalDate fireDate;
  final int minuteOfDay;
  final List<PaymentRef> refs;

  static const _version = 1;

  String encode() => jsonEncode({
    'v': _version,
    't': snoozed ? 'snoozed' : kind.name,
    'k': kind.name,
    'd': fireDate.epochDay,
    'm': minuteOfDay,
    'r': [for (final r in refs) r.key],
  });

  static ReminderPayload? decode(String? raw) {
    if (raw == null || !raw.startsWith('{')) return null;
    try {
      final map = jsonDecode(raw);
      if (map is! Map<String, Object?> || map['v'] != _version) return null;
      final type = map['t'];
      final kind = ReminderKind.values.asNameMap()[map['k']];
      final day = map['d'];
      final minute = map['m'];
      final keys = map['r'];
      if (kind == null ||
          type is! String ||
          day is! int ||
          minute is! int ||
          minute < 0 ||
          minute >= 24 * 60 ||
          keys is! List) {
        return null;
      }
      final snoozed = type == 'snoozed';
      if (!snoozed && type != kind.name) return null;
      final refs = <PaymentRef>[];
      for (final key in keys) {
        final ref = key is String ? PaymentRef.parse(key) : null;
        if (ref == null) return null;
        refs.add(ref);
      }
      if (refs.isEmpty) return null;
      return ReminderPayload(
        kind: kind,
        snoozed: snoozed,
        fireDate: LocalDate.fromEpochDay(day),
        minuteOfDay: minute,
        refs: List.unmodifiable(refs),
      );
    } on FormatException {
      return null;
    }
  }
}
