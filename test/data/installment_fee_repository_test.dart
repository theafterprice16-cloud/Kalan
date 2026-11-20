import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/engine/engine.dart';
import 'package:kalan/core/money/currency.dart';
import 'package:kalan/data/db/app_database.dart';
import 'package:kalan/data/models.dart';
import 'package:kalan/data/period_totals.dart';
import 'package:kalan/data/repositories/plan_repository.dart';
import 'package:kalan/data/repositories/settings_repository.dart';
import 'package:kalan/data/repositories/source_repository.dart';
import 'package:kalan/features/sources/charge_forecast_view.dart';

import '../core/date/local_date_test.dart' show d;

/// Fee per payment (22), stored: the brief's examples. JPY 10.000 in 4 ×
/// 2.500 from 10 Nov 2026, monthly; payday 25, income 100.000, today
/// 15 Nov 2026.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late PlanRepository plans;
  late SourceRepository sources;
  const schedule = PaySchedule.monthly(25);
  const income = 100000;
  final today = d('2026-11-15');
  const every = InstallmentFeeScope.everyPayment;
  const first = InstallmentFeeScope.firstPaymentOnly;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    plans = PlanRepository(db);
    sources = SourceRepository(db, plans);
  });
  tearDown(() => db.close());

  PlanDraft kenji({int? fee, InstallmentFeeScope scope = every}) =>
      PlanCalculator.monthly(
        firstDate: d('2026-11-10'),
        totalMinor: 10000,
        count: 4,
      ).withInstallmentFee(fee, scope);

  Future<int> save(PlanDraft draft) async => plans.saveDraft(
    draft,
    sourceId: await sources.findOrCreateProvider('Paidy'),
    origin: PlanOrigin.template,
  );

  Future<PlanWithPayments> load(int id) async =>
      (await plans.all()).firstWhere((p) => p.plan.id == id);

  Future<List<int?>> feesOf(int id) async => [
    for (final p in (await load(id)).allPayments) p.installmentFeeMinor,
  ];

  Future<PeriodSummary> summaryOf(String day) async => periodSummaryOn(
    plans: await plans.all(),
    recurring: const [],
    period: schedule.periodContaining(d(day)),
    today: today,
    incomeMinor: income,
  );

  Future<void> editFee(int id, int? fee, InstallmentFeeScope scope) async {
    final plan = await load(id);
    expect(
      await plans.editPlan(
        id,
        count: plan.plan.installmentCount,
        paidBefore: plan.paidBefore.length,
        installmentFee: (feeMinor: fee, scope: scope),
      ),
      isNull,
    );
  }

  test('example 1: 390 ¥ on every payment', () async {
    final id = await save(kenji(fee: 390));
    final plan = await load(id);
    expect(await feesOf(id), [390, 390, 390, 390]);
    expect(plan.plan.installmentFeeMinor, 390);
    expect(plan.totalMinor, 10000);
    expect(plan.installmentFeesMinor, 1560);
    expect(plan.totalWithFeesMinor, 11560);
    expect(plan.allPayments.map((p) => p.installmentMinor), everyElement(2890));
    expect(plan.allPayments.map((p) => p.amountMinor), everyElement(2500));
  });

  test('example 2: 2,50 € on the first payment only', () async {
    final id = await save(
      PlanCalculator.monthly(
        firstDate: d('2026-11-10'),
        totalMinor: 12000,
        count: 3,
      ).withInstallmentFee(250, first),
    );
    final plan = await load(id);
    expect(plan.allPayments.map((p) => p.installmentMinor), [4250, 4000, 4000]);
    expect(plan.totalWithFeesMinor, 12250);
  });

  test('"left" goes down by the fees in the period, and only them', () async {
    final none = await save(kenji());
    final before = await summaryOf('2026-12-10');
    await plans.deletePlan(none);
    await save(kenji(fee: 390));
    final after = await summaryOf('2026-12-10');
    expect(after.spokenForMinor - before.spokenForMinor, 390);
    expect(after.leftMinor, before.leftMinor! - 390);
  });

  test('the fee and an extra fee (21) add up at the same point', () async {
    final id = await save(kenji(fee: 390));
    final second = (await load(id)).allPayments[1];
    final before = await summaryOf('2026-12-10');
    await plans.setExtraFee(second.id, amountMinor: 600);
    final after = await summaryOf('2026-12-10');
    expect(after.spokenForMinor - before.spokenForMinor, 600);
    final row = (await load(id)).allPayments[1];
    expect(row.spokenForMinor, 2500 + 390 + 600);
    expect(row.installmentMinor, 2890);
  });

  test('example 3: added later, the paid payment stays 2.500 ¥', () async {
    final id = await save(kenji());
    final paid = (await load(id)).allPayments.first;
    await plans.setPaid(paid.id, paid: true);
    await editFee(id, 390, every);
    final plan = await load(id);
    expect(await feesOf(id), [null, 390, 390, 390]);
    expect(plan.allPayments.first.installmentMinor, 2500);
    expect(plan.installmentFeesMinor, 1170);
  });

  test('example 4: first only, first paid: no payment takes it', () async {
    final id = await save(kenji());
    await plans.setPaid((await load(id)).allPayments.first.id, paid: true);
    await editFee(id, 390, first);
    expect(await feesOf(id), [null, null, null, null]);
    expect((await load(id)).plan.installmentFeeScope, first);
  });

  test('example 5: removed: unpaid lose it, paid keep theirs', () async {
    final id = await save(kenji(fee: 390));
    await plans.setPaid((await load(id)).allPayments.first.id, paid: true);
    await editFee(id, null, every);
    expect(await feesOf(id), [390, null, null, null]);
    expect((await load(id)).plan.installmentFeeMinor, isNull);
    // Zero is no fee too.
    await editFee(id, 0, every);
    expect((await load(id)).plan.installmentFeeMinor, isNull);
  });

  test('already underway payments never take the fee', () async {
    final id = await save(kenji(fee: 390).withPaidBefore(2));
    expect(await feesOf(id), [null, null, 390, 390]);
    // Making one more payment "paid before Kalan" takes its fee away;
    // undoing it gives the fee back.
    await plans.setPaidBefore(id, count: 3);
    expect(await feesOf(id), [null, null, null, 390]);
    await plans.setPaidBefore(id, count: 1);
    expect(await feesOf(id), [null, 390, 390, 390]);
  });

  test('new payments from a larger count take the fee', () async {
    final id = await save(kenji(fee: 390));
    final rejected = await plans.editPlan(
      id,
      count: 6,
      paidBefore: 0,
      interval: PaymentInterval.sameDay,
    );
    expect(rejected, isNull);
    expect(await feesOf(id), List.filled(6, 390));
  });

  test('unmarking a paid payment follows the plan fee as it is now', () async {
    final id = await save(kenji(fee: 300));
    final p1 = (await load(id)).allPayments.first;
    await plans.setPaid(p1.id, paid: true);
    await editFee(id, 390, every);
    expect(await feesOf(id), [300, 390, 390, 390]);
    await plans.setPaid(p1.id, paid: false);
    expect(await feesOf(id), [390, 390, 390, 390]);
  });

  test('"Adjust amount" (19) changes amounts, never the fee', () async {
    final id = await save(kenji(fee: 390));
    expect(await plans.adjustTotal(id, 8000), isNull);
    final plan = await load(id);
    expect(plan.totalMinor, 8000);
    expect(await feesOf(id), List.filled(4, 390));
  });

  test('hold and close take the unpaid fees out of totals', () async {
    final id = await save(kenji(fee: 390));
    final none = (await summaryOf('2026-12-10')).spokenForMinor;
    await plans.hold(id, today: today);
    expect((await summaryOf('2026-12-10')).spokenForMinor, none - 2890);
    await plans.reopen(id, today: today);
    await plans.close(id, reason: CloseReason.refund, today: today);
    expect((await summaryOf('2026-12-10')).spokenForMinor, none - 2890);
    // A closed plan is read-only.
    await expectLater(editFee(id, 100, every), throwsA(anything));
  });

  test('"Change date" (20) moves the fee with the payment', () async {
    final id = await save(kenji(fee: 390));
    expect(
      await plans.movePayment(
        planId: id,
        seq: 2,
        newDate: d('2026-12-28'),
        shiftLater: false,
        today: today,
      ),
      isNull,
    );
    final moved = (await load(id)).allPayments[1];
    expect(moved.dueDay, d('2026-12-28').epochDay);
    expect(moved.installmentFeeMinor, 390);
  });

  test('card installments never take a fee', () async {
    final card = await sources.create(
      name: 'Bonus',
      kind: SourceKind.card,
      statementDay: 5,
      dueDay: 15,
    );
    final draft = PlanCalculator.card(
      purchaseDate: d('2026-11-01'),
      totalMinor: 9000,
      count: 3,
      terms: const CardTerms(statementDay: 5, dueDay: 15),
    ).withInstallmentFee(390, every);
    expect(draft.installmentFeeMinor, isNull);
    final id = await plans.saveDraft(
      draft,
      sourceId: card,
      origin: PlanOrigin.template,
    );
    await editFee(id, 390, every);
    expect(await feesOf(id), [null, null, null]);
    expect((await load(id)).plan.installmentFeeMinor, isNull);
  });

  test('pay later: one payment takes the fee, the scope is ignored', () async {
    final draft = PlanCalculator.payLater(
      purchaseDate: d('2026-11-10'),
      rule: const PayLaterRule.days(30),
      totalMinor: 5000,
    ).withInstallmentFee(150, first);
    final id = await save(draft);
    final plan = await load(id);
    expect(plan.plan.installmentFeeScope, every);
    expect(await feesOf(id), [150]);
    await plans.editPayLater(
      id,
      title: null,
      sourceId: null,
      amountMinor: 5000,
      purchaseDate: d('2026-11-10'),
      rule: const PayLaterRule.days(30),
      installmentFee: (feeMinor: 200, scope: every),
    );
    expect(await feesOf(id), [200]);
  });

  test('the amount to keep in an account (18) includes the fee', () async {
    final id = await save(kenji(fee: 390));
    final plan = await load(id);
    final items = chargeItemsOf([plan]);
    expect(items.map((i) => i.amountMinor), everyElement(2890));
  });

  test('a currency change scales the fees, never below 1', () async {
    final id = await save(kenji(fee: 390));
    await SettingsRepository(db).changeCurrency(
      from: Currency.fromCode('JPY'),
      to: Currency.fromCode('EUR'),
    );
    final plan = await load(id);
    expect(plan.plan.installmentFeeMinor, 39000);
    expect(await feesOf(id), List.filled(4, 39000));
  });

  test('a smaller count keeps the fee on what remains', () async {
    final id = await save(kenji(fee: 390));
    expect(
      await plans.editPlan(
        id,
        count: 2,
        paidBefore: 0,
        interval: PaymentInterval.sameDay,
      ),
      isNull,
    );
    expect(await feesOf(id), [390, 390]);
  });

  test('unmarking on a closed plan changes nothing', () async {
    final id = await save(kenji(fee: 390));
    final p1 = (await load(id)).allPayments.first;
    await plans.setPaid(p1.id, paid: true);
    await plans.close(id, reason: CloseReason.cancel, today: today);
    await plans.setPaid(p1.id, paid: false);
    final row = (await load(id)).allPayments.first;
    expect(row.isPaid, isTrue);
    expect(row.installmentFeeMinor, 390);
  });

  test('a paid "Pay later" keeps its own fee', () async {
    final id = await save(
      PlanCalculator.payLater(
        purchaseDate: d('2026-11-10'),
        rule: const PayLaterRule.days(30),
        totalMinor: 5000,
      ).withInstallmentFee(150, every),
    );
    await plans.setPaid((await load(id)).allPayments.first.id, paid: true);
    await plans.editPayLater(
      id,
      title: null,
      sourceId: null,
      amountMinor: 5000,
      purchaseDate: d('2026-11-10'),
      rule: const PayLaterRule.days(30),
      installmentFee: (feeMinor: 300, scope: every),
    );
    expect(await feesOf(id), [150]);
  });
}
