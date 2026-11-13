import 'dart:io';
import 'dart:isolate';

import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/date/local_date.dart';
import 'package:kalan/core/reminders/reminder_models.dart';
import 'package:kalan/data/db/app_database.dart';
import 'package:kalan/data/repositories/plan_repository.dart';
import 'package:kalan/features/reminders/notification_gateway.dart';
import 'package:kalan/features/reminders/reminder_scheduler.dart';
import 'package:material_ui/material_ui.dart' show Locale;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../helpers/app_harness.dart';
import '../helpers/fake_notifications.dart';

/// 20 Nov 2026, 08:00 in Istanbul (UTC+3).
final now = DateTime.utc(2026, 11, 20, 5);

ReminderScheduler schedulerFor(
  AppDatabase db,
  FakeNotificationGateway gateway, {
  String zone = 'Europe/Istanbul',
}) => ReminderScheduler(
  db: db,
  gateway: gateway,
  location: () => tz.getLocation(zone),
  now: () => now,
  localeFor: (s) => Locale(s.localeCode ?? 'tr'),
);

Future<void> setReminders(AppDatabase db, AppSettingsCompanion c) =>
    (db.update(db.appSettings)..where((s) => s.id.equals(1))).write(c);

void main() {
  setUpAll(() {
    tzdata.initializeTimeZones();
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  late AppDatabase db;
  late FakeNotificationGateway gateway;
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    gateway = FakeNotificationGateway();
    await seedSettings(db);
    // 20 Nov, 4 Dec, 18 Dec, 1 Jan; 100 TL each.
    await seedPayIn4(db);
  });
  tearDown(() => db.close());

  test('stored payments become notifications with engine dates', () async {
    final list = await schedulerFor(db, gateway).build();
    final first = list.first;
    expect(first.text, 'Bugün: Klarna 1/4 · ₺100');
    expect(first.fireAt.toUtc(), DateTime.utc(2026, 11, 20, 6)); // 09:00 TRT
    expect(first.hasPaidAction, isTrue);
    final paymentId = (await db.select(db.payments).get()).first.id;
    expect(first.payload.encode(), '/day/2026-11-20|p:$paymentId');
    expect(list.map((n) => n.text).toList(), [
      'Bugün: Klarna 1/4 · ₺100',
      '3 gün sonra: Klarna 2/4 · ₺100',
      'Bugün: Klarna 2/4 · ₺100',
      '3 gün sonra: Klarna 3/4 · ₺100',
      'Bugün: Klarna 3/4 · ₺100',
      '3 gün sonra: Klarna 4/4 · ₺100',
      'Bugün: Klarna 4/4 · ₺100',
    ]);
  });

  test('recurring payments are reminded too, grouped with plans', () async {
    await seedRent(db); // 1st of every month, 15.000 TL
    final texts = [
      for (final n in await schedulerFor(db, gateway).build()) n.text,
    ];
    expect(texts, contains('3 gün sonra: Kira · ₺15.000'));
    expect(texts, contains('Bugün: Kira · ₺15.000'));
    // 1 Jan: Klarna 4/4 and rent on the same day.
    expect(texts, contains('Bugün 2 ödemen var · toplam ₺15.100'));
  });

  test('settings: hidden amounts, other offsets, time, language', () async {
    await setReminders(
      db,
      const AppSettingsCompanion(
        hideAmountsInNotifications: Value(true),
        remindDays3: Value(false),
        remindDays1: Value(true),
        reminderMinute: Value(20 * 60 + 30),
        localeCode: Value('en'),
      ),
    );
    final list = await schedulerFor(db, gateway).build();
    expect(list.first.text, 'Today you have 1 payment');
    expect(list[1].text, 'Tomorrow you have 1 payment');
    expect(list.first.fireAt.hour, 20);
    expect(list.first.fireAt.minute, 30);
  });

  test(
    'nothing is scheduled when switched off, globally or per plan',
    () async {
      await setReminders(
        db,
        const AppSettingsCompanion(remindersEnabled: Value(false)),
      );
      expect(await schedulerFor(db, gateway).build(), isEmpty);

      await setReminders(
        db,
        const AppSettingsCompanion(remindersEnabled: Value(true)),
      );
      final planId = (await db.select(db.plans).getSingle()).id;
      await PlanRepository(db).setRemindersEnabled(planId, enabled: false);
      expect(await schedulerFor(db, gateway).build(), isEmpty);
    },
  );

  test('another time zone keeps 09:00 local', () async {
    final london = await schedulerFor(
      db,
      gateway,
      zone: 'Europe/London',
    ).build();
    final istanbul = await schedulerFor(db, gateway).build();
    expect(london.first.fireAt.hour, 9);
    expect(istanbul.first.fireAt.hour, 9);
    expect(
      london.first.fireAt.difference(istanbul.first.fireAt),
      const Duration(hours: 3),
    );
  });

  test('Paid action marks the payment and drops its reminders', () async {
    final scheduler = schedulerFor(db, gateway);
    await scheduler.rescheduleAll();
    final today = gateway.pending.first;
    expect(today.hasPaidAction, isTrue);

    final handled = await handlePaidAction(
      payload: today.payload.encode(),
      notificationId: today.id,
      scheduler: scheduler,
      now: now,
    );
    expect(handled, isTrue);
    final first = (await db.select(db.payments).get()).first;
    expect(first.paidAt, isNotNull);
    expect(gateway.cancelled, [today.id]);
    expect(gateway.texts, isNot(contains('Bugün: Klarna 1/4 · ₺100')));
    expect(gateway.texts.first, '3 gün sonra: Klarna 2/4 · ₺100');
  });

  test('Paid action on a recurring payment marks that occurrence', () async {
    final rentId = await seedRent(db);
    final day = LocalDate(2026, 12, 1).epochDay;
    final payload = NotificationPayload(
      route: '/day/2026-12-01',
      paymentRef: RecurringRef(rentId, day).encode(),
    ).encode();
    await handlePaidAction(
      payload: payload,
      notificationId: 7,
      scheduler: schedulerFor(db, gateway),
    );
    final marks = await db.select(db.recurringMarks).get();
    expect(marks.single.occurrenceDay, day);
  });

  test('payloads without a payment are ignored', () async {
    for (final payload in [null, '/day/2026-11-20', 'garbage']) {
      expect(
        await handlePaidAction(
          payload: payload,
          notificationId: 1,
          scheduler: schedulerFor(db, gateway),
        ),
        isFalse,
      );
    }
    expect(gateway.replaceCalls, 0);
  });

  test(
    'Paid with the app closed: a background isolate marks the payment',
    () async {
      // The app's database lives in a file; the app is closed.
      final dir = await Directory.systemTemp.createTemp('kalan');
      final path = '${dir.path}/kalan.sqlite';
      final appDb = AppDatabase(NativeDatabase(File(path)));
      await seedSettings(appDb);
      await seedPayIn4(appDb);
      final scheduler = schedulerFor(appDb, FakeNotificationGateway());
      final payload = (await scheduler.build()).first.payload.encode();
      await appDb.close();

      // What the notification plugin does: run the handler in a separate
      // isolate that opens the database on its own.
      final remaining = await Isolate.run(() async {
        tzdata.initializeTimeZones();
        driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
        final bg = AppDatabase(NativeDatabase(File(path)));
        final gw = FakeNotificationGateway();
        await handlePaidAction(
          payload: payload,
          notificationId: 1,
          scheduler: ReminderScheduler(
            db: bg,
            gateway: gw,
            location: () => tz.getLocation('Europe/Istanbul'),
            now: () => DateTime.utc(2026, 11, 20, 5),
            localeFor: (_) => const Locale('tr'),
          ),
        );
        await bg.close();
        return gw.texts;
      });
      expect(remaining.first, '3 gün sonra: Klarna 2/4 · ₺100');

      final reopened = AppDatabase(NativeDatabase(File(path)));
      final payments = await reopened.select(reopened.payments).get();
      expect(payments.first.paidAt, isNotNull);
      expect(payments.skip(1).every((p) => p.paidAt == null), isTrue);
      await reopened.close();
      await dir.delete(recursive: true);
    },
  );
}
