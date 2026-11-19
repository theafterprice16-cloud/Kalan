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
  });

  final PeriodSummary summary;

  /// Dated payments in the period, by date.
  final List<HomeEntry> entries;

  /// Unpaid past-due payments; only ever in the current period.
  final List<HomeEntry> pastDue;

  PayPeriod get period => summary.period;
  int get spokenForMinor => summary.spokenForMinor;
  int? get incomeMinor => summary.incomeMinor;
  int? get leftMinor => summary.leftMinor;
  bool get isNegative => summary.status == PeriodStatus.negative;

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
  for (final period in schedule.periodsFrom(today, count))
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
      );
    }(),
];

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
