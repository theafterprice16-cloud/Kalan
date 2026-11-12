import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/engine/engine.dart';

import '../date/local_date_test.dart' show d;

void main() {
  final cases =
      <(String, String, Recurrence, String, String, String?, List<String>)>[
        (
          'monthly rent on the 31st through short months',
          '2026-01-31',
          Recurrence.monthly,
          '2026-02-01',
          '2026-05-01',
          null,
          ['2026-02-28', '2026-03-31', '2026-04-30'],
        ),
        (
          'weekly within one period',
          '2026-11-02',
          Recurrence.weekly,
          '2026-11-12',
          '2026-11-26',
          null,
          ['2026-11-16', '2026-11-23'],
        ),
        (
          'biweekly',
          '2026-10-01',
          Recurrence.biweekly,
          '2026-11-01',
          '2026-12-01',
          null,
          ['2026-11-12', '2026-11-26'],
        ),
        (
          'yearly on 29 Feb falls on 28 Feb in common years',
          '2028-02-29',
          Recurrence.yearly,
          '2029-01-01',
          '2029-12-31',
          null,
          ['2029-02-28'],
        ),
        (
          'nothing before the start date',
          '2026-12-10',
          Recurrence.monthly,
          '2026-11-01',
          '2027-01-01',
          null,
          ['2026-12-10'],
        ),
        (
          'end date is inclusive',
          '2026-09-15',
          Recurrence.monthly,
          '2026-09-01',
          '2027-01-01',
          '2026-11-15',
          ['2026-09-15', '2026-10-15', '2026-11-15'],
        ),
        (
          'range end is exclusive',
          '2026-09-15',
          Recurrence.monthly,
          '2026-10-15',
          '2026-11-15',
          null,
          ['2026-10-15'],
        ),
      ];
  for (final (name, start, rec, from, to, end, expected) in cases) {
    test(name, () {
      expect(
        recurringOccurrences(
          start: d(start),
          recurrence: rec,
          from: d(from),
          toExclusive: d(to),
          endDate: end == null ? null : d(end),
        ),
        expected.map(d).toList(),
      );
    });
  }
}
