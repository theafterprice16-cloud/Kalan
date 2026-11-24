import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/routing/router.dart';
import 'package:kalan/core/routing/routes.dart';
import 'package:kalan/data/db/app_database.dart';
import 'package:kalan/features/home_widget/widget_amounts.dart';
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

  setUp(() {
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
}
