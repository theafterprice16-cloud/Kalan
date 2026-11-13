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
/// same kind on the same day are merged into one. Anything at or before
/// [now] is skipped (a past "ahead" does not drop the "on day"). The
/// [limit] soonest are returned, ordered by time.
List<PlannedReminder> planReminders({
  required Iterable<ReminderPayment> payments,
  required ReminderSettings settings,
  required tz.TZDateTime now,
  required ReminderTexts texts,
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
    group.sort((a, b) {
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
    planned.add(
      PlannedReminder(
        id: PlannedReminder.idFor(fireDate, kind),
        kind: kind,
        fireDate: fireDate,
        fireAt: fireAt,
        payments: List.unmodifiable(group),
        dueDates: List.unmodifiable(dueDates),
        title: texts.title,
        body: text.body,
        expandedBody: text.expanded,
      ),
    );
  }

  planned.sort((a, b) {
    final byTime = a.fireAt.compareTo(b.fireAt);
    return byTime != 0 ? byTime : a.kind.index.compareTo(b.kind.index);
  });
  return planned.length > limit ? planned.sublist(0, limit) : planned;
}
