import 'package:drift/drift.dart' show OrderingTerm, Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/engine/engine.dart';
import 'package:kalan/data/db/app_database.dart';
import 'package:kalan/data/models.dart';
import 'package:kalan/data/repositories/plan_repository.dart';
import 'package:kalan/data/repositories/source_repository.dart';

LocalDate d(int y, int m, int day) => LocalDate(y, m, day);
final now = DateTime(2026, 11, 13, 10);

void main() {
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  late AppDatabase db;
  late PlanRepository plans;
  late int planId;

  Future<List<PaymentRow>> rows() =>
      (db.select(db.payments)..orderBy([(p) => OrderingTerm.asc(p.seq)])).get();

  List<bool> before(List<PaymentRow> r) => [
    for (final p in r) p.paidBeforeKalan,
  ];

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    plans = PlanRepository(db);
    final source = await SourceRepository(
      db,
      plans,
    ).findOrCreateProvider('Telefon');
    // Mehmet: 10 x 850, 3 paid before Kalan, next on 5 Dec 2026.
    planId = await plans.saveDraft(
      underwayPlan(
        kind: PlanKind.monthly,
        totalMinor: 850000,
        count: 10,
        paidCount: 3,
        nextDate: d(2026, 12, 5),
      ),
      sourceId: source,
      origin: PlanOrigin.template,
      now: now,
    );
  });
  tearDown(() => db.close());

  test('saving: 10 payments, the first 3 paid before Kalan', () async {
    final r = await rows();
    expect(r, hasLength(10));
    expect(before(r), [true, true, true, ...List.filled(7, false)]);
    expect(r.take(3).every((p) => p.paidAt == now), isTrue);
    expect(r.skip(3).every((p) => p.paidAt == null), isTrue);
    expect(r.take(3).map((p) => p.date), [
      d(2026, 9, 5),
      d(2026, 10, 5),
      d(2026, 11, 5),
    ]);
    final plan = (await plans.all()).single;
    expect(plan.paidCount, 3);
    expect(plan.paidBefore, hasLength(3));
    expect(plan.paidBeforeMinor, 255000);
    expect(plan.listedPayments, hasLength(7));
    expect(plan.isOpen, isTrue);
    expect(maxPaidBeforeOf(r), 9);
  });

  group('editing', () {
    test('raising the count marks the next payments', () async {
      await plans.setPaidBefore(planId, count: 5, now: now);
      expect(before(await rows()), [
        ...List.filled(5, true),
        ...List.filled(5, false),
      ]);
    });

    test('lowering the count and switching off bring payments back', () async {
      await plans.setPaidBefore(planId, count: 1, now: now);
      var r = await rows();
      expect(before(r), [true, ...List.filled(9, false)]);
      expect(r.skip(1).every((p) => p.paidAt == null), isTrue);
      await plans.setPaidBefore(planId, count: 0, now: now);
      r = await rows();
      expect(r.every((p) => !p.paidBeforeKalan && p.paidAt == null), isTrue);
    });

    test('a payment marked paid in Kalan is never touched', () async {
      // Example 5: the 4th payment is marked paid in the app.
      final fourth = (await rows())[3];
      final marked = DateTime(2026, 12, 5, 9);
      await plans.setPaid(fourth.id, paid: true, now: marked);
      var r = await rows();
      expect(maxPaidBeforeOf(r), 3);
      expect((await plans.all()).single.paidCount, 4);

      expect(
        () => plans.setPaidBefore(planId, count: 4, now: now),
        throwsArgumentError,
      );
      for (final count in [3, 2, 0, 3]) {
        await plans.setPaidBefore(
          planId,
          count: count,
          nextDate: d(2027, 1, 10),
          pattern: const MonthlyPattern(),
          now: now,
        );
        r = await rows();
        expect(r[3].paidAt, marked, reason: 'count $count');
        expect(r[3].paidBeforeKalan, isFalse);
        expect(r[3].date, d(2026, 12, 5));
      }
    });

    test(
      'a new next date moves the payments that are not paid in Kalan',
      () async {
        // The 6th payment was edited by hand; it keeps its date.
        final sixth = (await rows())[5];
        await (db.update(db.payments)..where((p) => p.id.equals(sixth.id)))
            .write(const PaymentsCompanion(isEdited: Value(true)));
        await plans.setPaidBefore(
          planId,
          count: 3,
          nextDate: d(2026, 12, 10),
          pattern: const MonthlyPattern(),
          now: now,
        );
        final r = await rows();
        expect(r.map((p) => p.date), [
          d(2026, 9, 10),
          d(2026, 10, 10),
          d(2026, 11, 10),
          d(2026, 12, 10),
          d(2027, 1, 10),
          d(2027, 2, 5), // edited by hand
          d(2027, 3, 10),
          d(2027, 4, 10),
          d(2027, 5, 10),
          d(2027, 6, 10),
        ]);
        expect(r.map((p) => p.amountMinor).toSet(), {85000});
      },
    );
  });

  group('changing the installment count', () {
    int total(List<PaymentRow> r) => r.fold(0, (s, p) => s + p.amountMinor);

    test('10 -> 12: same total, new payments follow the plan', () async {
      final rejected = await plans.editPlan(
        planId,
        count: 12,
        paidBefore: 3,
        pattern: const MonthlyPattern(),
      );
      expect(rejected, isNull);
      final r = await rows();
      expect(r, hasLength(12));
      expect(total(r), 850000);
      expect(r.take(3).every((p) => p.amountMinor == 85000), isTrue);
      expect(r[10].date, d(2027, 7, 5));
      expect(r[11].date, d(2027, 8, 5));
      expect(before(r).where((b) => b), hasLength(3));
      final plan = (await plans.all()).single;
      expect(plan.plan.installmentCount, 12);
      expect(plan.paidCount, 3);
    });

    test('10 -> 8 with 2 paid before: both steps in one go', () async {
      expect(await plans.editPlan(planId, count: 8, paidBefore: 2), isNull);
      final r = await rows();
      expect(r, hasLength(8));
      expect(total(r), 850000);
      expect(before(r), [true, true, ...List.filled(6, false)]);
      // 8,500 - 1,700 paid, over 6 unpaid.
      expect(r.skip(2).map((p) => p.amountMinor).toSet(), {
        (850000 - 170000) ~/ 6,
        (850000 - 170000) ~/ 6 + (850000 - 170000) % 6,
      });
    });

    test(
      'never below a payment marked paid in Kalan; nothing changes',
      () async {
        final fifth = (await rows())[4];
        await plans.setPaid(fifth.id, paid: true, now: now);
        final rejected = await plans.editPlan(
          planId,
          count: 5,
          paidBefore: 1,
          pattern: const MonthlyPattern(),
        );
        expect(rejected, ResizeRejection.tooFew);
        final r = await rows();
        expect(r, hasLength(10));
        expect(before(r).where((b) => b), hasLength(3)); // rolled back
        expect(r[4].paidAt, now);
      },
    );
  });

  test('an underway plan counts as one open plan', () async {
    expect(await plans.countOpenPlans(), 1);
    expect((await plans.all()).single.isOpen, isTrue);
  });
}
