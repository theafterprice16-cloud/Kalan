import '../date/local_date.dart';
import 'reminder_models.dart';

/// iOS keeps at most 64 pending notifications; stay below it.
const maxScheduledReminders = 60;

/// Decides which notifications to schedule. Pure and deterministic.
///
/// Payments due on the same day are grouped into one notification per
/// offset. Paid payments, payments whose plan has reminders off and
/// anything that would fire at or before now are skipped. Only the
/// [limit] soonest reminders are returned, ordered by fire time.
List<PlannedReminder> planReminders({
  required Iterable<ReminderPayment> payments,
  required ReminderSettings settings,
  required LocalDate today,
  required int nowMinuteOfDay,
  int limit = maxScheduledReminders,
}) {
  if (!settings.enabled || settings.offsets.isEmpty) return const [];

  final byDay = <LocalDate, List<ReminderPayment>>{};
  for (final p in payments) {
    if (p.isPaid || !p.remindersEnabled) continue;
    byDay.putIfAbsent(p.date, () => []).add(p);
  }

  bool isFuture(LocalDate date, int minute) =>
      date > today || (date == today && minute > nowMinuteOfDay);

  final planned = <PlannedReminder>[];
  for (final MapEntry(key: due, value: group) in byDay.entries) {
    group.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    for (final offset in settings.offsets) {
      final fireDate = due.addDays(-offset.days);
      if (!isFuture(fireDate, settings.minuteOfDay)) continue;
      planned.add(
        PlannedReminder(
          id: PlannedReminder.idFor(due, offset),
          fireDate: fireDate,
          minuteOfDay: settings.minuteOfDay,
          offset: offset,
          dueDate: due,
          payments: List.unmodifiable(group),
        ),
      );
    }
  }

  planned.sort((a, b) {
    final byFire = a.fireDate.compareTo(b.fireDate);
    if (byFire != 0) return byFire;
    // Same moment: the nearer due date first.
    return a.dueDate.compareTo(b.dueDate);
  });
  return planned.length > limit ? planned.sublist(0, limit) : planned;
}
