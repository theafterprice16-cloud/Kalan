import '../date/local_date.dart';
import 'past_due.dart';
import 'pay_period.dart';
import 'payment_method.dart';

/// "Keep in account" (18): what will come out of each source by which day,
/// from the dated payments the engine already stored. Kalan never knows a
/// balance; this is only the money that leaves, so nothing here asks for,
/// keeps or guesses one.

/// One dated payment as the forecast sees it. [dueDate] is the effective
/// due date the engine stored (statement, due day and weekend shift
/// already applied), the same day every screen shows.
class ChargeItem {
  const ChargeItem({
    required this.planId,
    required this.dueDate,
    required this.amountMinor,
    required this.isPaid,
    required this.method,
    this.paymentId,
    this.name,
    this.sourceId,
    this.paidOn,
    this.paidBeforeKalan = false,
    this.isOwnCardInstallment = false,
  });

  final int planId;
  final int? paymentId;

  /// The plan's own name; null for an untitled "Pay later" plan (screens
  /// show a label in the app language instead).
  final String? name;

  /// Where it is taken from; null when not chosen.
  final int? sourceId;
  final PaymentMethod? method;
  final LocalDate dueDate;
  final int amountMinor;
  final bool isPaid;

  /// The day it was paid, only when marked "today" from the past-due list
  /// ([countingDate]).
  final LocalDate? paidOn;

  /// Paid before the plan was added to Kalan: never listed.
  final bool paidBeforeKalan;

  /// A card plan's installment taken from its own card: it is on the
  /// card's statements (16), not in this list (decision 8).
  final bool isOwnCardInstallment;

  /// Whether it belongs in the forecast at all: automatic only (decision
  /// 5), never paid before Kalan, never the card's own installments.
  bool get counts =>
      method == PaymentMethod.automatic &&
      !paidBeforeKalan &&
      !isOwnCardInstallment;

  /// The day it counts on: the home screen's one rule ([countingDate]).
  /// Unpaid and past due: today (decision 7).
  LocalDate countsOn(LocalDate today) => countingDate(
    dueDate: dueDate,
    isPaid: isPaid,
    paidOn: paidOn,
    today: today,
  );
}

/// One row of the list: the payments of one day. Paid payments of a day
/// are their own row ([isPaid]), shown muted with a tick and never added
/// to the running total (decision 6). Unpaid ones are gathered in one row
/// (decision 9).
class ChargeRow {
  const ChargeRow({
    required this.date,
    required this.items,
    required this.isPaid,
    required this.amountMinor,
    required this.cumulativeMinor,
    required this.includesPastDue,
  });

  final LocalDate date;

  /// By name.
  final List<ChargeItem> items;
  final bool isPaid;

  /// The day's sum.
  final int amountMinor;

  /// Unpaid amounts from the period's start up to and including this row;
  /// for a paid row, the running total before it (unchanged).
  final int cumulativeMinor;

  /// An unpaid payment past its due date moved to today (clock icon).
  final bool includesPastDue;
}

/// One pay period of one source.
class ChargePeriod {
  const ChargePeriod({required this.period, required this.rows});

  final PayPeriod period;

  /// By date; on one day the paid row comes first.
  final List<ChargeRow> rows;

  /// The next unpaid row: "Next withdrawal".
  ChargeRow? get nextCharge {
    for (final r in rows) {
      if (!r.isPaid) return r;
    }
    return null;
  }

  /// Everything still to come out in the period.
  int get totalMinor => rows.isEmpty ? 0 : rows.last.cumulativeMinor;

  /// Nothing left to come out (paid rows may still be listed).
  bool get hasNothingDue => nextCharge == null;
}

/// This period and the next one of one source.
class SourceCharges {
  const SourceCharges({
    required this.sourceId,
    required this.current,
    required this.next,
  });

  final int sourceId;
  final ChargePeriod current;
  final ChargePeriod next;
}

/// The whole forecast.
class ChargeForecast {
  const ChargeForecast({required this.bySource, required this.unassigned});

  /// Sources with at least one automatic payment: one still unpaid, or
  /// any in this or the next period.
  final Map<int, SourceCharges> bySource;

  /// Automatic plans without a source, each by its next unpaid payment,
  /// soonest first (decision 10).
  final List<ChargeItem> unassigned;

  /// [sourceId]'s periods, or empty ones when nothing automatic comes out
  /// of it.
  SourceCharges of(int sourceId, PayPeriod current, PayPeriod next) =>
      bySource[sourceId] ??
      SourceCharges(
        sourceId: sourceId,
        current: ChargePeriod(period: current, rows: const []),
        next: ChargePeriod(period: next, rows: const []),
      );
}

/// What comes out of each source in [current] and [next] (the home
/// screen's periods), as seen on [today].
ChargeForecast chargeForecast({
  required Iterable<ChargeItem> items,
  required PayPeriod current,
  required PayPeriod next,
  required LocalDate today,
}) {
  final bySourceItems = <int, List<ChargeItem>>{};
  final unassignedByPlan = <int, ChargeItem>{};
  for (final item in items) {
    if (!item.counts) continue;
    final source = item.sourceId;
    if (source == null) {
      if (item.isPaid) continue;
      final seen = unassignedByPlan[item.planId];
      if (seen == null || item.dueDate < seen.dueDate) {
        unassignedByPlan[item.planId] = item;
      }
      continue;
    }
    (bySourceItems[source] ??= []).add(item);
  }

  final bySource = <int, SourceCharges>{};
  for (final MapEntry(key: source, value: list) in bySourceItems.entries) {
    final charges = SourceCharges(
      sourceId: source,
      current: _period(current, list, today),
      next: _period(next, list, today),
    );
    final hasAny =
        list.any((i) => !i.isPaid) ||
        charges.current.rows.isNotEmpty ||
        charges.next.rows.isNotEmpty;
    if (hasAny) bySource[source] = charges;
  }

  final unassigned = unassignedByPlan.values.toList()..sort(_byDateThenName);
  return ChargeForecast(bySource: bySource, unassigned: unassigned);
}

ChargePeriod _period(
  PayPeriod period,
  List<ChargeItem> items,
  LocalDate today,
) {
  // Day -> (paid, unpaid).
  final days = <LocalDate, (List<ChargeItem>, List<ChargeItem>)>{};
  for (final item in items) {
    final day = item.countsOn(today);
    if (!period.contains(day)) continue;
    final (paid, unpaid) = days[day] ??= (<ChargeItem>[], <ChargeItem>[]);
    (item.isPaid ? paid : unpaid).add(item);
  }
  final rows = <ChargeRow>[];
  var running = 0;
  for (final day in days.keys.toList()..sort()) {
    final (paid, unpaid) = days[day]!;
    if (paid.isNotEmpty) {
      rows.add(
        ChargeRow(
          date: day,
          items: paid..sort(_byName),
          isPaid: true,
          amountMinor: _sum(paid),
          cumulativeMinor: running,
          includesPastDue: false,
        ),
      );
    }
    if (unpaid.isNotEmpty) {
      final amount = _sum(unpaid);
      running += amount;
      rows.add(
        ChargeRow(
          date: day,
          items: unpaid..sort(_byName),
          isPaid: false,
          amountMinor: amount,
          cumulativeMinor: running,
          includesPastDue: unpaid.any((i) => i.dueDate < today),
        ),
      );
    }
  }
  return ChargePeriod(period: period, rows: rows);
}

int _sum(List<ChargeItem> items) =>
    items.fold(0, (sum, i) => sum + i.amountMinor);

int _byName(ChargeItem a, ChargeItem b) {
  final c = (a.name ?? '').toLowerCase().compareTo(
    (b.name ?? '').toLowerCase(),
  );
  return c != 0 ? c : a.dueDate.compareTo(b.dueDate);
}

int _byDateThenName(ChargeItem a, ChargeItem b) {
  final c = a.dueDate.compareTo(b.dueDate);
  return c != 0 ? c : _byName(a, b);
}
