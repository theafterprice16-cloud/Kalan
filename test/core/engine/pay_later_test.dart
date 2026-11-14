import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/engine/engine.dart';
import 'package:kalan/core/money/currency.dart';
import 'package:kalan/core/money/money_format.dart';

LocalDate d(int y, int m, int day) => LocalDate(y, m, day);

void main() {
  group('due date', () {
    // purchase, rule, due
    final cases = <(String, LocalDate, PayLaterRule, LocalDate)>[
      (
        'Lena: 30 days',
        d(2026, 11, 14),
        const PayLaterRule.days(30),
        d(2026, 12, 14),
      ),
      (
        '14 days across the year',
        d(2026, 12, 25),
        const PayLaterRule.days(14),
        d(2027, 1, 8),
      ),
      ('45 days', d(2026, 11, 20), const PayLaterRule.days(45), d(2027, 1, 4)),
      ('1 day', d(2026, 11, 20), const PayLaterRule.days(1), d(2026, 11, 21)),
      (
        '180 days',
        d(2026, 11, 20),
        const PayLaterRule.days(180),
        d(2027, 5, 19),
      ),
      (
        'next month on the 27th, from 31 Jan',
        d(2027, 1, 31),
        const PayLaterRule.nextMonthDay(27),
        d(2027, 2, 27),
      ),
      (
        'next month on the 31st: last day of February',
        d(2027, 1, 15),
        const PayLaterRule.nextMonthDay(31),
        d(2027, 2, 28),
      ),
      (
        'next month on the 31st: leap year',
        d(2028, 1, 31),
        const PayLaterRule.nextMonthDay(31),
        d(2028, 2, 29),
      ),
      (
        'next month on the 5th, across the year',
        d(2026, 12, 30),
        const PayLaterRule.nextMonthDay(5),
        d(2027, 1, 5),
      ),
      (
        'next month on the 1st',
        d(2026, 11, 30),
        const PayLaterRule.nextMonthDay(1),
        d(2026, 12, 1),
      ),
      (
        'next month on the 31st, a 31-day month',
        d(2026, 11, 2),
        const PayLaterRule.nextMonthDay(31),
        d(2026, 12, 31),
      ),
      (
        '30 days on a weekend: no shift',
        d(2026, 11, 13),
        const PayLaterRule.days(30),
        d(2026, 12, 13),
      ),
    ];
    for (final (name, purchase, rule, due) in cases) {
      test(name, () {
        expect(payLaterDueDate(purchase: purchase, rule: rule), due);
      });
    }

    test('the month-end rule is the engine one', () {
      for (var day = 1; day <= 31; day++) {
        final purchase = d(2027, 1, 31);
        expect(
          payLaterDueDate(
            purchase: purchase,
            rule: PayLaterRule.nextMonthDay(day),
          ),
          purchase.addMonths(1, preferredDay: day),
        );
      }
    });

    test('a chosen date stays, whatever the purchase date', () {
      for (final purchase in [d(2026, 11, 14), d(2027, 2, 1)]) {
        expect(
          payLaterDueDate(
            purchase: purchase,
            rule: const PayLaterRule.chosenDate(),
            chosen: d(2027, 3, 3),
          ),
          d(2027, 3, 3),
        );
      }
    });

    test('out of range or missing: rejected', () {
      for (final rule in const [
        PayLaterRule.days(0),
        PayLaterRule.days(181),
        PayLaterRule.days(-3),
        PayLaterRule.nextMonthDay(0),
        PayLaterRule.nextMonthDay(32),
      ]) {
        expect(rule.isValid, isFalse, reason: '$rule');
        expect(
          () => payLaterDueDate(purchase: d(2026, 11, 14), rule: rule),
          throwsA(isA<InvalidPlanInput>()),
        );
      }
      expect(
        () => payLaterDueDate(
          purchase: d(2026, 11, 14),
          rule: const PayLaterRule.chosenDate(),
        ),
        throwsA(isA<InvalidPlanInput>()),
      );
    });

    test('stored rules read back; bad ones are null', () {
      expect(
        PayLaterRule.from(PayLaterRuleKind.days, 45),
        const PayLaterRule.days(45),
      );
      expect(
        PayLaterRule.from(PayLaterRuleKind.nextMonthDay, 27),
        const PayLaterRule.nextMonthDay(27),
      );
      expect(
        PayLaterRule.from(PayLaterRuleKind.chosenDate, null),
        const PayLaterRule.chosenDate(),
      );
      expect(PayLaterRule.from(PayLaterRuleKind.days, null), isNull);
      expect(PayLaterRule.from(PayLaterRuleKind.days, 400), isNull);
      expect(PayLaterRule.from(null, 30), isNull);
    });
  });

  group('the draft', () {
    test('Lena: one payment of 79 EUR on 14 December', () {
      final draft = PlanCalculator.payLater(
        purchaseDate: d(2026, 11, 14),
        rule: defaultPayLaterRule,
        totalMinor: 7900,
      );
      expect(draft.kind, PlanKind.payLater);
      expect(draft.installmentCount, 1);
      expect(draft.payments, [
        DraftPayment(seq: 1, date: d(2026, 12, 14), amountMinor: 7900),
      ]);
      expect(draft.purchaseDate, d(2026, 11, 14));
      expect(draft.payLaterRule, const PayLaterRule.days(30));
      expect(draft.paidBeforeCount, 0);
    });

    test('nothing to pay: rejected', () {
      expect(
        () => PlanCalculator.payLater(
          purchaseDate: d(2026, 11, 14),
          rule: defaultPayLaterRule,
          totalMinor: 0,
        ),
        throwsA(isA<InvalidPlanInput>()),
      );
    });
  });

  group('periods', () {
    const schedule = PaySchedule.monthly(1);
    final lena = PlanCalculator.payLater(
      purchaseDate: d(2026, 11, 14),
      rule: defaultPayLaterRule,
      totalMinor: 7900,
    ).payments.single;

    test('counts in December, not November', () {
      PeriodSummary sum(LocalDate inPeriod) => summarizePeriod(
        period: schedule.periodContaining(inPeriod),
        items: [DatedAmount(lena.date, lena.amountMinor)],
        incomeMinor: 300000,
      );
      expect(sum(d(2026, 11, 20)).spokenForMinor, 0);
      expect(sum(d(2026, 12, 1)).spokenForMinor, 7900);
      expect(sum(d(2026, 12, 1)).leftMinor, 292100);
    });

    test('IDR: whole rupiah, one payment', () {
      final draft = PlanCalculator.payLater(
        purchaseDate: d(2026, 11, 20),
        rule: const PayLaterRule.days(45),
        totalMinor: 1250000,
      );
      expect(draft.totalMinor, 1250000);
      expect(
        formatMoney(
          draft.payments.single.amountMinor,
          Currency.fromCode('IDR'),
          localeName: 'tr',
        ),
        'Rp1.250.000',
      );
    });
  });
}
