import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/data/db/app_database.dart';
import 'package:kalan/features/reminders/local_notifications.dart';
import 'package:kalan/features/reminders/reminder_providers.dart';
import 'package:kalan/features/reminders/reminder_scheduler.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../helpers/app_harness.dart';
import '../helpers/fake_notifications.dart';

/// 20 Nov 2026, 08:00 in Istanbul.
DateTime clock() => DateTime.utc(2026, 11, 20, 5);

Future<AppDatabase> pumpWithReminders(
  WidgetTester tester,
  FakeNotificationGateway gateway, {
  Future<void> Function(AppDatabase db)? seed,
  Locale locale = const Locale('tr', 'TR'),
}) async {
  final db = await pumpApp(
    tester,
    seed: seed,
    locale: locale,
    overrides: [
      notificationGatewayProvider.overrideWithValue(gateway),
      clockProvider.overrideWithValue(clock),
    ],
  );
  await settle(tester);
  return db;
}

/// Reschedules run after a short debounce, off the UI; let them finish.
Future<void> settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.pump(const Duration(milliseconds: 400));
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
  await tester.pumpAndSettle();
}

Future<void> addPayIn4(WidgetTester tester, String source) async {
  // Let a previous "Plan added." snackbar go away from the button.
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Plan ekle'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const ValueKey('source')), source);
  await tester.enterText(find.byKey(const ValueKey('total')), '400');
  // The preview grows as fields fill in; let it settle before scrolling.
  await tester.pumpAndSettle();
  await scrollTo(tester, find.byKey(const ValueKey('save-plan')));
  await tester.tap(find.byKey(const ValueKey('save-plan')));
  await settle(tester);
}

/// Brings a keyed widget into view, taps it and waits for reschedules.
Future<void> tapKey(WidgetTester tester, String key) async {
  final f = find.byKey(ValueKey(key));
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await settle(tester);
}

Future<SettingsRow> settingsOf(AppDatabase db) =>
    db.select(db.appSettings).getSingle();

const sheet = ValueKey('reminder-sheet');

Future<void> withPlan(AppDatabase db) async {
  await seedSettings(db);
  await seedPayIn4(db);
}

void main() {
  setUpAll(() {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
  });

  group('permission sheet', () {
    testWidgets('not on app start, only after the first plan', (tester) async {
      final gateway = FakeNotificationGateway(granted: false);
      final db = await pumpWithReminders(tester, gateway, seed: seedSettings);
      expect(find.byKey(sheet), findsNothing);

      await addPayIn4(tester, 'Klarna');
      expect(find.byKey(sheet), findsOneWidget);
      expect(
        find.text(
          'Ödeme gününden önce sana haber verelim. '
          'Hatırlatmalar yalnızca bu telefonda kurulur.',
        ),
        findsOneWidget,
      );
      expect(gateway.permissionRequests, 0);
      await tester.tap(find.text('Hatırlatmaları aç'));
      await settle(tester);

      expect(gateway.permissionRequests, 1);
      final s = await settingsOf(db);
      expect((s.reminderPromptShown, s.remindersEnabled), (true, true));
      expect(gateway.bodies.first, 'Bugün 1 ödeme var: Klarna, ₺100');

      await addPayIn4(tester, 'Zip');
      expect(find.byKey(sheet), findsNothing);
      expect(gateway.permissionRequests, 1);
    });

    testWidgets('"Not now": the app works, never asks again, Settings says '
        'the permission is off', (tester) async {
      final gateway = FakeNotificationGateway(granted: false);
      final db = await pumpWithReminders(tester, gateway, seed: seedSettings);
      await addPayIn4(tester, 'Klarna');
      await tester.tap(find.text('Şimdi değil'));
      await settle(tester);
      expect(gateway.permissionRequests, 0);
      final s = await settingsOf(db);
      expect((s.reminderPromptShown, s.remindersEnabled), (true, true));

      await addPayIn4(tester, 'Zip');
      expect(find.byKey(sheet), findsNothing);

      await openTab(tester, 'Ayarlar');
      await scrollTo(tester, find.byKey(const ValueKey('permission-status')));
      expect(find.text('Bildirim izni kapalı'), findsOneWidget);
      await tester.tap(find.text('Ayarları aç'));
      await tester.pumpAndSettle();
      expect(gateway.openSettingsCalls, 1);
    });

    testWidgets('a system "Don\'t allow" is not asked about again', (
      tester,
    ) async {
      final gateway = FakeNotificationGateway(
        granted: false,
        grantOnRequest: false,
      );
      await pumpWithReminders(tester, gateway, seed: seedSettings);
      await addPayIn4(tester, 'Klarna');
      await tester.tap(find.text('Hatırlatmaları aç'));
      await settle(tester);
      await addPayIn4(tester, 'Zip');
      expect(find.byKey(sheet), findsNothing);
      expect(gateway.permissionRequests, 1);
    });

    testWidgets('already allowed (Android 12 and older): no sheet', (
      tester,
    ) async {
      final gateway = FakeNotificationGateway();
      final db = await pumpWithReminders(tester, gateway, seed: seedSettings);
      await addPayIn4(tester, 'Klarna');
      expect(find.byKey(sheet), findsNothing);
      expect(gateway.permissionRequests, 0);
      expect((await settingsOf(db)).reminderPromptShown, isTrue);
    });

    testWidgets('a recurring payment does not ask', (tester) async {
      final gateway = FakeNotificationGateway(granted: false);
      await pumpWithReminders(tester, gateway, seed: seedSettings);
      await openTab(tester, 'Planlar');
      await tester.tap(find.text('Sabit'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sabit ödeme ekle'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('recurring-name')),
        'Kira',
      );
      await tester.enterText(
        find.byKey(const ValueKey('recurring-amount')),
        '15000',
      );
      await scrollTo(tester, find.byKey(const ValueKey('save-recurring')));
      await tester.tap(find.byKey(const ValueKey('save-recurring')));
      await settle(tester);
      expect(find.byKey(sheet), findsNothing);
      expect(gateway.bodies, contains('Bugün 1 ödeme var: Kira, ₺15.000'));
    });
  });

  group('Settings > Reminders', () {
    Future<void> openSection(WidgetTester tester) async {
      await openTab(tester, 'Ayarlar');
      await scrollTo(
        tester,
        find.byKey(const ValueKey('reminder-show-amount')),
      );
    }

    bool switchOn(WidgetTester tester, String key) =>
        tester.widget<SwitchListTile>(find.byKey(ValueKey(key))).value;

    bool enabled(WidgetTester tester, String key) =>
        tester.widget<ListTile>(find.byKey(ValueKey(key))).enabled;

    testWidgets('defaults: on, 2 days, 09:00, amounts shown', (tester) async {
      final gateway = FakeNotificationGateway();
      await pumpWithReminders(tester, gateway, seed: withPlan);
      await openSection(tester);
      expect(switchOn(tester, 'reminders-enabled'), isTrue);
      expect(find.text('2 gün önce'), findsOneWidget);
      expect(find.text('09:00'), findsOneWidget);
      expect(switchOn(tester, 'reminder-show-amount'), isTrue);
      expect(gateway.pending, hasLength(7));
      expect(find.byKey(const ValueKey('permission-status')), findsNothing);
    });

    testWidgets('days before, amounts and the master switch reschedule', (
      tester,
    ) async {
      final gateway = FakeNotificationGateway();
      final db = await pumpWithReminders(tester, gateway, seed: withPlan);
      await openSection(tester);

      await tapKey(tester, 'reminder-lead-days');
      expect(find.byType(SimpleDialog), findsOneWidget);
      for (final days in ['1', '2', '3', '5', '7']) {
        expect(find.text('$days gün önce'), findsWidgets);
      }
      await tester.tap(find.byKey(const ValueKey('choice-5')));
      await settle(tester);
      expect((await settingsOf(db)).reminderLeadDays, 5);
      expect(find.text('5 gün önce'), findsOneWidget);
      expect(gateway.pending[1].fireDate.toString(), '2026-11-29');

      await tapKey(tester, 'reminder-show-amount');
      expect(gateway.bodies.first, 'Bugün 1 ödeme var: Klarna');
      expect((await settingsOf(db)).hideAmountsInNotifications, isTrue);

      await tapKey(tester, 'reminders-enabled');
      expect(gateway.pending, isEmpty);
      // Inactive, values kept.
      expect(enabled(tester, 'reminder-lead-days'), isFalse);
      expect(enabled(tester, 'reminder-time'), isFalse);
      expect(find.text('5 gün önce'), findsOneWidget);
      expect((await settingsOf(db)).reminderLeadDays, 5);

      await tapKey(tester, 'reminders-enabled');
      expect(gateway.pending, isNotEmpty);
    });

    testWidgets('screen reader hears the current days before', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpWithReminders(
        tester,
        FakeNotificationGateway(),
        seed: withPlan,
      );
      await openSection(tester);
      expect(
        find.bySemanticsLabel('Kaç gün önce, şu an 2 gün'),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets('time picker changes the reminder time', (tester) async {
      final gateway = FakeNotificationGateway();
      await pumpWithReminders(tester, gateway, seed: withPlan);
      await openSection(tester);
      await tester.ensureVisible(find.byKey(const ValueKey('reminder-time')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('reminder-time')));
      await tester.pumpAndSettle();
      // Switch the dial to text entry and type 20:30.
      await tester.tap(find.byIcon(Icons.keyboard_outlined));
      await tester.pumpAndSettle();
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '20');
      await tester.enterText(fields.at(1), '30');
      await tester.tap(find.text('Tamam'));
      await settle(tester);
      expect(find.text('20:30'), findsOneWidget);
      expect(gateway.pending.first.fireAt.hour, 20);
      expect(gateway.pending.first.fireAt.minute, 30);
    });

    testWidgets('help page and debug test notification', (tester) async {
      final gateway = FakeNotificationGateway();
      await pumpWithReminders(tester, gateway, seed: withPlan);
      await openTab(tester, 'Ayarlar');
      await scrollTo(tester, find.byKey(const ValueKey('test-notification')));
      expect(find.text('Deneme bildirimi (10 saniye sonra)'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('test-notification')));
      await tester.pumpAndSettle();
      expect(gateway.testBody, 'Deneme: hatırlatmalar bu telefonda çalışıyor.');
      expect(
        find.text('10 saniye içinde bir deneme bildirimi gelecek.'),
        findsOneWidget,
      );

      await scrollTo(tester, find.text('Bildirimler gelmiyor mu?'));
      await tester.tap(find.text('Bildirimler gelmiyor mu?'));
      await tester.pumpAndSettle();
      expect(find.text('iPhone: Odak'), findsOneWidget);
    });

    testWidgets('where notifications are not available (web)', (tester) async {
      await pumpApp(tester, seed: withPlan);
      await openTab(tester, 'Ayarlar');
      await scrollTo(tester, find.byKey(const ValueKey('reminders-web-only')));
      expect(find.text('Bu özellik telefonda çalışır.'), findsOneWidget);
      expect(find.byKey(const ValueKey('reminder-time')), findsNothing);
    });

    testWidgets('language and currency changes reschedule', (tester) async {
      final gateway = FakeNotificationGateway();
      final db = await pumpWithReminders(tester, gateway, seed: withPlan);
      await (db.update(db.appSettings)..where((s) => s.id.equals(1))).write(
        const AppSettingsCompanion(localeCode: Value('en')),
      );
      await settle(tester);
      expect(gateway.bodies.first, '1 payment today: Klarna, ₺100');
      await (db.update(db.appSettings)..where((s) => s.id.equals(1))).write(
        const AppSettingsCompanion(currencyCode: Value('USD')),
      );
      await settle(tester);
      expect(gateway.bodies.first, r'1 payment today: Klarna, $100');
    });
  });

  group('per plan', () {
    testWidgets('General, Off and a different day', (tester) async {
      final gateway = FakeNotificationGateway();
      final db = await pumpWithReminders(tester, gateway, seed: withPlan);
      await openTab(tester, 'Planlar');
      await tester.tap(find.text('Klarna'));
      await tester.pumpAndSettle();
      expect(find.text('Hatırlatma'), findsOneWidget);
      expect(find.text('Genel ayar (2 gün önce)'), findsOneWidget);

      await tapKey(tester, 'item-reminders');
      expect(find.text('Farklı gün'), findsOneWidget);
      await tester.tap(find.text('Kapalı'));
      await settle(tester);
      expect(gateway.pending, isEmpty);
      final plan = await db.select(db.plans).getSingle();
      expect((plan.remindersEnabled, plan.reminderLeadDays), (false, null));

      await tapKey(tester, 'item-reminders');
      await tester.tap(find.text('Farklı gün'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('choice-3')));
      await settle(tester);
      final custom = await db.select(db.plans).getSingle();
      expect((custom.remindersEnabled, custom.reminderLeadDays), (true, 3));
      expect(find.text('3 gün önce'), findsOneWidget);
      expect(gateway.pending[1].fireDate.toString(), '2026-12-01');

      await tapKey(tester, 'item-reminders');
      await tester.tap(find.text('Genel ayar (2 gün önce)').last);
      await settle(tester);
      final general = await db.select(db.plans).getSingle();
      expect(
        (general.remindersEnabled, general.reminderLeadDays),
        (true, null),
      );
    });

    testWidgets('a recurring payment keeps its choice', (tester) async {
      final gateway = FakeNotificationGateway();
      final db = await pumpWithReminders(
        tester,
        gateway,
        seed: (db) async {
          await seedSettings(db);
          await seedRent(db);
        },
      );
      await openTab(tester, 'Planlar');
      await tester.tap(find.text('Sabit'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kira'));
      await tester.pumpAndSettle();
      await tapKey(tester, 'item-reminders');
      await tester.tap(find.text('Kapalı'));
      await tester.pumpAndSettle();
      await scrollTo(tester, find.byKey(const ValueKey('save-recurring')));
      await tester.tap(find.byKey(const ValueKey('save-recurring')));
      await settle(tester);
      final rent = await db.select(db.recurringPayments).getSingle();
      expect(rent.remindersEnabled, isFalse);
      expect(gateway.pending, isEmpty);
    });
  });

  group('when reminders are rebuilt', () {
    testWidgets('on start and when the app comes back', (tester) async {
      final gateway = FakeNotificationGateway();
      await pumpWithReminders(tester, gateway, seed: withPlan);
      expect(gateway.replaceCalls, greaterThanOrEqualTo(1));
      expect(gateway.pending, hasLength(7));
      final before = gateway.replaceCalls;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      // The time zone is read first (no platform answer in tests).
      await tester.pump(const Duration(seconds: 3));
      await settle(tester);
      expect(gateway.replaceCalls, before + 1);
    });

    testWidgets('marking paid and undoing', (tester) async {
      final gateway = FakeNotificationGateway();
      await pumpWithReminders(tester, gateway, seed: withPlan);
      expect(gateway.bodies.first, 'Bugün 1 ödeme var: Klarna, ₺100');
      await tester.tap(find.byTooltip('Ödendi olarak işaretle').first);
      await settle(tester);
      expect(gateway.pending, hasLength(6));
      expect(gateway.pending.first.fireDate.toString(), '2026-12-02');
    });

    testWidgets('a tap on a notification opens the home screen', (
      tester,
    ) async {
      await pumpWithReminders(
        tester,
        FakeNotificationGateway(),
        seed: withPlan,
      );
      await openTab(tester, 'Ayarlar');
      expect(find.text('15 Kas – 14 Ara'), findsNothing);
      notificationTaps.add(
        const NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          payload: 'home',
        ),
      );
      await settle(tester);
      expect(find.text('15 Kas – 14 Ara'), findsOneWidget);
    });
  });

  test('a burst of requests runs one reschedule (debounce)', () async {
    final db = AppDatabase(NativeDatabase.memory());
    await seedSettings(db);
    final gateway = FakeNotificationGateway();
    final sync = ReminderSync(
      ReminderScheduler(
        db: db,
        gateway: gateway,
        location: () => tz.getLocation('Europe/Istanbul'),
        now: clock,
        localeFor: (_) => const Locale('tr'),
      ),
      debounce: const Duration(milliseconds: 50),
    );
    for (var i = 0; i < 5; i++) {
      sync.request();
    }
    await sync.idle;
    expect(gateway.replaceCalls, 1);
    sync.request();
    await sync.idle;
    expect(gateway.replaceCalls, 2);
    sync.dispose();
    await db.close();
  });
}
