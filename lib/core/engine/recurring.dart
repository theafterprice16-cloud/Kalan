import '../date/local_date.dart';

enum Recurrence { weekly, biweekly, monthly, yearly }

/// Occurrences of a recurring payment that starts on [start], within
/// `[from, toExclusive)`, never after [endDate] (inclusive).
List<LocalDate> recurringOccurrences({
  required LocalDate start,
  required Recurrence recurrence,
  required LocalDate from,
  required LocalDate toExclusive,
  LocalDate? endDate,
}) {
  LocalDate nth(int i) => switch (recurrence) {
    Recurrence.weekly => start.addDays(7 * i),
    Recurrence.biweekly => start.addDays(14 * i),
    Recurrence.monthly => start.addMonths(i, preferredDay: start.day),
    Recurrence.yearly => LocalDate.clamped(
      start.year + i,
      start.month,
      start.day,
    ),
  };

  // Jump close to [from] instead of iterating from the start.
  var i = 0;
  if (from > start) {
    final days = start.daysUntil(from);
    final months = (from.year - start.year) * 12 + (from.month - start.month);
    i = switch (recurrence) {
      Recurrence.weekly => days ~/ 7,
      Recurrence.biweekly => days ~/ 14,
      Recurrence.monthly => months - 1,
      Recurrence.yearly => from.year - start.year - 1,
    };
    if (i < 0) i = 0;
  }

  final result = <LocalDate>[];
  while (true) {
    final date = nth(i);
    if (date >= toExclusive) break;
    if (endDate != null && date > endDate) break;
    if (date >= from) result.add(date);
    i++;
  }
  return result;
}
