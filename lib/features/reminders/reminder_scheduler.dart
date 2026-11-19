import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart' show Locale;
import 'package:timezone/timezone.dart' as tz;

import '../../app/format.dart' show planNameIn;
import '../../app/providers.dart' show payScheduleOf;
import '../../core/date/local_date.dart';
import '../../core/money/currency.dart';
import '../../core/reminders/reminder_models.dart';
import '../../core/reminders/reminder_planner.dart';
import '../../data/db/app_database.dart';
import '../../data/models.dart';
import '../../data/period_totals.dart';
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

  /// The payment reminders that would be scheduled right now (the payday
  /// summary: [buildPaydaySummary]).
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
    await gateway.replaceAll(_all(input));
  }

  /// Everything that would be handed to the system right now: payment
  /// reminders first, then the payday summary, then statement closing
  /// reminders, each only in the room the ones before it leave.
  Future<List<PlannedReminder>> buildAll() async {
    final input = await _input();
    if (input == null) return const [];
    return _all(input);
  }

  List<PlannedReminder> _all(_Input input) => withStatementClosings(
    withPaydaySummary(
      _plan(input),
      payday: input.payday,
      settings: input.settings,
      now: input.now,
      texts: input.texts,
    ),
    cards: input.cards,
    settings: input.settings,
    now: input.now,
    texts: input.texts,
  );

  /// The next payday summary that would be scheduled (null when it is
  /// off or reminders are off), without the payment reminders.
  Future<PlannedReminder?> buildPaydaySummary() async {
    final input = await _input();
    if (input == null) return null;
    final list = withPaydaySummary(
      const [],
      payday: input.payday,
      settings: input.settings,
      now: input.now,
      texts: input.texts,
    );
    return list.isEmpty ? null : list.single;
  }

  /// Debug builds: the "on the day" reminder of the nearest unpaid payment
  /// (with the others due that day), buttons included, firing at
  /// [fireAt]. Null when nothing is unpaid.
  Future<PlannedReminder?> testReminder({
    required int id,
    required tz.TZDateTime fireAt,
  }) async {
    final input = await _input();
    final group = input == null ? null : _nearestUnpaid(input);
    if (input == null || group == null) return null;
    return buildReminder(
      id: id,
      kind: ReminderKind.onDay,
      fireDate: group.first.date,
      minuteOfDay: input.settings.minuteOfDay,
      payments: group,
      settings: input.settings,
      location: input.now.location,
      texts: input.texts,
      fireAt: fireAt,
    );
  }

  /// Debug builds: the repeat reminder the nearest unpaid payment would
  /// get today (its kind follows today: ahead, on the day or overdue),
  /// once for each of [times], with ids from [firstId]. Empty when nothing
  /// is unpaid. Real repeats are never minutes apart; this only shows
  /// that "Paid" stops the rest.
  Future<List<PlannedReminder>> testRepeats({
    required int firstId,
    required List<tz.TZDateTime> times,
  }) async {
    final input = await _input();
    final group = input == null ? null : _nearestUnpaid(input);
    if (input == null || group == null) return const [];
    return [
      for (final (i, fireAt) in times.indexed)
        buildReminder(
          id: firstId + i,
          kind: reminderKindOn(input.today, group.first.date),
          fireDate: input.today,
          minuteOfDay: input.settings.minuteOfDay,
          payments: group,
          settings: input.settings,
          location: input.now.location,
          texts: input.texts,
          fireAt: fireAt,
        ),
    ];
  }

  /// The unpaid payments due on the nearest day (today or later first,
  /// else the latest past one); null when nothing is unpaid.
  List<ReminderPayment>? _nearestUnpaid(_Input input) {
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
    return [
      for (final p in unpaid)
        if (p.date == pick) p,
    ];
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

    final l10n = lookupAppLocalizations(localeFor(settings));
    // Month and weekday names, also in a background isolate.
    await initializeDateFormatting(l10n.localeName);

    // Dates are the effective due dates the engine stored: the same day
    // the screens show (card statement and weekend shift applied).
    final plans = await PlanRepository(db).all();
    final recurring = await RecurringRepository(db).all();
    final payments = <ReminderPayment>[
      for (final p in plans)
        for (final pay in p.payments)
          ReminderPayment(
            name: planNameIn(l10n, p),
            date: LocalDate.fromEpochDay(pay.dueDay),
            amountMinor: pay.amountMinor,
            isPaid: pay.paidAt != null,
            choice: reminderChoiceOf(
              enabled: p.plan.remindersEnabled,
              leadDays: p.plan.reminderLeadDays,
            ),
            ref: PlanPaymentRef(pay.id),
            repeat: p.plan.repeatMode,
            method: p.plan.paymentMethod,
          ),
      for (final r in recurring)
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
            repeat: r.item.repeatMode,
          ),
    ];

    // The next payday's summary, as the home screen will show it that
    // morning: the same calculation, seen from the period's first day.
    final period = nextPaydayPeriod(
      payScheduleOf(settings),
      local,
      settings.reminderMinute,
    );
    final summary = periodSummaryOn(
      plans: plans,
      recurring: recurring,
      period: period,
      today: period.start,
      incomeMinor: settings.netIncomeMinor,
    );

    return (
      settings: settings.reminderSettings,
      payday: PaydaySummary(
        date: period.start,
        paymentCount: summary.itemCount,
        totalMinor: summary.spokenForMinor,
        leftMinor: summary.leftMinor,
      ),
      now: local,
      today: today,
      payments: payments,
      cards: [
        for (final source in await db.select(db.sources).get())
          if (source.statementReminderEnabled)
            if (source.cardTerms case final terms?)
              StatementCard(
                id: source.id,
                name: source.name,
                terms: terms,
                leadDays: source.statementReminderDays,
              ),
      ],
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
  PaydaySummary payday,
  tz.TZDateTime now,
  LocalDate today,
  List<ReminderPayment> payments,
  List<StatementCard> cards,
  List<ReminderSnooze> snoozes,
  ReminderTexts texts,
});
