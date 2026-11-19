import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kalan/app/providers.dart';
import 'package:kalan/core/date/local_date.dart';
import 'package:kalan/core/money/currency.dart';
import 'package:kalan/core/reminders/reminder_models.dart';
import 'package:kalan/data/db/app_database.dart';
import 'package:kalan/data/repositories/plan_repository.dart';
import 'package:kalan/features/home/home_view.dart';
import 'package:kalan/features/reminders/reminder_scheduler.dart';
import 'package:kalan/features/reminders/reminder_texts.dart';
import 'package:kalan/l10n/generated/app_localizations.dart';
import 'package:material_ui/material_ui.dart' show Locale;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../helpers/app_harness.dart';
import '../helpers/fake_notifications.dart';

/// 20 Nov 2026, 08:00 in Istanbul (UTC+3). Payday is the 15th.
final now = DateTime.utc(2026, 11, 20, 5);

ReminderScheduler schedulerFor(
  AppDatabase db,
  FakeNotificationGateway gateway,
) => ReminderScheduler(
  db: db,
  gateway: gateway,
  location: () => tz.getLocation('Europe/Istanbul'),
  now: () => now,
  localeFor: (s) => Locale(s.localeCode ?? 'tr'),
);

void main() {
  setUpAll(() async {
    tzdata.initializeTimeZones();
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    await initializeDateFormatting('tr');
  });

  late AppDatabase db;
  late FakeNotificationGateway gateway;
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    gateway = FakeNotificationGateway();
    await seedSettings(db, incomeMinor: 2075000);
    // Fri 20 Nov, Fri 4 Dec, Fri 18 Dec, Fri 1 Jan; ₺100 each.
    await seedPayIn4(db);
  });
  tearDown(() => db.close());

  Future<void> setSettings(AppSettingsCompanion c) =>
      (db.update(db.appSettings)..where((s) => s.id.equals(1))).write(c);

  Future<PlannedReminder?> summary() async {
    await schedulerFor(db, gateway).rescheduleAll();
    expect(gateway.paydays.length, lessThanOrEqualTo(1));
    return gateway.paydays.firstOrNull;
  }

  test('on by default: the next 15th at 09:00, with the period\'s totals '
      'as the home screen will show them that morning', () async {
    final r = (await summary())!;
    expect(r.fireAt.toUtc(), DateTime.utc(2026, 12, 15, 6));
    expect(r.buttons, isEmpty);
    expect(r.payload, reminderPayload);
    // 15 Dec - 14 Jan: 18 Dec and 1 Jan, plus 20 Nov and 4 Dec still
    // unpaid (past due then, so they count in that period).
    expect(
      r.body,
      'Yeni dönem başladı. Bu dönem 4 ödeme, toplam ₺400. Kalan ₺20.350.',
    );
  });

  test('the same numbers as the home screen on that day', () async {
    await seedRent(db); // 1st of every month, ₺15.000
    await PlanRepository(db)
        .setPaidOn((await db.select(db.payments).get()).first.id, d(11, 20));
    final r = (await summary())!;

    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWithValue(LocalDate(2026, 12, 15)),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(homeViewProvider, (_, _) {});
    addTearDown(subscription.close);
    await container.read(settingsProvider.future);
    await container.read(plansProvider.future);
    await container.read(recurringProvider.future);
    final home = container.read(homeViewProvider)!.summary;
    expect(home.period.start, LocalDate(2026, 12, 15));

    final expected =
        L10nReminderTexts(
          l10n: lookupAppLocalizations(const Locale('tr')),
          currency: Currency.fromCode('TRY'),
        ).payday(
          PaydaySummary(
            date: home.period.start,
            paymentCount: home.itemCount,
            totalMinor: home.spokenForMinor,
            leftMinor: home.leftMinor,
          ),
          showAmounts: true,
        );
    expect(r.body, expected.body);
    // 4 Dec (past due), 18 Dec, rent 1 Jan, Klarna 1 Jan; 20 Nov was
    // paid on its day, in an earlier period.
    expect(home.itemCount, 4);
  });

  test('rebuilt with the data: a payment, the income, the payday', () async {
    expect((await summary())!.body, contains('4 ödeme, toplam ₺400'));

    // Paid in the app: no longer counted.
    final first = (await db.select(db.payments).get()).first;
    await PlanRepository(db).setPaid(first.id, paid: true);
    expect((await summary())!.body, contains('3 ödeme, toplam ₺300'));

    // Income cleared: count and total only.
    await setSettings(const AppSettingsCompanion(netIncomeMinor: Value(null)));
    expect(
      (await summary())!.body,
      'Yeni dönem başladı. Bu dönem 3 ödeme, toplam ₺300.',
    );

    // A smaller income: short, calmly.
    await setSettings(const AppSettingsCompanion(netIncomeMinor: Value(20000)));
    expect(
      (await summary())!.body,
      'Yeni dönem başladı. Bu dönem 3 ödeme, toplam ₺300. '
      'Bu dönem ₺100 eksik kalıyor.',
    );

    // Payday on the 1st: 1 Dec - 31 Dec.
    await setSettings(const AppSettingsCompanion(payDay: Value(1)));
    final r = (await summary())!;
    expect(r.fireDate, LocalDate(2026, 12, 1));
    expect(r.body, contains('2 ödeme, toplam ₺200'));
  });

  test('turned off, or reminders off: no summary, payment reminders as '
      'before', () async {
    await summary();
    final payments = [for (final r in gateway.pending) (r.id, r.body)];
    expect(payments, isNotEmpty);

    await setSettings(
      const AppSettingsCompanion(paydaySummaryEnabled: Value(false)),
    );
    expect(await summary(), equals(null));
    expect([for (final r in gateway.pending) (r.id, r.body)], payments);

    await setSettings(
      const AppSettingsCompanion(
        paydaySummaryEnabled: Value(true),
        remindersEnabled: Value(false),
      ),
    );
    expect(await summary(), equals(null));
    expect(gateway.all, isEmpty);
  });

  test('English, another currency and the reminder time', () async {
    await setSettings(
      const AppSettingsCompanion(
        localeCode: Value('en'),
        currencyCode: Value('JPY'),
        netIncomeMinor: Value(207500),
        reminderMinute: Value(20 * 60 + 30),
      ),
    );
    final r = (await summary())!;
    expect((r.fireAt.hour, r.fireAt.minute), (20, 30));
    expect(r.body, startsWith('A new pay period has started. 4 payments'));
    expect(r.body, contains('¥'));
  });

  test('scheduler: the summary alone, and in the list handed over', () async {
    final scheduler = schedulerFor(db, gateway);
    final alone = await scheduler.buildPaydaySummary();
    final payments = await scheduler.build();
    expect(payments.where((r) => r.isPaydaySummary), isEmpty);
    await scheduler.rescheduleAll();
    expect(gateway.all, hasLength(payments.length + 1));
    expect(gateway.paydays.single.id, alone!.id);
    expect(gateway.paydays.single.body, alone.body);
  });
}

LocalDate d(int m, int day) => LocalDate(2026, m, day);
