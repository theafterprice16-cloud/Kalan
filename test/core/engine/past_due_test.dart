import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/engine/engine.dart';
import 'package:kalan/core/money/currency.dart';
import 'package:kalan/core/money/money_format.dart';

LocalDate d(int m, int day, [int y = 2026]) => LocalDate(y, m, day);

/// Paid on the 1st: periods are calendar months.
const schedule = PaySchedule.monthly(1);

class Pay {
  const Pay(this.due, this.amount, {this.paid = false, this.paidOn});
  final LocalDate due;
  final int amount;
  final bool paid;
  final LocalDate? paidOn;
}

PeriodSummary summary(List<Pay> pays, LocalDate today, {int? income}) =>
    summarizePeriod(
      period: schedule.periodContaining(today),
      items: [
        for (final p in pays)
          DatedAmount(
            countingDate(
              dueDate: p.due,
              isPaid: p.paid,
              paidOn: p.paidOn,
              today: today,
            ),
            p.amount,
          ),
      ],
      incomeMinor: income,
    );

void main() {
  group('which period a payment counts in', () {
    // due, paid, paidOn, today, counts on, past due
    final cases =
        <(String, LocalDate, bool, LocalDate?, LocalDate, LocalDate, bool)>[
          (
            'unpaid, last period',
            d(10, 28),
            false,
            null,
            d(11, 1),
            d(11, 1),
            true,
          ),
          (
            'unpaid, two periods back',
            d(9, 15),
            false,
            null,
            d(11, 1),
            d(11, 1),
            true,
          ),
          (
            'unpaid, earlier this period',
            d(11, 5),
            false,
            null,
            d(11, 10),
            d(11, 10),
            true,
          ),
          (
            'unpaid, due today',
            d(11, 1),
            false,
            null,
            d(11, 1),
            d(11, 1),
            false,
          ),
          (
            'unpaid, due later',
            d(11, 20),
            false,
            null,
            d(11, 1),
            d(11, 20),
            false,
          ),
          (
            'unpaid, last day of last period',
            d(10, 31),
            false,
            null,
            d(11, 1),
            d(11, 1),
            true,
          ),
          (
            'paid "today" from the list',
            d(10, 28),
            true,
            d(11, 1),
            d(11, 1),
            d(11, 1),
            false,
          ),
          (
            'paid "on the due date"',
            d(10, 28),
            true,
            d(10, 28),
            d(11, 1),
            d(10, 28),
            false,
          ),
          (
            'paid the old way, no paid-on date',
            d(10, 30),
            true,
            null,
            d(11, 2),
            d(10, 30),
            false,
          ),
          ('paid early', d(11, 20), true, d(11, 3), d(11, 5), d(11, 20), false),
          // Card due Sat 5 Dec moved to Mon 7 Dec: not past due on Sunday.
          (
            'card, shifted due date, on the Sunday',
            d(12, 7),
            false,
            null,
            d(12, 6),
            d(12, 7),
            false,
          ),
          (
            'card, shifted due date, the day after',
            d(12, 7),
            false,
            null,
            d(12, 8),
            d(12, 8),
            true,
          ),
        ];
    for (final (name, due, paid, paidOn, today, expected, pastDue) in cases) {
      test(name, () {
        expect(
          countingDate(
            dueDate: due,
            isPaid: paid,
            paidOn: paidOn,
            today: today,
          ),
          expected,
        );
        expect(isPastDue(dueDate: due, isPaid: paid, today: today), pastDue);
      });
    }

    test('days past due are calendar days', () {
      expect(daysPastDue(dueDate: d(10, 28), today: d(11, 1)), 4);
      expect(daysPastDue(dueDate: d(12, 31, 2026), today: d(1, 2, 2027)), 2);
    });
  });

  group('Zeynep: 850 unpaid from 28 Oct, 1 Nov', () {
    final today = d(11, 1);
    const income = 3000000;
    // November's own payments: 12,000.00.
    final november = [Pay(d(11, 10), 1200000)];

    test('unpaid: counted in November', () {
      final s = summary(
        [...november, Pay(d(10, 28), 85000)],
        today,
        income: income,
      );
      expect(s.spokenForMinor, 1285000);
      expect(s.leftMinor, 1715000);
    });

    test('"Today": stays in November', () {
      final s = summary(
        [...november, Pay(d(10, 28), 85000, paid: true, paidOn: today)],
        today,
        income: income,
      );
      expect(s.leftMinor, 1715000);
    });

    test('"On the due date": back to October, November gains 850', () {
      final s = summary(
        [...november, Pay(d(10, 28), 85000, paid: true, paidOn: d(10, 28))],
        today,
        income: income,
      );
      expect(s.leftMinor, 1800000);
      final october = summarizePeriod(
        period: schedule.periodContaining(d(10, 28)),
        items: [
          DatedAmount(
            countingDate(
              dueDate: d(10, 28),
              isPaid: true,
              paidOn: d(10, 28),
              today: today,
            ),
            85000,
          ),
        ],
      );
      expect(october.spokenForMinor, 85000);
    });

    test('September and October both count in November', () {
      final s = summary(
        [...november, Pay(d(9, 20), 40000), Pay(d(10, 28), 85000)],
        today,
        income: income,
      );
      expect(s.spokenForMinor, 1325000);
    });

    test('without income: only spoken for, past due included', () {
      final s = summary([...november, Pay(d(10, 28), 85000)], today);
      expect(s.status, PeriodStatus.noIncome);
      expect(s.leftMinor, isNull);
      expect(s.spokenForMinor, 1285000);
    });

    test('IDR: whole rupiah', () {
      final s = summary([Pay(d(10, 28), 850000), Pay(d(11, 9), 150000)], today);
      expect(
        formatMoney(
          s.spokenForMinor,
          Currency.fromCode('IDR'),
          localeName: 'tr',
        ),
        'Rp1.000.000',
      );
    });
  });

  test('no payment past due: every period total is as before', () {
    // Paid ones (old way and early), future ones, one due today.
    final pays = [
      Pay(d(9, 5), 10000, paid: true),
      Pay(d(10, 5), 10000, paid: true),
      Pay(d(10, 30), 20000, paid: true), // marked on 2 Nov, old way
      Pay(d(11, 5), 10000),
      Pay(d(11, 20), 30000, paid: true, paidOn: d(11, 3)),
      Pay(d(12, 5), 10000),
      Pay(d(1, 5, 2027), 10000),
    ];
    for (var day = d(11, 1); day <= d(11, 5); day = day.addDays(1)) {
      for (final period in [
        schedule.periodContaining(d(10, 1)),
        schedule.periodContaining(day),
        schedule.periodContaining(d(12, 1)),
      ]) {
        final before = summarizePeriod(
          period: period,
          items: [for (final p in pays) DatedAmount(p.due, p.amount)],
          incomeMinor: 3000000,
        );
        final after = summarizePeriod(
          period: period,
          items: [
            for (final p in pays)
              DatedAmount(
                countingDate(
                  dueDate: p.due,
                  isPaid: p.paid,
                  paidOn: p.paidOn,
                  today: day,
                ),
                p.amount,
              ),
          ],
          incomeMinor: 3000000,
        );
        expect(after.spokenForMinor, before.spokenForMinor, reason: '$day');
        expect(after.leftMinor, before.leftMinor);
      }
    }
  });
}
