import 'package:timezone/timezone.dart' as tz;

import '../../core/date/local_date.dart';
import '../../core/engine/past_due.dart';
import '../../core/reminders/reminder_models.dart';
import '../../core/reminders/reminder_planner.dart';
import '../../core/reminders/reminder_time.dart';
import '../../data/repositories/plan_repository.dart';
import '../../data/repositories/recurring_repository.dart';
import '../../data/repositories/reminder_snooze_repository.dart';
import 'reminder_scheduler.dart';

/// Button identifiers shared with the platform (Android action ids, iOS
/// action and category identifiers).
abstract final class ReminderActionIds {
  static String of(ReminderAction action) => switch (action) {
    ReminderAction.paid => 'kalan.paid',
    ReminderAction.allPaid => 'kalan.all_paid',
    ReminderAction.remindTonight => 'kalan.remind_tonight',
    ReminderAction.remindTomorrow => 'kalan.remind_tomorrow',
  };

  static ReminderAction? parse(String? id) => switch (id) {
    'kalan.paid' => ReminderAction.paid,
    'kalan.all_paid' => ReminderAction.allPaid,
    'kalan.remind_tonight' => ReminderAction.remindTonight,
    'kalan.remind_tomorrow' => ReminderAction.remindTomorrow,
    _ => null,
  };

  /// Every button combination a reminder can have (iOS registers one
  /// category for each).
  static const combinations = [
    [ReminderAction.paid],
    [ReminderAction.paid, ReminderAction.remindTonight],
    [ReminderAction.paid, ReminderAction.remindTomorrow],
    [ReminderAction.allPaid],
    [ReminderAction.allPaid, ReminderAction.remindTonight],
    [ReminderAction.allPaid, ReminderAction.remindTomorrow],
  ];

  /// iOS category of a reminder with [actions]; null without buttons.
  static String? category(Iterable<ReminderAction> actions) =>
      actions.isEmpty ? null : 'kalan.${actions.map((a) => a.name).join('.')}';
}

/// What a button did.
enum ReminderActionOutcome {
  /// Not Kalan's button, or a payload that cannot be read.
  ignored,

  /// This many payments were marked paid (possibly none: all were already
  /// paid or deleted).
  markedPaid,

  /// The reminder comes back later.
  snoozed,

  /// The "later" time has already passed; nothing stored.
  tooLate,
}

/// The one place that handles a notification button, whether the app is
/// in the foreground or a background isolate runs it. Marking goes
/// through the app's own "paid" code (the repositories); then reminders
/// are rescheduled, so a paid payment gets no more reminders and a merged
/// one is rebuilt with the payments still unpaid.
///
/// Every step is safe to repeat: a payment already paid or deleted is
/// skipped without an error, and the same snooze is stored once.
class ReminderActionHandler {
  ReminderActionHandler(this._scheduler);

  final ReminderScheduler _scheduler;

  /// With [reschedule] false only the change is made; the caller then
  /// reschedules (the background isolate does, once the notification
  /// service is up).
  Future<({ReminderActionOutcome outcome, int marked})> handle({
    required String? actionId,
    required String? payload,
    bool reschedule = true,
  }) async {
    final action = ReminderActionIds.parse(actionId);
    final data = ReminderPayload.decode(payload);
    if (action == null || data == null) {
      return (outcome: ReminderActionOutcome.ignored, marked: 0);
    }
    final now = tz.TZDateTime.from(_scheduler.now(), _scheduler.location());
    final ReminderActionOutcome outcome;
    var marked = 0;
    if (action.marksPaid) {
      marked = await _markPaid(data.refs, now);
      outcome = ReminderActionOutcome.markedPaid;
    } else {
      outcome = await _snooze(data, action, now);
    }
    if (reschedule) await _scheduler.rescheduleAll();
    return (outcome: outcome, marked: marked);
  }

  /// Plan payments: the usual "paid"; one whose due date has passed is
  /// marked as paid today, like "Today" in the past-due list. Recurring
  /// occurrences: the usual mark.
  Future<int> _markPaid(List<PaymentRef> refs, tz.TZDateTime now) {
    final db = _scheduler.db;
    final today = LocalDate(now.year, now.month, now.day);
    final plans = PlanRepository(db);
    final recurring = RecurringRepository(db);
    final stamp = _scheduler.now();
    return db.transaction(() async {
      var marked = 0;
      for (final ref in refs) {
        switch (ref) {
          case PlanPaymentRef(:final paymentId):
            final row = await (db.select(
              db.payments,
            )..where((p) => p.id.equals(paymentId))).getSingleOrNull();
            if (row == null || row.paidAt != null) continue;
            final due = LocalDate.fromEpochDay(row.dueDay);
            if (isPastDue(dueDate: due, isPaid: false, today: today)) {
              await plans.setPaidOn(paymentId, today, now: stamp);
            } else {
              await plans.setPaid(paymentId, paid: true, now: stamp);
            }
            marked++;
          case RecurringRef(:final recurringId, :final date):
            final all = await recurring.all();
            final item = all.where((r) => r.item.id == recurringId).firstOrNull;
            if (item == null ||
                item.paidDays.contains(date.epochDay) ||
                !item.occurrences(date, date.addDays(1)).contains(date)) {
              continue;
            }
            await recurring.setPaid(
              recurringId,
              date.epochDay,
              paid: true,
              now: stamp,
            );
            marked++;
        }
      }
      return marked;
    });
  }

  Future<ReminderActionOutcome> _snooze(
    ReminderPayload data,
    ReminderAction action,
    tz.TZDateTime now,
  ) async {
    final target = snoozeTarget(data, action);
    if (target == null) return ReminderActionOutcome.ignored;
    final fireAt = localWallClock(
      target.fireDate,
      target.minuteOfDay,
      now.location,
    );
    if (!fireAt.isAfter(now)) return ReminderActionOutcome.tooLate;
    await ReminderSnoozeRepository(_scheduler.db).add(
      kind: data.kind,
      fireDate: target.fireDate,
      minuteOfDay: target.minuteOfDay,
      refs: data.refs,
    );
    return ReminderActionOutcome.snoozed;
  }
}
