import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/engine/engine.dart';
import 'package:kalan/core/reminders/reminder_models.dart' show ReminderRepeat;
import 'package:kalan/data/db/app_database.dart';
import 'package:kalan/data/models.dart';
import 'package:kalan/data/period_totals.dart';
import 'package:kalan/data/repositories/plan_repository.dart';
import 'package:kalan/data/repositories/source_repository.dart';
import 'package:kalan/entitlement/entitlement.dart';
import 'package:kalan/features/home/home_view.dart';
import 'package:kalan/features/periods/calendar_month.dart';
import 'package:kalan/features/periods/coming_periods.dart';
import 'package:kalan/features/sources/charge_forecast_view.dart';

import '../core/date/local_date_test.dart' show d;
import '../helpers/app_harness.dart' show seedCard;

class _Free implements Entitlement {
  @override
  bool get isPro => false;
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late PlanRepository plans;
  late SourceRepository sources;
  const schedule = PaySchedule.monthly(15);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    plans = PlanRepository(db);
    sources = SourceRepository(db, plans);
  });
  tearDown(() => db.close());

  /// 4 payments every 14 days from 20 Nov 2026: 20 Nov, 4 Dec, 18 Dec,
  /// 1 Jan. [total] 240 EUR by default (Example 1).
  Future<int> savePayIn4({int total = 24000, String name = 'Mont'}) async {
    final sourceId = await sources.findOrCreateProvider(name);
    return plans.saveDraft(
      PlanCalculator.payIn4(firstDate: d('2026-11-20'), totalMinor: total),
      sourceId: sourceId,
      origin: PlanOrigin.template,
    );
  }

  Future<PlanWithPayments> load(int id) async =>
      (await plans.all()).firstWhere((p) => p.plan.id == id);

  Future<void> payFirst(int id) async =>
      plans.setPaid((await load(id)).allPayments.first.id, paid: true);

  Future<PeriodSummary> summaryOn(LocalDate today) async => periodSummaryOn(
    plans: await plans.all(),
    recurring: const [],
    period: schedule.periodContaining(today),
    today: today,
    incomeMinor: 100000,
  );

  group('Example 1: put on hold (240 EUR, 4 x 60, first paid)', () {
    test('unpaid payments leave the totals; the paid one stays', () async {
      final id = await savePayIn4();
      await payFirst(id);
      final today = d('2026-11-21');
      final before = await summaryOn(today);
      expect(before.spokenForMinor, 12000); // 20 Nov paid + 4 Dec
      expect(before.leftMinor, 88000);
      final openBefore = await plans.countOpenPlans();

      await plans.hold(id, today: today);

      final plan = await load(id);
      expect(plan.status, PlanStatus.onHold);
      expect(plan.payments.map((p) => p.amountMinor), [6000]);
      expect(plan.setAside.map((p) => p.amountMinor), [6000, 6000, 6000]);
      expect(plan.allPayments, hasLength(4));
      expect(plan.remainingMinor, 18000);
      expect(plan.isOpen, isTrue);
      expect(await plans.countOpenPlans(), openBefore);

      final after = await summaryOn(today);
      expect(after.spokenForMinor, 6000);
      // "Left" grows by the unpaid payment of this period.
      expect(after.leftMinor, 94000);
    });

    test('reopen brings the payments back on their own dates', () async {
      final id = await savePayIn4();
      await payFirst(id);
      final datesBefore = [
        for (final p in (await load(id)).allPayments) p.dueDay,
      ];
      final today = d('2026-11-21');
      final before = await summaryOn(today);
      await plans.hold(id, today: today);
      await plans.reopen(id, today: today);
      final plan = await load(id);
      expect(plan.status, PlanStatus.open);
      expect([for (final p in plan.payments) p.dueDay], datesBefore);
      expect((await summaryOn(today)).leftMinor, before.leftMinor);
    });

    test('a held payment past its date is not past due; after reopen it '
        'is, and the plan says how many passed', () async {
      final id = await savePayIn4();
      await payFirst(id);
      await plans.hold(id, today: d('2026-11-21'));
      final later = d('2026-12-10'); // 4 Dec passed while on hold
      final period = schedule.periodContaining(later);

      var rows = homeEntriesFor(
        plans: await plans.all(),
        recurring: const [],
        period: period,
        today: later,
      );
      expect(rows.pastDue, isEmpty);
      // Only the paid 20 Nov payment is listed in this period.
      expect(rows.entries.map((e) => (e.date, e.isPaid)), [
        (d('2026-11-20'), true),
      ]);

      await plans.reopen(id, today: later);
      rows = homeEntriesFor(
        plans: await plans.all(),
        recurring: const [],
        period: period,
        today: later,
      );
      expect(rows.pastDue.map((e) => e.date), [d('2026-12-04')]);
      expect((await load(id)).passedWhileHeld, 1);

      // Marked as paid: the line goes away.
      await plans.setPaid((await load(id)).allPayments[1].id, paid: true);
      expect((await load(id)).passedWhileHeld, 0);
    });

    test('held payments are not on the coming periods, the calendar or the '
        'charge forecast (12, 13, 18)', () async {
      final id = await savePayIn4();
      await payFirst(id);
      final today = d('2026-11-21');
      await plans.hold(id, today: today);
      final all = await plans.all();

      final periods = comingPeriods(
        plans: all,
        recurring: const [],
        schedule: schedule,
        today: today,
      );
      expect(periods.first.summary.spokenForMinor, 6000); // paid only
      for (final p in periods.skip(1)) {
        expect(p.summary.spokenForMinor, 0);
        expect(p.entries, isEmpty);
      }

      final december = calendarMonth(
        plans: all,
        recurring: const [],
        schedule: schedule,
        month: const CalendarMonth(2026, 12),
        today: today,
      );
      // Only the payday is marked; no payment on any day.
      expect(december.values.expand((day) => day.payments), isEmpty);

      expect(chargeItemsOf(all).map((c) => c.amountMinor), [6000]);
    });
  });

  group('Example 2: close', () {
    test('closed for a return: archive, reason, limit drops by one', () async {
      final id = await savePayIn4();
      await payFirst(id);
      final today = d('2026-11-21');
      await plans.hold(id, today: today);
      final openBefore = await plans.countOpenPlans();

      await plans.close(id, reason: CloseReason.refund, today: d('2026-12-05'));

      final plan = await load(id);
      expect(plan.status, PlanStatus.closed);
      expect(plan.plan.closeReason, CloseReason.refund);
      expect(plan.plan.closedDay, d('2026-12-05').epochDay);
      expect(plan.isOpen, isFalse);
      expect(plan.payments.map((p) => p.amountMinor), [6000]);
      expect(await plans.countOpenPlans(), openBefore - 1);
      // The paid payment stays in its period; nothing else counts.
      expect((await summaryOn(today)).spokenForMinor, 6000);
      expect((await summaryOn(d('2026-12-20'))).spokenForMinor, 0);
    });

    test('an open plan can be closed directly (cancellation)', () async {
      final id = await savePayIn4();
      await plans.close(id, reason: CloseReason.cancel, today: d('2026-11-21'));
      final plan = await load(id);
      expect(plan.plan.closeReason, CloseReason.cancel);
      expect(plan.payments, isEmpty);
      expect(plan.allPayments, hasLength(4));
      expect(await plans.countOpenPlans(), 0);
    });

    test('a closed plan is read-only', () async {
      final id = await savePayIn4();
      await payFirst(id);
      await plans.close(id, reason: CloseReason.refund, today: d('2026-11-21'));
      final rows = (await load(id)).allPayments;

      await plans.setPaid(rows[0].id, paid: false);
      await plans.setPaid(rows[1].id, paid: true);
      await plans.setPaidOn(rows[2].id, d('2026-11-21'));
      final after = (await load(id)).allPayments;
      expect([for (final p in after) p.isPaid], [true, false, false, false]);

      await expectLater(plans.adjustTotal(id, 10000), throwsStateError);
      await expectLater(
        plans.editPayment(
          planId: id,
          seq: 2,
          date: d('2026-12-04'),
          amountMinor: 100,
        ),
        throwsStateError,
      );
      await expectLater(
        plans.hold(id, today: d('2026-11-22')),
        throwsStateError,
      );
      await expectLater(
        plans.reopen(id, today: d('2026-11-22')),
        throwsStateError,
      );
    });
  });

  test('a closed plan keeps its settings and card dates; a held one '
      'follows the card', () async {
    final card = await seedCard(db);
    const oldTerms = CardTerms(statementDay: 25, dueDay: 5);
    Future<int> cardPlan() => plans.saveDraft(
      PlanCalculator.card(
        purchaseDate: d('2026-11-10'),
        totalMinor: 60000,
        count: 3,
        terms: oldTerms,
      ),
      sourceId: card,
      origin: PlanOrigin.template,
    );
    final closed = await cardPlan();
    final held = await cardPlan();
    await plans.close(
      closed,
      reason: CloseReason.refund,
      today: d('2026-11-20'),
    );
    await plans.hold(held, today: d('2026-11-20'));
    List<int> days(PlanWithPayments p) => [
      for (final x in p.allPayments) x.dueDay,
    ];
    final closedBefore = days(await load(closed));
    final heldBefore = days(await load(held));

    await plans.recomputeCardPlans(
      sourceId: card,
      oldTerms: oldTerms,
      newTerms: const CardTerms(statementDay: 10, dueDay: 20),
    );
    expect(days(await load(closed)), closedBefore);
    expect(days(await load(held)), isNot(heldBefore));

    await plans.setReminderChoice(closed, enabled: false);
    await plans.setRepeatMode(closed, ReminderRepeat.daily);
    await plans.setPaymentMethod(closed, PaymentMethod.manual);
    final row = (await load(closed)).plan;
    expect(row.remindersEnabled, isTrue);
    expect(row.repeatMode, isNull);
    expect(row.paymentMethod, isNull);
    await expectLater(plans.setPaidBefore(closed, count: 1), throwsStateError);
    await expectLater(plans.resize(closed, count: 2), throwsStateError);
  });

  group('Example 3: adjust amount (300 EUR, 4 x 75, first paid)', () {
    // new total, result, amounts
    final cases = <(int, AdjustRejection?, List<int>)>[
      (15000, null, [7500, 2500, 2500, 2500]),
      (20000, null, [7500, 4166, 4166, 4168]),
      (6000, AdjustRejection.belowPaid, [7500, 7500, 7500, 7500]),
      (7500, AdjustRejection.nothingLeft, [7500, 7500, 7500, 7500]),
      (30100, AdjustRejection.aboveTotal, [7500, 7500, 7500, 7500]),
    ];
    for (final (total, rejection, amounts) in cases) {
      test('$total -> ${rejection ?? amounts}', () async {
        final id = await savePayIn4(total: 30000);
        await payFirst(id);
        final dates = [for (final p in (await load(id)).allPayments) p.dueDay];
        expect(await plans.adjustTotal(id, total), rejection);
        final plan = await load(id);
        expect([for (final p in plan.allPayments) p.amountMinor], amounts);
        expect([for (final p in plan.allPayments) p.dueDay], dates);
        expect(plan.status, PlanStatus.open);
      });
    }

    test('works on hold and keeps the plan on hold', () async {
      final id = await savePayIn4(total: 30000);
      await payFirst(id);
      await plans.hold(id, today: d('2026-11-21'));
      expect(await plans.adjustTotal(id, 15000), isNull);
      final plan = await load(id);
      expect(plan.status, PlanStatus.onHold);
      expect(plan.totalMinor, 15000);
      expect(plan.remainingMinor, 7500);
    });
  });

  group('30 days on hold', () {
    test(
      '29th day no line, 30th day the line; "Keep on hold" resets',
      () async {
        final id = await savePayIn4();
        await plans.hold(id, today: d('2026-11-01'));
        var plan = await load(id);
        expect(plan.holdCheckDueOn(d('2026-11-29')), isFalse);
        expect(plan.holdCheckDueOn(d('2026-11-30')), isTrue);

        await plans.keepOnHold(id, today: d('2026-11-30'));
        plan = await load(id);
        expect(plan.holdCheckDueOn(d('2026-11-30')), isFalse);
        expect(plan.holdCheckDueOn(d('2026-12-28')), isFalse);
        expect(plan.holdCheckDueOn(d('2026-12-29')), isTrue);
        // The hold day itself does not move.
        expect(plan.plan.heldSinceDay, d('2026-11-01').epochDay);
      },
    );

    test('an open plan never asks', () async {
      final id = await savePayIn4();
      expect((await load(id)).holdCheckDueOn(d('2027-06-01')), isFalse);
    });
  });

  group('free plan limit (Decision 1)', () {
    Future<bool> canAdd() async => canAddPlan(
      openPlans: (await plans.all()).where((p) => p.isOpen).length,
      entitlement: _Free(),
    );

    test('a plan on hold counts; a closed one does not; reopen keeps the '
        'count', () async {
      final ids = [for (var i = 0; i < 4; i++) await savePayIn4(name: 'P$i')];
      expect(await canAdd(), isFalse);

      await plans.hold(ids.first, today: d('2026-11-21'));
      expect(await canAdd(), isFalse);
      expect(await plans.countOpenPlans(), 4);

      await plans.reopen(ids.first, today: d('2026-11-22'));
      expect(await canAdd(), isFalse);
      expect(await plans.countOpenPlans(), 4);

      await plans.close(
        ids.first,
        reason: CloseReason.cancel,
        today: d('2026-11-22'),
      );
      expect(await canAdd(), isTrue);
      expect(await plans.countOpenPlans(), 3);
      // The screen's count and the database's count agree.
      expect((await plans.all()).where((p) => p.isOpen).length, 3);
    });
  });
}
