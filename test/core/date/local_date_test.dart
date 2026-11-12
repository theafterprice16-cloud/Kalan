import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/date/local_date.dart';

LocalDate d(String iso) {
  final p = iso.split('-').map(int.parse).toList();
  return LocalDate(p[0], p[1], p[2]);
}

void main() {
  group('LocalDate.clamped', () {
    final cases = <(int, int, int, String)>[
      (2026, 2, 31, '2026-02-28'),
      (2028, 2, 31, '2028-02-29'),
      (2028, 2, 29, '2028-02-29'),
      (2026, 4, 31, '2026-04-30'),
      (2026, 13, 15, '2027-01-15'),
      (2026, 0, 15, '2025-12-15'),
      (2026, -11, 31, '2025-01-31'),
      (2026, 25, 1, '2028-01-01'),
    ];
    for (final (y, m, day, expected) in cases) {
      test('($y, $m, $day) -> $expected', () {
        expect(LocalDate.clamped(y, m, day), d(expected));
      });
    }
  });

  group('addMonths keeps the preferred day', () {
    final cases = <(String, int, int?, String)>[
      ('2026-01-31', 1, null, '2026-02-28'),
      ('2026-01-31', 2, null, '2026-03-31'),
      ('2026-02-28', 1, 31, '2026-03-31'),
      ('2027-12-15', 1, null, '2028-01-15'),
      ('2028-02-29', 12, null, '2029-02-28'),
    ];
    for (final (from, months, preferred, expected) in cases) {
      test('$from + $months -> $expected', () {
        expect(d(from).addMonths(months, preferredDay: preferred), d(expected));
      });
    }
  });

  test('epoch day round-trips across years and leap days', () {
    for (final iso in [
      '1970-01-01',
      '2026-11-12',
      '2028-02-29',
      '2099-12-31',
    ]) {
      final date = d(iso);
      expect(LocalDate.fromEpochDay(date.epochDay), date);
    }
    expect(d('1970-01-02').epochDay, 1);
  });

  test('ordering and weekday', () {
    expect(d('2026-11-14') < d('2026-11-15'), isTrue);
    expect(d('2026-11-14').weekday, DateTime.saturday);
    expect(d('2026-11-14').isWeekend, isTrue);
    expect(d('2026-11-16').isWeekend, isFalse);
    expect(d('2026-11-14').toString(), '2026-11-14');
  });
}
