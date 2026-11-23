import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/lock/app_lock_machine.dart';
import 'package:kalan/core/routing/router.dart';
import 'package:kalan/core/routing/routes.dart';
import 'package:kalan/data/db/app_database.dart';
import 'package:kalan/features/lock/app_lock_controller.dart';
import 'package:kalan/features/lock/app_lock_store.dart';
import 'package:kalan/features/lock/device_lock_gateway.dart';
import 'package:kalan/features/reminders/local_notifications.dart';
import 'package:kalan/features/reminders/reminder_providers.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/app_harness.dart';
import '../helpers/fake_device_lock.dart';
import '../helpers/fake_notifications.dart';

void main() {
  late FakeDeviceLock phone;
  late MemoryAppLockStore store;
  late FakeLockClock clock;
  late bool active;

  setUp(() {
    phone = FakeDeviceLock();
    store = MemoryAppLockStore();
    clock = FakeLockClock();
    active = true;
  });

  Future<AppDatabase> start(
    WidgetTester tester, {
    AppLockSettings lock = const AppLockSettings(),
    String? route,
    bool notifications = false,
    List<Override> extra = const [],
  }) async {
    await store.write(lock);
    return pumpApp(
      tester,
      seed: (db) async {
        await seedSettings(db, incomeMinor: 4500000);
        await seedPayIn4(db, title: 'Kulaklık');
      },
      overrides: [
        appLockStoreProvider.overrideWithValue(store),
        deviceLockGatewayProvider.overrideWithValue(phone),
        lockClockProvider.overrideWithValue(clock),
        appIsActiveProvider.overrideWithValue(() => active),
        // Off unless a test needs it: resuming then reads the time zone.
        if (notifications)
          notificationGatewayProvider.overrideWithValue(
            FakeNotificationGateway(),
          ),
        if (route != null) initialRouteProvider.overrideWithValue(route),
        ...extra,
      ],
    );
  }

  final lockScreen = find.byKey(const ValueKey('lock-screen'));
  final cover = find.byKey(const ValueKey('app-switcher-cover'));
  final lockSwitch = find.byKey(const ValueKey('app-lock'));
  final homeNumber = find.byKey(const ValueKey('home-number'));

  Future<void> lifecycle(
    WidgetTester tester,
    List<AppLifecycleState> states,
  ) async {
    for (final s in states) {
      tester.binding.handleAppLifecycleStateChanged(s);
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  const leave = [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
  ];
  const back = [
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ];

  Future<void> openSettings(WidgetTester tester) async {
    await openTab(tester, 'Ayarlar');
    await scrollTo(tester, lockSwitch);
  }

  bool switchValue(WidgetTester tester) =>
      tester.widget<SwitchListTile>(lockSwitch).value;

  group('turning the lock on (Settings)', () {
    testWidgets('Example 1: Face ID says yes; 1 minute; amounts row', (
      tester,
    ) async {
      final db = await start(tester, notifications: true);
      await openSettings(tester);
      expect(find.text('Uygulama kilidi'), findsOneWidget);
      expect(find.byKey(const ValueKey('app-lock-delay')), findsNothing);
      await tester.tap(lockSwitch);
      await tester.pumpAndSettle();

      expect(phone.calls, 1);
      expect(phone.asked.single.reason, contains('kimliğini doğrula'));
      expect(switchValue(tester), isTrue);
      expect(store.read().enabled, isTrue);
      expect(find.text('1 dakika sonra'), findsOneWidget);
      expect(
        find.text('Bildirimlerde tutar görünüyor. Gizlemek için dokun.'),
        findsOneWidget,
      );
      // Turning the lock on leaves "show amount" as it was.
      final row = await db.select(db.appSettings).getSingle();
      expect(row.hideAmountsInNotifications, isFalse);
      // The app switcher cover is on natively too.
      expect(phone.covers.last, isTrue);
      expect(lockScreen, findsNothing);
    });

    testWidgets('Example 2: cancelled, the switch stays off', (tester) async {
      phone.answer(DeviceAuthResult.failed);
      await start(tester);
      await openSettings(tester);
      await tester.tap(lockSwitch);
      await tester.pumpAndSettle();
      expect(phone.calls, 1);
      expect(switchValue(tester), isFalse);
      expect(store.read().enabled, isFalse);
      expect(find.byKey(const ValueKey('app-lock-delay')), findsNothing);
    });

    testWidgets('Example 6: no screen lock, the switch cannot turn on', (
      tester,
    ) async {
      phone.screenLock = false;
      await start(tester);
      await openSettings(tester);
      await tester.tap(lockSwitch);
      await tester.pumpAndSettle();
      expect(phone.calls, 0);
      expect(switchValue(tester), isFalse);
      expect(store.read().enabled, isFalse);
      expect(
        find.text('Bunun için telefonunda ekran kilidi olmalı.'),
        findsOneWidget,
      );
    });

    testWidgets('the delay choice is stored', (tester) async {
      await start(tester, lock: const AppLockSettings(enabled: true));
      // Opened by the first, automatic check.
      expect(phone.calls, 1);
      await openSettings(tester);
      await scrollTo(tester, find.byKey(const ValueKey('app-lock-delay')));
      await tester.tap(find.byKey(const ValueKey('app-lock-delay')));
      await tester.pumpAndSettle();
      expect(find.text('Hemen'), findsOneWidget);
      expect(find.text('5 dakika sonra'), findsOneWidget);
      await tester.tap(find.text('Hemen'));
      await tester.pumpAndSettle();
      expect(store.read().delay, RelockDelay.immediately);
      expect(find.text('Hemen'), findsOneWidget);
    });

    testWidgets('tapping the amounts row hides amounts; the row goes', (
      tester,
    ) async {
      final db = await start(tester, notifications: true);
      await openSettings(tester);
      await tester.tap(lockSwitch);
      await tester.pumpAndSettle();
      final row = find.byKey(const ValueKey('app-lock-amounts'));
      await tester.tap(row);
      await tester.pumpAndSettle();
      final s = await db.select(db.appSettings).getSingle();
      expect(s.hideAmountsInNotifications, isTrue);
      expect(row, findsNothing);
      expect(store.read().enabled, isTrue);
    });

    testWidgets('turning off needs no check and opens nothing', (tester) async {
      await start(tester);
      await openSettings(tester);
      await tester.tap(lockSwitch);
      await tester.pumpAndSettle();
      await tester.tap(lockSwitch);
      await tester.pumpAndSettle();
      expect(phone.calls, 1);
      expect(store.read().enabled, isFalse);
      expect(phone.covers.last, isFalse);
    });
  });

  group('the lock screen', () {
    testWidgets('a cold start is locked, asks once by itself, no data', (
      tester,
    ) async {
      phone.answer(DeviceAuthResult.failed);
      await start(tester, lock: const AppLockSettings(enabled: true));
      expect(lockScreen, findsOneWidget);
      expect(phone.calls, 1);
      // Nothing of the data is on screen (the screens wait underneath).
      expect(homeNumber, findsNothing);
      expect(
        find.byType(NavigationBar, skipOffstage: false),
        findsOneWidget,
        reason: 'the screens wait under the lock',
      );
      expect(find.textContaining('₺'), findsNothing);
      expect(find.byType(NavigationBar), findsNothing);
      // Failed: it stays, and does not ask again by itself.
      await tester.pumpAndSettle();
      expect(phone.calls, 1);
      expect(lockScreen, findsOneWidget);
      expect(find.text('Kilidi aç'), findsOneWidget);
      expect(
        find.text("Kalan'ı açmak için kimliğini doğrula."),
        findsOneWidget,
      );
    });

    testWidgets('Example 4: fails twice, opens on the third; no counter', (
      tester,
    ) async {
      phone
        ..answer(DeviceAuthResult.failed)
        ..answer(DeviceAuthResult.failed);
      await start(tester, lock: const AppLockSettings(enabled: true));
      await tester.tap(find.byKey(const ValueKey('lock-unlock')));
      await tester.pumpAndSettle();
      expect(lockScreen, findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('lock-unlock')));
      await tester.pumpAndSettle();
      expect(phone.calls, 3);
      expect(lockScreen, findsNothing);
      expect(homeNumber, findsOneWidget);
      expect(store.read().enabled, isTrue);
    });

    testWidgets('not active at launch: asks when Kalan becomes active', (
      tester,
    ) async {
      active = false;
      await start(tester, lock: const AppLockSettings(enabled: true));
      expect(phone.calls, 0);
      expect(lockScreen, findsOneWidget);
      active = true;
      await lifecycle(tester, [AppLifecycleState.resumed]);
      expect(phone.calls, 1);
      expect(lockScreen, findsNothing);
    });

    testWidgets('Example 7: screen lock removed, opens and says so once', (
      tester,
    ) async {
      phone.screenLock = false;
      await start(tester, lock: const AppLockSettings(enabled: true));
      expect(lockScreen, findsNothing);
      expect(phone.calls, 0);
      expect(store.read().enabled, isFalse);
      expect(homeNumber, findsOneWidget);
      const note =
          'Telefonunda ekran kilidi olmadığı için uygulama kilidi kapatıldı.';
      expect(store.read().notice, AppLockNotice.noScreenLock);
      await openSettings(tester);
      expect(find.text(note), findsOneWidget);
      expect(switchValue(tester), isFalse);
      // Once: shown, then no longer stored for the next time.
      expect(store.read().notice, isNull);
      expect(phone.covers.last, isFalse);
    });

    testWidgets('a check the phone cannot show opens Kalan, never stuck', (
      tester,
    ) async {
      phone.answer(DeviceAuthResult.unavailable);
      await start(tester, lock: const AppLockSettings(enabled: true));
      expect(lockScreen, findsNothing);
      expect(store.read().enabled, isFalse);
      expect(store.read().notice, AppLockNotice.unavailable);
    });

    testWidgets('a notification tap while locked: lock first, then target', (
      tester,
    ) async {
      phone.hold = true;
      await start(
        tester,
        route: Routes.settings,
        lock: const AppLockSettings(enabled: true),
      );
      notificationTaps.add(
        const NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          payload: 'payment',
        ),
      );
      await tester.pumpAndSettle();
      expect(lockScreen, findsOneWidget);
      phone.complete(DeviceAuthResult.success);
      await tester.pumpAndSettle();
      expect(lockScreen, findsNothing);
      // The reminder's target: home.
      expect(homeNumber, findsOneWidget);
    });

    testWidgets('Android back while locked keeps the screens underneath', (
      tester,
    ) async {
      await start(tester, lock: const AppLockSettings(enabled: true));
      // Open, go to a pushed screen, lock again.
      final container = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp)),
      );
      unawaited(container.read(routerProvider).push(Routes.sources));
      await tester.pumpAndSettle();
      expect(find.text('Kaynaklar ve kartlar'), findsWidgets);
      await lifecycle(tester, leave);
      clock.pass(const Duration(minutes: 2));
      phone.answer(DeviceAuthResult.failed);
      await lifecycle(tester, back);
      expect(lockScreen, findsOneWidget);
      final handled = await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(handled, isTrue);
      // Android's predictive back gesture too.
      const codec = StandardMethodCodec();
      for (final method in ['startBackGesture', 'commitBackGesture']) {
        await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
          SystemChannels.backGesture.name,
          codec.encodeMethodCall(
            MethodCall(
              method,
              method == 'startBackGesture'
                  ? <String, Object?>{
                      'touchOffset': <double>[0, 0],
                      'progress': 0.0,
                      'swipeEdge': 0,
                    }
                  : null,
            ),
          ),
          (_) {},
        );
        await tester.pumpAndSettle();
      }
      expect(lockScreen, findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('lock-unlock')));
      await tester.pumpAndSettle();
      expect(lockScreen, findsNothing);
      expect(find.text('Kaynaklar ve kartlar'), findsWidgets);
    });
  });

  group('review fixes', () {
    testWidgets('turning on: the dialog says it turns the lock on', (
      tester,
    ) async {
      await start(tester);
      await openSettings(tester);
      await tester.tap(lockSwitch);
      await tester.pumpAndSettle();
      expect(phone.asked.single.title, 'Uygulama kilidini aç');
      expect(
        phone.asked.single.reason,
        'Uygulama kilidini açmak için kimliğini doğrula.',
      );
    });

    testWidgets('turned off while Settings is open: the note shows there', (
      tester,
    ) async {
      await start(tester, lock: const AppLockSettings(enabled: true));
      await openSettings(tester);
      expect(switchValue(tester), isTrue);
      // The screen lock goes; Kalan locks again and opens by itself.
      phone.screenLock = false;
      await lifecycle(tester, leave);
      clock.pass(const Duration(minutes: 2));
      await lifecycle(tester, back);
      expect(lockScreen, findsNothing);
      expect(switchValue(tester), isFalse);
      expect(
        find.text(
          'Telefonunda ekran kilidi olmadığı için uygulama kilidi kapatıldı.',
        ),
        findsOneWidget,
      );
      expect(store.read().notice, isNull);
    });

    testWidgets('the screen lock note goes when Kalan comes back', (
      tester,
    ) async {
      phone.screenLock = false;
      await start(tester);
      await openSettings(tester);
      await tester.tap(lockSwitch);
      await tester.pumpAndSettle();
      const note = 'Bunun için telefonunda ekran kilidi olmalı.';
      expect(find.text(note), findsOneWidget);
      // The user sets a screen lock in the phone's settings.
      await lifecycle(tester, leave);
      await lifecycle(tester, back);
      expect(find.text(note), findsNothing);
    });

    testWidgets('landscape with large text: nothing overlaps or overflows', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1688, 780);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      phone.hold = true;
      await start(tester, lock: const AppLockSettings(enabled: true));
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final mark = tester.getRect(find.byType(Image));
      final text = tester.getRect(
        find.text("Kalan'ı açmak için kimliğini doğrula."),
      );
      expect(mark.bottom, lessThanOrEqualTo(text.top));
    });
  });

  group('locking again (Example 3)', () {
    testWidgets('1 minute: 40 seconds away stays open, 3 minutes locks', (
      tester,
    ) async {
      await start(tester, lock: const AppLockSettings(enabled: true));
      expect(phone.calls, 1);
      expect(lockScreen, findsNothing);

      await lifecycle(tester, leave);
      clock.pass(const Duration(seconds: 40));
      await lifecycle(tester, back);
      expect(lockScreen, findsNothing);
      expect(phone.calls, 1);

      phone.hold = true;
      await lifecycle(tester, leave);
      clock.pass(const Duration(minutes: 3));
      await lifecycle(tester, back);
      expect(lockScreen, findsOneWidget);
      // Asked by itself, once.
      expect(phone.calls, 2);
      // The dialog itself makes Kalan inactive and back: no loop.
      await lifecycle(tester, [
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]);
      expect(phone.calls, 2);
      phone.complete(DeviceAuthResult.success);
      await tester.pumpAndSettle();
      expect(lockScreen, findsNothing);
    });

    testWidgets('the passcode screen hiding Kalan is not a new lock', (
      tester,
    ) async {
      await start(
        tester,
        lock: const AppLockSettings(
          enabled: true,
          delay: RelockDelay.immediately,
        ),
      );
      phone.hold = true;
      await lifecycle(tester, leave);
      await lifecycle(tester, back);
      expect(phone.calls, 2);
      // Android's passcode screen: Kalan hides and shows during the check.
      await lifecycle(tester, leave);
      clock.pass(const Duration(minutes: 1));
      await lifecycle(tester, back);
      phone.complete(DeviceAuthResult.success);
      await tester.pumpAndSettle();
      expect(lockScreen, findsNothing);
      expect(phone.calls, 2);
    });

    testWidgets('with the lock off nothing locks or covers', (tester) async {
      await start(tester);
      await lifecycle(tester, [AppLifecycleState.inactive]);
      expect(cover, findsNothing);
      await lifecycle(tester, [
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ]);
      clock.pass(const Duration(hours: 1));
      await lifecycle(tester, back);
      expect(lockScreen, findsNothing);
      expect(phone.calls, 0);
      expect(phone.covers, isEmpty);
    });
  });

  group('the app switcher cover (Example 5)', () {
    testWidgets('lock on: ground and mark only while not in front', (
      tester,
    ) async {
      await start(tester, lock: const AppLockSettings(enabled: true));
      await lifecycle(tester, [AppLifecycleState.inactive]);
      expect(cover, findsOneWidget);
      expect(
        find.descendant(of: cover, matching: find.byType(Text)),
        findsNothing,
      );
      expect(
        find.descendant(of: cover, matching: find.byType(Image)),
        findsOneWidget,
      );
      await lifecycle(tester, [AppLifecycleState.resumed]);
      expect(cover, findsNothing);
    });
  });

  testWidgets('lock settings stay out of the database', (tester) async {
    final db = await start(tester);
    final columns = db.appSettings.$columns.map((c) => c.name);
    expect(columns.where((c) => c.contains('lock')), isEmpty);
  });

  test('lock screens use no accent but the button, never late', () {
    for (final f in Directory('lib/features/lock').listSync()) {
      final source = (f as File).readAsStringSync();
      expect(source, isNot(contains('.accent')), reason: f.path);
      expect(source, isNot(contains('.late')), reason: f.path);
    }
  });
}
