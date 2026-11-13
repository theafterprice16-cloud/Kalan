import 'package:material_ui/material_ui.dart' show Locale;
import 'package:timezone/timezone.dart' as tz;

import '../../core/date/local_date.dart';
import '../../core/money/currency.dart';
import '../../core/reminders/reminder_models.dart';
import '../../core/reminders/reminder_planner.dart';
import '../../core/reminders/reminder_time.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/plan_repository.dart';
import '../../data/repositories/recurring_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../l10n/generated/app_localizations.dart';
import 'notification_gateway.dart';
import 'reminder_messages.dart';
import 'reminder_settings_store.dart';

/// How far ahead recurring payments are expanded; the planner keeps only
/// the soonest 60 anyway.
const _recurringHorizonDays = 400;

/// Turns stored payments and settings into scheduled notifications.
/// Every run replaces all pending reminders, so it is safe to call after
/// any change.
class ReminderScheduler {
  ReminderScheduler({
    required this.db,
    required this.gateway,
    required this.location,
    required this.now,
    required this.localeFor,
  });

  final AppDatabase db;
  final NotificationGateway gateway;

  /// The device's current time zone.
  final tz.Location Function() location;
  final DateTime Function() now;

  /// App language for notification text (settings override or device).
  final Locale Function(SettingsRow settings) localeFor;

  /// The reminders that would be scheduled right now.
  Future<List<ScheduledNotification>> build() async {
    final settings = await SettingsRepository(db).get();
    if (settings == null) return const [];
    final zone = location();
    final local = tz.TZDateTime.from(now(), zone);
    final today = LocalDate(local.year, local.month, local.day);

    final payments = <ReminderPayment>[];
    for (final p in await PlanRepository(db).all()) {
      for (final pay in p.payments) {
        payments.add(
          ReminderPayment(
            ref: PlanPaymentRef(pay.id),
            name: p.displayName,
            date: LocalDate.fromEpochDay(pay.dueDay),
            amountMinor: pay.amountMinor,
            seq: pay.seq,
            count: p.plan.installmentCount,
            isPaid: pay.paidAt != null,
            remindersEnabled: p.plan.remindersEnabled,
          ),
        );
      }
    }
    for (final r in await RecurringRepository(db).all()) {
      for (final date in r.occurrences(
        today,
        today.addDays(_recurringHorizonDays),
      )) {
        payments.add(
          ReminderPayment(
            ref: RecurringRef(r.item.id, date.epochDay),
            name: r.item.name,
            date: date,
            amountMinor: r.item.amountMinor,
            isPaid: r.paidDays.contains(date.epochDay),
            remindersEnabled: r.item.remindersEnabled,
          ),
        );
      }
    }

    final reminderSettings = settings.reminderSettings;
    final planned = planReminders(
      payments: payments,
      settings: reminderSettings,
      today: today,
      nowMinuteOfDay: local.hour * 60 + local.minute,
    );
    final l10n = lookupAppLocalizations(localeFor(settings));
    final currency = Currency.fromCode(settings.currencyCode);
    return [
      for (final r in planned)
        ScheduledNotification(
          id: r.id,
          text: reminderText(
            r,
            l10n: l10n,
            currency: currency,
            hideAmounts: reminderSettings.hideAmounts,
          ),
          fireAt: localWallClock(r.fireDate, r.minuteOfDay, zone),
          payload: NotificationPayload(
            route: r.route,
            paymentRef: r.paidAction?.encode(),
          ),
          hasPaidAction: r.paidAction != null,
        ),
    ];
  }

  Future<void> rescheduleAll() async {
    if (!gateway.supported) return;
    await gateway.replaceAll(await build());
  }
}

/// The "Paid" action from a notification: marks the payment, removes the
/// notification and reschedules. Runs in the app or in a background
/// isolate with the app closed. Returns false for a payload it ignores.
Future<bool> handlePaidAction({
  required String? payload,
  required int? notificationId,
  required ReminderScheduler scheduler,
  DateTime? now,
}) async {
  final ref = PaymentRef.decode(
    NotificationPayload.decode(payload)?.paymentRef,
  );
  if (ref == null) return false;
  final db = scheduler.db;
  switch (ref) {
    case PlanPaymentRef(:final paymentId):
      await PlanRepository(db).setPaid(paymentId, paid: true, now: now);
    case RecurringRef(:final recurringId, :final epochDay):
      await RecurringRepository(db)
          .setPaid(recurringId, epochDay, paid: true, now: now);
  }
  if (notificationId != null) await scheduler.gateway.cancel(notificationId);
  await scheduler.rescheduleAll();
  return true;
}
