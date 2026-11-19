import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/app/providers.dart';
import 'package:kalan/core/engine/engine.dart';
import 'package:kalan/data/db/app_database.dart';
import 'package:kalan/data/repositories/plan_repository.dart';
import 'package:kalan/data/repositories/recurring_repository.dart';
import 'package:kalan/features/home/home_view.dart';
import 'package:kalan/features/periods/coming_periods.dart';

import '../../helpers/app_harness.dart';

LocalDate d(int y, int m, int day) => LocalDate(y, m, day);

/// Pure call with no payments, for the schedule tests.
List<ComingPeriod> bare(PaySchedule schedule, LocalDate today) => comingPeriods(
  plans: const [],
  recurring: const [],
  schedule: schedule,
  today: today,
);

List<LocalDate> startsOf(List<ComingPeriod> periods) => [
  for (final p in periods) p.period.start,
];

void expectConsecutive(List<ComingPeriod> periods) {
  expect(periods, hasLength(6));
  for (var i = 0; i < periods.length - 1; i++) {
    expect(periods[i].period.end, periods[i + 1].period.start);
  }
}

/// One single payment on [date], [amountMinor] in total.
Future<int> addSingle(
  AppDatabase db,
  LocalDate date,
  int amountMinor, {
  String title = 'Single',
}) => PlanRepository(db).saveDraft(
  PlanCalculator.manual(
    firstDate: date,
    totalMinor: amountMinor,
    count: 1,
    unit: IntervalUnit.month,
  ),
  sourceId: null,
  origin: PlanOrigin.manual,
  title: title,
);

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  /// Lets the database streams deliver, until [done] holds.
  Future<void> settle([bool Function()? done]) async {
    for (var i = 0; i < 50; i++) {
      await pumpEventQueue();
      if (container.read(comingPeriodsProvider) != null &&
          (done?.call() ?? true)) {
        return;
      }
    }
  }

  /// A container on [db] with every stream loaded and kept alive.
  Future<void> open({LocalDate? today}) async {
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWithValue(today ?? testToday),
      ],
    );
    addTearDown(container.dispose);
    container.listen(comingPeriodsProvider, (_, _) {});
    container.listen(homeViewProvider, (_, _) {});
    await settle();
  }

  List<ComingPeriod> coming() => container.read(comingPeriodsProvider)!;

  test('monthly payday 15, today 20 Nov 2026: six periods', () {
    final periods = bare(const PaySchedule.monthly(15), d(2026, 11, 20));
    expectConsecutive(periods);
    expect(startsOf(periods), [
      d(2026, 11, 15),
      d(2026, 12, 15),
      d(2027, 1, 15),
      d(2027, 2, 15),
      d(2027, 3, 15),
      d(2027, 4, 15),
    ]);
    expect(periods.last.period.end, d(2027, 5, 15));
  });

  test('biweekly and weekly: consecutive, floor, payday starts period 0', () {
    final anchor = d(2026, 11, 6);
    final after = d(2027, 1, 1);
    for (final (schedule, afterAnchor, step) in [
      (PaySchedule.biweekly(anchor), PaySchedule.biweekly(after), 14),
      (PaySchedule.weekly(anchor), PaySchedule.weekly(after), 7),
    ]) {
      final periods = bare(schedule, d(2026, 11, 20));
      expectConsecutive(periods);
      for (final p in periods) {
        expect(p.period.start.daysUntil(p.period.end), step);
      }
      expect(periods.first.period.contains(d(2026, 11, 20)), isTrue);

      // Anchor after today: periods step backwards from the anchor.
      final late = bare(afterAnchor, d(2026, 11, 20));
      expectConsecutive(late);
      expect(late.first.period.contains(d(2026, 11, 20)), isTrue);
      expect(late.first.period.start.daysUntil(d(2027, 1, 1)) % step, 0);

      // Today is a payday: a new period 0 starts that day.
      final onPayday = bare(schedule, anchor.addDays(step * 2));
      expect(onPayday.first.period.start, anchor.addDays(step * 2));
      expectConsecutive(onPayday);
    }
  });

  test('monthly payday 31: clamped starts, edge payments', () async {
    await seedSettings(db, payDay: 31);
    await addSingle(db, d(2027, 2, 28), 11100, title: 'On 28th');
    await addSingle(db, d(2027, 2, 27), 22200, title: 'On 27th');
    await open(today: d(2026, 11, 19));
    final periods = coming();
    expectConsecutive(periods);
    expect(startsOf(periods), [
      d(2026, 10, 31),
      d(2026, 11, 30),
      d(2026, 12, 31),
      d(2027, 1, 31),
      d(2027, 2, 28),
      d(2027, 3, 31),
    ]);
    expect(periods[3].spokenForMinor, 22200); // 27 Feb in 31 Jan period
    expect(periods[4].spokenForMinor, 11100); // 28 Feb starts a period
    expect(periods[4].rows.single.date, d(2027, 2, 28));
  });

  test('period 0 equals the home screen', () async {
    await seedSettings(db, incomeMinor: 2075000, thresholdMinor: 2000000);
    await seedPayIn4(db);
    await seedRent(db);
    await addSingle(db, d(2026, 11, 10), 5000, title: 'Late');
    await open();

    final home = container.read(homeViewProvider)!;
    final first = coming().first;
    expect(first.summary.spokenForMinor, home.summary.spokenForMinor);
    expect(first.summary.itemCount, home.summary.itemCount);
    expect(first.summary.leftMinor, home.summary.leftMinor);
    expect(first.summary.status, home.summary.status);
    expect(home.pastDue, hasLength(1));

    List<(int?, int?, LocalDate)> ids(List<HomeEntry> rows) => [
      for (final r in rows) (r.paymentId, r.recurringId, r.date),
    ];
    expect(ids(first.rows), ids([...home.pastDue, ...home.entries]));
  });

  test(
    'past-due unpaid payment: counted and listed only in period 0',
    () async {
      await seedSettings(db, incomeMinor: 100000);
      final planId = await addSingle(db, d(2026, 11, 10), 5000);
      await open();
      final paymentId = (await db.select(db.payments).get())
          .firstWhere((p) => p.planId == planId)
          .id;

      final periods = coming();
      expect(periods[0].spokenForMinor, 5000);
      expect(periods[0].summary.itemCount, 1);
      expect(periods[0].pastDue.map((e) => e.paymentId), [paymentId]);
      expect(periods[0].rows.map((e) => e.paymentId), [paymentId]);
      for (final p in periods.skip(1)) {
        expect(p.spokenForMinor, 0);
        expect(p.summary.itemCount, 0);
        expect(p.rows, isEmpty);
      }
    },
  );

  test('paid today from the past-due list counts in period 0; plain paid '
      'counts on its due date', () async {
    await seedSettings(db, incomeMinor: 100000);
    await addSingle(db, d(2026, 11, 10), 5000, title: 'Earlier');
    await addSingle(db, d(2026, 12, 20), 7000, title: 'Later');
    await open();
    final repo = container.read(planRepositoryProvider);
    final payments = await db.select(db.payments).get();
    final earlier = payments.firstWhere((p) => p.amountMinor == 5000);
    final later = payments.firstWhere((p) => p.amountMinor == 7000);

    await repo.setPaidOn(earlier.id, testToday);
    await repo.setPaid(later.id, paid: true);
    await settle(() => coming()[1].spokenForMinor == 7000);

    final periods = coming();
    expect(periods[0].spokenForMinor, 5000);
    expect(periods[0].summary.itemCount, 1);
    expect(periods[0].pastDue, isEmpty);
    expect(periods[0].entries.single.paymentId, earlier.id);
    expect(periods[0].entries.single.isPaid, isTrue);
    // Due 20 Dec, paid without a day: counts in 15 Dec - 15 Jan.
    expect(periods[1].spokenForMinor, 7000);
    expect(periods[1].entries.single.paymentId, later.id);
    expect(periods[2].spokenForMinor, 0);
  });

  test(
    'income: none gives null left and noIncome; same income everywhere',
    () async {
      await seedSettings(db);
      await seedPayIn4(db);
      await open();
      for (final p in coming()) {
        expect(p.leftMinor, isNull);
        expect(p.incomeMinor, isNull);
        expect(p.summary.status, PeriodStatus.noIncome);
      }

      await container
          .read(settingsRepositoryProvider)
          .update(const AppSettingsCompanion(netIncomeMinor: Value(900000)));
      await settle(() => coming().first.incomeMinor == 900000);
      for (final p in coming()) {
        expect(p.incomeMinor, 900000);
        expect(p.leftMinor, 900000 - p.spokenForMinor);
      }
    },
  );

  test('negative period only where spoken for exceeds income', () async {
    await seedSettings(db, incomeMinor: 50000);
    await addSingle(db, d(2026, 12, 20), 80000); // period 1 only
    await open();
    final periods = coming();
    expect(periods[1].summary.status, PeriodStatus.negative);
    expect(periods[1].leftMinor, -30000);
    expect(periods[1].isNegative, isTrue);
    for (final i in [0, 2, 3, 4, 5]) {
      expect(periods[i].isNegative, isFalse);
      expect(periods[i].leftMinor, 50000);
    }
  });

  group('shortfall (15)', () {
    test('Example 1: income 30.000, February 31.200: 1.200 short there '
        'only', () async {
      await seedSettings(db, incomeMinor: 3000000);
      // Period 3 is 15 Feb - 14 Mar 2027.
      await addSingle(db, d(2027, 2, 20), 3120000);
      await open();
      final periods = coming();
      expect(periods[3].period.start, d(2027, 2, 15));
      expect(periods[3].shortMinor, 120000);
      expect(periods[3].isNegative, isTrue);
      expect(periods[3].isCurrent, isFalse);
      for (final i in [0, 1, 2, 4, 5]) {
        expect(periods[i].shortMinor, isNull);
      }
    });

    test('only the first period is the current one', () async {
      await seedSettings(db, incomeMinor: 3000000);
      await open();
      expect(
        [for (final p in coming()) p.isCurrent],
        [true, false, false, false, false, false],
      );
    });

    test('Example 3: no income, nothing is ever short', () async {
      await seedSettings(db);
      await addSingle(db, d(2027, 2, 20), 3120000);
      await open();
      for (final p in coming()) {
        expect(p.shortMinor, isNull);
        expect(p.isNegative, isFalse);
      }
    });

    test('Example 4: an unpaid past-due payment counts only in this '
        'period', () async {
      await seedSettings(db, incomeMinor: 100000);
      // Due 10 Nov (before the current period), unpaid, 1.500 > income.
      await addSingle(db, d(2026, 11, 10), 150000);
      await addSingle(db, d(2026, 12, 20), 40000); // period 1
      await open();
      final periods = coming();
      expect(periods[0].shortMinor, 50000);
      expect(periods[0].isCurrent, isTrue);
      expect(periods[1].spokenForMinor, 40000);
      expect(periods[1].shortMinor, isNull);
      for (final p in periods.skip(1)) {
        expect(p.isNegative, isFalse);
      }
    });

    test(
      'boundaries: equal to income is not short, one kuruş over is',
      () async {
        await seedSettings(db, incomeMinor: 100000);
        await addSingle(db, d(2026, 12, 20), 100000); // period 1: equal
        await addSingle(db, d(2027, 1, 20), 100001); // period 2: 1 over
        await open();
        final periods = coming();
        expect(periods[1].leftMinor, 0);
        expect(periods[1].shortMinor, isNull);
        expect(periods[1].isNegative, isFalse);
        expect(periods[2].shortMinor, 1);
        expect(periods[2].isNegative, isTrue);
      },
    );
  });

  test('no payments: every period is empty', () async {
    await seedSettings(db, incomeMinor: 50000);
    await open();
    expect(coming(), hasLength(6));
    for (final p in coming()) {
      expect(p.summary.itemCount, 0);
      expect(p.spokenForMinor, 0);
      expect(p.rows, isEmpty);
    }
  });

  test('recurring: yearly in exactly one period, monthly in each', () async {
    await seedSettings(db);
    final repo = RecurringRepository(db);
    await repo.create(
      RecurringPaymentsCompanion.insert(
        name: 'Insurance',
        amountMinor: 300000,
        recurrence: Recurrence.yearly,
        startDay: d(2026, 3, 10).epochDay,
      ),
    );
    await repo.create(
      RecurringPaymentsCompanion.insert(
        name: 'Rent',
        amountMinor: 1500000,
        recurrence: Recurrence.monthly,
        startDay: d(2026, 1, 1).epochDay,
      ),
    );
    await open();
    final periods = coming();
    final yearly = [
      for (final p in periods)
        if (p.rows.any((r) => r.name == 'Insurance')) p,
    ];
    expect(yearly, hasLength(1));
    expect(yearly.single.period.contains(d(2027, 3, 10)), isTrue);
    for (final p in periods) {
      expect(p.rows.where((r) => r.name == 'Rent'), hasLength(1));
    }
  });

  test('the provider follows a new plan, income and payday', () async {
    await seedSettings(db, incomeMinor: 100000);
    await open();
    expect(coming().first.spokenForMinor, 0);

    await PlanRepository(db).saveDraft(
      PlanCalculator.manual(
        firstDate: d(2026, 11, 25),
        totalMinor: 4000,
        count: 1,
        unit: IntervalUnit.month,
      ),
      sourceId: null,
      origin: PlanOrigin.manual,
      title: 'New',
    );
    await settle(() => coming().first.spokenForMinor == 4000);
    expect(coming().first.spokenForMinor, 4000);
    expect(coming().first.summary.itemCount, 1);

    final settings = container.read(settingsRepositoryProvider);
    await settings.update(
      const AppSettingsCompanion(netIncomeMinor: Value(250000)),
    );
    await settle(() => coming().first.incomeMinor == 250000);
    expect(coming().first.leftMinor, 246000);

    await settings.update(const AppSettingsCompanion(payDay: Value(1)));
    await settle(() => coming().first.period.start == d(2026, 11, 1));
    expect(coming().first.period.start, d(2026, 11, 1));
    expect(coming().first.period.end, d(2026, 12, 1));
    expect(coming().first.spokenForMinor, 4000);
  });
}
