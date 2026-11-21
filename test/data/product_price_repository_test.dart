import 'dart:ui' show Locale;

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
import 'package:kalan/features/reminders/reminder_scheduler.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../core/date/local_date_test.dart' show d;
import '../helpers/app_harness.dart' show seedSettings;
import '../helpers/fake_notifications.dart';

/// Product price (23), stored: display only. Putri's phone: Rp6.000.000,
/// 12 × Rp580.000 from 10 Dec 2026; payday 25, today 15 Nov 2026.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late PlanRepository plans;
  late SourceRepository sources;
  const schedule = PaySchedule.monthly(25);
  final today = d('2026-11-15');

  setUpAll(tzdata.initializeTimeZones);
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    plans = PlanRepository(db);
    sources = SourceRepository(db, plans);
  });
  tearDown(() => db.close());

  PlanDraft putri({int? price, int paidBefore = 0}) => PlanCalculator.monthly(
    firstDate: d('2026-07-10'),
    totalMinor: 6960000,
    count: 12,
  ).withPaidBefore(paidBefore).withProductPrice(price);

  Future<int> save(PlanDraft draft) async => plans.saveDraft(
    draft,
    sourceId: await sources.findOrCreateProvider('Kredivo'),
    origin: PlanOrigin.template,
  );

  Future<PlanWithPayments> load(int id) async =>
      (await plans.all()).firstWhere((p) => p.plan.id == id);

  Future<ResizeRejection?> editPrice(int id, int? price) async {
    final plan = await load(id);
    return plans.editPlan(
      id,
      count: plan.plan.installmentCount,
      paidBefore: plan.paidBefore.length,
      productPrice: (priceMinor: price),
    );
  }

  test('example 1 is stored and shown', () async {
    final id = await save(putri(price: 6000000));
    final plan = await load(id);
    expect(plan.productPrice, 6000000);
    expect(plan.priceDifference?.totalRepaidMinor, 6960000);
    expect(plan.priceDifference?.differenceMinor, 960000);
  });

  test('example 6: paid before Kalan counts in the total', () async {
    final id = await save(putri(price: 6000000, paidBefore: 5));
    final plan = await load(id);
    expect(plan.paidBefore, hasLength(5));
    expect(plan.priceDifference?.totalRepaidMinor, 6960000);
    expect(plan.priceDifference?.differenceMinor, 960000);
  });

  test('Pay in 4 never stores a price', () async {
    final draft = PlanCalculator.payIn4(
      firstDate: d('2026-12-10'),
      totalMinor: 40000,
    ).withProductPrice(30000);
    final id = await save(draft);
    expect((await load(id)).productPrice, isNull);
  });

  test('a price can be added, changed and cleared later', () async {
    final id = await save(putri());
    expect((await load(id)).priceDifference, isNull);
    expect(await editPrice(id, 6000000), isNull);
    expect((await load(id)).priceDifference?.differenceMinor, 960000);
    expect(await editPrice(id, 6500000), isNull);
    expect((await load(id)).priceDifference?.differenceMinor, 460000);
    expect(await editPrice(id, 0), isNull);
    expect((await load(id)).productPrice, isNull);
    expect(await editPrice(id, 6000000), isNull);
    expect(await editPrice(id, null), isNull);
    expect((await load(id)).productPrice, isNull);
  });

  test('editing without a price input keeps it', () async {
    final id = await save(putri(price: 6000000));
    final plan = await load(id);
    expect(
      await plans.editPlan(id, count: 12, paidBefore: plan.paidBefore.length),
      isNull,
    );
    expect((await load(id)).productPrice, 6000000);
  });

  test('price equal to or above the total: stored, rows hidden', () async {
    final equal = await save(putri(price: 6960000));
    final above = await save(putri(price: 7000000));
    expect((await load(equal)).productPrice, 6960000);
    expect((await load(equal)).priceDifference, isNull);
    expect((await load(above)).productPrice, 7000000);
    expect((await load(above)).priceDifference, isNull);
  });

  test('on hold and closed (19): rows hidden, price kept', () async {
    final held = await save(putri(price: 6000000));
    final closed = await save(putri(price: 6000000));
    await plans.hold(held, today: today);
    await plans.close(closed, reason: CloseReason.refund, today: today);
    expect((await load(held)).priceDifference, isNull);
    expect((await load(closed)).priceDifference, isNull);
    expect((await load(closed)).productPrice, 6000000);
    await plans.reopen(held, today: today);
    expect((await load(held)).priceDifference?.differenceMinor, 960000);
  });

  test('a closed plan cannot take a price', () async {
    final id = await save(putri());
    await plans.close(id, reason: CloseReason.cancel, today: today);
    expect(() => editPrice(id, 6000000), throwsA(anything));
  });

  test('"Adjust amount" (19): the total follows the new payments', () async {
    final id = await save(putri(price: 6000000));
    expect(await plans.adjustTotal(id, 6600000), isNull);
    final plan = await load(id);
    expect(plan.priceDifference?.totalRepaidMinor, 6600000);
    expect(plan.priceDifference?.differenceMinor, 600000);
  });

  test(
    'extra fees (21) are not in the total; fees per payment (22) are',
    () async {
      final draft =
          PlanCalculator.monthly(
                firstDate: d('2026-07-10'),
                totalMinor: 660000,
                count: 6,
              )
              .withInstallmentFee(1000, InstallmentFeeScope.everyPayment)
              .withProductPrice(600000);
      final id = await save(draft);
      var plan = await load(id);
      expect(plan.priceDifference?.totalRepaidMinor, 666000);
      expect(plan.priceDifference?.differenceMinor, 66000);
      final overdue = plan.allPayments.firstWhere((p) => !p.isPaid);
      expect(await plans.setExtraFee(overdue.id, amountMinor: 5000), isNull);
      plan = await load(id);
      expect(plan.extraFeesMinor, 5000);
      expect(plan.priceDifference?.totalRepaidMinor, 666000);
      expect(plan.priceDifference?.differenceMinor, 66000);
    },
  );

  test('a currency change scales the price, never below 1', () async {
    final id = await save(putri(price: 6000000));
    final none = await save(putri());
    await SettingsRepository(db).changeCurrency(
      from: Currency.fromCode('IDR'),
      to: Currency.fromCode('KWD'),
    );
    expect((await load(id)).productPrice, 6000000000);
    expect((await load(none)).productPrice, isNull);
    await SettingsRepository(db).changeCurrency(
      from: Currency.fromCode('KWD'),
      to: Currency.fromCode('JPY'),
    );
    expect((await load(id)).productPrice, 6000000);
  });

  test('periods and left never see the price', () async {
    final a = await save(putri());
    Future<List<PeriodSummary>> summaries() async {
      final all = await plans.all();
      return [
        for (final day in ['2026-11-15', '2026-12-30', '2027-03-30'])
          periodSummaryOn(
            plans: all,
            recurring: const [],
            period: schedule.periodContaining(d(day)),
            today: today,
            incomeMinor: 10000000,
          ),
      ];
    }

    String describe(List<PeriodSummary> s) =>
        [for (final x in s) '${x.spokenForMinor} ${x.leftMinor} ${x.itemCount}']
            .join('|');
    final before = describe(await summaries());
    expect(await editPrice(a, 6000000), isNull);
    expect(describe(await summaries()), before);
  });

  test('reminders never see the price', () async {
    await seedSettings(db, currency: 'IDR');
    final id = await save(putri());
    final gateway = FakeNotificationGateway();
    final scheduler = ReminderScheduler(
      db: db,
      gateway: gateway,
      location: () => tz.getLocation('Asia/Jakarta'),
      now: () => DateTime.utc(2026, 11, 15, 3),
      localeFor: (s) => const Locale('en'),
    );
    await scheduler.rescheduleAll();
    final before = [
      for (final r in gateway.pending) '${r.fireDate} ${r.kind} ${r.body}',
    ];
    expect(before, isNotEmpty);
    expect(await editPrice(id, 6000000), isNull);
    await scheduler.rescheduleAll();
    expect([
      for (final r in gateway.pending) '${r.fireDate} ${r.kind} ${r.body}',
    ], before);
  });

  test('manual entry: stored, added later and cleared', () async {
    final base = putri();
    final draft = PlanDraft(
      kind: PlanKind.manual,
      installmentCount: base.installmentCount,
      payments: base.payments,
    );
    final id = await save(draft.withProductPrice(6000000));
    expect((await load(id)).priceDifference?.differenceMinor, 960000);
    expect(await editPrice(id, 6500000), isNull);
    expect((await load(id)).priceDifference?.differenceMinor, 460000);
    expect(await editPrice(id, null), isNull);
    expect((await load(id)).productPrice, isNull);
  });
}
