import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/engine/engine.dart';

/// One row on the home screen: a plan payment or a recurring occurrence.
class HomeEntry {
  const HomeEntry({
    required this.name,
    required this.date,
    required this.amountMinor,
    required this.isPaid,
    this.paymentId,
    this.planId,
    this.seq,
    this.installmentCount,
    this.recurringId,
  });

  final String name;
  final LocalDate date;
  final int amountMinor;
  final bool isPaid;

  final int? paymentId;
  final int? planId;
  final int? seq;
  final int? installmentCount;

  final int? recurringId;

  bool get isRecurring => recurringId != null;
}

class HomeView {
  const HomeView({
    required this.summary,
    required this.entries,
    required this.overdue,
    required this.today,
    this.tightThresholdMinor,
  });

  final PeriodSummary summary;

  /// Everything dated in the current period, by date.
  final List<HomeEntry> entries;

  /// Unpaid plan payments dated before the current period.
  final List<HomeEntry> overdue;
  final LocalDate today;
  final int? tightThresholdMinor;
}

int _byDateThenName(HomeEntry a, HomeEntry b) {
  final c = a.date.compareTo(b.date);
  return c != 0 ? c : a.name.toLowerCase().compareTo(b.name.toLowerCase());
}

/// Null while data loads or before onboarding.
final homeViewProvider = Provider<HomeView?>((ref) {
  final settings = ref.watch(settingsProvider).value;
  final plans = ref.watch(plansProvider).value;
  final recurring = ref.watch(recurringProvider).value;
  if (settings == null || plans == null || recurring == null) return null;
  final today = ref.watch(todayProvider);
  final period = payScheduleOf(settings).periodContaining(today);

  final entries = <HomeEntry>[];
  final overdue = <HomeEntry>[];
  for (final p in plans) {
    for (final pay in p.payments) {
      final date = LocalDate.fromEpochDay(pay.dueDay);
      final entry = HomeEntry(
        name: p.displayName,
        date: date,
        amountMinor: pay.amountMinor,
        isPaid: pay.paidAt != null,
        paymentId: pay.id,
        planId: p.plan.id,
        seq: pay.seq,
        installmentCount: p.plan.installmentCount,
      );
      if (period.contains(date)) {
        entries.add(entry);
      } else if (isOverdue(date: date, isPaid: entry.isPaid, current: period)) {
        overdue.add(entry);
      }
    }
  }
  for (final r in recurring) {
    for (final date in r.occurrences(period.start, period.end)) {
      entries.add(
        HomeEntry(
          name: r.item.name,
          date: date,
          amountMinor: r.item.amountMinor,
          isPaid: r.paidDays.contains(date.epochDay),
          recurringId: r.item.id,
        ),
      );
    }
  }
  entries.sort(_byDateThenName);
  overdue.sort(_byDateThenName);

  return HomeView(
    summary: summarizePeriod(
      period: period,
      items: [for (final e in entries) DatedAmount(e.date, e.amountMinor)],
      incomeMinor: settings.netIncomeMinor,
      tightThresholdMinor: settings.tightThresholdMinor,
    ),
    entries: entries,
    overdue: overdue,
    today: today,
    tightThresholdMinor: settings.tightThresholdMinor,
  );
});

/// Every payment due on [date]: plan payments and recurring occurrences.
/// Opened from a reminder ("payments of the day").
final dayEntriesProvider = Provider.family<List<HomeEntry>?, LocalDate>((
  ref,
  date,
) {
  final plans = ref.watch(plansProvider).value;
  final recurring = ref.watch(recurringProvider).value;
  if (plans == null || recurring == null) return null;
  final entries = <HomeEntry>[
    for (final p in plans)
      for (final pay in p.payments)
        if (pay.dueDay == date.epochDay)
          HomeEntry(
            name: p.displayName,
            date: date,
            amountMinor: pay.amountMinor,
            isPaid: pay.paidAt != null,
            paymentId: pay.id,
            planId: p.plan.id,
            seq: pay.seq,
            installmentCount: p.plan.installmentCount,
          ),
    for (final r in recurring)
      for (final d in r.occurrences(date, date.addDays(1)))
        HomeEntry(
          name: r.item.name,
          date: d,
          amountMinor: r.item.amountMinor,
          isPaid: r.paidDays.contains(d.epochDay),
          recurringId: r.item.id,
        ),
  ]..sort(_byDateThenName);
  return entries;
});
