import 'package:kalan/core/engine/engine.dart';
import 'package:kalan/data/db/app_database.dart';
import 'package:kalan/data/repositories/plan_repository.dart';
import 'package:kalan/data/repositories/recurring_repository.dart';

import 'app_harness.dart';

/// "Today" for the calendar examples: Friday 13 November 2026, so 10 Nov
/// is late and 14 Nov still to come (Example 3 itself uses the 19th).
final calendarToday = LocalDate(2026, 11, 13);

/// One single-payment plan named [title] on [date].
Future<int> seedSingle(
  AppDatabase db,
  String title,
  LocalDate date,
  int amountMinor,
) => PlanRepository(db).saveDraft(
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

/// Examples 1 and 3 of item 13, payday 15, income 45.000: 5 Nov paid,
/// 10 Nov unpaid (late), 14 Nov two pending payments
/// (₺1.400 + ₺1.500), a recurring payment on the 28th.
Future<void> seedCalendar(AppDatabase db) async {
  await seedSettings(db, incomeMinor: 4500000);
  final watch = await seedSingle(db, 'Saat', LocalDate(2026, 11, 5), 90000);
  await seedSingle(db, 'Kulaklık', LocalDate(2026, 11, 10), 60000);
  await seedSingle(db, 'Telefon taksiti', LocalDate(2026, 11, 14), 140000);
  await seedSingle(db, 'Laptop taksiti', LocalDate(2026, 11, 14), 150000);
  await RecurringRepository(db).create(
    RecurringPaymentsCompanion.insert(
      name: 'Spor salonu',
      amountMinor: 75000,
      recurrence: Recurrence.monthly,
      startDay: LocalDate(2026, 10, 28).epochDay,
    ),
  );
  final paymentId = (await (db.select(
    db.payments,
  )..where((p) => p.planId.equals(watch))).getSingle()).id;
  await PlanRepository(db)
      .setPaid(paymentId, paid: true, now: DateTime(2026, 11, 5, 10));
}

/// 20 Nov 2026, payday 15: this period 15 Nov - 14 Dec, the next one
/// 15 Dec - 14 Jan (the "December" period of the examples).
final busyWeekToday = LocalDate(2026, 11, 20);

/// Item 14, Example 1: six plan payments in the December period, four of them
/// 17-21 Dec (₺1.000 + ₺1.500 + ₺1.200 + ₺1.500 = ₺5.200).
Future<void> seedBusyWeek(AppDatabase db) async {
  await seedSettings(db, incomeMinor: 4500000);
  await seedSingle(db, 'Saat', LocalDate(2026, 12, 17), 100000);
  await seedSingle(db, 'Kulaklık', LocalDate(2026, 12, 18), 150000);
  await seedSingle(db, 'Mont', LocalDate(2026, 12, 20), 120000);
  await seedSingle(db, 'Telefon', LocalDate(2026, 12, 21), 150000);
  await seedSingle(db, 'Bot', LocalDate(2027, 1, 2), 80000);
  await seedSingle(db, 'Laptop', LocalDate(2027, 1, 10), 200000);
}
