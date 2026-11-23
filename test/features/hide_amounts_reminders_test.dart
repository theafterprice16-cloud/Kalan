import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/data/db/app_database.dart';
import 'package:kalan/features/privacy/amounts_hidden.dart';
import 'package:kalan/features/reminders/reminder_providers.dart';
import 'package:kalan/features/reminders/reminder_scheduler.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../helpers/app_harness.dart';
import '../helpers/fake_notifications.dart';

/// "Hide amounts" (28) in notifications, from the stored data to the
/// system: Example 6.

/// 20 Nov 2026, 08:00 in Istanbul.
DateTime clock() => DateTime.utc(2026, 11, 20, 5);

ReminderScheduler schedulerFor(
  AppDatabase db,
  FakeNotificationGateway gateway, {
  required bool hidden,
}) => ReminderScheduler(
  db: db,
  gateway: gateway,
  location: () => tz.getLocation('Europe/Istanbul'),
  now: clock,
  localeFor: (s) => Locale(s.localeCode ?? 'tr'),
  amountsHidden: () => hidden,
);

/// Reschedules run after a short debounce, off the UI; let them finish.
Future<void> settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.pump(const Duration(milliseconds: 400));
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  group('scheduler', () {
    late AppDatabase db;
    late FakeNotificationGateway gateway;
    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      gateway = FakeNotificationGateway();
      // Income ₺10.000; Klarna 4 × ₺100 from today; rent ₺15.000.
      await seedSettings(db, incomeMinor: 1000000);
      await seedPayIn4(db);
      await seedRent(db);
    });
    tearDown(() => db.close());

    for (final (show, hide, amounts) in [
      (true, false, true),
      (true, true, false),
      (false, false, false),
      (false, true, false),
    ]) {
      test('show amount $show, hide amounts $hide', () async {
        await (db.update(db.appSettings)..where((s) => s.id.equals(1))).write(
          AppSettingsCompanion(hideAmountsInNotifications: Value(!show)),
        );
        final scheduler = schedulerFor(db, gateway, hidden: hide);
        await scheduler.rescheduleAll();
        expect(gateway.pending, isNotEmpty);
        for (final r in gateway.all) {
          expect(r.body.contains('₺'), amounts, reason: r.body);
          expect(r.expandedBody.contains('₺'), amounts, reason: r.body);
        }
        // Combined: 1 Jan has Klarna 4/4 and the rent.
        expect(
          gateway.bodies,
          contains(
            amounts ? 'Bugün 2 ödeme var, toplam ₺15.100' : 'Bugün 2 ödeme var',
          ),
        );
        final payday = await scheduler.buildPaydaySummary();
        expect(payday!.body.contains('₺'), amounts, reason: payday.body);
        // "Hide amounts" never writes the other switch.
        final row = await db.select(db.appSettings).getSingle();
        expect(row.hideAmountsInNotifications, !show);
      });
    }
  });

  testWidgets('Example 6: the eye reschedules; the other switch stays', (
    tester,
  ) async {
    final gateway = FakeNotificationGateway();
    final store = MemoryAmountsHiddenStore();
    final db = await pumpApp(
      tester,
      seed: (db) async {
        await seedSettings(db, incomeMinor: 1000000);
        await seedPayIn4(db);
      },
      overrides: [
        notificationGatewayProvider.overrideWithValue(gateway),
        clockProvider.overrideWithValue(clock),
        amountsHiddenStoreProvider.overrideWithValue(store),
      ],
    );
    await settle(tester);
    expect(gateway.bodies.first, 'Bugün 1 ödeme var: Klarna, ₺100');
    expect(gateway.paydays.single.body, contains('₺'));
    final before = gateway.replaceCalls;

    await tester.tap(find.byKey(const ValueKey('hide-amounts')));
    await settle(tester);
    expect(gateway.replaceCalls, greaterThan(before));
    expect(gateway.bodies.first, 'Bugün 1 ödeme var: Klarna');
    expect(gateway.all.where((r) => r.body.contains('₺')), isEmpty);
    expect(
      gateway.paydays.single.body,
      'Yeni dönem başladı. Bu dönem 4 ödeme var.',
    );
    var row = await db.select(db.appSettings).getSingle();
    expect(row.hideAmountsInNotifications, isFalse);

    await tester.tap(find.byKey(const ValueKey('hide-amounts')));
    await settle(tester);
    expect(gateway.bodies.first, 'Bugün 1 ödeme var: Klarna, ₺100');
    row = await db.select(db.appSettings).getSingle();
    expect(row.hideAmountsInNotifications, isFalse);
  });
}
