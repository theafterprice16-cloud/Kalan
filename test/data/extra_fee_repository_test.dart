import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/engine/engine.dart';
import 'package:kalan/data/db/app_database.dart';
import 'package:kalan/data/models.dart';
import 'package:kalan/data/period_totals.dart';
import 'package:kalan/data/repositories/plan_repository.dart';
import 'package:kalan/data/repositories/source_repository.dart';
import 'package:kalan/features/sources/card_statements.dart';
import 'package:kalan/features/sources/charge_forecast_view.dart';

import '../core/date/local_date_test.dart' show d;

/// Extra fee (21), stored: the brief's examples (EUR, payday 25, income
/// 1.000 €, today 15 Nov 2026; 4 × 60 € from 10 Nov, monthly).
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late PlanRepository plans;
  late SourceRepository sources;
  const schedule = PaySchedule.monthly(25);
  const income = 100000;
  final today = d('2026-11-15');

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    plans = PlanRepository(db);
    sources = SourceRepository(db, plans);
  });
  tearDown(() => db.close());

  Future<int> saveSofia({int paidBefore = 0}) async => plans.saveDraft(
    PlanCalculator.monthly(
      firstDate: d('2026-11-10'),
      totalMinor: 24000,
      count: 4,
    ).withPaidBefore(paidBefore),
    sourceId: await sources.findOrCreateProvider('Klarna'),
    origin: PlanOrigin.template,
  );

  Future<PlanWithPayments> load(int id) async =>
      (await plans.all()).firstWhere((p) => p.plan.id == id);

  Future<PaymentRow> payment(int id, int seq) async =>
      (await load(id)).allPayments.firstWhere((p) => p.seq == seq);

  Future<PeriodSummary> summaryOf(String day) async => periodSummaryOn(
    plans: await plans.all(),
    recurring: const [],
    period: schedule.periodContaining(d(day)),
    today: today,
    incomeMinor: income,
  );

  test(
    'example 1: paid late, the fee counts where the payment counts',
    () async {
      final id = await saveSofia();
      final first = await payment(id, 1);
      // Due 10 Nov, paid "today" on 13 Nov: counts on 13 Nov, in the
      // 25 Oct - 24 Nov period.
      await plans.setPaidOn(first.id, d('2026-11-13'));
      final before = await summaryOf('2026-11-13');
      final next = await summaryOf('2026-12-10');

      expect(await plans.setExtraFee(first.id, amountMinor: 600), isNull);

      final after = await summaryOf('2026-11-13');
      expect(after.spokenForMinor - before.spokenForMinor, 600);
      expect(after.leftMinor, before.leftMinor! - 600);
      expect(
        (await summaryOf('2026-12-10')).spokenForMinor,
        next.spokenForMinor,
      );
      final plan = await load(id);
      expect(plan.totalMinor, 24000, reason: 'the plan total never changes');
      expect(plan.allPayments.map((p) => p.amountMinor), everyElement(6000));
      expect(plan.extraFeesMinor, 600);
    },
  );

  test('example 2: unpaid and past due, 66 € in this period', () async {
    final id = await saveSofia();
    final first = await payment(id, 1);
    final before = await summaryOf('2026-11-15');
    await plans.setExtraFee(first.id, amountMinor: 600);
    final after = await summaryOf('2026-11-15');
    expect(after.spokenForMinor - before.spokenForMinor, 600);
    final row = await payment(id, 1);
    expect(row.amountMinor, 6000);
    expect(row.spokenForMinor, 6600);
  });

  test('a fee follows its payment to its counting period', () async {
    final id = await saveSofia();
    final third = await payment(id, 3); // due 10 Jan 2027
    final dec = await summaryOf('2026-12-10');
    final jan = await summaryOf('2027-01-10');
    await plans.setExtraFee(third.id, amountMinor: 250);
    expect((await summaryOf('2026-12-10')).spokenForMinor, dec.spokenForMinor);
    expect(
      (await summaryOf('2027-01-10')).spokenForMinor,
      jan.spokenForMinor + 250,
    );
  });

  test('example 3 and 4: correct, delete and undo', () async {
    final id = await saveSofia();
    final first = await payment(id, 1);
    final base = await summaryOf('2026-11-15');
    await plans.setExtraFee(first.id, amountMinor: 600);
    // A second fee: the amount is corrected, never a second line.
    expect(
      await plans.setExtraFee(
        first.id,
        amountMinor: 1200,
        note: '  İkinci ücret ',
      ),
      isNull,
    );
    var row = await payment(id, 1);
    expect(row.extraFeeMinor, 1200);
    expect(row.extraFeeNote, 'İkinci ücret');
    expect(
      (await summaryOf('2026-11-15')).spokenForMinor,
      base.spokenForMinor + 1200,
    );

    final removed = await plans.removeExtraFee(first.id);
    expect(removed, (amountMinor: 1200, note: 'İkinci ücret'));
    row = await payment(id, 1);
    expect(row.extraFeeMinor, isNull);
    expect(row.extraFeeNote, isNull);
    final cleared = await summaryOf('2026-11-15');
    expect(cleared.spokenForMinor, base.spokenForMinor);
    expect(cleared.leftMinor, base.leftMinor);

    // Undo stores it again.
    await plans.setExtraFee(
      first.id,
      amountMinor: removed!.amountMinor,
      note: removed.note,
    );
    row = await payment(id, 1);
    expect((row.extraFeeMinor, row.extraFeeNote), (1200, 'İkinci ücret'));
    expect(await plans.removeExtraFee((await payment(id, 2)).id), isNull);
  });

  test('zero, negative and a long note are never stored', () async {
    final id = await saveSofia();
    final first = await payment(id, 1);
    expect(
      await plans.setExtraFee(first.id, amountMinor: 0),
      ExtraFeeRejection.nonPositiveAmount,
    );
    expect(
      await plans.setExtraFee(first.id, amountMinor: 600, note: 'x' * 81),
      ExtraFeeRejection.noteTooLong,
    );
    expect(
      await plans.setExtraFee(first.id, amountMinor: 600, note: '   '),
      isNull,
    );
    expect((await payment(id, 1)).extraFeeNote, isNull);
    expect(
      await plans.setExtraFee(999, amountMinor: 600),
      ExtraFeeRejection.notFound,
    );
  });

  group('which payments can have one', () {
    test('not one paid before Kalan', () async {
      final id = await saveSofia(paidBefore: 1);
      final first = await payment(id, 1);
      expect(first.paidBeforeKalan, isTrue);
      expect(
        await plans.setExtraFee(first.id, amountMinor: 600),
        ExtraFeeRejection.notAllowed,
      );
    });

    test('on hold: paid ones only; closed: none, and fees stay', () async {
      final id = await saveSofia();
      final first = await payment(id, 1);
      final second = await payment(id, 2);
      await plans.setPaid(first.id, paid: true);
      await plans.setExtraFee(second.id, amountMinor: 300);
      await plans.hold(id, today: today);
      expect(
        await plans.setExtraFee(second.id, amountMinor: 400),
        ExtraFeeRejection.notAllowed,
      );
      expect(await plans.removeExtraFee(second.id), isNull);
      expect(await plans.setExtraFee(first.id, amountMinor: 600), isNull);
      // A held payment's fee is out of every total, like the payment.
      expect((await load(id)).extraFeesMinor, 600);

      await plans.close(id, reason: CloseReason.refund, today: today);
      expect(
        await plans.setExtraFee(first.id, amountMinor: 700),
        ExtraFeeRejection.notAllowed,
      );
      expect(await plans.removeExtraFee(first.id), isNull);
      expect((await payment(id, 1)).extraFeeMinor, 600);
      expect((await load(id)).extraFeesMinor, 600);
    });

    test('"already underway" never covers a payment with a fee', () async {
      final id = await saveSofia();
      expect(maxPaidBeforeOf((await load(id)).allPayments), 3);
      await plans.setExtraFee((await payment(id, 2)).id, amountMinor: 600);
      final rows = (await load(id)).allPayments;
      expect(leadingRunOf(rows), 1);
      expect(maxPaidBeforeOf(rows), 1);
      expect(
        () => plans.setPaidBefore(id, count: 2),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  test('a card installment: in the period, never on its statement', () async {
    final card = await sources.create(
      name: 'Ada Kart',
      kind: SourceKind.card,
      statementDay: 14,
      dueDay: 24,
    );
    final terms = (await sources.byId(card))!.cardTermsIn(null)!;
    final id = await plans.saveDraft(
      PlanCalculator.card(
        purchaseDate: d('2026-11-01'),
        totalMinor: 30000,
        count: 3,
        terms: terms,
      ),
      sourceId: card,
      origin: PlanOrigin.template,
      paymentMethod: PaymentMethod.automatic,
    );
    final first = await payment(id, 1);
    final cardRow = (await sources.byId(card))!;
    final statementBefore = cardStatementsOf(
      card: cardRow,
      plans: await plans.all(),
      today: today,
      holidays: null,
    )!.statements.map((s) => s.totalMinor).toList();
    final periodBefore = await summaryOf(first.date.toString());

    await plans.setExtraFee(first.id, amountMinor: 500);

    final statementAfter = cardStatementsOf(
      card: cardRow,
      plans: await plans.all(),
      today: today,
      holidays: null,
    )!.statements.map((s) => s.totalMinor).toList();
    expect(statementAfter, statementBefore);
    expect(
      (await summaryOf(first.date.toString())).spokenForMinor,
      periodBefore.spokenForMinor + 500,
    );
    expect((await load(id)).totalMinor, 30000);
  });

  test('keep in account (18) counts the fee with the payment', () async {
    final id = await saveSofia();
    final second = await payment(id, 2);
    await plans.setExtraFee(second.id, amountMinor: 600);
    final item = chargeItemsOf(await plans.all())
        .firstWhere((i) => i.paymentId == second.id);
    expect(item.amountMinor, 6600);
  });

  test('IDR: Rp25.000 on a Rp500.000 installment, all int', () async {
    final id = await plans.saveDraft(
      PlanCalculator.monthly(
        firstDate: d('2026-11-10'),
        totalMinor: 2000000,
        count: 4,
      ),
      sourceId: await sources.findOrCreateProvider('Kredivo'),
      origin: PlanOrigin.template,
    );
    final first = await payment(id, 1);
    final before = await summaryOf('2026-11-15');
    await plans.setExtraFee(first.id, amountMinor: 25000);
    final after = await summaryOf('2026-11-15');
    expect(after.spokenForMinor - before.spokenForMinor, 25000);
    expect((await payment(id, 1)).spokenForMinor, 525000);
  });

  test('a fee change reaches the stream reminders are rebuilt from', () async {
    final id = await saveSofia();
    final first = await payment(id, 1);
    final seen = <int?>[];
    final sub = plans.watchAll().listen(
      (all) => seen.add(
        all.firstWhere((p) => p.plan.id == id).allPayments.first.extraFeeMinor,
      ),
    );
    await pumpEventQueue();
    await plans.setExtraFee(first.id, amountMinor: 600);
    await pumpEventQueue();
    await plans.setExtraFee(first.id, amountMinor: 1200);
    await pumpEventQueue();
    final removed = await plans.removeExtraFee(first.id);
    await pumpEventQueue();
    await plans.setExtraFee(first.id, amountMinor: removed!.amountMinor);
    await pumpEventQueue();
    await sub.cancel();
    expect(seen, [null, 600, 1200, null, 1200]);
  });
}
