import 'package:intl/date_symbol_data_local.dart' show dateTimeSymbolMap;

import '../../core/engine/engine.dart';
import '../../data/models.dart';
import '../home/home_view.dart';

/// How one payment looks on the calendar.
enum CalendarStatus { pending, paid, late }

/// The one mark a day cell shows. When a day has several payments the
/// strongest wins: late > pending > paid.
enum CalendarMark { none, paid, pending, late }

/// One payment on its calendar day.
class CalendarPayment {
  const CalendarPayment(this.entry, this.status);

  final HomeEntry entry;
  final CalendarStatus status;
}

/// Everything the calendar knows about one day of a month.
class CalendarDay {
  const CalendarDay({
    required this.date,
    required this.payments,
    required this.isPayday,
  });

  final LocalDate date;

  /// By name, as on the home screen.
  final List<CalendarPayment> payments;

  /// A pay period starts on this day.
  final bool isPayday;

  int _count(CalendarStatus s) => payments.where((p) => p.status == s).length;
  int get lateCount => _count(CalendarStatus.late);
  int get pendingCount => _count(CalendarStatus.pending);
  int get paidCount => _count(CalendarStatus.paid);

  /// Sum of every payment due this day, paid or not.
  int get totalMinor => payments.fold(0, (sum, p) => sum + p.entry.amountMinor);

  CalendarMark get mark {
    if (lateCount > 0) return CalendarMark.late;
    if (pendingCount > 0) return CalendarMark.pending;
    if (paidCount > 0) return CalendarMark.paid;
    return CalendarMark.none;
  }
}

/// A calendar month, `month` 1-12.
class CalendarMonth {
  const CalendarMonth(this.year, this.month);

  factory CalendarMonth.of(LocalDate date) =>
      CalendarMonth(date.year, date.month);

  final int year;
  final int month;

  LocalDate get first => LocalDate(year, month, 1);
  int get dayCount => LocalDate.daysInMonth(year, month);

  /// [months] later (or earlier when negative); crosses years.
  CalendarMonth add(int months) {
    final total = year * 12 + (month - 1) + months;
    return CalendarMonth(total ~/ 12, total % 12 + 1);
  }

  /// Whole months from this one to [other].
  int monthsUntil(CalendarMonth other) =>
      (other.year * 12 + other.month) - (year * 12 + month);

  bool operator <(CalendarMonth other) => monthsUntil(other) > 0;
  bool operator >(CalendarMonth other) => monthsUntil(other) < 0;

  @override
  bool operator ==(Object other) =>
      other is CalendarMonth && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);

  @override
  String toString() => 'CalendarMonth($year-$month)';
}

/// How far back the calendar goes from today's month.
const calendarMonthsBack = 12;

/// How far ahead it always goes, even with no later payments.
const calendarMinMonthsAhead = 6;

/// The months the calendar can show: twelve back from [today]'s month,
/// forward to the month of the last known payment (at least six ahead).
/// Open-ended recurring payments do not stretch the range.
({CalendarMonth first, CalendarMonth last}) calendarRange({
  required Iterable<PlanWithPayments> plans,
  required Iterable<RecurringWithMarks> recurring,
  required LocalDate today,
}) {
  final current = CalendarMonth.of(today);
  var last = current.add(calendarMinMonthsAhead);
  void reach(LocalDate date) {
    final m = CalendarMonth.of(date);
    if (m > last) last = m;
  }

  for (final p in plans) {
    for (final pay in p.payments) {
      reach(LocalDate.fromEpochDay(pay.dueDay));
    }
  }
  for (final r in recurring) {
    final end = r.end;
    if (end != null) reach(end);
  }
  return (first: current.add(-calendarMonthsBack), last: last);
}

/// Days of [month] that have a payment or a payday, as seen on [today].
///
/// Dates are the ones the engine stored: a plan payment sits on its
/// effective due day (a late one too: the calendar never moves it to
/// today), a recurring payment on its occurrence. Payments paid before
/// Kalan are never listed. A plan payment is late when [isPastDue]. A
/// recurring occurrence is late only inside the current pay period, as
/// on the home screen; earlier unmarked ones are never late (decision
/// 24a) and show as plain payments. Paydays are the starts of
/// [schedule]'s pay periods. Days with neither are left out.
Map<LocalDate, CalendarDay> calendarMonth({
  required Iterable<PlanWithPayments> plans,
  required Iterable<RecurringWithMarks> recurring,
  required PaySchedule schedule,
  required CalendarMonth month,
  required LocalDate today,
}) {
  final start = month.first;
  final end = month.add(1).first;
  bool inMonth(LocalDate d) => d >= start && d < end;
  final current = schedule.periodContaining(today);

  final byDay = <LocalDate, List<CalendarPayment>>{};
  void put(HomeEntry e, CalendarStatus s) =>
      (byDay[e.date] ??= []).add(CalendarPayment(e, s));

  for (final p in plans) {
    for (final pay in p.payments) {
      if (pay.paidBeforeKalan) continue;
      final due = LocalDate.fromEpochDay(pay.dueDay);
      if (!inMonth(due)) continue;
      final e = planEntryOf(p, pay);
      put(
        e,
        e.isPaid
            ? CalendarStatus.paid
            : isPastDue(dueDate: due, isPaid: false, today: today)
            ? CalendarStatus.late
            : CalendarStatus.pending,
      );
    }
  }
  for (final r in recurring) {
    for (final date in r.occurrences(start, end)) {
      final paid = r.paidDays.contains(date.epochDay);
      put(
        HomeEntry(
          name: r.item.name,
          date: date,
          amountMinor: r.item.amountMinor,
          isPaid: paid,
          recurringId: r.item.id,
        ),
        paid
            ? CalendarStatus.paid
            : date < today && current.contains(date)
            ? CalendarStatus.late
            : CalendarStatus.pending,
      );
    }
  }

  final paydays = <LocalDate>{};
  var period = schedule.periodContaining(start);
  while (period.start < end) {
    if (inMonth(period.start)) paydays.add(period.start);
    period = schedule.next(period);
  }

  final days = <LocalDate>{...byDay.keys, ...paydays}.toList()..sort();
  return {
    for (final d in days)
      d: CalendarDay(
        date: d,
        payments: (byDay[d] ?? [])
          ..sort((a, b) => compareHomeEntries(a.entry, b.entry)),
        isPayday: paydays.contains(d),
      ),
  };
}

/// The first day of the week for a region, as a [DateTime] weekday
/// (1 Monday ... 7 Sunday), from intl's locale data: Sunday for the US,
/// Monday for Turkey. Tries language and region, then language alone;
/// null when intl does not know either.
int? firstWeekdayFor(String languageCode, [String? countryCode]) {
  final symbols = dateTimeSymbolMap();
  final data =
      (countryCode == null || countryCode.isEmpty
          ? null
          : symbols['${languageCode}_$countryCode']) ??
      symbols[languageCode];
  // intl counts from Monday = 0.
  return data == null ? null : data.FIRSTDAYOFWEEK + 1;
}

/// The days a month grid shows, whole weeks starting on [firstWeekday]
/// (1 Monday ... 7 Sunday): the month's days with the neighbouring
/// months' days that fill its first and last week.
List<LocalDate> calendarGridDays(CalendarMonth month, int firstWeekday) {
  final first = month.first;
  final lead = (first.weekday - firstWeekday + 7) % 7;
  final start = first.addDays(-lead);
  final shown = lead + month.dayCount;
  final weeks = (shown + 6) ~/ 7;
  return [for (var i = 0; i < weeks * 7; i++) start.addDays(i)];
}
