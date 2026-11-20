import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/engine/engine.dart';
import 'package:kalan/data/db/app_database.dart';
import 'package:kalan/data/models.dart';
import 'package:kalan/data/period_totals.dart';
import 'package:kalan/data/repositories/plan_repository.dart';
import 'package:kalan/data/repositories/source_repository.dart';
import 'package:kalan/features/home/home_view.dart';
import 'package:kalan/features/periods/calendar_month.dart';
import 'package:kalan/features/periods/coming_periods.dart';
import 'package:kalan/features/sources/charge_forecast_view.dart';

import '../core/date/local_date_test.dart' show d;

/// "Change date" (20), stored: the brief's examples (payday 25, today
/// 15 Nov, 4 × 60 $: 20 Nov, 4 Dec, 18 Dec, 1 Jan).
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late PlanRepository plans;
  late SourceRepository sources;
  const schedule = PaySchedule.monthly(25);
  final today = d('2026-11-15');

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    plans = PlanRepository(db);
    sources = SourceRepository(db, plans);
  });
  tearDown(() => db.close());

  Future<int> saveTom() async => plans.saveDraft(
    PlanCalculator.payIn4(firstDate: d('2026-11-20'), totalMinor: 24000),
    sourceId: await sources.findOrCreateProvider('Afterpay'),
    origin: PlanOrigin.template,
  );

  Future<PlanWithPayments> load(int id) async =>
      (await plans.all()).firstWhere((p) => p.plan.id == id);

  Future<List<(int, LocalDate, LocalDate?)>> dates(int id) async => [
    for (final p in (await load(id)).allPayments)
      (p.seq, p.date, p.originalDate),
  ];

  Future<MoveRejection?> move(
    int id,
    int seq,
    String date, {
    bool shift = false,
  }) => plans.movePayment(
    planId: id,
    seq: seq,
    newDate: d(date),
    shiftLater: shift,
    today: today,
  );

  /// Home's summary of the period containing [day], as seen on [today].
  Future<PeriodSummary> summaryOf(String day, {int? income}) async =>
      periodSummaryOn(
        plans: await plans.all(),
        recurring: const [],
        period: schedule.periodContaining(d(day)),
        today: today,
        incomeMinor: income,
      );

  group('the preview is what home shows after saving', () {
    final cases = <(String, int, String, bool, List<String>)>[
      ('example 1', 1, '2026-11-27', false, ['2026-10-25', '2026-11-25']),
      ('example 2', 1, '2026-11-27', true, ['2026-10-25', '2026-12-25']),
      ('example 4', 2, '2026-12-06', false, []),
    ];
    for (final (name, seq, date, shift, periods) in cases) {
      test(name, () async {
        final id = await saveTom();
        final plan = await load(id);
        final preview = dateChangePreview(
          plan: plan,
          newDates: movedDates(
            [for (final p in plan.payments) p.toMovable()],
            seq: seq,
            newDate: d(date),
            shiftLater: shift,
          ),
          schedule: schedule,
          today: today,
        );
        expect(preview.map((c) => c.period.start), [
          for (final p in periods) d(p),
        ]);
        const starts = ['2026-11-01', '2026-12-01', '2027-01-01'];
        final before = [
          for (final s in starts) await summaryOf(s, income: 100000),
        ];

        expect(await move(id, seq, date, shift: shift), isNull);

        final after = [
          for (final s in starts) await summaryOf(s, income: 100000),
        ];
        for (var i = 0; i < starts.length; i++) {
          final change = preview
              .where((c) => c.period == before[i].period)
              .firstOrNull;
          expect(
            after[i].leftMinor! - before[i].leftMinor!,
            change?.leftDeltaMinor ?? 0,
            reason: starts[i],
          );
          expect(
            after[i].spokenForMinor - before[i].spokenForMinor,
            change?.spokenForDeltaMinor ?? 0,
          );
        }
      });
    }

    test('example 1 in numbers: this period +60 left, next −60', () async {
      final id = await saveTom();
      final thisBefore = await summaryOf('2026-11-15', income: 100000);
      final nextBefore = await summaryOf('2026-12-01', income: 100000);
      await move(id, 1, '2026-11-27');
      final thisAfter = await summaryOf('2026-11-15', income: 100000);
      final nextAfter = await summaryOf('2026-12-01', income: 100000);
      expect(thisAfter.leftMinor! - thisBefore.leftMinor!, 6000);
      expect(nextAfter.leftMinor! - nextBefore.leftMinor!, -6000);
      // Example 3, no income: spoken for −60 and +60.
      expect(
        (await summaryOf('2026-11-15')).spokenForMinor,
        thisBefore.spokenForMinor - 6000,
      );
    });
  });

  group('stored dates', () {
    test('example 1: only the chosen payment, original kept', () async {
      final id = await saveTom();
      expect(await move(id, 1, '2026-11-27'), isNull);
      expect(await dates(id), [
        (1, d('2026-11-27'), d('2026-11-20')),
        (2, d('2026-12-04'), null),
        (3, d('2026-12-18'), null),
        (4, d('2027-01-01'), null),
      ]);
    });

    test('example 2: later unpaid ones move too and get a note', () async {
      final id = await saveTom();
      expect(await move(id, 1, '2026-11-27', shift: true), isNull);
      expect(await dates(id), [
        (1, d('2026-11-27'), d('2026-11-20')),
        (2, d('2026-12-11'), d('2026-12-04')),
        (3, d('2026-12-25'), d('2026-12-18')),
        (4, d('2027-01-08'), d('2027-01-01')),
      ]);
    });

    test('later ones too: paid and earlier payments never move', () async {
      final id = await saveTom();
      final rows = (await load(id)).allPayments;
      await plans.setPaid(rows[2].id, paid: true); // 18 Dec paid
      expect(await move(id, 2, '2026-12-06', shift: true), isNull);
      expect(await dates(id), [
        (1, d('2026-11-20'), null),
        (2, d('2026-12-06'), d('2026-12-04')),
        (3, d('2026-12-18'), null),
        (4, d('2027-01-03'), d('2027-01-01')),
      ]);
    });

    test('the original date is written once, never overwritten, and goes '
        'when the payment is back on it (example 4)', () async {
      final id = await saveTom();
      await move(id, 2, '2026-12-06');
      await move(id, 2, '2026-12-09');
      expect((await dates(id))[1], (2, d('2026-12-09'), d('2026-12-04')));
      await move(id, 2, '2026-12-04');
      expect((await dates(id))[1], (2, d('2026-12-04'), null));
    });

    test(
      'example 5: past the next one; numbers kept, listed by date',
      () async {
        final id = await saveTom();
        expect(await move(id, 2, '2026-12-20'), isNull);
        final plan = await load(id);
        expect(plan.listedPayments.map((p) => (p.seq, p.date)), [
          (1, d('2026-11-20')),
          (3, d('2026-12-18')),
          (2, d('2026-12-20')),
          (4, d('2027-01-01')),
        ]);
        await plans.setPaid(plan.allPayments.first.id, paid: true);
        expect((await load(id)).nextUnpaid!.seq, 3);
      },
    );

    test('amounts, numbers and "edited" never change', () async {
      final id = await saveTom();
      await move(id, 1, '2026-11-27', shift: true);
      final plan = await load(id);
      expect(plan.allPayments.map((p) => p.amountMinor), everyElement(6000));
      expect(plan.allPayments.map((p) => p.isEdited), everyElement(false));
      expect(plan.allPayments.map((p) => p.seq), [1, 2, 3, 4]);
    });
  });

  group('refused: nothing is written', () {
    Future<void> expectRefused(
      int id,
      Future<MoveRejection?> Function() run,
      MoveRejection reason,
    ) async {
      final before = await dates(id);
      expect(await run(), reason);
      expect(await dates(id), before);
    }

    test('before today, unchanged, unknown payment', () async {
      final id = await saveTom();
      await expectRefused(
        id,
        () => move(id, 2, '2026-11-14'),
        MoveRejection.beforeToday,
      );
      await expectRefused(
        id,
        () => move(id, 2, '2026-12-04'),
        MoveRejection.unchanged,
      );
      await expectRefused(
        id,
        () => move(id, 9, '2026-12-08'),
        MoveRejection.notFound,
      );
    });

    test('paid payment, plan on hold, closed plan', () async {
      final id = await saveTom();
      await plans.setPaid((await load(id)).allPayments.first.id, paid: true);
      await expectRefused(
        id,
        () => move(id, 1, '2026-11-27'),
        MoveRejection.notAllowed,
      );
      await plans.hold(id, today: today);
      await expectRefused(
        id,
        () => move(id, 2, '2026-12-08'),
        MoveRejection.notAllowed,
      );
      await plans.close(id, reason: CloseReason.refund, today: today);
      await expectRefused(
        id,
        () => move(id, 2, '2026-12-08'),
        MoveRejection.notAllowed,
      );
    });

    test('card installment', () async {
      final cardId = await sources.create(
        name: 'Maximum',
        kind: SourceKind.card,
        statementDay: 10,
        dueDay: 20,
      );
      final id = await plans.saveDraft(
        PlanCalculator.card(
          purchaseDate: d('2026-11-01'),
          totalMinor: 30000,
          count: 3,
          terms: const CardTerms(statementDay: 10, dueDay: 20),
        ),
        sourceId: cardId,
        origin: PlanOrigin.template,
      );
      final seq = (await load(id)).allPayments.first.seq;
      await expectRefused(
        id,
        () => move(id, seq, '2027-03-01'),
        MoveRejection.notAllowed,
      );
    });

    test('later ones too would put one before today', () async {
      final id = await saveTom();
      await move(id, 3, '2026-11-16'); // 18 Dec moved alone to 16 Nov
      await expectRefused(
        id,
        () => move(id, 2, '2026-11-30', shift: true),
        MoveRejection.laterBeforeToday,
      );
    });
  });

  group('other edits keep a moved date', () {
    test('a new interval leaves the moved payment where it is', () async {
      final id = await saveTom();
      await move(id, 3, '2026-12-22');
      final rejected = await plans.editPlan(
        id,
        count: 4,
        paidBefore: 0,
        interval: PaymentInterval.weekly,
      );
      expect(rejected, isNull);
      expect(await dates(id), [
        (1, d('2026-11-20'), null),
        (2, d('2026-11-27'), null),
        (3, d('2026-12-22'), d('2026-12-18')),
        (4, d('2026-12-11'), null),
      ]);
    });

    test(
      'the amount edit dialog back on the original date clears it',
      () async {
        final id = await saveTom();
        await move(id, 2, '2026-12-08');
        await plans.editPayment(
          planId: id,
          seq: 2,
          date: d('2026-12-04'),
          amountMinor: 6000,
        );
        expect((await dates(id))[1], (2, d('2026-12-04'), null));
      },
    );

    test('"Pay later": a moved date stays until its rule changes', () async {
      final id = await plans.saveDraft(
        PlanCalculator.payLater(
          purchaseDate: d('2026-11-10'),
          rule: const PayLaterRule.days(30),
          totalMinor: 9000,
        ),
        sourceId: null,
        origin: PlanOrigin.template,
      );
      expect((await dates(id)).single.$2, d('2026-12-10'));
      expect(await move(id, 1, '2026-12-24'), isNull);

      Future<void> edit(String purchase, PayLaterRule rule) =>
          plans.editPayLater(
            id,
            title: 'Bot',
            sourceId: null,
            amountMinor: 9000,
            purchaseDate: d(purchase),
            rule: rule,
          );

      await edit('2026-11-10', const PayLaterRule.days(30));
      expect((await dates(id)).single, (1, d('2026-12-24'), d('2026-12-10')));
      await edit('2026-11-10', const PayLaterRule.days(14));
      expect((await dates(id)).single, (1, d('2026-11-24'), null));
    });
  });

  test('home, coming periods, calendar and charges read the new date '
      '(12, 13, 18)', () async {
    final id = await saveTom();
    await move(id, 1, '2026-11-27');
    final all = await plans.all();
    final rows = homeEntriesFor(
      plans: all,
      recurring: const [],
      period: schedule.periodContaining(today),
      today: today,
    );
    expect(rows.entries, isEmpty);
    final periods = comingPeriods(
      plans: all,
      recurring: const [],
      schedule: schedule,
      today: today,
    );
    expect(periods.first.summary.spokenForMinor, 0);
    expect(periods[1].entries.map((e) => e.date).first, d('2026-11-27'));
    final november = calendarMonth(
      plans: all,
      recurring: const [],
      schedule: schedule,
      month: const CalendarMonth(2026, 11),
      today: today,
    );
    expect(november[d('2026-11-20')]?.payments ?? const [], isEmpty);
    expect(november[d('2026-11-27')]!.payments, hasLength(1));
    expect(chargeItemsOf(all).first.dueDate, d('2026-11-27'));
    expect(id, isPositive);
  });
}
