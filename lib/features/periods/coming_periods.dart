import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/engine/engine.dart';
import '../../data/models.dart';
import '../../data/period_totals.dart';
import '../home/home_view.dart';

/// Everyone sees the same number of coming pay periods, the current one
/// included (product decision, Karar 4).
const comingPeriodCount = 6;

/// One coming pay period: its total exactly as the home screen computes
/// it, and its rows.
class ComingPeriod {
  const ComingPeriod({
    required this.summary,
    required this.entries,
    required this.pastDue,
    this.busyWeek,
    this.isCurrent = false,
  });

  final PeriodSummary summary;

  /// Dated payments in the period, by date.
  final List<HomeEntry> entries;

  /// Unpaid past-due payments; only ever in the current period.
  final List<HomeEntry> pastDue;

  /// Plan payments piled up in a few days of the period; null when not.
  /// An observation, not the tight status ([PeriodStatus.tight]).
  final BusyWeek? busyWeek;

  /// The period containing today (the first one). Its shortfall is
  /// certain ("short"); a later one's "looks short" until it comes.
  final bool isCurrent;

  PayPeriod get period => summary.period;
  int get spokenForMinor => summary.spokenForMinor;
  int? get incomeMinor => summary.incomeMinor;
  int? get leftMinor => summary.leftMinor;
  bool get isNegative => summary.status == PeriodStatus.negative;

  /// How much spoken for exceeds income; null without income or when
  /// nothing is short ([PeriodSummary.shortMinor]).
  int? get shortMinor => summary.shortMinor;

  /// What the period's list shows: past-due ones first, oldest first.
  List<HomeEntry> get rows => [...pastDue, ...entries];
}

/// [count] pay periods from the one containing [today]. Totals come from
/// [periodSummaryOn] and rows from [homeEntriesFor], the home screen's
/// own calculations, so the first period equals the home screen.
List<ComingPeriod> comingPeriods({
  required Iterable<PlanWithPayments> plans,
  required Iterable<RecurringWithMarks> recurring,
  required PaySchedule schedule,
  required LocalDate today,
  int? incomeMinor,
  int? tightThresholdMinor,
  int count = comingPeriodCount,
}) => [
  for (final (i, period) in schedule.periodsFrom(today, count).indexed)
    () {
      final rows = homeEntriesFor(
        plans: plans,
        recurring: recurring,
        period: period,
        today: today,
      );
      return ComingPeriod(
        summary: periodSummaryOn(
          plans: plans,
          recurring: recurring,
          period: period,
          today: today,
          incomeMinor: incomeMinor,
          tightThresholdMinor: tightThresholdMinor,
        ),
        entries: rows.entries,
        pastDue: rows.pastDue,
        busyWeek: busyWeekIn(plans: plans, period: period),
        isCurrent: i == 0,
      );
    }(),
];

/// The busy week of [period] from [plans]' payments: plan payments only
/// (recurring payments never count), each on the due day the engine
/// stored, paid or not. Payments paid before Kalan are left out: their
/// dates are never shown. The one data path for the chart and the
/// calendar.
BusyWeek? busyWeekIn({
  required Iterable<PlanWithPayments> plans,
  required PayPeriod period,
}) => busyWeekOf(
  period: period,
  planPayments: [
    for (final p in plans)
      for (final pay in p.payments)
        if (!pay.paidBeforeKalan)
          DatedAmount(LocalDate.fromEpochDay(pay.dueDay), pay.installmentMinor),
  ],
);

/// The coming pay periods; null while data loads or before onboarding.
/// Follows plans, payments, recurring payments, income and payday.
final comingPeriodsProvider = Provider<List<ComingPeriod>?>((ref) {
  final settings = ref.watch(settingsProvider).value;
  final plans = ref.watch(plansProvider).value;
  final recurring = ref.watch(recurringProvider).value;
  if (settings == null || plans == null || recurring == null) return null;
  return comingPeriods(
    plans: plans,
    recurring: recurring,
    schedule: payScheduleOf(settings),
    today: ref.watch(todayProvider),
    incomeMinor: settings.netIncomeMinor,
    tightThresholdMinor: settings.tightThresholdMinor,
  );
});
