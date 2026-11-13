import 'package:drift/drift.dart' show Value;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/routing/router.dart';
import 'package:kalan/data/db/app_database.dart';
import 'package:kalan/features/reminders/local_notifications.dart';
import 'package:kalan/features/reminders/notification_gateway.dart';
import 'package:kalan/features/reminders/reminder_providers.dart';
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
  String? initialRoute,
}) => pumpApp(
  tester,
  seed: seed,
  overrides: [
    notificationGatewayProvider.overrideWithValue(gateway),
    clockProvider.overrideWithValue(clock),
    if (initialRoute != null)
      initialRouteProvider.overrideWithValue(initialRoute),
  ],
);

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

/// Reschedules finish after the UI settles; let them complete.
Future<void> settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
  await tester.pumpAndSettle();
}

Future<SettingsRow> settingsOf(AppDatabase db) =>
    db.select(db.appSettings).getSingle();

void main() {
  setUpAll(() {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
  });

  group('permission prompt', () {
    testWidgets('after the first plan: explanation, then system dialog', (
      tester,
    ) async {
      final gateway = FakeNotificationGateway();
      final db = await pumpWithReminders(tester, gateway, seed: seedSettings);
      await addPayIn4(tester, 'Klarna');

      expect(find.byKey(const ValueKey('reminder-prompt')), findsOneWidget);
      expect(
        find.text(
          'Ödeme gününden önce sana haber verelim mi? '
          'Bildirimler yalnızca bu telefonda hazırlanır.',
        ),
        findsOneWidget,
      );
      expect(gateway.permissionRequests, 0);
      await tester.tap(find.text('Hatırlat'));
      await settle(tester);

      expect(gateway.permissionRequests, 1);
      final s = await settingsOf(db);
      expect(s.reminderPromptShown, isTrue);
      expect(s.remindersEnabled, isTrue);
      expect(gateway.texts.first, 'Bugün: Klarna 1/4 · ₺100');

      // The second plan does not ask again.
      await addPayIn4(tester, 'Zip');
      expect(find.byKey(const ValueKey('reminder-prompt')), findsNothing);
    });

    testWidgets('"Not now" is final and leaves reminders off', (tester) async {
      final gateway = FakeNotificationGateway();
      final db = await pumpWithReminders(tester, gateway, seed: seedSettings);
      await addPayIn4(tester, 'Klarna');
      await tester.tap(find.text('Şimdi değil'));
      await settle(tester);
      expect(gateway.permissionRequests, 0);
      final s = await settingsOf(db);
      expect(s.reminderPromptShown, isTrue);
      expect(s.remindersEnabled, isFalse);
      expect(gateway.pending, isEmpty);
      await addPayIn4(tester, 'Zip');
      expect(find.byKey(const ValueKey('reminder-prompt')), findsNothing);
    });

    testWidgets('the first recurring payment asks too', (tester) async {
      final gateway = FakeNotificationGateway();
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
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('reminder-prompt')), findsOneWidget);
    });
  });

  group('Settings > Reminders', () {
    Future<void> seed(AppDatabase db) async {
      await seedSettings(db);
      await db
          .update(db.appSettings)
          .write(const AppSettingsCompanion(reminderPromptShown: Value(true)));
      await seedPayIn4(db);
    }

    Future<void> openSection(WidgetTester tester) async {
      await openTab(tester, 'Ayarlar');
      await scrollTo(tester, find.byKey(const ValueKey('reminder-time')));
    }

    testWidgets('defaults, and every change reschedules at once', (
      tester,
    ) async {
      final gateway = FakeNotificationGateway();
      final db = await pumpWithReminders(tester, gateway, seed: seed);
      await openSection(tester);
      bool switchOn(String key) =>
          tester.widget<SwitchListTile>(find.byKey(ValueKey(key))).value;
      expect(switchOn('reminders-enabled'), isTrue);
      expect(switchOn('reminder-days7'), isFalse);
      expect(switchOn('reminder-days3'), isTrue);
      expect(switchOn('reminder-days1'), isFalse);
      expect(switchOn('reminder-sameDay'), isTrue);
      expect(find.text('09:00'), findsOneWidget);
      expect(gateway.texts, hasLength(7));

      await tapKey(tester, 'reminder-days1');
      expect(gateway.texts, contains('Yarın: Klarna 2/4 · ₺100'));

      await tapKey(tester, 'reminder-hide-amounts');
      expect(gateway.texts.first, 'Bugün 1 ödemen var');
      expect((await settingsOf(db)).hideAmountsInNotifications, isTrue);

      await tapKey(tester, 'reminders-enabled');
      expect(gateway.pending, isEmpty);
    });

    testWidgets('time picker changes the reminder time', (tester) async {
      final gateway = FakeNotificationGateway();
      await pumpWithReminders(tester, gateway, seed: seed);
      await openSection(tester);
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

    testWidgets('permission off: calm banner with a settings button', (
      tester,
    ) async {
      final gateway = FakeNotificationGateway(granted: false);
      await pumpWithReminders(tester, gateway, seed: seed);
      await openTab(tester, 'Ayarlar');
      await scrollTo(tester, find.byKey(const ValueKey('permission-banner')));
      expect(
        find.text(
          'Kalan için bildirimler kapalı, bu yüzden hatırlatmalar görünmez.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Telefon ayarlarını aç'));
      await tester.pumpAndSettle();
      expect(gateway.openSettingsCalls, 1);
    });

    testWidgets('help page and debug test notification', (tester) async {
      final gateway = FakeNotificationGateway();
      await pumpWithReminders(tester, gateway, seed: seed);
      await openTab(tester, 'Ayarlar');
      await scrollTo(tester, find.byKey(const ValueKey('test-notification')));
      await tester.tap(find.byKey(const ValueKey('test-notification')));
      await tester.pumpAndSettle();
      expect(gateway.testText, 'Test: hatırlatmalar bu telefonda çalışıyor.');
      expect(
        find.text('10 saniye içinde bir test bildirimi gelecek.'),
        findsOneWidget,
      );

      await scrollTo(tester, find.text('Bildirimler gelmiyor mu?'));
      await tester.tap(find.text('Bildirimler gelmiyor mu?'));
      await tester.pumpAndSettle();
      expect(find.text('iPhone: Odak'), findsOneWidget);
      expect(find.text('Android: pil tasarrufu'), findsOneWidget);
    });

    testWidgets('where notifications are not available (web)', (tester) async {
      await pumpApp(tester, seed: seed);
      await openTab(tester, 'Ayarlar');
      await scrollTo(tester, find.byKey(const ValueKey('reminders-web-only')));
      expect(find.text('Bu özellik telefonda çalışır.'), findsOneWidget);
      expect(find.byKey(const ValueKey('reminder-time')), findsNothing);
    });
  });

  testWidgets('"Reminders for this plan" switch', (tester) async {
    final gateway = FakeNotificationGateway();
    await pumpWithReminders(
      tester,
      gateway,
      seed: (db) async {
        await seedSettings(db);
        await seedPayIn4(db);
      },
    );
    expect(gateway.pending, isNotEmpty);
    await openTab(tester, 'Planlar');
    await tester.tap(find.text('Klarna'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('item-reminders')));
    await settle(tester);
    expect(gateway.pending, isEmpty);
  });

  group('opening from a notification', () {
    testWidgets('a cold start lands on the day of the reminder', (
      tester,
    ) async {
      await pumpWithReminders(
        tester,
        FakeNotificationGateway(),
        initialRoute: '/day/2026-11-20',
        seed: (db) async {
          await seedSettings(db);
          await seedPayIn4(db);
        },
      );
      expect(find.text('20 Kas 2026 ödemeleri'), findsOneWidget);
      expect(find.text('Klarna'), findsOneWidget);
      expect(find.text('1/4'), findsOneWidget);
      // Nothing to pop: the back button goes home.
      await tester.tap(find.byType(BackButtonIcon));
      await tester.pumpAndSettle();
      expect(find.text('15 Kas – 14 Ara'), findsOneWidget);
    });

    testWidgets('a tap while running opens the day', (tester) async {
      await pumpWithReminders(
        tester,
        FakeNotificationGateway(),
        seed: (db) async {
          await seedSettings(db);
          await seedPayIn4(db);
        },
      );
      notificationResponses.add(
        const NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          payload: '/day/2026-12-04',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('4 Ara 2026 ödemeleri'), findsOneWidget);
      expect(find.text('2/4'), findsOneWidget);
    });

    testWidgets('"Paid" pressed while the app is open', (tester) async {
      final gateway = FakeNotificationGateway();
      final db = await pumpWithReminders(
        tester,
        gateway,
        seed: (db) async {
          await seedSettings(db);
          await seedPayIn4(db);
        },
      );
      final today = gateway.pending.first;
      notificationResponses.add(
        NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotificationAction,
          actionId: ReminderIds.paidAction,
          id: today.id,
          payload: today.payload.encode(),
        ),
      );
      await tester.pumpAndSettle();
      final first = (await db.select(db.payments).get()).first;
      expect(first.paidAt, isNotNull);
      expect(gateway.cancelled, [today.id]);
      expect(find.text('Ödendi'), findsOneWidget);
    });

    testWidgets('a day without payments says so', (tester) async {
      await pumpWithReminders(
        tester,
        FakeNotificationGateway(),
        initialRoute: '/day/2026-11-25',
        seed: seedSettings,
      );
      expect(find.text('Bu gün ödeme yok.'), findsOneWidget);
    });
  });

  test('payload round trip', () {
    const p = NotificationPayload(route: '/day/2026-11-20', paymentRef: 'p:3');
    expect(NotificationPayload.decode(p.encode())!.paymentRef, 'p:3');
    expect(NotificationPayload.decode('/day/2026-11-20')!.paymentRef, isNull);
    expect(NotificationPayload.decode('x'), isNull);
  });
}
