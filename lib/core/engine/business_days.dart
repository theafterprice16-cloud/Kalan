import '../date/local_date.dart';

/// The days a country's banks do not count as business days: its weekend
/// and its nationwide public holidays (Roadmap 26). The engine knows no
/// country; the app hands one in (the holiday data file it ships).
abstract interface class HolidayCalendar {
  /// ISO weekdays of the weekend (Monday 1 … Sunday 7).
  Set<int> get weekendDays;

  /// A nationwide public holiday. False for years the data does not
  /// cover: there only the weekend moves a date.
  bool isHoliday(LocalDate date);
}

/// The weekend without a holiday country: Saturday and Sunday, the rule
/// Kalan always had.
const Set<int> defaultWeekendDays = {DateTime.saturday, DateTime.sunday};

/// Where a due date lands after the days to skip, and why it moved.
class BusinessDayShift {
  const BusinessDayShift(this.date, {required this.skippedHoliday});

  final LocalDate date;

  /// At least one skipped day was a public holiday: the "moved for a
  /// public holiday" note. A date moved only off a weekend has none.
  final bool skippedHoliday;
}

/// The engine's one rule for moving a due date (DECISIONS 23, Roadmap 26):
/// the days to skip are the weekend (with [weekends]) and the public
/// holidays (with [holidays]) of [calendar]; a [date] on such a day moves
/// to the first later day that is neither, in one step, so a holiday next
/// to a weekend is passed at once.
///
/// Without a [calendar] the weekend is Saturday and Sunday and there are
/// no holidays: exactly the old Saturday/Sunday-to-Monday shift.
BusinessDayShift nextBusinessDay(
  LocalDate date, {
  required bool weekends,
  required bool holidays,
  HolidayCalendar? calendar,
}) {
  final weekend = calendar?.weekendDays ?? defaultWeekendDays;
  bool holiday(LocalDate d) =>
      holidays && calendar != null && calendar.isHoliday(d);
  bool skip(LocalDate d) =>
      weekends && weekend.contains(d.weekday) || holiday(d);
  var day = date;
  var skippedHoliday = false;
  // A calendar always leaves business days (the data file allows at most
  // two weekend days); the bound only guards a malformed one.
  for (var i = 0; i < 366 && skip(day); i++) {
    if (holiday(day)) skippedHoliday = true;
    day = day.addDays(1);
  }
  return BusinessDayShift(day, skippedHoliday: skippedHoliday);
}

/// Moves a Saturday or Sunday to the following Monday.
LocalDate shiftToBusinessDay(LocalDate date) =>
    nextBusinessDay(date, weekends: true, holidays: false).date;
