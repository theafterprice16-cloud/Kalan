import 'package:timezone/timezone.dart' as tz;

import '../date/local_date.dart';

/// The real moment a local wall-clock time happens in [location].
///
/// "09:00 on 29 March" stays 09:00 across daylight-saving changes; when
/// the device moves to another zone, rescheduling with the new location
/// keeps it at 09:00 there. A time that does not exist (inside a
/// spring-forward gap) moves forward to the next valid instant.
tz.TZDateTime localWallClock(
  LocalDate date,
  int minuteOfDay,
  tz.Location location,
) => tz.TZDateTime(
  location,
  date.year,
  date.month,
  date.day,
  minuteOfDay ~/ 60,
  minuteOfDay % 60,
);
