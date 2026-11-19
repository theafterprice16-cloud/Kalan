import 'package:timezone/timezone.dart' as tz;

import '../date/local_date.dart';
import '../engine/pay_period.dart';
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
/// notification on it, at the chosen local time. Repeat reminders
/// ([repeatModeFor]) add more moments, only ever at that time and at
/// 20:00 (see [reminderMoments]). Notifications at the same moment and of
/// the same kind are merged into one. Each stored [snoozes] entry adds one
/// notification with the payments in it that are still unpaid, or, for a
/// "skip the rest of today" entry, moves that payment's repeats to the
/// next day. Anything at or before [now] is skipped (a past "ahead" does
/// not drop the "on day"). The [limit] soonest are returned, ordered by
/// time; repeats and snoozes count towards the limit like any other.
///
/// With repeats off and no "skip" entries the list is exactly what it was
/// before repeat reminders existed.
///
/// Payment reminders only; the payday summary is added by
/// [withPaydaySummary].
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
  final skips = [
    for (final s in snoozes)
      if (s.skipsDay) s,
  ];

  final groups = <ReminderMoment, List<ReminderPayment>>{};
  for (final p in payments) {
    if (p.isPaid || p.choice.off) continue;
    for (final m in reminderMoments(
      p,
      settings,
      skips: [
        for (final s in skips)
          if (p.ref != null && s.refs.contains(p.ref)) s,
      ],
    )) {
      groups.putIfAbsent(m, () => []).add(p);
    }
  }

  final planned = <PlannedReminder>[];
  for (final MapEntry(key: m, value: group) in groups.entries) {
    final fireAt = localWallClock(m.date, m.minuteOfDay, location);
    if (!fireAt.isAfter(now)) continue;
    final evening = m.minuteOfDay != settings.minuteOfDay;
    planned.add(
      buildReminder(
        id: !evening && m.kind != ReminderKind.overdue
            ? PlannedReminder.idFor(m.date, m.kind)
            : PlannedReminder.idForRepeat(m.date, m.kind, evening: evening),
        kind: m.kind,
        fireDate: m.date,
        minuteOfDay: m.minuteOfDay,
        payments: group,
        settings: settings,
        location: location,
        texts: texts,
      ),
    );
  }

  final byRef = _unpaidByRef(payments);
  for (final s in snoozes) {
    if (s.skipsDay) continue;
    final fireAt = localWallClock(s.fireDate, s.minuteOfDay, location);
    if (!fireAt.isAfter(now)) continue;
    // A payment already reminded at that very moment (repeats turned on
    // after the snooze) is not reminded twice.
    final already = {
      for (final MapEntry(key: m, value: group) in groups.entries)
        if (m.date == s.fireDate && m.minuteOfDay == s.minuteOfDay) ...group,
    };
    final group = [
      for (final ref in s.refs)
        if (byRef[ref] case final p? when !p.choice.off && !already.contains(p))
          p,
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

/// The payment reminders [planned] ([planReminders]) with the payday
/// summary for [payday] added in time order: its own notification, never
/// merged, not touching the others. Only with reminders and the summary
/// on, when it is still ahead of [now] and the payment reminders leave
/// room under [limit]: they keep priority.
List<PlannedReminder> withPaydaySummary(
  List<PlannedReminder> planned, {
  required PaydaySummary? payday,
  required ReminderSettings settings,
  required tz.TZDateTime now,
  required ReminderTexts texts,
  int limit = maxScheduledReminders,
}) {
  if (payday == null ||
      !settings.enabled ||
      !settings.paydaySummary ||
      planned.length >= limit) {
    return planned;
  }
  final summary = paydayReminder(
    payday,
    settings: settings,
    location: now.location,
    texts: texts,
  );
  if (!summary.fireAt.isAfter(now)) return planned;
  // After every payment reminder at the same moment.
  final at = planned.indexWhere((r) => r.fireAt.isAfter(summary.fireAt));
  return List.unmodifiable([
    ...planned.take(at < 0 ? planned.length : at),
    summary,
    if (at >= 0) ...planned.skip(at),
  ]);
}

/// [planned] (payment reminders and the payday summary) with the
/// statement closing reminders of [cards] added in time order, last in
/// priority: only in the room [planned] leaves under [limit], the
/// soonest first. Each card's reminder is its own notification, never
/// merged; at the same moment it comes after the others. Only with
/// reminders on.
List<PlannedReminder> withStatementClosings(
  List<PlannedReminder> planned, {
  required Iterable<StatementCard> cards,
  required ReminderSettings settings,
  required tz.TZDateTime now,
  required ReminderTexts texts,
  int limit = maxScheduledReminders,
}) {
  if (!settings.enabled || planned.length >= limit) return planned;
  final closings = statementClosingReminders(
    cards,
    settings: settings,
    now: now,
    texts: texts,
  ).take(limit - planned.length).toList();
  if (closings.isEmpty) return planned;
  final merged = <PlannedReminder>[];
  var i = 0;
  for (final c in closings) {
    while (i < planned.length && !planned[i].fireAt.isAfter(c.fireAt)) {
      merged.add(planned[i++]);
    }
    merged.add(c);
  }
  merged.addAll(planned.skip(i));
  return List.unmodifiable(merged);
}

/// Every statement closing reminder still ahead of [now] for [cards],
/// soonest first (then by card id): for each of a card's next
/// [statementClosingHorizon] statements, [StatementCard.leadDays] days
/// before its statement date, at the reminder time. No amount, no
/// buttons.
///
/// The statement dates are the engine's ([CardTerms.statementFor] for
/// the first, [CardTerms.statementInMonth] after it): clamped in short
/// months, never moved off a weekend or holiday. The planner writes no
/// date rule of its own.
List<PlannedReminder> statementClosingReminders(
  Iterable<StatementCard> cards, {
  required ReminderSettings settings,
  required tz.TZDateTime now,
  required ReminderTexts texts,
}) {
  final today = LocalDate(now.year, now.month, now.day);
  final list = <(int, PlannedReminder)>[];
  for (final card in cards) {
    final days = statementLeadDayChoices.contains(card.leadDays)
        ? card.leadDays
        : initialStatementLeadDays;
    final terms = card.terms;
    final first = terms.statementFor(today);
    for (var i = 0; i < statementClosingHorizon; i++) {
      final statement = terms.statementInMonth(first.year, first.month + i);
      final fireDate = statement.addDays(-days);
      final fireAt = localWallClock(
        fireDate,
        settings.minuteOfDay,
        now.location,
      );
      if (!fireAt.isAfter(now)) continue;
      final body = texts.statementClosing(
        card: card.name,
        days: days,
        date: statement,
        next: terms.statementInMonth(statement.year, statement.month + 1),
      );
      list.add((
        card.id,
        PlannedReminder(
          id: PlannedReminder.idForStatementClosing(card.id, fireDate),
          kind: ReminderKind.ahead,
          isStatementClosing: true,
          fireDate: fireDate,
          fireAt: fireAt,
          payments: const [],
          dueDates: const [],
          title: texts.title,
          body: body,
          expandedBody: body,
          payload: cardStatementPayload(card.id),
        ),
      ));
    }
  }
  list.sort((a, b) {
    final byTime = a.$2.fireAt.compareTo(b.$2.fireAt);
    return byTime != 0 ? byTime : a.$1.compareTo(b.$1);
  });
  return [for (final (_, r) in list) r];
}

/// The pay period whose payday summary comes next: the current one when
/// today is its first day and the reminder time has not passed yet,
/// otherwise the one after it. The payday is the schedule's own day, never
/// moved off a weekend.
PayPeriod nextPaydayPeriod(
  PaySchedule schedule,
  tz.TZDateTime now,
  int minuteOfDay,
) {
  final today = LocalDate(now.year, now.month, now.day);
  final current = schedule.periodContaining(today);
  final fireAt = localWallClock(current.start, minuteOfDay, now.location);
  return current.start == today && fireAt.isAfter(now)
      ? current
      : schedule.next(current);
}

/// The payday summary notification for [summary]: on its day at the
/// reminder time, no buttons; a tap opens the home screen.
PlannedReminder paydayReminder(
  PaydaySummary summary, {
  required ReminderSettings settings,
  required tz.Location location,
  required ReminderTexts texts,
  tz.TZDateTime? fireAt,
}) {
  final text = texts.payday(summary, showAmounts: settings.showAmounts);
  return PlannedReminder(
    id: PlannedReminder.idForPayday(summary.date),
    kind: ReminderKind.onDay,
    isPaydaySummary: true,
    fireDate: summary.date,
    fireAt:
        fireAt ?? localWallClock(summary.date, settings.minuteOfDay, location),
    payments: const [],
    dueDates: const [],
    title: texts.title,
    body: text.body,
    expandedBody: text.expanded,
  );
}

/// A local day, a time on it and the kind of reminder due then.
typedef ReminderMoment = ({LocalDate date, int minuteOfDay, ReminderKind kind});

/// The kind of a reminder for a payment due on [due], fired on [day]:
/// before the due date "ahead", on it "on day", after it "overdue".
ReminderKind reminderKindOn(LocalDate day, LocalDate due) => day < due
    ? ReminderKind.ahead
    : day == due
    ? ReminderKind.onDay
    : ReminderKind.overdue;

/// Every moment [payment] should be reminded at, past ones included:
///
/// - always "ahead" ([leadDaysFor] days before) and "on day", at the
///   reminder time;
/// - "once more in the evening": the same two days at 20:00 too;
/// - "every day": each day from the "ahead" day to [repeatDaysAfterDue]
///   days after the due date, at the reminder time and at 20:00;
/// - 20:00 only when the reminder time is 18:00 or earlier;
/// - a [skips] entry drops the moments on the day before its date and
///   adds its date at the reminder time.
///
/// The kind follows the day ([reminderKindOn]).
Set<ReminderMoment> reminderMoments(
  ReminderPayment payment,
  ReminderSettings settings, {
  List<ReminderSnooze> skips = const [],
}) {
  final due = payment.date;
  final ahead = due.addDays(-leadDaysFor(payment, settings));
  final minute = settings.minuteOfDay;
  ReminderMoment at(LocalDate day, int minute) =>
      (date: day, minuteOfDay: minute, kind: reminderKindOn(day, due));

  final moments = <ReminderMoment>{at(ahead, minute), at(due, minute)};
  switch (repeatModeFor(payment, settings)) {
    case ReminderRepeat.off:
      break;
    case ReminderRepeat.evening:
      moments
        ..add(at(ahead, remindTonightMinute))
        ..add(at(due, remindTonightMinute));
    case ReminderRepeat.daily:
      final last = due.addDays(repeatDaysAfterDue);
      for (var day = ahead; day <= last; day = day.addDays(1)) {
        moments.add(at(day, minute));
        if (settings.eveningAllowed) moments.add(at(day, remindTonightMinute));
      }
  }
  for (final skip in skips) {
    final skipped = skip.fireDate.addDays(-1);
    moments
      ..removeWhere((m) => m.date == skipped)
      ..add(at(skip.fireDate, skip.minuteOfDay));
  }
  return moments;
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
    method: reminderMethodOf(kind, group),
    account: reminderAccountOf(
      kind,
      group,
      showAmounts: settings.showAmounts,
    )?.name,
  );
  final repeating = group.any(
    (p) => repeatModeFor(p, settings) != ReminderRepeat.off,
  );
  final actions = reminderActions(
    kind: kind,
    snoozed: snoozed,
    payments: group,
    fireDate: fireDate,
    minuteOfDay: minuteOfDay,
    repeating: repeating,
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
            repeating: repeating && !snoozed,
          ),
  );
}

/// The buttons a notification gets, at most two:
///
/// - "Paid" for one payment, "All paid" for several; none at all when a
///   payment has no [PaymentRef];
/// - a snoozed reminder only marks paid: it is never snoozed again;
/// - with repeat reminders ([repeating], a payment in it repeats): "Remind
///   tomorrow", which skips the rest of today's repeats, except on the
///   last day of a payment's window ([repeatDaysAfterDue] days after its
///   due date), when there is no tomorrow;
/// - otherwise, "on day": "Remind tonight" (20:00) when the reminder time
///   is 18:00 or earlier; "ahead": "Remind tomorrow" (same time) unless a
///   payment in it is due the next day, when the "on day" reminder does
///   that job.
List<ReminderAction> reminderActions({
  required ReminderKind kind,
  required bool snoozed,
  required List<ReminderPayment> payments,
  required LocalDate fireDate,
  required int minuteOfDay,
  bool repeating = false,
}) {
  if (payments.isEmpty || payments.any((p) => p.ref == null)) return const [];
  final paid = payments.length == 1
      ? ReminderAction.paid
      : ReminderAction.allPaid;
  if (snoozed) return [paid];
  if (repeating) {
    final lastDay = payments.any(
      (p) => fireDate >= p.date.addDays(repeatDaysAfterDue),
    );
    return lastDay ? [paid] : [paid, ReminderAction.remindTomorrow];
  }
  return switch (kind) {
    ReminderKind.onDay when minuteOfDay <= latestMinuteForRemindTonight => [
      paid,
      ReminderAction.remindTonight,
    ],
    ReminderKind.onDay || ReminderKind.overdue => [paid],
    ReminderKind.ahead
        when payments.any((p) => p.date == fireDate.addDays(1)) =>
      [paid],
    ReminderKind.ahead => [paid, ReminderAction.remindTomorrow],
  };
}

/// "Remind tomorrow" on a reminder with repeats: the rest of the day it
/// fired is skipped and the payment is reminded on the returned day at
/// the reminder time; the repeats go on from there. Null otherwise.
LocalDate? repeatSkipDate(ReminderPayload payload, ReminderAction action) =>
    !payload.snoozed &&
        payload.repeating &&
        action == ReminderAction.remindTomorrow
    ? payload.fireDate.addDays(1)
    : null;

/// When a "remind later" button brings the notification back: "tonight"
/// is 20:00 on the day it fired, "tomorrow" is the next day at the time
/// it fired. Null for the "paid" buttons and for a snoozed reminder.
({LocalDate fireDate, int minuteOfDay})? snoozeTarget(
  ReminderPayload payload,
  ReminderAction action,
) {
  if (payload.snoozed) return null;
  // With repeats, "Remind tomorrow" is a skip ([repeatSkipDate]).
  if (payload.repeating) return null;
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
