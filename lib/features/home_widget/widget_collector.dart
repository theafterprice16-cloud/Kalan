import '../../app/format.dart' show planNameIn;
import '../../app/providers.dart' show payScheduleOf;
import '../../core/date/local_date.dart';
import '../../core/widget/widget_snapshot.dart';
import '../../data/db/app_database.dart';
import '../../data/models.dart';
import '../../data/period_totals.dart';
import '../../data/repositories/plan_repository.dart';
import '../../data/repositories/recurring_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../l10n/generated/app_localizations.dart';

/// How far ahead recurring payments are looked at for the next rows.
const _recurringHorizonDays = 400;

/// The widget's input from stored data, read the way the reminders read
/// it ([ReminderScheduler]); null [settings]: setup not finished.
Future<WidgetInput> readWidgetInput(
  AppDatabase db, {
  required LocalDate today,
  required AppLocalizations l10n,
}) async {
  final settings = await SettingsRepository(db).get();
  if (settings == null) return const WidgetSetupInput();
  return widgetInputOf(
    settings: settings,
    plans: await PlanRepository(db).all(),
    recurring: await RecurringRepository(db).all(),
    today: today,
    l10n: l10n,
  );
}

/// Today and the next 7 days, each as the home screen would show it on
/// that day if nothing changes until then: the period containing the day
/// and its total ([periodSummaryOn], the home screen's and the payday
/// summary's one calculation: a payment still unpaid when its day has
/// passed counts in that day's period), and the unpaid payments due that
/// day or later. A payday inside the week starts the new period on its
/// own record, so the widget turns over at midnight without the app.
WidgetInput widgetInputOf({
  required SettingsRow settings,
  required List<PlanWithPayments> plans,
  required List<RecurringWithMarks> recurring,
  required LocalDate today,
  required AppLocalizations l10n,
}) {
  if (plans.isEmpty && recurring.isEmpty) return const WidgetNoPaymentsInput();
  final schedule = payScheduleOf(settings);
  final payments = _payments(plans, recurring, today, l10n);
  final pastDueDays = [
    for (final p in plans)
      for (final pay in p.payments)
        if (!pay.isPaid) LocalDate.fromEpochDay(pay.dueDay),
  ];
  return WidgetDaysInput([
    for (var i = 0; i < widgetDayCount; i++)
      if (today.addDays(i) case final day)
        WidgetDayInput(
          date: day,
          summary: periodSummaryOn(
            plans: plans,
            recurring: recurring,
            period: schedule.periodContaining(day),
            today: day,
            incomeMinor: settings.netIncomeMinor,
          ),
          upcoming: [
            for (final p in payments)
              if (p.date >= day) p,
          ].take(widgetMaxRows).toList(),
          lock: lockDayCounts(
            day: day,
            upcoming: [for (final p in payments) p.date],
            planDueDays: pastDueDays,
          ),
        ),
  ]);
}

/// What the Lock Screen widget counts on [day] (Roadmap 32), as the app
/// would see it then if nothing changes: [upcoming] holds the due dates of
/// every unpaid payment due today or later, plan and recurring, sorted
/// ([_payments]); [planDueDays] the due dates of every unpaid plan payment
/// that counts (nothing on hold or closed), past ones included. A plan
/// payment due before [day] is past due; a recurring one never is (the
/// home screen's "Past due" list).
LockDayCounts lockDayCounts({
  required LocalDate day,
  required List<LocalDate> upcoming,
  required List<LocalDate> planDueDays,
}) {
  final later = [
    for (final d in upcoming)
      if (d > day) d,
  ];
  final next = later.isEmpty ? null : later.reduce((a, b) => a < b ? a : b);
  return LockDayCounts(
    today: upcoming.where((d) => d == day).length,
    pastDue: planDueDays.where((d) => d < day).length,
    nextDate: next,
    nextCount: next == null ? 0 : later.where((d) => d == next).length,
  );
}

/// Every unpaid payment due today or later, soonest first, then by name:
/// plan payments that count ([PlanWithPayments.payments]: nothing on hold
/// or closed; never one paid before Kalan, being paid) on their stored
/// due day, and recurring occurrences. Past-due payments are not "next";
/// they stay on the home screen's own list.
List<WidgetPayment> _payments(
  List<PlanWithPayments> plans,
  List<RecurringWithMarks> recurring,
  LocalDate today,
  AppLocalizations l10n,
) {
  final list = <WidgetPayment>[
    for (final p in plans)
      for (final pay in p.payments)
        if (!pay.isPaid && LocalDate.fromEpochDay(pay.dueDay) >= today)
          WidgetPayment(
            name: planNameIn(l10n, p),
            date: LocalDate.fromEpochDay(pay.dueDay),
            // As the home screen row shows it: with its fee (22).
            amountMinor: pay.installmentMinor,
          ),
    for (final r in recurring)
      for (final date in r.occurrences(
        today,
        today.addDays(_recurringHorizonDays),
      ))
        if (!r.paidDays.contains(date.epochDay))
          WidgetPayment(
            name: r.item.name,
            date: date,
            amountMinor: r.item.amountMinor,
          ),
  ]..sort(_byDateThenName);
  return list;
}

int _byDateThenName(WidgetPayment a, WidgetPayment b) {
  final c = a.date.compareTo(b.date);
  return c != 0 ? c : a.name.toLowerCase().compareTo(b.name.toLowerCase());
}
