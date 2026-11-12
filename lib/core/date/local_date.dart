/// A calendar day without time or time zone.
///
/// Kalan reasons about days, not instants. Using UTC internally avoids
/// daylight-saving surprises when adding days or comparing dates.
class LocalDate implements Comparable<LocalDate> {
  LocalDate(this.year, this.month, this.day)
    : assert(month >= 1 && month <= 12, 'month out of range: $month'),
      assert(
        day >= 1 && day <= daysInMonth(year, month),
        'day out of range: $year-$month-$day',
      );

  factory LocalDate.fromDateTime(DateTime dateTime) =>
      LocalDate(dateTime.year, dateTime.month, dateTime.day);

  /// Days since 1970-01-01.
  factory LocalDate.fromEpochDay(int epochDay) {
    final dt = DateTime.utc(1970, 1, 1 + epochDay);
    return LocalDate(dt.year, dt.month, dt.day);
  }

  /// Builds a date, normalising [month] (may be any integer) and clamping
  /// [day] to the last day of the resulting month.
  ///
  /// `LocalDate.clamped(2026, 2, 31)` is 28 February 2026.
  factory LocalDate.clamped(int year, int month, int day) {
    final total = year * 12 + (month - 1);
    final normalizedMonth = total % 12 + 1;
    final normalizedYear = (total - (normalizedMonth - 1)) ~/ 12;
    final last = daysInMonth(normalizedYear, normalizedMonth);
    return LocalDate(
      normalizedYear,
      normalizedMonth,
      day < 1
          ? 1
          : day > last
          ? last
          : day,
    );
  }

  factory LocalDate.today() => LocalDate.fromDateTime(DateTime.now());

  final int year;
  final int month;
  final int day;

  static int daysInMonth(int year, int month) =>
      DateTime.utc(year, month + 1, 0).day;

  int get epochDay =>
      DateTime.utc(year, month, day).difference(DateTime.utc(1970)).inDays;

  /// ISO weekday: Monday is 1, Sunday is 7.
  int get weekday => DateTime.utc(year, month, day).weekday;

  bool get isWeekend =>
      weekday == DateTime.saturday || weekday == DateTime.sunday;

  LocalDate addDays(int days) => LocalDate.fromEpochDay(epochDay + days);

  /// Moves by [months], keeping [preferredDay] (defaults to [day]) when the
  /// target month has it, otherwise using the month's last day.
  LocalDate addMonths(int months, {int? preferredDay}) =>
      LocalDate.clamped(year, month + months, preferredDay ?? day);

  int daysUntil(LocalDate other) => other.epochDay - epochDay;

  DateTime toDateTime() => DateTime(year, month, day);

  bool operator <(LocalDate other) => compareTo(other) < 0;
  bool operator <=(LocalDate other) => compareTo(other) <= 0;
  bool operator >(LocalDate other) => compareTo(other) > 0;
  bool operator >=(LocalDate other) => compareTo(other) >= 0;

  @override
  int compareTo(LocalDate other) {
    if (year != other.year) return year.compareTo(other.year);
    if (month != other.month) return month.compareTo(other.month);
    return day.compareTo(other.day);
  }

  @override
  bool operator ==(Object other) =>
      other is LocalDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';
}
