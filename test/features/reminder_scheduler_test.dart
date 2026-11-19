import 'dart:io';
import 'dart:isolate';

import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/date/local_date.dart';
import 'package:kalan/core/engine/engine.dart' show PlanKind, underwayPlan;
import 'package:kalan/core/reminders/reminder_models.dart';
import 'package:kalan/data/db/app_database.dart';
import 'package:kalan/data/repositories/plan_repository.dart';
import 'package:kalan/data/repositories/recurring_repository.dart';
import 'package:kalan/data/repositories/source_repository.dart';
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
    // Fri 20 Nov, Fri 4 Dec, Fri 18 Dec, Fri 1 Jan; ₺100 each.
    await seedPayIn4(db);
  });
  tearDown(() => db.close());

  Future<List<String>> bodies() async => [
    for (final n in await schedulerFor(db, gateway).build()) n.body,
  ];

  test('stored payments: "2 days before" and "on the day" at 09:00', () async {
    final list = await schedulerFor(db, gateway).build();
    expect(list.first.fireAt.toUtc(), DateTime.utc(2026, 11, 20, 6)); // TRT
    expect(list.every((n) => n.title == 'Kalan'), isTrue);
    expect(list.every((n) => n.payload == reminderPayload), isTrue);
    expect(list.map((n) => n.body), [
      'Bugün 1 ödeme var: Klarna, ₺100',
      '4 Aralık Cuma günü 1 ödeme var: Klarna, ₺100',
      'Bugün 1 ödeme var: Klarna, ₺100',
      '18 Aralık Cuma günü 1 ödeme var: Klarna, ₺100',
      'Bugün 1 ödeme var: Klarna, ₺100',
      '1 Ocak Cuma günü 1 ödeme var: Klarna, ₺100',
      'Bugün 1 ödeme var: Klarna, ₺100',
    ]);
    expect(list[1].fireDate, LocalDate(2026, 12, 2));
  });

  test('recurring payments are included and merged with plans', () async {
    await seedRent(db); // 1st of every month, ₺15.000
    final texts = await bodies();
    expect(texts, contains('1 Aralık Salı günü 1 ödeme var: Kira, ₺15.000'));
    // 1 Jan: Klarna 4/4 and rent on the same day.
    expect(texts, contains('Bugün 2 ödeme var, toplam ₺15.100'));
  });

  test('settings: hidden amounts, 1 day, 20:30, English', () async {
    await setReminders(
      db,
      const AppSettingsCompanion(
        hideAmountsInNotifications: Value(true),
        reminderLeadDays: Value(1),
        reminderMinute: Value(20 * 60 + 30),
        localeCode: Value('en'),
      ),
    );
    final list = await schedulerFor(db, gateway).build();
    expect(list.first.body, '1 payment today: Klarna');
    expect(list[1].body, '1 payment on Friday, December 4: Klarna');
    expect(list[1].fireDate, LocalDate(2026, 12, 3));
    expect((list.first.fireAt.hour, list.first.fireAt.minute), (20, 30));
  });

  test('a currency change changes the text', () async {
    await setReminders(
      db,
      const AppSettingsCompanion(currencyCode: Value('IDR')),
    );
    expect((await bodies()).first, 'Bugün 1 ödeme var: Klarna, Rp10.000');
  });

  group('per plan', () {
    late int planId;
    setUp(() async => planId = (await db.select(db.plans).getSingle()).id);

    test('"Off": nothing for that plan', () async {
      await PlanRepository(db).setReminderChoice(planId, enabled: false);
      expect(await bodies(), isEmpty);
    });

    test('"Different day": its own days before', () async {
      await PlanRepository(db)
          .setReminderChoice(planId, enabled: true, leadDays: 5);
      final list = await schedulerFor(db, gateway).build();
      expect(list[1].fireDate, LocalDate(2026, 11, 29));
    });

    test('recurring payment "Off"', () async {
      final rentId = await seedRent(db);
      final repo = RecurringRepository(db);
      final rent = (await repo.byId(rentId))!;
      await repo.update(rent.copyWith(remindersEnabled: false));
      expect((await bodies()).any((b) => b.contains('Kira')), isFalse);
    });
  });

  group('rescheduling replaces what is pending', () {
    test('master switch off cancels everything', () async {
      final scheduler = schedulerFor(db, gateway);
      await scheduler.rescheduleAll();
      expect(gateway.pending, hasLength(7));
      await setReminders(
        db,
        const AppSettingsCompanion(remindersEnabled: Value(false)),
      );
      await scheduler.rescheduleAll();
      expect(gateway.pending, isEmpty);
    });

    test('a deleted plan leaves no reminder behind', () async {
      final scheduler = schedulerFor(db, gateway);
      await scheduler.rescheduleAll();
      final planId = (await db.select(db.plans).getSingle()).id;
      await PlanRepository(db).deletePlan(planId);
      await scheduler.rescheduleAll();
      expect(gateway.pending, isEmpty);
    });

    test(
      '"Paid" drops that payment\'s reminders, undo brings them back',
      () async {
        final scheduler = schedulerFor(db, gateway);
        await scheduler.rescheduleAll();
        final first = (await db.select(db.payments).get()).first;
        await PlanRepository(db).setPaid(first.id, paid: true, now: now);
        await scheduler.rescheduleAll();
        expect(gateway.pending.first.fireDate, LocalDate(2026, 12, 2));
        expect(gateway.pending, hasLength(6));

        await PlanRepository(db).setPaid(first.id, paid: false, now: now);
        await scheduler.rescheduleAll();
        expect(gateway.pending, hasLength(7));
      },
    );

    test('a settings change moves the reminders', () async {
      final scheduler = schedulerFor(db, gateway);
      await scheduler.rescheduleAll();
      await setReminders(
        db,
        const AppSettingsCompanion(reminderLeadDays: Value(7)),
      );
      await scheduler.rescheduleAll();
      expect(gateway.pending[1].fireDate, LocalDate(2026, 11, 27));
      expect(gateway.replaceCalls, 2);
    });

    test('the same data gives the same ids: no duplicates', () async {
      final scheduler = schedulerFor(db, gateway);
      await scheduler.rescheduleAll();
      final first = [for (final n in gateway.pending) n.id];
      await scheduler.rescheduleAll();
      expect([for (final n in gateway.pending) n.id], first);
      expect(first.toSet(), hasLength(first.length));
    });

    test('never more than 60 pending', () async {
      for (var i = 0; i < 30; i++) {
        await seedPayIn4(
          db,
          first: LocalDate(2026, 11, 21).addDays(i * 3),
          source: 'P$i',
        );
      }
      await schedulerFor(db, gateway).rescheduleAll();
      expect(gateway.pending, hasLength(60));
    });

    test('web or unsupported: nothing is touched', () async {
      final web = FakeNotificationGateway(supported: false);
      await schedulerFor(db, web).rescheduleAll();
      expect(web.replaceCalls, 0);
    });
  });

  group('statement closing reminder', () {
    Future<int> card({bool on = true, int days = 2}) =>
        SourceRepository(db, PlanRepository(db)).create(
          name: 'Bonus',
          kind: SourceKind.card,
          statementDay: 25,
          dueDay: 5,
          statementReminderEnabled: on,
          statementReminderDays: days,
        );

    String ids(List<PlannedReminder> list) =>
        [for (final r in list) '${r.id} ${r.fireAt} ${r.body}'].join('\n');

    test('switch off (the default): the list is exactly as before', () async {
      final scheduler = schedulerFor(db, gateway);
      final before = ids(await scheduler.buildAll());
      await card(on: false);
      await scheduler.rescheduleAll();
      expect(ids(gateway.all), before);
      expect(gateway.statements, isEmpty);
    });

    test('switch on: 2 days before the statement, at 09:00', () async {
      final id = await card();
      await schedulerFor(db, gateway).rescheduleAll();
      final first = gateway.statements.first;
      expect(first.fireAt.toUtc(), DateTime.utc(2026, 11, 23, 6)); // TRT
      expect(
        first.body,
        'Bonus kartının hesabı 2 gün sonra, 25 Kasım tarihinde kesiliyor. '
        'Bu tarihten sonraki taksitler 25 Aralık ekstresine girer.',
      );
      expect(first.payload, cardStatementPayload(id));
      expect(first.buttons, isEmpty);
      // The payment reminders do not change.
      expect(gateway.pending, hasLength(7));
      expect(gateway.all.length, 7 + 1 + statementClosingHorizon);
    });

    test('1 day before', () async {
      await card(days: 1);
      await schedulerFor(db, gateway).rescheduleAll();
      expect(gateway.statements.first.fireDate, LocalDate(2026, 11, 24));
      expect(gateway.statements.first.body, contains('1 gün sonra'));
    });

    test('a card without its days set gets none', () async {
      final id = await card();
      final row = await (db.select(
        db.sources,
      )..where((s) => s.id.equals(id))).getSingle();
      await db
          .update(db.sources)
          .replace(row.copyWith(dueDay: const Value(null)));
      await schedulerFor(db, gateway).rescheduleAll();
      expect(gateway.statements, isEmpty);
    });

    test('60 payment reminders: no statement reminder', () async {
      await card();
      for (var i = 0; i < 30; i++) {
        await seedPayIn4(
          db,
          first: LocalDate(2026, 11, 21).addDays(i * 3),
          source: 'P$i',
        );
      }
      await schedulerFor(db, gateway).rescheduleAll();
      expect(gateway.pending, hasLength(60));
      expect(gateway.statements, isEmpty);
      expect(gateway.all, hasLength(60));
    });
  });

  test('payments paid before Kalan are never reminded', () async {
    // Dates in the future on purpose: even then nothing is scheduled.
    final source = await SourceRepository(
      db,
      PlanRepository(db),
    ).findOrCreateProvider('Telefon');
    await PlanRepository(db).saveDraft(
      underwayPlan(
        kind: PlanKind.monthly,
        totalMinor: 30000,
        count: 3,
        paidCount: 2,
        nextDate: LocalDate(2027, 3, 10),
      ),
      sourceId: source,
      origin: PlanOrigin.template,
    );
    final list = await schedulerFor(db, gateway).build();
    final dates = {
      for (final n in list)
        for (final p in n.payments)
          if (p.name == 'Telefon') p.date,
    };
    expect(dates, {LocalDate(2027, 3, 10)});
  });

  test('another time zone keeps 09:00 local', () async {
    final london = await schedulerFor(
      db,
      gateway,
      zone: 'Europe/London',
    ).build();
    final istanbul = await schedulerFor(db, gateway).build();
    expect((london.first.fireAt.hour, istanbul.first.fireAt.hour), (9, 9));
    expect(
      london.first.fireAt.difference(istanbul.first.fireAt),
      const Duration(hours: 3),
    );
  });

  test('app closed (Android reboot or time change): a background isolate '
      'reschedules from the stored data', () async {
    final dir = await Directory.systemTemp.createTemp('kalan');
    final path = '${dir.path}/kalan.sqlite';
    final appDb = AppDatabase(NativeDatabase(File(path)));
    await seedSettings(appDb);
    await seedPayIn4(appDb);
    await appDb.close();

    final texts = await Isolate.run(() async {
      tzdata.initializeTimeZones();
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      final bg = AppDatabase(NativeDatabase(File(path)));
      final gw = FakeNotificationGateway();
      await ReminderScheduler(
        db: bg,
        gateway: gw,
        location: () => tz.getLocation('Europe/Istanbul'),
        now: () => DateTime.utc(2026, 11, 20, 5),
        localeFor: (_) => const Locale('tr'),
      ).rescheduleAll();
      await bg.close();
      return gw.bodies;
    });
    expect(texts.take(2), [
      'Bugün 1 ödeme var: Klarna, ₺100',
      '4 Aralık Cuma günü 1 ödeme var: Klarna, ₺100',
    ]);
    await dir.delete(recursive: true);
  });
}
