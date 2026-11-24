import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/routing/router.dart';
import 'package:kalan/core/routing/routes.dart';
import 'package:kalan/data/db/app_database.dart';
import 'package:kalan/entitlement/pro_controller.dart';
import 'package:kalan/entitlement/pro_rules.dart';
import 'package:kalan/entitlement/pro_status_store.dart';
import 'package:kalan/features/home_widget/lock_screen_left.dart';
import 'package:kalan/features/home_widget/widget_amounts.dart';
import 'package:kalan/features/home_widget/widget_gateway.dart';
import 'package:kalan/features/home_widget/widget_sync.dart';
import 'package:kalan/features/lock/app_lock_controller.dart';
import 'package:kalan/features/lock/app_lock_store.dart';
import 'package:kalan/features/lock/device_lock_gateway.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/app_harness.dart';
import '../helpers/fake_device_lock.dart';
import '../helpers/fake_widget.dart';

/// Home screen widget (Roadmap 31): the "Show amounts in widget" switch
/// in Settings > Privacy and a tap on the widget.
void main() {
  late FakeWidgetGateway gateway;
  late MemoryWidgetAmountsStore amounts;
  late FakeDeviceLock phone;
  late MemoryLockScreenLeftStore left;

  setUp(() {
    left = MemoryLockScreenLeftStore();
    phone = FakeDeviceLock();
    gateway = FakeWidgetGateway();
    amounts = MemoryWidgetAmountsStore();
  });

  Future<AppDatabase> start(
    WidgetTester tester, {
    bool lock = false,
    bool widget = true,
    String? route,
    Locale locale = const Locale('tr', 'TR'),
    bool iPhonePro = false,
  }) => pumpApp(
    tester,
    locale: locale,
    seed: (db) async {
      await seedSettings(db, incomeMinor: 4500000);
      await seedPayIn4(db, title: 'Kulaklık');
    },
    overrides: <Override>[
      appLockStoreProvider.overrideWithValue(
        MemoryAppLockStore(AppLockSettings(enabled: lock)),
      ),
      deviceLockGatewayProvider.overrideWithValue(phone),
      appIsActiveProvider.overrideWithValue(() => true),
      widgetAmountsStoreProvider.overrideWithValue(amounts),
      if (widget) widgetGatewayProvider.overrideWithValue(gateway),
      if (route != null) initialRouteProvider.overrideWithValue(route),
      // Lock Screen widget (32).
      if (iPhonePro) ...[
        lockScreenWidgetSupportedProvider.overrideWithValue(true),
        lockScreenLeftStoreProvider.overrideWithValue(left),
        proStatusStoreProvider.overrideWithValue(
          MemoryProStatusStore(ProStatus.pro),
        ),
      ],
    ],
  );

  final widgetSwitch = find.byKey(const ValueKey('widget-amounts'));

  Future<void> openPrivacy(WidgetTester tester) async {
    await openTab(tester, 'Ayarlar');
    await scrollTo(tester, find.byKey(const ValueKey('app-lock')));
  }

  testWidgets('only while the app lock is on', (tester) async {
    await start(tester);
    await openPrivacy(tester);
    expect(widgetSwitch, findsNothing);
  });

  testWidgets('lock on: shown, off by default; the choice is kept', (
    tester,
  ) async {
    await start(tester, lock: true);
    // (The automatic check at start has unlocked it.)
    await openPrivacy(tester);
    await scrollTo(tester, widgetSwitch);
    expect(find.text("Widget'ta tutarı göster"), findsOneWidget);
    expect(
      find.text(
        "Kapalıyken ana ekran widget'ında tutarların yerine ••• görünür.",
      ),
      findsOneWidget,
    );
    expect(tester.widget<SwitchListTile>(widgetSwitch).value, isFalse);
    await tester.tap(widgetSwitch);
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(widgetSwitch).value, isTrue);
    expect(amounts.read(), isTrue);

    // Turning the lock off hides the row; the choice stays for next time.
    await scrollTo(tester, find.byKey(const ValueKey('app-lock')));
    await tester.tap(find.byKey(const ValueKey('app-lock')));
    await tester.pumpAndSettle();
    expect(widgetSwitch, findsNothing);
    expect(amounts.read(), isTrue);
  });

  testWidgets('no widget on this platform: no switch', (tester) async {
    await start(tester, lock: true, widget: false);
    await openPrivacy(tester);
    expect(widgetSwitch, findsNothing);
  });

  testWidgets('a tap on the widget opens home', (tester) async {
    await start(tester, route: Routes.plans);
    final router = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    ).read(routerProvider);
    expect(router.state.uri.toString(), Routes.plans);
    gateway.tap();
    await tester.pumpAndSettle();
    expect(router.state.uri.toString(), Routes.home);
    expect(find.byKey(const ValueKey('home-number')), findsOneWidget);
  });

  testWidgets('during setup a tap keeps what was typed', (tester) async {
    await pumpApp(
      tester,
      overrides: [widgetGatewayProvider.overrideWithValue(gateway)],
    );
    final router = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    ).read(routerProvider);
    expect(router.state.uri.toString(), Routes.onboarding);
    await tester.enterText(find.byType(TextField).first, '25000');
    gateway.tap();
    await tester.pumpAndSettle();
    expect(router.state.uri.toString(), Routes.onboarding);
    expect(find.text('25000'), findsOneWidget);
  });

  testWidgets('with the app lock on, the lock screen comes first', (
    tester,
  ) async {
    // The phone's check stays open: the app is still locked.
    phone.hold = true;
    await start(tester, lock: true, route: Routes.plans);
    gateway.tap();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('lock-screen')), findsOneWidget);
    expect(find.text('Kulaklık'), findsNothing);
    phone.complete(DeviceAuthResult.success);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('lock-screen')), findsNothing);
    expect(find.byKey(const ValueKey('home-number')), findsOneWidget);
  });

  // Lock Screen widget (32).
  final leftSwitch = find.byKey(const ValueKey('lock-screen-left'));

  testWidgets('"Kalan sayısını göster": iPhone with Pro, off by default', (
    tester,
  ) async {
    await start(tester, iPhonePro: true);
    await openPrivacy(tester);
    await scrollTo(tester, leftSwitch);
    expect(find.text('Kalan sayısını göster'), findsOneWidget);
    expect(
      find.text(
        "Kilit ekranı widget'ında bu dönem kalan da görünür. "
        'Tutarlar gizliyken görünmez.',
      ),
      findsOneWidget,
    );
    expect(tester.widget<SwitchListTile>(leftSwitch).value, isFalse);
    await tester.tap(leftSwitch);
    await tester.pumpAndSettle();
    expect(left.read(), isTrue);
  });

  testWidgets('no switch without Pro or on other phones', (tester) async {
    await start(tester);
    await openPrivacy(tester);
    expect(leftSwitch, findsNothing);
  });

  testWidgets('the Lock Screen widget\'s Pro note opens the Pro screen', (
    tester,
  ) async {
    await start(tester, route: Routes.plans);
    final router = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    ).read(routerProvider);
    gateway.tap(WidgetTap.pro);
    await tester.pumpAndSettle();
    expect(router.state.uri.toString(), Routes.pro());
    expect(find.byKey(const ValueKey('pro-screen')), findsOneWidget);
    // Again: not a second Pro screen; back goes home.
    gateway.tap(WidgetTap.pro);
    await tester.pumpAndSettle();
    router.pop();
    await tester.pumpAndSettle();
    expect(router.state.uri.toString(), Routes.home);
  });

  testWidgets('a cold start from the Pro note: Pro over home', (tester) async {
    gateway = FakeWidgetGateway(launchedBy: WidgetTap.pro);
    await start(tester);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('pro-screen')), findsOneWidget);
  });

  testWidgets('with the app lock on, the lock screen covers Pro first', (
    tester,
  ) async {
    phone.hold = true;
    await start(tester, lock: true);
    gateway.tap(WidgetTap.pro);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('lock-screen')), findsOneWidget);
    phone.complete(DeviceAuthResult.success);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('pro-screen')), findsOneWidget);
  });
}
