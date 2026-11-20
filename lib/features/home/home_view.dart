import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/format.dart';
import '../../app/providers.dart';
import '../../core/engine/engine.dart';
import '../../data/db/app_database.dart' show PaymentRow;
import '../../data/models.dart';
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
    this.extraFeeMinor,
    this.extraFeeNote,
    this.canHaveExtraFee = false,
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

  /// The payment's extra fee (21), shown as a note next to [amountMinor],
  /// which stays the payment's own amount. Null when none (and for
  /// recurring payments).
  final int? extraFeeMinor;
  final String? extraFeeNote;

  /// Whether the payment can take, change or lose an extra fee
  /// ([canHaveExtraFee] in the engine, the one rule).
  final bool canHaveExtraFee;

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

/// The row of one plan payment, dated on its stored (effective) due day.
HomeEntry planEntryOf(PlanWithPayments p, PaymentRow pay) => HomeEntry(
  name: p.ownName,
  date: LocalDate.fromEpochDay(pay.dueDay),
  amountMinor: pay.amountMinor,
  isPaid: pay.paidAt != null,
  paymentId: pay.id,
  planId: p.plan.id,
  seq: pay.seq,
  installmentCount: p.plan.installmentCount,
  isPayLater: p.isPayLater,
  paymentMethod: p.plan.paymentMethod,
  extraFeeMinor: pay.extraFeeMinor,
  extraFeeNote: pay.extraFeeNote,
  canHaveExtraFee: canHaveExtraFee(
    status: p.status,
    isPaid: pay.isPaid,
    paidBeforeKalan: pay.paidBeforeKalan,
  ),
);

/// Home order: by date, then name.
int compareHomeEntries(HomeEntry a, HomeEntry b) => _byDateThenName(a, b);

int _byDateThenName(HomeEntry a, HomeEntry b) {
  final c = a.date.compareTo(b.date);
  return c != 0
      ? c
      : (a.name ?? '').toLowerCase().compareTo((b.name ?? '').toLowerCase());
}

/// The rows of [period] as seen on [today]: its dated payments (plan
/// payments by [countingDate], recurring occurrences) and, only when
/// [period] is the current one, the unpaid past-due plan payments, which
/// all count in it. Payments paid before Kalan are never listed. Both
/// lists by date, then name. The one row rule for the home screen and the
/// coming pay periods.
({List<HomeEntry> entries, List<HomeEntry> pastDue}) homeEntriesFor({
  required Iterable<PlanWithPayments> plans,
  required Iterable<RecurringWithMarks> recurring,
  required PayPeriod period,
  required LocalDate today,
}) {
  final entries = <HomeEntry>[];
  final pastDue = <HomeEntry>[];
  final isCurrent = period.contains(today);
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
      final entry = planEntryOf(p, pay);
      // Past due: only in its own section, never twice, and only in the
      // current period (where it counts).
      if (isPastDue(dueDate: due, isPaid: isPaid, today: today)) {
        if (isCurrent) pastDue.add(entry);
      } else if (period.contains(countsOn)) {
        entries.add(entry);
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
  pastDue.sort(_byDateThenName);
  return (entries: entries, pastDue: pastDue);
}

/// Null while data loads or before onboarding.
final homeViewProvider = Provider<HomeView?>((ref) {
  final settings = ref.watch(settingsProvider).value;
  final plans = ref.watch(plansProvider).value;
  final recurring = ref.watch(recurringProvider).value;
  if (settings == null || plans == null || recurring == null) return null;
  final today = ref.watch(todayProvider);
  final period = payScheduleOf(settings).periodContaining(today);
  final rows = homeEntriesFor(
    plans: plans,
    recurring: recurring,
    period: period,
    today: today,
  );

  return HomeView(
    summary: periodSummaryOn(
      plans: plans,
      recurring: recurring,
      period: period,
      today: today,
      incomeMinor: settings.netIncomeMinor,
      tightThresholdMinor: settings.tightThresholdMinor,
    ),
    entries: rows.entries,
    pastDue: rows.pastDue,
    today: today,
    tightThresholdMinor: settings.tightThresholdMinor,
  );
});
