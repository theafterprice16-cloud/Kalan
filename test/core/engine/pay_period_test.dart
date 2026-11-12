import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/engine/engine.dart';

import '../date/local_date_test.dart' show d;

void main() {
  group('monthly periods', () {
    final cases = <(int, String, String, String)>[
      // payday, date, expected start, expected end (exclusive)
      (15, '2026-11-12', '2026-10-15', '2026-11-15'),
      (15, '2026-11-15', '2026-11-15', '2026-12-15'),
      (15, '2026-11-14', '2026-10-15', '2026-11-15'),
      (1, '2026-12-31', '2026-12-01', '2027-01-01'),
      (31, '2026-02-10', '2026-01-31', '2026-02-28'),
      (31, '2026-02-28', '2026-02-28', '2026-03-31'),
      (30, '2026-03-01', '2026-02-28', '2026-03-30'),
      (29, '2028-02-29', '2028-02-29', '2028-03-29'),
      (29, '2027-02-28', '2027-02-28', '2027-03-29'),
      (31, '2026-04-30', '2026-04-30', '2026-05-31'),
      (31, '2027-01-15', '2026-12-31', '2027-01-31'),
      // Payday on a weekend is not moved (14 Nov 2026 is a Saturday).
      (14, '2026-11-14', '2026-11-14', '2026-12-14'),
    ];
    for (final (day, date, start, end) in cases) {
      test('day $day, $date -> [$start, $end)', () {
        final p = PaySchedule.monthly(day).periodContaining(d(date));
        expect(p, PayPeriod(d(start), d(end)));
        expect(p.contains(d(date)), isTrue);
      });
    }
  });

  group('biweekly and weekly periods', () {
    final cases = <(PaySchedule, String, String, String)>[
      (
        PaySchedule.biweekly(d('2026-11-06')),
        '2026-11-12',
        '2026-11-06',
        '2026-11-20',
      ),
      (
        PaySchedule.biweekly(d('2026-11-06')),
        '2026-11-20',
        '2026-11-20',
        '2026-12-04',
      ),
      // Dates before the anchor still resolve.
      (
        PaySchedule.biweekly(d('2026-11-06')),
        '2026-11-05',
        '2026-10-23',
        '2026-11-06',
      ),
      (
        PaySchedule.biweekly(d('2026-12-25')),
        '2027-01-08',
        '2027-01-08',
        '2027-01-22',
      ),
      (
        PaySchedule.weekly(d('2026-11-13')),
        '2026-11-12',
        '2026-11-06',
        '2026-11-13',
      ),
      (
        PaySchedule.weekly(d('2026-11-13')),
        '2027-03-01',
        '2027-02-26',
        '2027-03-05',
      ),
    ];
    for (final (schedule, date, start, end) in cases) {
      test('${schedule.frequency.name} $date -> [$start, $end)', () {
        expect(schedule.periodContaining(d(date)), PayPeriod(d(start), d(end)));
      });
    }
  });

  test('periodsFrom returns consecutive periods without gaps', () {
    for (final schedule in [
      const PaySchedule.monthly(31),
      PaySchedule.biweekly(d('2026-01-02')),
      PaySchedule.weekly(d('2026-01-05')),
    ]) {
      final periods = schedule.periodsFrom(d('2026-01-10'), 30);
      for (var i = 1; i < periods.length; i++) {
        expect(periods[i].start, periods[i - 1].end);
        expect(periods[i].start < periods[i].end, isTrue);
      }
    }
  });
}
