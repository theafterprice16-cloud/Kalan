import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart' show Locale;
import 'package:timezone/timezone.dart' as tz;

import '../../core/date/local_date.dart';
import '../../core/money/currency.dart';
import '../../core/reminders/reminder_models.dart';
import '../../core/reminders/reminder_planner.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/plan_repository.dart';
import '../../data/repositories/recurring_repository.dart';
import '../../data/repositories/reminder_snooze_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../l10n/generated/app_localizations.dart';
import 'notification_gateway.dart';
import 'reminder_settings_store.dart';
import 'reminder_texts.dart';

/// How far ahead recurring payments are expanded; the planner keeps only
/// the soonest 60 anyway.
const _recurringHorizonDays = 400;

/// Turns stored payments and settings into scheduled notifications.
/// Every run cancels Kalan's pending reminders and schedules the list
/// again, so it is safe (and cheap) to call after any change.
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
  Future<List<PlannedReminder>> build() async {
    final input = await _input();
    if (input == null) return const [];
    return _plan(input);
  }

  /// Snoozes whose time has passed or whose payments are all paid or gone
  /// are deleted first; then Kalan's pending reminders are replaced. With
  /// the master switch off the list is empty, so every pending reminder is
  /// cancelled.
  Future<void> rescheduleAll() async {
    if (!gateway.supported) return;
    final input = await _input();
    if (input == null) {
      await gateway.replaceAll(const []);
      return;
    }
    await ReminderSnoozeRepository(db).delete(
      staleSnoozeIds(
        snoozes: input.snoozes,
        payments: input.payments,
        now: input.now,
      ),
    );
    await gateway.replaceAll(_plan(input));
  }

  /// Debug builds: the "on the day" reminder of the nearest unpaid payment
  /// (with the others due that day), buttons included, firing at
  /// [fireAt]. Null when nothing is unpaid.
  Future<PlannedReminder?> testReminder({
    required int id,
    required tz.TZDateTime fireAt,
  }) async {
    final input = await _input();
    if (input == null) return null;
    final unpaid = [
      for (final p in input.payments)
        if (!p.isPaid) p,
    ];
    if (unpaid.isEmpty) return null;
    final today = input.today;
    LocalDate? pick;
    for (final p in unpaid) {
      final better = switch (pick) {
        null => true,
        final current when current < today => p.date > current,
        final current => p.date >= today && p.date < current,
      };
      if (better) pick = p.date;
    }
    final settings = input.settings;
    return buildReminder(
      id: id,
      kind: ReminderKind.onDay,
      fireDate: pick!,
      minuteOfDay: settings.minuteOfDay,
      payments: [
        for (final p in unpaid)
          if (p.date == pick) p,
      ],
      settings: settings,
      location: input.now.location,
      texts: input.texts,
      fireAt: fireAt,
    );
  }

  List<PlannedReminder> _plan(_Input input) => planReminders(
    payments: input.payments,
    snoozes: input.snoozes,
    settings: input.settings,
    now: input.now,
    texts: input.texts,
  );

  Future<_Input?> _input() async {
    final settings = await SettingsRepository(db).get();
    if (settings == null) return null;
    final local = tz.TZDateTime.from(now(), location());
    final today = LocalDate(local.year, local.month, local.day);

    // Dates are the effective due dates the engine stored: the same day
    // the screens show (card statement and weekend shift applied).
    final payments = <ReminderPayment>[
      for (final p in await PlanRepository(db).all())
        for (final pay in p.payments)
          ReminderPayment(
            name: p.displayName,
            date: LocalDate.fromEpochDay(pay.dueDay),
            amountMinor: pay.amountMinor,
            isPaid: pay.paidAt != null,
            choice: reminderChoiceOf(
              enabled: p.plan.remindersEnabled,
              leadDays: p.plan.reminderLeadDays,
            ),
            ref: PlanPaymentRef(pay.id),
          ),
      for (final r in await RecurringRepository(db).all())
        for (final date in r.occurrences(
          today,
          today.addDays(_recurringHorizonDays),
        ))
          ReminderPayment(
            name: r.item.name,
            date: date,
            amountMinor: r.item.amountMinor,
            isPaid: r.paidDays.contains(date.epochDay),
            choice: reminderChoiceOf(
              enabled: r.item.remindersEnabled,
              leadDays: r.item.reminderLeadDays,
            ),
            ref: RecurringRef(r.item.id, date),
          ),
    ];

    final l10n = lookupAppLocalizations(localeFor(settings));
    // Month and weekday names, also in a background isolate.
    await initializeDateFormatting(l10n.localeName);
    return (
      settings: settings.reminderSettings,
      now: local,
      today: today,
      payments: payments,
      snoozes: await ReminderSnoozeRepository(db).all(),
      texts: L10nReminderTexts(
        l10n: l10n,
        currency: Currency.fromCode(settings.currencyCode),
      ),
    );
  }
}

typedef _Input = ({
  ReminderSettings settings,
  tz.TZDateTime now,
  LocalDate today,
  List<ReminderPayment> payments,
  List<ReminderSnooze> snoozes,
  ReminderTexts texts,
});
