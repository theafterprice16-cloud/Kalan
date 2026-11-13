import 'package:timezone/timezone.dart' as tz;

import '../date/local_date.dart';
import 'reminder_models.dart';
import 'reminder_time.dart';

/// iOS keeps at most 64 pending notifications; four stay free. The same
/// cap applies on Android, so both platforms follow one code path.
const maxScheduledReminders = 60;

/// Decides which notifications to schedule. Pure and deterministic: the
/// same input always gives the same list, with the same ids.
///
/// Every unpaid payment whose plan has reminders on gets an "ahead"
/// notification [leadDaysFor] days before its due date and an "on day"
/// notification on it, at the chosen local time. Notifications of the
/// same kind on the same day are merged into one. Each stored [snoozes]
/// entry adds one notification with the payments in it that are still
/// unpaid. Anything at or before [now] is skipped (a past "ahead" does
/// not drop the "on day"). The [limit] soonest are returned, ordered by
/// time; snoozed reminders count towards the limit like any other.
List<PlannedReminder> planReminders({
  required Iterable<ReminderPayment> payments,
  required ReminderSettings settings,
  required tz.TZDateTime now,
  required ReminderTexts texts,
  Iterable<ReminderSnooze> snoozes = const [],
  int limit = maxScheduledReminders,
}) {
  if (!settings.enabled) return const [];
  final location = now.location;

  final groups = <(LocalDate, ReminderKind), List<ReminderPayment>>{};
  for (final p in payments) {
    if (p.isPaid || p.choice.off) continue;
    final ahead = p.date.addDays(-leadDaysFor(p, settings));
    groups.putIfAbsent((ahead, ReminderKind.ahead), () => []).add(p);
    groups.putIfAbsent((p.date, ReminderKind.onDay), () => []).add(p);
  }

  final planned = <PlannedReminder>[];
  for (final MapEntry(key: (fireDate, kind), value: group) in groups.entries) {
    final fireAt = localWallClock(fireDate, settings.minuteOfDay, location);
    if (!fireAt.isAfter(now)) continue;
    planned.add(
      buildReminder(
        id: PlannedReminder.idFor(fireDate, kind),
        kind: kind,
        fireDate: fireDate,
        minuteOfDay: settings.minuteOfDay,
        payments: group,
        settings: settings,
        location: location,
        texts: texts,
      ),
    );
  }

  final byRef = _unpaidByRef(payments);
  for (final s in snoozes) {
    final fireAt = localWallClock(s.fireDate, s.minuteOfDay, location);
    if (!fireAt.isAfter(now)) continue;
    final group = [
      for (final ref in s.refs)
        if (byRef[ref] case final p? when !p.choice.off) p,
    ];
    if (group.isEmpty) continue;
    planned.add(
      buildReminder(
        id: PlannedReminder.idForSnooze(s.id),
        kind: s.kind,
        fireDate: s.fireDate,
        minuteOfDay: s.minuteOfDay,
        payments: group,
        settings: settings,
        location: location,
        texts: texts,
        snoozed: true,
      ),
    );
  }

  planned.sort((a, b) {
    final byTime = a.fireAt.compareTo(b.fireAt);
    if (byTime != 0) return byTime;
    final byKind = a.kind.index.compareTo(b.kind.index);
    if (byKind != 0) return byKind;
    return a.id.compareTo(b.id);
  });
  return planned.length > limit ? planned.sublist(0, limit) : planned;
}

/// One notification for [payments] (same kind, same fire day). Used by
/// [planReminders] and by the debug "test reminder" so both look alike.
PlannedReminder buildReminder({
  required int id,
  required ReminderKind kind,
  required LocalDate fireDate,
  required int minuteOfDay,
  required List<ReminderPayment> payments,
  required ReminderSettings settings,
  required tz.Location location,
  required ReminderTexts texts,
  bool snoozed = false,
  tz.TZDateTime? fireAt,
}) {
  final group = List.of(payments)
    ..sort((a, b) {
      final byDate = a.date.compareTo(b.date);
      if (byDate != 0) return byDate;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  final dueDates = <LocalDate>[];
  for (final p in group) {
    if (dueDates.isEmpty || dueDates.last != p.date) dueDates.add(p.date);
  }
  final text = texts.describe(
    kind: kind,
    payments: group,
    dueDates: dueDates,
    showAmounts: settings.showAmounts,
  );
  final actions = reminderActions(
    kind: kind,
    snoozed: snoozed,
    payments: group,
    fireDate: fireDate,
    minuteOfDay: minuteOfDay,
  );
  return PlannedReminder(
    id: id,
    kind: kind,
    fireDate: fireDate,
    fireAt: fireAt ?? localWallClock(fireDate, minuteOfDay, location),
    payments: List.unmodifiable(group),
    dueDates: List.unmodifiable(dueDates),
    title: texts.title,
    body: text.body,
    expandedBody: text.expanded,
    buttons: List.unmodifiable([
      for (final a in actions) ReminderButton(a, texts.actionTitle(a)),
    ]),
    data: actions.isEmpty
        ? null
        : ReminderPayload(
            kind: kind,
            snoozed: snoozed,
            fireDate: fireDate,
            minuteOfDay: minuteOfDay,
            refs: List.unmodifiable([for (final p in group) p.ref!]),
          ),
  );
}

/// The buttons a notification gets, at most two:
///
/// - "Paid" for one payment, "All paid" for several; none at all when a
///   payment has no [PaymentRef];
/// - "on day": also "Remind tonight" (20:00) when the reminder time is
///   18:00 or earlier;
/// - "ahead": also "Remind tomorrow" (same time) unless a payment in it is
///   due the next day, when the "on day" reminder does that job;
/// - a snoozed reminder only marks paid: it is never snoozed again.
List<ReminderAction> reminderActions({
  required ReminderKind kind,
  required bool snoozed,
  required List<ReminderPayment> payments,
  required LocalDate fireDate,
  required int minuteOfDay,
}) {
  if (payments.isEmpty || payments.any((p) => p.ref == null)) return const [];
  final paid = payments.length == 1
      ? ReminderAction.paid
      : ReminderAction.allPaid;
  if (snoozed) return [paid];
  return switch (kind) {
    ReminderKind.onDay when minuteOfDay <= latestMinuteForRemindTonight => [
      paid,
      ReminderAction.remindTonight,
    ],
    ReminderKind.onDay => [paid],
    ReminderKind.ahead
        when payments.any((p) => p.date == fireDate.addDays(1)) =>
      [paid],
    ReminderKind.ahead => [paid, ReminderAction.remindTomorrow],
  };
}

/// When a "remind later" button brings the notification back: "tonight"
/// is 20:00 on the day it fired, "tomorrow" is the next day at the time
/// it fired. Null for the "paid" buttons and for a snoozed reminder.
({LocalDate fireDate, int minuteOfDay})? snoozeTarget(
  ReminderPayload payload,
  ReminderAction action,
) {
  if (payload.snoozed) return null;
  return switch ((payload.kind, action)) {
    (ReminderKind.onDay, ReminderAction.remindTonight) => (
      fireDate: payload.fireDate,
      minuteOfDay: remindTonightMinute,
    ),
    (ReminderKind.ahead, ReminderAction.remindTomorrow) => (
      fireDate: payload.fireDate.addDays(1),
      minuteOfDay: payload.minuteOfDay,
    ),
    _ => null,
  };
}

/// Snoozes to delete: their time has passed, or none of their payments is
/// still there unpaid (paid in the app or from a notification, or its
/// plan deleted).
Set<int> staleSnoozeIds({
  required Iterable<ReminderSnooze> snoozes,
  required Iterable<ReminderPayment> payments,
  required tz.TZDateTime now,
}) {
  final byRef = _unpaidByRef(payments);
  return {
    for (final s in snoozes)
      if (!localWallClock(
            s.fireDate,
            s.minuteOfDay,
            now.location,
          ).isAfter(now) ||
          !s.refs.any(byRef.containsKey))
        s.id,
  };
}

Map<PaymentRef, ReminderPayment> _unpaidByRef(
  Iterable<ReminderPayment> payments,
) => {
  for (final p in payments)
    if (p.ref case final ref? when !p.isPaid) ref: p,
};
