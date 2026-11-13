import 'dart:io';

import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/engine/engine.dart';
import 'package:kalan/core/reminders/reminder_models.dart';
import 'package:kalan/core/reminders/reminder_planner.dart';
import 'package:kalan/data/db/app_database.dart';
import 'package:kalan/data/repositories/plan_repository.dart';
import 'package:kalan/data/repositories/recurring_repository.dart';
import 'package:kalan/data/repositories/source_repository.dart';
import 'package:kalan/features/reminders/local_notifications.dart';
import 'package:kalan/features/reminders/reminder_actions.dart';
import 'package:kalan/features/reminders/reminder_providers.dart';
import 'package:kalan/features/reminders/reminder_scheduler.dart';
import 'package:kalan/l10n/generated/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../helpers/app_harness.dart';
import '../helpers/fake_notifications.dart';

late tz.Location istanbul;

/// A wall-clock moment in Istanbul, as the UTC instant the clock returns.
DateTime at(LocalDate day, int hour, [int minute = 0]) =>
    tz.TZDateTime(istanbul, day.year, day.month, day.day, hour, minute).toUtc();

LocalDate d(int m, int day) => LocalDate(2026, m, day);

/// A one-payment plan; returns the payment's id.
Future<int> seedOne(
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
  return payment.id;
}

Future<PaymentRow> paymentOf(AppDatabase db, int id) =>
    (db.select(db.payments)..where((p) => p.id.equals(id))).getSingle();

void main() {
  setUpAll(() {
    tzdata.initializeTimeZones();
    istanbul = tz.getLocation('Europe/Istanbul');
    tz.setLocalLocation(istanbul);
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  late AppDatabase db;
  late FakeNotificationGateway gateway;
  late DateTime clock;
  late ReminderScheduler scheduler;
  late ReminderActionHandler handler;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    gateway = FakeNotificationGateway();
    clock = at(d(11, 10), 20);
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

  /// The pending notification of [kind] on [day], as the system holds it.
  PlannedReminder pending(
    LocalDate day,
    ReminderKind kind, {
    bool snoozed = false,
  }) => gateway.pending.singleWhere(
    (r) => r.fireDate == day && r.kind == kind && r.isSnoozed == snoozed,
  );

  Future<({ReminderActionOutcome outcome, int marked})> press(
    ReminderAction action,
    PlannedReminder r,
  ) => handler.handle(
    actionId: ReminderActionIds.of(action),
    payload: r.data!.encode(),
  );

  bool mentions(String name) =>
      gateway.pending.any((r) => r.payments.any((p) => p.name == name));

  group('"Paid"', () {
    test('Can: Tabby is paid, no more reminders for it', () async {
      final tabby = await seedOne(db, 'Tabby', d(11, 14));
      await scheduler.rescheduleAll();
      final onDay = pending(d(11, 14), ReminderKind.onDay);
      expect(onDay.body, 'Bugün 1 ödeme var: Tabby, ₺400');
      expect(onDay.buttons.map((b) => b.title), ['Ödendi', 'Akşam hatırlat']);

      clock = at(d(11, 14), 9, 1);
      final result = await press(ReminderAction.paid, onDay);
      expect(result.outcome, ReminderActionOutcome.markedPaid);
      expect(result.marked, 1);
      final row = await paymentOf(db, tabby);
      expect(row.paidAt, isNotNull);
      // On time: no paid-on day, it stays in its own period.
      expect(row.paidOnDay, isNull);
      expect(mentions('Tabby'), isFalse);
    });

    test('Example 2: paid from "ahead", the on-day one is not set', () async {
      await seedOne(db, 'Tabby', d(11, 14));
      await scheduler.rescheduleAll();
      final ahead = pending(d(11, 12), ReminderKind.ahead);
      expect(ahead.buttons.map((b) => b.title), ['Ödendi', 'Yarın hatırlat']);
      clock = at(d(11, 12), 9, 1);
      await press(ReminderAction.paid, ahead);
      expect(mentions('Tabby'), isFalse);
    });

    test('Example 4: "All paid" marks every payment in it', () async {
      final ids = [
        await seedOne(db, 'Tabby', d(11, 14)),
        await seedOne(db, 'Klarna', d(11, 14), amountMinor: 85000),
        await seedOne(db, 'Zip', d(11, 14), amountMinor: 120000),
      ];
      await scheduler.rescheduleAll();
      final onDay = pending(d(11, 14), ReminderKind.onDay);
      expect(onDay.body, 'Bugün 3 ödeme var, toplam ₺2.450');
      expect(onDay.buttons.map((b) => b.action), [
        ReminderAction.allPaid,
        ReminderAction.remindTonight,
      ]);
      clock = at(d(11, 14), 9, 1);
      final result = await press(ReminderAction.allPaid, onDay);
      expect(result.marked, 3);
      for (final id in ids) {
        expect((await paymentOf(db, id)).paidAt, isNotNull);
      }
      expect(gateway.pending, isEmpty);
    });

    test('a merged reminder is rebuilt without the paid one', () async {
      final a = await seedOne(db, 'Tabby', d(11, 14));
      await seedOne(db, 'Zip', d(11, 14));
      await scheduler.rescheduleAll();
      final ahead = pending(d(11, 12), ReminderKind.ahead);
      clock = at(d(11, 12), 9, 1);
      // A was paid in the app meanwhile; the button marks only B.
      await PlanRepository(db).setPaid(a, paid: true);
      final result = await press(ReminderAction.allPaid, ahead);
      expect(result.marked, 1);
      expect(gateway.pending, isEmpty);
    });

    test('A paid early: the on-day reminder carries only B', () async {
      final a = await seedOne(db, 'Tabby', d(11, 14));
      await seedOne(db, 'Zip', d(11, 14));
      await scheduler.rescheduleAll();
      expect(pending(d(11, 14), ReminderKind.onDay).payments, hasLength(2));
      final ahead = gateway.pending
          .where((r) => r.kind == ReminderKind.ahead)
          .first;
      await handler.handle(
        actionId: ReminderActionIds.of(ReminderAction.paid),
        payload: ReminderPayload(
          kind: ahead.kind,
          fireDate: ahead.fireDate,
          minuteOfDay: 540,
          refs: [PlanPaymentRef(a)],
        ).encode(),
      );
      final onDay = pending(d(11, 14), ReminderKind.onDay);
      expect(onDay.payments.map((p) => p.name), ['Zip']);
      expect(onDay.buttons.first.action, ReminderAction.paid);
    });

    test('already paid: nothing changes, no error', () async {
      final tabby = await seedOne(db, 'Tabby', d(11, 14));
      await scheduler.rescheduleAll();
      final onDay = pending(d(11, 14), ReminderKind.onDay);
      final paidAt = DateTime.utc(2026, 11, 11, 7);
      await PlanRepository(db).setPaid(tabby, paid: true, now: paidAt);
      clock = at(d(11, 14), 9, 1);
      final result = await press(ReminderAction.paid, onDay);
      expect(result.marked, 0);
      final after = (await paymentOf(db, tabby)).paidAt!;
      expect(after.isAtSameMomentAs(paidAt), isTrue);
    });

    test('Example 6: plan deleted: nothing happens, no error', () async {
      final tabby = await seedOne(db, 'Tabby', d(11, 14));
      await scheduler.rescheduleAll();
      final onDay = pending(d(11, 14), ReminderKind.onDay);
      final planId = (await paymentOf(db, tabby)).planId;
      await PlanRepository(db).deletePlan(planId);
      clock = at(d(11, 14), 9, 1);
      final result = await press(ReminderAction.paid, onDay);
      expect(result.outcome, ReminderActionOutcome.markedPaid);
      expect(result.marked, 0);
      expect(await db.select(db.payments).get(), isEmpty);
    });

    test('pressed twice at once: marked once', () async {
      final tabby = await seedOne(db, 'Tabby', d(11, 14));
      await scheduler.rescheduleAll();
      final onDay = pending(d(11, 14), ReminderKind.onDay);
      clock = at(d(11, 14), 9, 1);
      final results = await Future.wait([
        press(ReminderAction.paid, onDay),
        press(ReminderAction.paid, onDay),
      ]);
      expect(results.map((r) => r.marked).reduce((a, b) => a + b), 1);
      final first = (await paymentOf(db, tabby)).paidAt;
      clock = at(d(11, 14), 9, 30);
      await press(ReminderAction.paid, onDay);
      expect((await paymentOf(db, tabby)).paidAt, first);
    });

    test(
      'past due when pressed: paid "today", like the past-due list',
      () async {
        final tabby = await seedOne(db, 'Tabby', d(11, 14));
        await scheduler.rescheduleAll();
        final onDay = pending(d(11, 14), ReminderKind.onDay);
        // Pressed the next morning.
        clock = at(d(11, 15), 8, 30);
        await press(ReminderAction.paid, onDay);
        final row = await paymentOf(db, tabby);
        expect(row.paidAt, isNotNull);
        expect(row.paidOnDay, d(11, 15).epochDay);
      },
    );

    test('recurring payment: that occurrence is marked, once', () async {
      final rent = await seedRent(db); // 1st of every month
      clock = at(d(11, 28), 20);
      await scheduler.rescheduleAll();
      final onDay = pending(d(12, 1), ReminderKind.onDay);
      expect(onDay.payments.single.name, 'Kira');
      clock = at(d(12, 1), 9, 1);
      await press(ReminderAction.paid, onDay);
      await press(ReminderAction.paid, onDay);
      final marks = await db.select(db.recurringMarks).get();
      expect(marks.single.recurringId, rent);
      expect(marks.single.occurrenceDay, d(12, 1).epochDay);
      expect(gateway.pending.any((r) => r.fireDate == d(12, 1)), isFalse);
    });

    test('recurring payment removed: nothing happens', () async {
      final rent = await seedRent(db);
      clock = at(d(11, 28), 20);
      await scheduler.rescheduleAll();
      final onDay = pending(d(12, 1), ReminderKind.onDay);
      await RecurringRepository(db).delete(rent);
      final result = await press(ReminderAction.paid, onDay);
      expect(result.marked, 0);
      expect(await db.select(db.recurringMarks).get(), isEmpty);
    });

    test('unreadable payloads and foreign buttons do nothing', () async {
      final tabby = await seedOne(db, 'Tabby', d(11, 14));
      await scheduler.rescheduleAll();
      final payload = pending(d(11, 14), ReminderKind.onDay).data!.encode();
      final calls = gateway.replaceCalls;
      for (final (actionId, raw) in [
        ('kalan.paid', 'home'),
        ('kalan.paid', '{"v":1'),
        ('kalan.paid', null),
        ('something_else', payload),
        (null, payload),
      ]) {
        final result = await handler.handle(actionId: actionId, payload: raw);
        expect(result.outcome, ReminderActionOutcome.ignored);
      }
      expect((await paymentOf(db, tabby)).paidAt, isNull);
      expect(gateway.replaceCalls, calls);
    });
  });

  group('"Remind tonight" / "Remind tomorrow"', () {
    test('tonight: one snoozed reminder at 20:00, only "Paid"', () async {
      await seedOne(db, 'Tabby', d(11, 14));
      await scheduler.rescheduleAll();
      final onDay = pending(d(11, 14), ReminderKind.onDay);
      clock = at(d(11, 14), 9, 1);
      final result = await press(ReminderAction.remindTonight, onDay);
      expect(result.outcome, ReminderActionOutcome.snoozed);
      // Pressed again (or delivered twice): still one.
      await press(ReminderAction.remindTonight, onDay);
      expect(await db.select(db.reminderSnoozes).get(), hasLength(1));
      final later = pending(d(11, 14), ReminderKind.onDay, snoozed: true);
      expect(later.fireAt.toUtc(), at(d(11, 14), 20));
      expect(later.body, onDay.body);
      expect(later.buttons.map((b) => b.title), ['Ödendi']);
    });

    test('Example 3: tomorrow at the same time; the on-day stays', () async {
      await setTime(db, 10 * 60 + 15);
      await seedOne(db, 'Tabby', d(11, 14));
      await scheduler.rescheduleAll();
      final ahead = pending(d(11, 12), ReminderKind.ahead);
      clock = at(d(11, 12), 10, 16);
      await press(ReminderAction.remindTomorrow, ahead);
      final later = pending(d(11, 13), ReminderKind.ahead, snoozed: true);
      expect(later.fireAt.toUtc(), at(d(11, 13), 10, 15));
      expect(later.body, ahead.body);
      expect(later.buttons.map((b) => b.action), [ReminderAction.paid]);
      expect(pending(d(11, 14), ReminderKind.onDay), isNotNull);

      // A full reschedule (any change in the app) keeps it.
      await scheduler.rescheduleAll();
      await scheduler.rescheduleAll();
      expect(
        pending(d(11, 13), ReminderKind.ahead, snoozed: true).id,
        later.id,
      );
    });

    test('Example 4: one paid in the app, 20:00 has the other two', () async {
      final ids = [
        await seedOne(db, 'Tabby', d(11, 14)),
        await seedOne(db, 'Klarna', d(11, 14), amountMinor: 85000),
        await seedOne(db, 'Zip', d(11, 14), amountMinor: 120000),
      ];
      await scheduler.rescheduleAll();
      final onDay = pending(d(11, 14), ReminderKind.onDay);
      clock = at(d(11, 14), 9, 1);
      await press(ReminderAction.remindTonight, onDay);
      await PlanRepository(db).setPaid(ids[1], paid: true);
      await scheduler.rescheduleAll();
      final later = pending(d(11, 14), ReminderKind.onDay, snoozed: true);
      expect(later.payments.map((p) => p.name), ['Tabby', 'Zip']);
      expect(later.buttons.single.action, ReminderAction.allPaid);

      // "All paid" on the snoozed one, then nothing is left.
      final result = await press(ReminderAction.allPaid, later);
      expect(result.marked, 2);
      expect(await db.select(db.reminderSnoozes).get(), isEmpty);
      expect(gateway.pending, isEmpty);
    });

    test('paid in the app or plan deleted: the snooze goes too', () async {
      final tabby = await seedOne(db, 'Tabby', d(11, 14));
      await scheduler.rescheduleAll();
      final onDay = pending(d(11, 14), ReminderKind.onDay);
      clock = at(d(11, 14), 9, 1);
      await press(ReminderAction.remindTonight, onDay);
      expect(await db.select(db.reminderSnoozes).get(), hasLength(1));
      final planId = (await paymentOf(db, tabby)).planId;
      await PlanRepository(db).deletePlan(planId);
      await scheduler.rescheduleAll();
      expect(await db.select(db.reminderSnoozes).get(), isEmpty);
    });

    test('passed snoozes are cleaned up', () async {
      await seedOne(db, 'Tabby', d(11, 14));
      await scheduler.rescheduleAll();
      final onDay = pending(d(11, 14), ReminderKind.onDay);
      clock = at(d(11, 14), 9, 1);
      await press(ReminderAction.remindTonight, onDay);
      clock = at(d(11, 14), 20, 5);
      await scheduler.rescheduleAll();
      expect(await db.select(db.reminderSnoozes).get(), isEmpty);
    });

    test('"tonight" after 20:00 stores nothing', () async {
      await seedOne(db, 'Tabby', d(11, 14));
      await scheduler.rescheduleAll();
      final onDay = pending(d(11, 14), ReminderKind.onDay);
      clock = at(d(11, 14), 20, 30);
      final result = await press(ReminderAction.remindTonight, onDay);
      expect(result.outcome, ReminderActionOutcome.tooLate);
      expect(await db.select(db.reminderSnoozes).get(), isEmpty);
    });

    test('Example 5: reminder time 20:30, only "Paid" on the day', () async {
      await setTime(db, 20 * 60 + 30);
      await seedOne(db, 'Tabby', d(11, 14));
      await scheduler.rescheduleAll();
      expect(
        pending(d(11, 14), ReminderKind.onDay).buttons.map((b) => b.action),
        [ReminderAction.paid],
      );
    });

    test('a snoozed reminder cannot be snoozed again', () async {
      await seedOne(db, 'Tabby', d(11, 14));
      await scheduler.rescheduleAll();
      clock = at(d(11, 14), 9, 1);
      await press(
        ReminderAction.remindTonight,
        pending(d(11, 14), ReminderKind.onDay),
      );
      final later = pending(d(11, 14), ReminderKind.onDay, snoozed: true);
      final result = await press(ReminderAction.remindTonight, later);
      expect(result.outcome, ReminderActionOutcome.ignored);
      expect(await db.select(db.reminderSnoozes).get(), hasLength(1));
    });
  });

  test('English: the buttons follow the app language', () async {
    await (db.update(db.appSettings)..where((s) => s.id.equals(1))).write(
      const AppSettingsCompanion(localeCode: Value('en')),
    );
    await seedOne(db, 'Tabby', d(11, 14));
    await seedOne(db, 'Zip', d(11, 20));
    await seedOne(db, 'Klarna', d(11, 20));
    await scheduler.rescheduleAll();
    expect(pending(d(11, 14), ReminderKind.onDay).buttons.map((b) => b.title), [
      'Paid',
      'Remind tonight',
    ]);
    expect(pending(d(11, 12), ReminderKind.ahead).buttons.map((b) => b.title), [
      'Paid',
      'Remind tomorrow',
    ]);
    expect(pending(d(11, 20), ReminderKind.onDay).buttons.map((b) => b.title), [
      'All paid',
      'Remind tonight',
    ]);
  });

  group('platform setup', () {
    test('iOS categories: "Paid" asks to unlock, nothing opens the app', () {
      for (final lang in ['tr', 'en']) {
        final l10n = lookupAppLocalizations(Locale(lang));
        final categories = reminderCategories(reminderButtonTitles(l10n));
        expect(categories, hasLength(6));
        for (final c in categories) {
          for (final a in c.actions) {
            final action = ReminderActionIds.parse(a.identifier)!;
            expect(
              a.options.contains(
                DarwinNotificationActionOption.authenticationRequired,
              ),
              action.marksPaid,
            );
            expect(
              a.options.contains(DarwinNotificationActionOption.foreground),
              isFalse,
            );
          }
        }
        final titles = {
          for (final c in categories)
            for (final a in c.actions) a.title,
        };
        expect(
          titles,
          lang == 'tr'
              ? {'Ödendi', 'Hepsi ödendi', 'Akşam hatırlat', 'Yarın hatırlat'}
              : {'Paid', 'All paid', 'Remind tonight', 'Remind tomorrow'},
        );
      }
    });

    test('every reminder button has its iOS category', () {
      final ids = {
        for (final c in ReminderActionIds.combinations)
          ReminderActionIds.category(c),
      };
      for (final kind in ReminderKind.values) {
        for (final snoozed in [false, true]) {
          for (final count in [1, 3]) {
            for (final minute in [540, 1230]) {
              final actions = reminderActions(
                kind: kind,
                snoozed: snoozed,
                payments: [
                  for (var i = 0; i < count; i++)
                    ReminderPayment(
                      name: 'P$i',
                      date: d(11, 14),
                      amountMinor: 1,
                      ref: PlanPaymentRef(i),
                    ),
                ],
                fireDate: kind == ReminderKind.ahead ? d(11, 12) : d(11, 14),
                minuteOfDay: minute,
              );
              expect(ids, contains(ReminderActionIds.category(actions)));
            }
          }
        }
      }
    });

    test('Android: buttons run in the background and close it', () {
      final actions = reminderAndroidActions(const [
        ReminderButton(ReminderAction.paid, 'Ödendi'),
        ReminderButton(ReminderAction.remindTonight, 'Akşam hatırlat'),
      ]);
      expect(actions.map((a) => a.id), ['kalan.paid', 'kalan.remind_tonight']);
      expect(actions.every((a) => !a.showsUserInterface), isTrue);
      expect(actions.every((a) => a.cancelNotification), isTrue);
    });

    test('the background handler is a kept entry point', () {
      final background = File('lib/features/reminders/background.dart')
          .readAsStringSync();
      expect(
        background,
        contains(
          "@pragma('vm:entry-point')\n"
          'Future<void> reminderActionInBackground(',
        ),
      );
      final gatewaySource = File(
        'lib/features/reminders/local_notifications.dart',
      ).readAsStringSync();
      expect(
        gatewaySource,
        contains(
          'onDidReceiveBackgroundNotificationResponse: '
          'reminderActionInBackground',
        ),
      );
      expect(gatewaySource, contains('NotificationVisibility.secret'));
    });
  });

  group('in the app', () {
    testWidgets('a button delivered to the running app marks it there', (
      tester,
    ) async {
      final appGateway = FakeNotificationGateway();
      late int tabby;
      final appDb = await pumpApp(
        tester,
        today: d(11, 14),
        overrides: [
          notificationGatewayProvider.overrideWithValue(appGateway),
          clockProvider.overrideWithValue(() => at(d(11, 14), 9, 1)),
        ],
        seed: (db) async {
          await seedSettings(db);
          tabby = await seedOne(db, 'Tabby', d(11, 14));
        },
      );
      expect(find.text('Tabby'), findsOneWidget);
      expect(find.byTooltip('Ödenmedi olarak işaretle'), findsNothing);
      notificationTaps.add(
        NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotificationAction,
          actionId: ReminderActionIds.of(ReminderAction.paid),
          payload: ReminderPayload(
            kind: ReminderKind.onDay,
            fireDate: d(11, 14),
            minuteOfDay: 540,
            refs: [PlanPaymentRef(tabby)],
          ).encode(),
        ),
      );
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Ödenmedi olarak işaretle'), findsOneWidget);
      final row = await tester.runAsync(() => paymentOf(appDb, tabby));
      expect(row!.paidAt, isNotNull);
    });

    testWidgets('debug: test reminder with buttons, nearest unpaid', (
      tester,
    ) async {
      final appGateway = FakeNotificationGateway();
      await pumpApp(
        tester,
        today: d(11, 10),
        overrides: [
          notificationGatewayProvider.overrideWithValue(appGateway),
          clockProvider.overrideWithValue(() => at(d(11, 10), 12)),
        ],
        seed: (db) async {
          await seedSettings(db);
          await seedOne(db, 'Zip', d(11, 20));
          await seedOne(db, 'Tabby', d(11, 14));
          await seedOne(db, 'Eski', d(11, 2));
        },
      );
      await openTab(tester, 'Ayarlar');
      final button = find.byKey(const ValueKey('test-reminder-actions'));
      await scrollTo(tester, button);
      expect(
        find.text('Eylemli deneme bildirimi (10 saniye sonra)'),
        findsOneWidget,
      );
      await tester.tap(button);
      await tester.pumpAndSettle();
      final r = appGateway.testReminder!;
      expect(r.id, ReminderIds.testReminder);
      expect(r.kind, ReminderKind.onDay);
      expect(r.payments.single.name, 'Tabby');
      expect(r.body, 'Bugün 1 ödeme var: Tabby, ₺400');
      expect(r.buttons.map((b) => b.title), ['Ödendi', 'Akşam hatırlat']);
      expect(
        find.text('10 saniye içinde bir deneme bildirimi gelecek.'),
        findsOneWidget,
      );
    });

    testWidgets('debug: nothing unpaid, a calm note', (tester) async {
      final appGateway = FakeNotificationGateway();
      await pumpApp(
        tester,
        overrides: [notificationGatewayProvider.overrideWithValue(appGateway)],
        seed: seedSettings,
      );
      await openTab(tester, 'Ayarlar');
      final button = find.byKey(const ValueKey('test-reminder-actions'));
      await scrollTo(tester, button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(appGateway.testReminder, isNull);
      expect(find.text('Denemek için ödenmemiş ödeme yok.'), findsOneWidget);
    });
  });
}

Future<void> setTime(AppDatabase db, int minute) =>
    (db.update(db.appSettings)..where((s) => s.id.equals(1))).write(
      AppSettingsCompanion(reminderMinute: Value(minute)),
    );
