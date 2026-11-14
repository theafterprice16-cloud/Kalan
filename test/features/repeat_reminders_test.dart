import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/engine/engine.dart';
import 'package:kalan/core/reminders/reminder_models.dart';
import 'package:kalan/data/db/app_database.dart';
import 'package:kalan/data/repositories/plan_repository.dart';
import 'package:kalan/data/repositories/source_repository.dart';
import 'package:kalan/features/reminders/local_notifications.dart';
import 'package:kalan/features/reminders/reminder_actions.dart';
import 'package:kalan/features/reminders/reminder_providers.dart';
import 'package:kalan/features/reminders/reminder_scheduler.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../helpers/app_harness.dart';
import '../helpers/fake_notifications.dart';

late tz.Location istanbul;

DateTime at(LocalDate day, int hour, [int minute = 0]) =>
    tz.TZDateTime(istanbul, day.year, day.month, day.day, hour, minute).toUtc();

LocalDate d(int m, int day) => LocalDate(2026, m, day);

/// A one-payment plan; returns (plan id, payment id).
Future<(int, int)> seedOne(
  AppDatabase db,
  String name,
  LocalDate due, {
  int amountMinor = 40000,
}) async {
  final plans = PlanRepository(db);
  final source = await SourceRepository(db, plans).findOrCreateProvider(name);
  final planId = await plans.saveDraft(
    PlanCalculator.monthly(firstDate: due, totalMinor: amountMinor, count: 1),
    sourceId: source,
    origin: PlanOrigin.template,
  );
  final payment = await (db.select(
    db.payments,
  )..where((p) => p.planId.equals(planId))).getSingle();
  return (planId, payment.id);
}

Future<void> setGlobal(AppDatabase db, ReminderRepeat mode, {int? minute}) =>
    (db.update(db.appSettings)..where((s) => s.id.equals(1))).write(
      AppSettingsCompanion(
        repeatMode: Value(mode),
        reminderMinute: minute == null ? const Value.absent() : Value(minute),
      ),
    );

void main() {
  setUpAll(() {
    tzdata.initializeTimeZones();
    istanbul = tz.getLocation('Europe/Istanbul');
    tz.setLocalLocation(istanbul);
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  group('buttons on repeat reminders', () {
    late AppDatabase db;
    late FakeNotificationGateway gateway;
    late DateTime clock;
    late ReminderScheduler scheduler;
    late ReminderActionHandler handler;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      gateway = FakeNotificationGateway();
      clock = at(d(11, 23), 20);
      scheduler = ReminderScheduler(
        db: db,
        gateway: gateway,
        location: () => istanbul,
        now: () => clock,
        localeFor: (s) => Locale(s.localeCode ?? 'tr'),
      );
      handler = ReminderActionHandler(scheduler);
      await seedSettings(db);
    });
    tearDown(() => db.close());

    PlannedReminder pendingAt(LocalDate day, int hour) => gateway.pending
        .singleWhere((r) => r.fireDate == day && r.fireAt.hour == hour);

    Future<({ReminderActionOutcome outcome, int marked})> press(
      ReminderAction action,
      PlannedReminder r,
    ) => handler.handle(
      actionId: ReminderActionIds.of(action),
      payload: r.data!.encode(),
    );

    bool mentions(String name) =>
        gateway.pending.any((r) => r.payments.any((p) => p.name == name));

    test('Hiroshi: "Paid" on the 26th stops every repeat', () async {
      await setGlobal(db, ReminderRepeat.daily);
      final (planId, _) = await seedOne(db, 'Konbini', d(11, 27));
      await PlanRepository(db)
          .setReminderChoice(planId, enabled: true, leadDays: 3);
      await scheduler.rescheduleAll();
      expect(pendingAt(d(11, 24), 9).kind, ReminderKind.ahead);
      expect(pendingAt(d(11, 24), 20).kind, ReminderKind.ahead);
      expect(gateway.pending, hasLength(22));

      final morning = pendingAt(d(11, 26), 9);
      expect(morning.buttons.map((b) => b.title), ['Ödendi', 'Yarın hatırlat']);
      clock = at(d(11, 26), 12);
      final result = await press(ReminderAction.paid, morning);
      expect(result.marked, 1);
      expect(mentions('Konbini'), isFalse);
      expect(gateway.pending, isEmpty);
    });

    test('"All paid" on a merged overdue repeat', () async {
      await setGlobal(db, ReminderRepeat.daily);
      await seedOne(db, 'Zip', d(11, 18), amountMinor: 85000);
      await seedOne(db, 'Tabby', d(11, 17));
      clock = at(d(11, 20), 19);
      await scheduler.rescheduleAll();
      final r = pendingAt(d(11, 20), 20);
      expect(r.body, '2 ödeme henüz işaretlenmedi, toplam ₺1.250');
      expect(r.buttons.map((b) => b.title), ['Hepsi ödendi', 'Yarın hatırlat']);
      clock = at(d(11, 20), 20, 5);
      final result = await press(ReminderAction.allPaid, r);
      expect(result.marked, 2);
      expect(gateway.pending, isEmpty);
      // Past due when pressed: paid "today", as in the past-due list.
      final rows = await db.select(db.payments).get();
      expect(rows.every((p) => p.paidOnDay == d(11, 20).epochDay), isTrue);
    });

    test('Example 4: "Remind tomorrow" skips the rest of today', () async {
      await setGlobal(db, ReminderRepeat.daily);
      final (planId, _) = await seedOne(db, 'Konbini', d(11, 27));
      await PlanRepository(db)
          .setReminderChoice(planId, enabled: true, leadDays: 3);
      await scheduler.rescheduleAll();
      final morning = pendingAt(d(11, 25), 9);
      clock = at(d(11, 25), 9, 2);
      final result = await press(ReminderAction.remindTomorrow, morning);
      expect(result.outcome, ReminderActionOutcome.snoozed);
      // Pressed again: still one entry.
      await press(ReminderAction.remindTomorrow, morning);
      final rows = await db.select(db.reminderSnoozes).get();
      expect(rows, hasLength(1));
      expect(rows.single.skipsDay, isTrue);
      expect(rows.single.fireDay, d(11, 26).epochDay);

      expect(gateway.pending.any((r) => r.fireDate == d(11, 25)), isFalse);
      expect(pendingAt(d(11, 26), 9).kind, ReminderKind.ahead);
      expect(pendingAt(d(11, 26), 20).kind, ReminderKind.ahead);
      // Not a second reminder at 26 Nov 09:00.
      expect(
        gateway.pending.where(
          (r) => r.fireDate == d(11, 26) && r.fireAt.hour == 9,
        ),
        hasLength(1),
      );
      // Kept by a full reschedule, removed once paid.
      await scheduler.rescheduleAll();
      expect(gateway.pending.any((r) => r.fireDate == d(11, 25)), isFalse);
      await PlanRepository(db)
          .setPaid((await db.select(db.payments).getSingle()).id, paid: true);
      await scheduler.rescheduleAll();
      expect(await db.select(db.reminderSnoozes).get(), isEmpty);
    });

    test('Example 3: the last day has no "Remind tomorrow"', () async {
      await setGlobal(db, ReminderRepeat.daily);
      await seedOne(db, 'Tabby', d(11, 14));
      clock = at(d(11, 20), 21);
      await scheduler.rescheduleAll();
      final last = gateway.pending.last;
      expect(last.fireDate, d(11, 21));
      expect(last.fireAt.hour, 20);
      expect(
        last.body,
        "14 Kasım'daki 1 ödeme henüz işaretlenmedi: Tabby, ₺400",
      );
      expect(last.buttons.map((b) => b.action), [ReminderAction.paid]);
    });

    test('Example 2: morning on the day: [Paid] [Remind tomorrow]', () async {
      await setGlobal(db, ReminderRepeat.evening);
      await seedOne(db, 'Tabby', d(11, 26));
      await scheduler.rescheduleAll();
      expect(pendingAt(d(11, 26), 9).buttons.map((b) => b.title), [
        'Ödendi',
        'Yarın hatırlat',
      ]);
      expect(pendingAt(d(11, 26), 20).kind, ReminderKind.onDay);
      expect(gateway.pending.any((r) => r.fireDate == d(11, 25)), isFalse);
    });

    test('repeats off: the 4th item buttons are unchanged', () async {
      await seedOne(db, 'Tabby', d(11, 26));
      await scheduler.rescheduleAll();
      expect(pendingAt(d(11, 26), 9).buttons.map((b) => b.title), [
        'Ödendi',
        'Akşam hatırlat',
      ]);
      expect(pendingAt(d(11, 24), 9).buttons.map((b) => b.title), [
        'Ödendi',
        'Yarın hatırlat',
      ]);
      // "Remind tomorrow" there is the 4th item snooze, not a skip.
      clock = at(d(11, 24), 9, 2);
      await press(ReminderAction.remindTomorrow, pendingAt(d(11, 24), 9));
      final row = await db.select(db.reminderSnoozes).getSingle();
      expect(row.skipsDay, isFalse);
      // The snoozed one on the 25th and the on-day one on the 26th.
      expect(gateway.pending, hasLength(2));
      expect(gateway.pending.first.isSnoozed, isTrue);
    });

    test('the plan choice wins over the global one', () async {
      final (planId, _) = await seedOne(db, 'Tabby', d(11, 26));
      await PlanRepository(db).setRepeatMode(planId, ReminderRepeat.daily);
      await scheduler.rescheduleAll();
      expect(gateway.pending.any((r) => r.fireAt.hour == 20), isTrue);

      await setGlobal(db, ReminderRepeat.daily);
      await PlanRepository(db).setRepeatMode(planId, ReminderRepeat.off);
      await scheduler.rescheduleAll();
      expect(gateway.pending, hasLength(2));

      // The plan's reminders off: nothing at all.
      await PlanRepository(db).setRepeatMode(planId, null);
      await PlanRepository(db).setReminderChoice(planId, enabled: false);
      await scheduler.rescheduleAll();
      expect(gateway.pending, isEmpty);
    });

    test('reminder time 19:30: no 20:00, once a day', () async {
      await setGlobal(db, ReminderRepeat.daily, minute: 19 * 60 + 30);
      await seedOne(db, 'Tabby', d(11, 26));
      await scheduler.rescheduleAll();
      expect(gateway.pending.every((r) => r.fireAt.hour == 19), isTrue);
    });

    test('debug: three repeats a minute apart for the nearest one', () async {
      await setGlobal(db, ReminderRepeat.daily);
      await seedOne(db, 'Tabby', d(11, 26));
      await seedOne(db, 'Zip', d(12, 5));
      final now = tz.TZDateTime.from(clock, istanbul);
      final list = await scheduler.testRepeats(
        firstId: ReminderIds.testRepeats,
        times: [for (var i = 1; i <= 3; i++) now.add(Duration(minutes: i))],
      );
      expect(list.map((r) => r.id), [
        ReminderIds.testRepeats,
        ReminderIds.testRepeats + 1,
        ReminderIds.testRepeats + 2,
      ]);
      expect(list.every((r) => r.payments.single.name == 'Tabby'), isTrue);
      expect(list.first.buttons.map((b) => b.title), [
        'Ödendi',
        'Yarın hatırlat',
      ]);
      expect(list[1].fireAt.difference(list[0].fireAt).inMinutes, 1);
    });
  });

  group('screens', () {
    testWidgets('Settings: three choices, check mark, daily hint', (
      tester,
    ) async {
      final db = await pumpApp(
        tester,
        overrides: [
          notificationGatewayProvider.overrideWithValue(
            FakeNotificationGateway(),
          ),
        ],
        seed: seedSettings,
      );
      await openTab(tester, 'Ayarlar');
      final row = find.byKey(const ValueKey('reminder-repeat'));
      await scrollTo(tester, row);
      expect(
        find.descendant(of: row, matching: find.text('Israrlı hatırlatma')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: row, matching: find.text('Kapalı')),
        findsOneWidget,
      );
      expect(
        find.text(
          'Ödendi diyene kadar sakin aralıklarla yeniden hatırlatır. '
          'Son günden en fazla 7 gün sonrasına kadar sürer.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('repeat-daily-hint')), findsNothing);

      await tester.tap(row);
      await tester.pumpAndSettle();
      expect(find.text('Akşam bir kez daha'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('choice-ReminderRepeat.off')),
          matching: find.byIcon(Icons.check),
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Her gün'));
      await tester.pumpAndSettle();
      final settings = await tester.runAsync(
        () => db.select(db.appSettings).getSingle(),
      );
      expect(settings!.repeatMode, ReminderRepeat.daily);
      expect(
        find.text('Senin bildirim saatinde ve akşam 20:00\'de.'),
        findsOneWidget,
      );

      // Master switch off: inactive, value kept.
      await tester.runAsync(
        () => (db.update(db.appSettings)..where((s) => s.id.equals(1))).write(
          const AppSettingsCompanion(remindersEnabled: Value(false)),
        ),
      );
      await tester.pumpAndSettle();
      final tile = tester.widget<ListTile>(row);
      expect(tile.enabled, isFalse);
      expect(
        find.descendant(of: row, matching: find.text('Her gün')),
        findsOneWidget,
      );
    });

    testWidgets('plan: own choice, repeat icon and its label', (tester) async {
      final semantics = tester.ensureSemantics();
      late int planId;
      final db = await pumpApp(
        tester,
        seed: (db) async {
          await seedSettings(db);
          (planId, _) = await seedOne(db, 'Tabby', d(11, 26));
        },
      );
      await openTab(tester, 'Planlar');
      expect(find.byIcon(Icons.repeat), findsNothing);
      await tester.tap(find.text('Tabby'));
      await tester.pumpAndSettle();
      final tile = find.byKey(const ValueKey('item-repeat'));
      await scrollTo(tester, tile);
      expect(
        find.descendant(of: tile, matching: find.text('Genel ayar (Kapalı)')),
        findsOneWidget,
      );
      await tester.tap(tile);
      await tester.pumpAndSettle();
      expect(find.text('Genel ayar (Kapalı)'), findsNWidgets(2));
      await tester.tap(find.text('Her gün'));
      await tester.pumpAndSettle();
      final plan = await tester.runAsync(
        () => (db.select(
          db.plans,
        )..where((p) => p.id.equals(planId))).getSingle(),
      );
      expect(plan!.repeatMode, ReminderRepeat.daily);
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 2000));
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel(RegExp('Israrlı hatırlatma açık')),
        findsOneWidget,
      );

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      // The list row reads as one item; the label is part of it.
      expect(
        find.bySemanticsLabel(RegExp('Israrlı hatırlatma açık')),
        findsOneWidget,
      );

      // The plan's reminders off: the choice is inactive, no icon.
      await tester.runAsync(
        () => PlanRepository(db).setReminderChoice(planId, enabled: false),
      );
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel(RegExp('Israrlı hatırlatma açık')),
        findsNothing,
      );
      await tester.tap(find.text('Tabby'));
      await tester.pumpAndSettle();
      await scrollTo(tester, tile);
      expect(tester.widget<ListTile>(tile).enabled, isFalse);
      semantics.dispose();
    });

    testWidgets('English labels', (tester) async {
      await pumpApp(
        tester,
        locale: const Locale('en', 'US'),
        overrides: [
          notificationGatewayProvider.overrideWithValue(
            FakeNotificationGateway(),
          ),
        ],
        seed: (db) async {
          await seedSettings(db);
          await setGlobal(db, ReminderRepeat.daily);
        },
      );
      await openTab(tester, 'Settings');
      final row = find.byKey(const ValueKey('reminder-repeat'));
      await scrollTo(tester, row);
      expect(find.text('Repeat reminders'), findsOneWidget);
      expect(find.text('Every day'), findsOneWidget);
      expect(
        find.text('At your reminder time and at 8:00 PM.'),
        findsOneWidget,
      );
    });

    testWidgets('debug: repeat test button', (tester) async {
      final gateway = FakeNotificationGateway();
      await pumpApp(
        tester,
        today: d(11, 20),
        overrides: [
          notificationGatewayProvider.overrideWithValue(gateway),
          clockProvider.overrideWithValue(() => at(d(11, 20), 12)),
        ],
        seed: (db) async {
          await seedSettings(db);
          await seedOne(db, 'Tabby', d(11, 26));
        },
      );
      await openTab(tester, 'Ayarlar');
      final button = find.byKey(const ValueKey('test-repeats'));
      await scrollTo(tester, button);
      expect(
        find.text("Israrlı deneme (1'er dakika arayla 3 bildirim)"),
        findsOneWidget,
      );
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(gateway.testReminder!.id, ReminderIds.testRepeats + 2);
      expect(gateway.testReminder!.payments.single.name, 'Tabby');
    });
  });
}
