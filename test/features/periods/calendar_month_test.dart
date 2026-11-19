import 'package:drift/drift.dart' as drift show Value;
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/engine/engine.dart';
import 'package:kalan/data/db/app_database.dart';
import 'package:kalan/data/models.dart';
import 'package:kalan/data/repositories/plan_repository.dart';
import 'package:kalan/data/repositories/recurring_repository.dart';
import 'package:kalan/features/home/home_view.dart';
import 'package:kalan/features/periods/calendar_month.dart';

LocalDate d(int y, int m, int day) => LocalDate(y, m, day);

/// One single payment on [date].
Future<int> addSingle(
  AppDatabase db,
  LocalDate date,
  int amountMinor, {
  required String title,
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

Future<int> addRecurring(
  AppDatabase db,
  String name,
  LocalDate start, {
  int amountMinor = 100000,
  Recurrence recurrence = Recurrence.monthly,
  LocalDate? end,
}) => RecurringRepository(db).create(
  RecurringPaymentsCompanion.insert(
    name: name,
    amountMinor: amountMinor,
    recurrence: recurrence,
    startDay: start.epochDay,
    endDay: drift.Value(end?.epochDay),
  ),
);

/// The only payment of plan [planId].
Future<int> paymentOf(AppDatabase db, int planId) async => (await (db.select(
  db.payments,
)..where((p) => p.planId.equals(planId))).getSingle()).id;

void main() {
  late AppDatabase db;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  /// Plans and recurring payments as the app loads them.
  Future<(List<PlanWithPayments>, List<RecurringWithMarks>)> load() async => (
    await PlanRepository(db).watchAll().first,
    await RecurringRepository(db).watchAll().first,
  );

  Future<Map<LocalDate, CalendarDay>> month(
    int year,
    int m, {
    required LocalDate today,
    PaySchedule schedule = const PaySchedule.monthly(15),
  }) async {
    final (plans, recurring) = await load();
    return calendarMonth(
      plans: plans,
      recurring: recurring,
      schedule: schedule,
      month: CalendarMonth(year, m),
      today: today,
    );
  }

  test('Example 1: November 2026, payday 15', () async {
    final paid = await addSingle(db, d(2026, 11, 5), 100000, title: 'Saat');
    await addSingle(db, d(2026, 11, 14), 140000, title: 'Telefon taksiti');
    await addSingle(db, d(2026, 11, 14), 150000, title: 'Laptop taksiti');
    await addRecurring(db, 'Spor salonu', d(2026, 1, 28));
    await PlanRepository(db).setPaid(await paymentOf(db, paid), paid: true);

    final days = await month(2026, 11, today: d(2026, 11, 2));
    expect(days.keys, [
      d(2026, 11, 5),
      d(2026, 11, 14),
      d(2026, 11, 15),
      d(2026, 11, 28),
    ]);
    expect(days[d(2026, 11, 5)]!.mark, CalendarMark.paid);
    final fourteenth = days[d(2026, 11, 14)]!;
    expect(fourteenth.mark, CalendarMark.pending);
    expect(fourteenth.payments.map((p) => p.entry.name), [
      'Laptop taksiti',
      'Telefon taksiti',
    ]);
    expect(fourteenth.totalMinor, 290000);
    expect(fourteenth.isPayday, isFalse);
    final payday = days[d(2026, 11, 15)]!;
    expect(payday.isPayday, isTrue);
    expect(payday.mark, CalendarMark.none);
    // A recurring payment gets the same mark as a plan payment.
    final rent = days[d(2026, 11, 28)]!;
    expect(rent.mark, CalendarMark.pending);
    expect(rent.payments.single.entry.isRecurring, isTrue);
  });

  test('Example 3: today 19 Nov, 10 Nov unpaid: late on its own day', () async {
    await addSingle(db, d(2026, 11, 10), 50000, title: 'Kulaklık');
    final days = await month(2026, 11, today: d(2026, 11, 19));
    final tenth = days[d(2026, 11, 10)]!;
    expect(tenth.mark, CalendarMark.late);
    expect(tenth.lateCount, 1);
    // Never moved to today.
    expect(days.containsKey(d(2026, 11, 19)), isFalse);
  });

  test('one mark per day: late > pending > paid', () async {
    final cases = <(List<CalendarStatus>, CalendarMark)>[
      ([], CalendarMark.none),
      ([CalendarStatus.paid], CalendarMark.paid),
      ([CalendarStatus.pending], CalendarMark.pending),
      ([CalendarStatus.late], CalendarMark.late),
      ([CalendarStatus.paid, CalendarStatus.pending], CalendarMark.pending),
      ([CalendarStatus.paid, CalendarStatus.late], CalendarMark.late),
      ([CalendarStatus.pending, CalendarStatus.late], CalendarMark.late),
      (
        [CalendarStatus.paid, CalendarStatus.pending, CalendarStatus.late],
        CalendarMark.late,
      ),
    ];
    final entry = HomeEntryStub.entry;
    for (final (statuses, mark) in cases) {
      final day = CalendarDay(
        date: d(2026, 11, 1),
        payments: [for (final s in statuses) CalendarPayment(entry, s)],
        isPayday: false,
      );
      expect(day.mark, mark, reason: '$statuses');
    }
  });

  test('late, pending and paid on one day are all counted', () async {
    final a = await addSingle(db, d(2026, 11, 10), 100, title: 'A');
    await addSingle(db, d(2026, 11, 10), 200, title: 'B');
    await addRecurring(db, 'C', d(2026, 10, 10));
    await PlanRepository(db).setPaid(await paymentOf(db, a), paid: true);
    final day = (await month(
      2026,
      11,
      today: d(2026, 11, 19),
      // Payday on the 1st: 10 Nov is in the current period.
      schedule: const PaySchedule.monthly(1),
    ))[d(2026, 11, 10)]!;
    // B is a late plan payment; C is this period's unmarked recurring one,
    // late as on the home screen.
    expect(day.paidCount, 1);
    expect(day.lateCount, 2);
    expect(day.mark, CalendarMark.late);
    expect(day.totalMinor, 100 + 200 + 100000);
  });

  test('earlier periods: unmarked recurring is a plain payment, not late '
      '(decision 24a); a late plan payment stays late', () async {
    await addRecurring(db, 'Kira', d(2026, 1, 1));
    await addSingle(db, d(2026, 9, 3), 100, title: 'Eski');
    final days = await month(2026, 9, today: d(2026, 11, 19));
    expect(days[d(2026, 9, 1)]!.mark, CalendarMark.pending);
    expect(days[d(2026, 9, 3)]!.mark, CalendarMark.late);
  });

  test('paid "today" from past due stays on its due day, paid', () async {
    final id = await addSingle(db, d(2026, 11, 10), 100, title: 'A');
    await PlanRepository(db)
        .setPaidOn(await paymentOf(db, id), d(2026, 11, 19));
    final days = await month(2026, 11, today: d(2026, 11, 19));
    expect(days[d(2026, 11, 10)]!.mark, CalendarMark.paid);
    expect(days.containsKey(d(2026, 11, 19)), isFalse);
  });

  test('payments paid before Kalan are never shown', () async {
    final id = await PlanRepository(db).saveDraft(
      PlanCalculator.manual(
        firstDate: d(2026, 10, 10),
        totalMinor: 300,
        count: 3,
        unit: IntervalUnit.month,
      ),
      sourceId: null,
      origin: PlanOrigin.manual,
      title: 'Sürüyor',
    );
    await PlanRepository(db).setPaidBefore(id, count: 1);
    final (plans, _) = await load();
    final before = plans.single.payments.singleWhere((p) => p.paidBeforeKalan);
    final shown = await month(2026, 10, today: d(2026, 11, 19));
    expect(shown.containsKey(LocalDate.fromEpochDay(before.dueDay)), isFalse);
    expect(shown.values.expand((v) => v.payments), isEmpty);
  });

  test('month end: payday 31 clamps to 28 Feb 2027, 29 Feb 2028, 30 Apr; '
      'a recurring 31st falls on the last day', () async {
    await addRecurring(db, 'Son gün', d(2026, 1, 31));
    const s = PaySchedule.monthly(31);
    final today = d(2026, 11, 19);
    final feb27 = await month(2027, 2, today: today, schedule: s);
    expect(feb27[d(2027, 2, 28)]!.isPayday, isTrue);
    expect(feb27[d(2027, 2, 28)]!.payments, hasLength(1));
    final feb28 = await month(2028, 2, today: today, schedule: s);
    expect(feb28[d(2028, 2, 29)]!.isPayday, isTrue);
    final apr = await month(2027, 4, today: today, schedule: s);
    expect(apr[d(2027, 4, 30)]!.isPayday, isTrue);
    expect(
      [
        for (final e in apr.entries)
          if (e.value.isPayday) e.key,
      ],
      [d(2027, 4, 30)],
    );
  });

  test('payday on the 1st, year turn: Dec 2026 and Jan 2027', () async {
    await addRecurring(
      db,
      'Yıl sonu',
      d(2026, 12, 31),
      recurrence: Recurrence.monthly,
    );
    const s = PaySchedule.monthly(1);
    final today = d(2026, 12, 20);
    final dec = await month(2026, 12, today: today, schedule: s);
    expect(dec[d(2026, 12, 1)]!.isPayday, isTrue);
    expect(dec[d(2026, 12, 31)]!.payments, hasLength(1));
    final jan = await month(2027, 1, today: today, schedule: s);
    expect(jan[d(2027, 1, 1)]!.isPayday, isTrue);
    expect(jan[d(2027, 1, 31)]!.payments, hasLength(1));
    expect(const CalendarMonth(2026, 12).add(1), const CalendarMonth(2027, 1));
    expect(const CalendarMonth(2027, 1).add(-1), const CalendarMonth(2026, 12));
    expect(
      const CalendarMonth(2026, 11).add(-12),
      const CalendarMonth(2025, 11),
    );
  });

  test('biweekly: three paydays in a month; weekly: five', () async {
    final bi = await month(
      2027,
      1,
      today: d(2026, 11, 19),
      schedule: PaySchedule.biweekly(d(2026, 11, 6)),
    );
    // 6 Nov + 14k: 1, 15 and 29 Jan 2027.
    expect(
      [
        for (final e in bi.entries)
          if (e.value.isPayday) e.key,
      ],
      [d(2027, 1, 1), d(2027, 1, 15), d(2027, 1, 29)],
    );
    final weekly = await month(
      2027,
      1,
      today: d(2026, 11, 19),
      schedule: PaySchedule.weekly(d(2026, 11, 6)),
    );
    expect(weekly.values.where((v) => v.isPayday), hasLength(5));
  });

  test('recurring end day on the month edge is included', () async {
    await addRecurring(db, 'Biten', d(2026, 1, 30), end: d(2027, 1, 30));
    final jan = await month(2027, 1, today: d(2026, 11, 19));
    expect(jan[d(2027, 1, 30)]!.payments, hasLength(1));
    final feb = await month(2027, 2, today: d(2026, 11, 19));
    expect(feb.values.expand((v) => v.payments), isEmpty);
  });

  test(
    'range: 12 months back, forward to the last payment, at least 6',
    () async {
      var (plans, recurring) = await load();
      final today = d(2026, 11, 19);
      var r = calendarRange(plans: plans, recurring: recurring, today: today);
      expect(r.first, const CalendarMonth(2025, 11));
      expect(r.last, const CalendarMonth(2027, 5));

      await addSingle(db, d(2028, 3, 4), 100, title: 'Uzak');
      // An open-ended recurring payment does not stretch the range.
      await addRecurring(db, 'Kira', d(2026, 1, 1));
      (plans, recurring) = await load();
      r = calendarRange(plans: plans, recurring: recurring, today: today);
      expect(r.last, const CalendarMonth(2028, 3));
    },
  );

  test('first weekday from the region: US Sunday, TR Monday', () {
    expect(firstWeekdayFor('en', 'US'), DateTime.sunday);
    expect(firstWeekdayFor('tr', 'TR'), DateTime.monday);
    expect(firstWeekdayFor('en', 'GB'), DateTime.monday);
    expect(firstWeekdayFor('tr'), DateTime.monday);
    // A Turkish phone in the US: Sunday, as the region.
    expect(firstWeekdayFor('tr', 'US'), DateTime.sunday);
    expect(firstWeekdayFor('tr', 'us'), DateTime.sunday);
    // No intl locale for language and region: the region's CLDR day.
    expect(firstWeekdayFor('en', 'TR'), DateTime.monday);
    expect(firstWeekdayFor('en', 'BR'), DateTime.sunday);
    expect(firstWeekdayFor('en', 'EG'), DateTime.saturday);
    expect(firstWeekdayFor('en', 'MV'), DateTime.friday);
    // A region the table does not list: Monday (CLDR 001).
    expect(firstWeekdayFor('en', 'ZZ'), DateTime.monday);
    // No region: the language's intl data; unknown language: null.
    expect(firstWeekdayFor('xx'), isNull);
  });

  test('grid: whole weeks from the first weekday', () {
    // 1 Nov 2026 is a Sunday.
    final mon = calendarGridDays(
      const CalendarMonth(2026, 11),
      DateTime.monday,
    );
    expect(mon.first, d(2026, 10, 26));
    expect(mon.length % 7, 0);
    expect(mon.last, d(2026, 12, 6));
    final sun = calendarGridDays(
      const CalendarMonth(2026, 11),
      DateTime.sunday,
    );
    expect(sun.first, d(2026, 11, 1));
    expect(sun.last, d(2026, 12, 5));
  });
}

/// A plain entry for the mark table.
abstract final class HomeEntryStub {
  static final entry = HomeEntry(
    name: 'X',
    date: LocalDate(2026, 11, 1),
    amountMinor: 1,
    isPaid: false,
  );
}
