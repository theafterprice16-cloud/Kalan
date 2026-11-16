import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/format.dart';
import '../../app/providers.dart';
import '../../core/engine/engine.dart';
import '../../data/period_totals.dart';
import '../../l10n/generated/app_localizations.dart';

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
    this.isPayLater = false,
    this.paymentMethod,
  });

  /// Null for an untitled "Pay later" plan: see [label].
  final String? name;
  final LocalDate date;
  final int amountMinor;
  final bool isPaid;

  final int? paymentId;
  final int? planId;
  final int? seq;
  final int? installmentCount;

  final int? recurringId;

  /// One payment on a set day: shown with its type, never "1/1".
  final bool isPayLater;

  /// The plan's payment method; null when not set (and for recurring
  /// payments): no icon then.
  final PaymentMethod? paymentMethod;

  bool get isRecurring => recurringId != null;

  /// The name to show: [name], or "Pay later · Dec 14" in [l10n]'s
  /// language for an untitled "Pay later" plan.
  String label(AppLocalizations l10n) => name ?? payLaterAutoName(l10n, date);
}

class HomeView {
  const HomeView({
    required this.summary,
    required this.entries,
    required this.pastDue,
    required this.today,
    this.tightThresholdMinor,
  });

  final PeriodSummary summary;

  /// Everything dated in the current period, by date.
  final List<HomeEntry> entries;

  /// Unpaid plan payments whose due date is before today, oldest first.
  /// All of them count in this period. Recurring payments are not
  /// included (their past occurrences are never marked one by one).
  final List<HomeEntry> pastDue;

  /// Whether any past-due payment comes from an earlier period.
  bool get pastDueFromEarlier =>
      pastDue.any((e) => !summary.period.contains(e.date));
  final LocalDate today;
  final int? tightThresholdMinor;
}

int _byDateThenName(HomeEntry a, HomeEntry b) {
  final c = a.date.compareTo(b.date);
  return c != 0
      ? c
      : (a.name ?? '').toLowerCase().compareTo((b.name ?? '').toLowerCase());
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
  final pastDue = <HomeEntry>[];
  // Every plan payment counts on [countingDate]: past-due ones in this
  // period, payments paid "today" from the past-due list on that day,
  // everything else on its due date. Paid before Kalan: counted like any
  // paid payment, never listed (and, being paid, never past due). The
  // total comes from [periodSummaryOn], as for the payday summary.
  for (final p in plans) {
    for (final pay in p.payments) {
      final due = LocalDate.fromEpochDay(pay.dueDay);
      final isPaid = pay.paidAt != null;
      final countsOn = countingDate(
        dueDate: due,
        isPaid: isPaid,
        paidOn: pay.paidOnDay == null
            ? null
            : LocalDate.fromEpochDay(pay.paidOnDay!),
        today: today,
      );
      if (pay.paidBeforeKalan) continue;
      final entry = HomeEntry(
        name: p.ownName,
        date: due,
        amountMinor: pay.amountMinor,
        isPaid: isPaid,
        paymentId: pay.id,
        planId: p.plan.id,
        seq: pay.seq,
        installmentCount: p.plan.installmentCount,
        isPayLater: p.isPayLater,
        paymentMethod: p.plan.paymentMethod,
      );
      // Past due: only in its own section, never twice.
      if (isPastDue(dueDate: due, isPaid: isPaid, today: today)) {
        pastDue.add(entry);
      } else if (period.contains(countsOn)) {
        entries.add(entry);
      }
    }
  }
  for (final r in recurring) {
    for (final date in r.occurrences(period.start, period.end)) {
      final entry = HomeEntry(
        name: r.item.name,
        date: date,
        amountMinor: r.item.amountMinor,
        isPaid: r.paidDays.contains(date.epochDay),
        recurringId: r.item.id,
      );
      entries.add(entry);
    }
  }
  entries.sort(_byDateThenName);
  pastDue.sort(_byDateThenName);

  return HomeView(
    summary: periodSummaryOn(
      plans: plans,
      recurring: recurring,
      period: period,
      today: today,
      incomeMinor: settings.netIncomeMinor,
      tightThresholdMinor: settings.tightThresholdMinor,
    ),
    entries: entries,
    pastDue: pastDue,
    today: today,
    tightThresholdMinor: settings.tightThresholdMinor,
  );
});
