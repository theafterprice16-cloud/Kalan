import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/data/db/app_database.dart';
import 'package:kalan/features/reminders/reminder_providers.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../helpers/app_harness.dart';
import '../helpers/fake_notifications.dart';

/// 20 Nov 2026, 08:00 in Istanbul.
DateTime clock() => DateTime.utc(2026, 11, 20, 5);

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
  });

  const key = ValueKey('payday-summary');

  Future<(AppDatabase, FakeNotificationGateway)> open(
    WidgetTester tester, {
    Locale locale = const Locale('tr', 'TR'),
  }) async {
    final gateway = FakeNotificationGateway();
    final db = await pumpApp(
      tester,
      locale: locale,
      seed: (db) async {
        await seedSettings(db, incomeMinor: 2075000);
        await seedPayIn4(db);
      },
      overrides: [
        notificationGatewayProvider.overrideWithValue(gateway),
        clockProvider.overrideWithValue(clock),
      ],
    );
    await settle(tester);
    await openTab(tester, locale.languageCode == 'tr' ? 'Ayarlar' : 'Settings');
    await scrollTo(tester, find.byKey(key));
    return (db, gateway);
  }

  bool switchOn(WidgetTester tester) =>
      tester.widget<SwitchListTile>(find.byKey(key)).value;

  testWidgets('on by default, with a short line on what comes when', (
    tester,
  ) async {
    final (_, gateway) = await open(tester);
    expect(switchOn(tester), isTrue);
    expect(find.text('Maaş günü özeti'), findsOneWidget);
    expect(
      find.text(
        'Maaş gününde, hatırlatma saatinde: bu dönemin ödemeleri, toplamı '
        've kalanı.',
      ),
      findsOneWidget,
    );
    expect(gateway.paydays, hasLength(1));
    expect(gateway.pending, hasLength(7));
  });

  testWidgets('turning it off cancels the summary only; on brings it back', (
    tester,
  ) async {
    final (db, gateway) = await open(tester);
    final payments = [for (final r in gateway.pending) (r.id, r.body)];
    await tester.tap(find.byKey(key));
    await settle(tester);
    expect(switchOn(tester), isFalse);
    expect(
      (await db.select(db.appSettings).getSingle()).paydaySummaryEnabled,
      isFalse,
    );
    expect(gateway.paydays, isEmpty);
    expect([for (final r in gateway.pending) (r.id, r.body)], payments);

    await tester.tap(find.byKey(key));
    await settle(tester);
    expect(gateway.paydays, hasLength(1));
  });

  testWidgets('inactive while reminders are off', (tester) async {
    await open(tester);
    await scrollTo(tester, find.byKey(const ValueKey('reminders-enabled')));
    await tester.tap(find.byKey(const ValueKey('reminders-enabled')));
    await settle(tester);
    await scrollTo(tester, find.byKey(key));
    expect(
      tester.widget<SwitchListTile>(find.byKey(key)).onChanged,
      equals(null),
    );
  });

  testWidgets('English', (tester) async {
    await open(tester, locale: const Locale('en', 'US'));
    expect(find.text('Payday summary'), findsOneWidget);
    expect(
      find.text(
        "On payday, at your reminder time: this period's payments, total "
        "and what's left.",
      ),
      findsOneWidget,
    );
  });
}
