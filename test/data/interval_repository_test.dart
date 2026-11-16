import 'package:drift/drift.dart' show OrderingTerm, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/engine/engine.dart';
import 'package:kalan/data/db/app_database.dart';
import 'package:kalan/data/models.dart';
import 'package:kalan/data/repositories/plan_repository.dart';
import 'package:kalan/data/repositories/source_repository.dart';

LocalDate d(int y, int m, int day) => LocalDate(y, m, day);
final now = DateTime(2026, 11, 16, 10);

void main() {
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  late AppDatabase db;
  late PlanRepository plans;
  late int sourceId;

  Future<List<PaymentRow>> rows(int planId) =>
      (db.select(db.payments)
            ..where((p) => p.planId.equals(planId))
            ..orderBy([(p) => OrderingTerm.asc(p.seq)]))
          .get();

  Future<PlanWithPayments> plan(int planId) async =>
      (await plans.all()).singleWhere((p) => p.plan.id == planId);

  Future<int> save(PlanDraft draft) => plans.saveDraft(
    draft,
    sourceId: sourceId,
    origin: PlanOrigin.template,
    now: now,
  );

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    plans = PlanRepository(db);
    sourceId = await SourceRepository(db, plans).findOrCreateProvider('Klarna');
  });
  tearDown(() => db.close());

  test('the chosen interval is stored and read back', () async {
    final monthly = await save(
      PlanCalculator.monthly(
        firstDate: d(2027, 8, 1),
        totalMinor: 30000,
        count: 3,
        interval: PaymentInterval.every30Days,
      ),
    );
    final sameDay = await save(
      PlanCalculator.monthly(
        firstDate: d(2027, 8, 1),
        totalMinor: 30000,
        count: 3,
      ),
    );
    final payIn4 = await save(
      PlanCalculator.payIn4(firstDate: d(2027, 8, 1), totalMinor: 40000),
    );
    final card = await save(
      PlanCalculator.card(
        purchaseDate: d(2027, 8, 1),
        totalMinor: 30000,
        count: 3,
        terms: const CardTerms(statementDay: 10, dueDay: 20),
      ),
    );
    expect((await plan(monthly)).plan.intervalDays, 30);
    expect((await plan(monthly)).interval, PaymentInterval.every30Days);
    expect((await plan(sameDay)).plan.intervalDays, null);
    expect((await plan(sameDay)).interval, PaymentInterval.sameDay);
    expect((await plan(payIn4)).interval, PaymentInterval.biweekly);
    expect((await plan(card)).plan.intervalDays, null);
    expect((await plan(card)).interval, null);
  });

  group('changing the interval', () {
    test('redates unpaid, unedited payments after the first unpaid', () async {
      // 6 monthly from 31 Jan 2027: the 1st paid in Kalan, the 4th edited.
      final id = await save(
        PlanCalculator.monthly(
          firstDate: d(2027, 1, 31),
          totalMinor: 60000,
          count: 6,
        ),
      );
      var r = await rows(id);
      await plans.setPaid(r[0].id, paid: true, now: now);
      await plans.editPayment(
        planId: id,
        seq: 4,
        date: d(2027, 4, 25),
        amountMinor: 10000,
      );

      expect(
        await plans.editPlan(
          id,
          count: 6,
          paidBefore: 0,
          pattern: const IntervalPattern(PaymentInterval.every30Days),
          interval: PaymentInterval.every30Days,
        ),
        isNull,
      );
      r = await rows(id);
      expect(r.map((p) => p.date), [
        d(2027, 1, 31), // paid in Kalan: kept
        d(2027, 2, 28), // the anchor: first unpaid, keeps its date
        d(2027, 3, 30),
        d(2027, 4, 25), // edited by hand: kept
        d(2027, 5, 29),
        d(2027, 6, 28),
      ]);
      expect(r.map((p) => p.amountMinor), List.filled(6, 10000));
      expect(r[0].isPaid, isTrue);
      expect((await plan(id)).interval, PaymentInterval.every30Days);
    });

    test('the same interval changes nothing', () async {
      final id = await save(
        PlanCalculator.monthly(
          firstDate: d(2027, 1, 31),
          totalMinor: 30000,
          count: 3,
        ),
      );
      final before = (await rows(id)).map((p) => p.dueDay).toList();
      await plans.editPlan(
        id,
        count: 3,
        paidBefore: 0,
        pattern: const MonthlyPattern(),
        interval: PaymentInterval.sameDay,
      );
      expect((await rows(id)).map((p) => p.dueDay), before);
    });

    test('an underway plan keeps its next payment where it is', () async {
      // 5 payments every 2 weeks, 2 paid before Kalan; now weekly.
      final id = await save(
        underwayPlan(
          kind: PlanKind.monthly,
          totalMinor: 50000,
          count: 5,
          paidCount: 2,
          nextDate: d(2026, 12, 1),
          interval: PaymentInterval.biweekly,
        ),
      );
      await plans.editPlan(
        id,
        count: 5,
        paidBefore: 2,
        pattern: const IntervalPattern(PaymentInterval.weekly),
        interval: PaymentInterval.weekly,
      );
      final r = await rows(id);
      // Paid before Kalan: their (hidden) dates follow the new rule back
      // from the next payment, as when the plan was added.
      expect(r.map((p) => p.date), [
        d(2026, 11, 17),
        d(2026, 11, 24),
        d(2026, 12, 1),
        d(2026, 12, 8),
        d(2026, 12, 15),
      ]);
      expect(r.map((p) => p.paidBeforeKalan), [
        true,
        true,
        false,
        false,
        false,
      ]);
    });

    test('with a new next date and more installments', () async {
      final id = await save(
        PlanCalculator.payIn4(firstDate: d(2027, 1, 4), totalMinor: 40000),
      );
      // Pay in 4 cannot grow; a monthly plan can.
      final m = await save(
        PlanCalculator.monthly(
          firstDate: d(2027, 1, 4),
          totalMinor: 30000,
          count: 3,
        ),
      );
      expect(
        await plans.editPlan(
          m,
          count: 4,
          paidBefore: 1,
          nextDate: d(2027, 2, 10),
          pattern: const IntervalPattern(PaymentInterval.every30Days),
          interval: PaymentInterval.every30Days,
        ),
        isNull,
      );
      expect((await rows(m)).map((p) => p.date), [
        d(2027, 1, 11),
        d(2027, 2, 10),
        d(2027, 3, 12),
        d(2027, 4, 11),
      ]);
      expect((await plan(m)).totalMinor, 30000);

      await plans.editPlan(
        id,
        count: 4,
        paidBefore: 0,
        pattern: const MonthlyPattern(),
        interval: PaymentInterval.sameDay,
      );
      expect((await rows(id)).map((p) => p.date), [
        d(2027, 1, 4),
        d(2027, 2, 4),
        d(2027, 3, 4),
        d(2027, 4, 4),
      ]);
      expect((await plan(id)).interval, PaymentInterval.sameDay);
    });

    test('paid ones at the start: nothing moves into the past', () async {
      // 15 Jan - 15 Jun, the first 3 marked paid; now weekly.
      final id = await save(
        PlanCalculator.monthly(
          firstDate: d(2027, 1, 15),
          totalMinor: 60000,
          count: 6,
        ),
      );
      for (final p in (await rows(id)).take(3)) {
        await plans.setPaid(p.id, paid: true, now: now);
      }
      await plans.editPlan(
        id,
        count: 6,
        paidBefore: 0,
        interval: PaymentInterval.weekly,
      );
      expect((await rows(id)).map((p) => p.date), [
        d(2027, 1, 15),
        d(2027, 2, 15),
        d(2027, 3, 15),
        d(2027, 4, 15),
        d(2027, 4, 22),
        d(2027, 4, 29),
      ]);
    });

    test('a rejected change stores nothing, the interval too', () async {
      // 6 payments of 1 minor unit cannot become 7.
      final id = await save(
        PlanCalculator.monthly(
          firstDate: d(2027, 1, 15),
          totalMinor: 6,
          count: 6,
        ),
      );
      final before = (await rows(id)).map((p) => p.dueDay).toList();
      expect(
        await plans.editPlan(
          id,
          count: 7,
          paidBefore: 0,
          interval: PaymentInterval.weekly,
        ),
        ResizeRejection.cannotSplit,
      );
      expect((await rows(id)).map((p) => p.dueDay), before);
      expect((await plan(id)).plan.intervalDays, null);
      expect((await plan(id)).plan.installmentCount, 6);
    });

    test('the interval sets the dates, whatever pattern is passed', () async {
      final id = await save(
        PlanCalculator.monthly(
          firstDate: d(2027, 1, 15),
          totalMinor: 30000,
          count: 3,
        ),
      );
      await plans.editPlan(
        id,
        count: 4,
        paidBefore: 0,
        pattern: const MonthlyPattern(),
        interval: PaymentInterval.weekly,
      );
      expect((await rows(id)).map((p) => p.date), [
        d(2027, 1, 15),
        d(2027, 1, 22),
        d(2027, 1, 29),
        d(2027, 2, 5),
      ]);
    });

    test('ignored for kinds without an interval', () async {
      final id = await save(
        PlanCalculator.manual(
          firstDate: d(2027, 1, 4),
          totalMinor: 30000,
          count: 3,
          unit: IntervalUnit.day,
          step: 10,
        ),
      );
      final before = (await rows(id)).map((p) => p.dueDay).toList();
      await plans.editPlan(
        id,
        count: 3,
        paidBefore: 0,
        interval: PaymentInterval.weekly,
      );
      expect((await rows(id)).map((p) => p.dueDay), before);
      expect((await plan(id)).plan.intervalDays, null);
    });
  });
}
