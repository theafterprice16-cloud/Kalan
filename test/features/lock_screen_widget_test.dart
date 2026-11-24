import 'dart:convert';

import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/app/locale.dart';
import 'package:kalan/app/providers.dart';
import 'package:kalan/core/engine/engine.dart';
import 'package:kalan/core/money/currency.dart';
import 'package:kalan/core/money/money_format.dart';
import 'package:kalan/core/widget/widget_snapshot.dart';
import 'package:kalan/data/db/app_database.dart';
import 'package:kalan/data/repositories/plan_repository.dart';
import 'package:kalan/data/repositories/recurring_repository.dart';
import 'package:kalan/data/repositories/source_repository.dart';
import 'package:kalan/entitlement/pro_controller.dart';
import 'package:kalan/entitlement/pro_status_store.dart';
import 'package:kalan/features/home_widget/lock_screen_left.dart';
import 'package:kalan/features/home_widget/widget_amounts.dart';
import 'package:kalan/features/home_widget/widget_gateway.dart';
import 'package:kalan/features/home_widget/widget_sync.dart';
import 'package:kalan/features/lock/app_lock_controller.dart';
import 'package:kalan/features/lock/app_lock_store.dart';
import 'package:kalan/features/lock/device_lock_gateway.dart';
import 'package:kalan/features/privacy/amounts_hidden.dart';
import 'package:kalan/features/reminders/reminder_providers.dart';
import 'package:material_ui/material_ui.dart' show Locale;

import '../helpers/app_harness.dart' show seedSettings;
import '../helpers/fake_device_lock.dart';
import '../helpers/fake_widget.dart';

/// Lock Screen widget (Roadmap 32): what the app writes for it, built
/// from stored data. Today is Friday 20 November 2026 throughout.

final _today = LocalDate(2026, 11, 20);

Future<int> _plan(
  AppDatabase db,
  String title,
  LocalDate first,
  int each, {
  int count = 2,
}) async {
  final plans = PlanRepository(db);
  final source = await SourceRepository(
    db,
    plans,
  ).findOrCreateProvider('Banka');
  await plans.saveDraft(
    PlanCalculator.monthly(
      firstDate: first,
      totalMinor: each * count,
      count: count,
    ),
    sourceId: source,
    origin: PlanOrigin.manual,
    title: title,
  );
  return (await plans.all()).firstWhere((p) => p.ownName == title).plan.id;
}

/// Monthly rent of 9.000 on the 1st.
Future<void> _rent(AppDatabase db) => RecurringRepository(db).create(
  RecurringPaymentsCompanion.insert(
    name: 'Kira',
    amountMinor: 900000,
    recurrence: Recurrence.monthly,
    startDay: LocalDate(2026, 1, 1).epochDay,
  ),
);

/// The home screen widget's example 1: 1.400 on 22 Nov, 1.500 on 25 Nov,
/// rent on 1 Dec; income 24.350 leaves 12.450 this period.
Future<void> _example1(AppDatabase db) async {
  await seedSettings(db, incomeMinor: 2435000);
  await _plan(db, 'Telefon taksiti', LocalDate(2026, 11, 22), 140000);
  await _plan(db, 'Laptop taksiti', LocalDate(2026, 11, 25), 150000);
  await _rent(db);
}

WidgetPublisher _publisher(
  AppDatabase db, {
  bool pro = true,
  bool showLeft = false,
  bool masked = false,
  DateTime? now,
  String locale = 'tr',
}) => WidgetPublisher(
  db: db,
  gateway: FakeWidgetGateway(),
  now: () => now ?? DateTime(2026, 11, 20, 8),
  localeFor: (_) => Locale(locale),
  masked: () => masked,
  lockScreen: (_) => LockScreenOptions(pro: pro, showLeft: showLeft),
);

String _money(int minor) =>
    formatMoney(minor, Currency.fromCode('TRY'), localeName: 'tr');

/// Every string the Lock Screen reads, the day's and the shared ones.
List<String> _lockStrings(WidgetSnapshot s) => [
  ...s.lock.toJson().values.whereType<String>(),
  for (final d in s.days)
    if (d.lock case final lock?) ...lock.toJson().values.whereType<String>(),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    await loadLocaleData();
  });

  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  group('the examples', () {
    test('1: Pro, a payment in two days, the option off', () async {
      await _example1(db);
      final s = await _publisher(db).build();
      final lock = s.days.first.lock!;
      expect(lock.line, '2 gün sonra 1 ödeme');
      expect(lock.centerKind, LockCenter.number);
      expect(lock.center, '2');
      expect(lock.count, '1 ödeme');
      expect(lock.left, isEmpty);
      expect(s.lock.title, 'Kalan');
      expect(s.lock.pro, isTrue);
    });

    test('2: the option on, lock and hiding off: "Kalan 12.450"', () async {
      await _example1(db);
      final s = await _publisher(db, showLeft: true).build();
      expect(s.days.first.lock!.left, 'Kalan ${_money(1245000)}');
      expect(s.days.first.lock!.left, 'Kalan ₺12.450');
    });

    test('3: the option on but amounts masked: no line, no amount', () async {
      await _example1(db);
      final s = await _publisher(db, showLeft: true, masked: true).build();
      expect([for (final d in s.days) d.lock!.left], everyElement(isEmpty));
      expect(
        jsonEncode([for (final d in s.days) d.lock!.toJson()]),
        isNot(contains('12.450')),
      );
    });

    test('4: two payments today: "Bugün 2 ödeme"', () async {
      await seedSettings(db, incomeMinor: 2435000);
      await _plan(db, 'Telefon taksiti', _today, 140000);
      await _plan(db, 'Laptop taksiti', _today, 150000);
      final lock = (await _publisher(db).build()).days.first.lock!;
      expect(lock.line, 'Bugün 2 ödeme');
      expect((lock.centerKind, lock.center), (LockCenter.word, 'Bugün'));
      expect(lock.count, '2 ödeme');
    });

    test('5: none today, one unpaid yesterday: "Günü geçen 1 ödeme"', () async {
      await seedSettings(db, incomeMinor: 2435000);
      await _plan(db, 'Telefon taksiti', LocalDate(2026, 11, 19), 140000);
      await _plan(db, 'Laptop taksiti', LocalDate(2026, 11, 25), 150000);
      final lock = (await _publisher(db).build()).days.first.lock!;
      expect(lock.line, 'Günü geçen 1 ödeme');
      expect((lock.centerKind, lock.center), (LockCenter.word, 'Geçti'));
      expect(lock.count, '1 ödeme');
    });

    test('6: not Pro: the calm Pro note only, no day text', () async {
      await _example1(db);
      final s = await _publisher(db, pro: false, showLeft: true).build();
      expect(s.lock.pro, isFalse);
      expect(s.lock.gateInline, 'Kalan Pro ile');
      expect(
        s.lock.gate,
        "Kilit ekranı widget'ı Kalan Pro ile kullanılabilir.",
      );
      expect([for (final d in s.days) d.lock], everyElement(isNull));
      final json = jsonEncode(s.toJson()['lock']);
      expect(json, isNot(contains('ödeme')));
      expect(json, isNot(contains('!')));
    });

    test('7: stale (not opened for 10 days): "Open Kalan" texts', () async {
      await _example1(db);
      final s = await _publisher(db).build();
      // Native code shows these once no record matches its today.
      expect(s.lock.open, "Kalan'ı aç");
      expect(s.lock.stale, "Güncel bilgi için Kalan'ı aç.");
      expect(s.days.length, widgetDayCount);
    });
  });

  test('English', () async {
    await _example1(db);
    final s = await _publisher(db, locale: 'en', showLeft: true).build();
    final lock = s.days.first.lock!;
    expect(lock.line, '1 payment in 2 days');
    expect(lock.count, '1 payment');
    expect(lock.left, startsWith('Left '));
    expect(s.lock.gateInline, 'With Kalan Pro');
    expect(s.lock.gate, 'The Lock Screen widget comes with Kalan Pro.');
    expect(s.lock.open, 'Open Kalan');
  });

  test('each day as it would be: tomorrow, today, past due, next', () async {
    await _example1(db);
    final days = (await _publisher(db).build()).days;
    expect(
      [for (final d in days) d.lock!.line],
      [
        '2 gün sonra 1 ödeme', // Fri 20: phone on the 22nd
        'Yarın 1 ödeme', // Sat 21
        'Bugün 1 ödeme', // Sun 22
        // From the 23rd the phone, still unpaid, is past due and comes
        // first, even before the laptop on the 25th.
        'Günü geçen 1 ödeme',
        'Günü geçen 1 ödeme',
        'Bugün 1 ödeme', // Wed 25: today's laptop before the past-due phone
        'Günü geçen 2 ödeme',
        'Günü geçen 2 ödeme',
      ],
    );
    expect(days[1].lock!.center, '1');
  });

  test('plans and recurring payments count together', () async {
    await seedSettings(db, incomeMinor: 2435000);
    await _plan(db, 'Telefon taksiti', LocalDate(2026, 12, 1), 140000);
    await _rent(db); // also on 1 Dec
    final lock = (await _publisher(db).build()).days.first.lock!;
    expect(lock.line, '11 gün sonra 2 ödeme');
    expect(lock.center, '11');
  });

  test('plans on hold and closed plans do not count', () async {
    await seedSettings(db, incomeMinor: 2435000);
    final held = await _plan(db, 'Beklemede', LocalDate(2026, 11, 19), 1000);
    final closed = await _plan(db, 'Kapatıldı', _today, 1000);
    await _plan(db, 'Laptop taksiti', LocalDate(2026, 11, 25), 150000);
    final plans = PlanRepository(db);
    await plans.hold(held, today: _today);
    await plans.close(closed, reason: CloseReason.cancel, today: _today);
    final lock = (await _publisher(db).build()).days.first.lock!;
    expect(lock.line, '5 gün sonra 1 ödeme');
  });

  test('nothing ahead: "Yaklaşan ödeme yok." and the logo', () async {
    await seedSettings(db, incomeMinor: 2435000);
    await _plan(
      db,
      'Telefon taksiti',
      LocalDate(2026, 11, 10),
      140000,
      count: 1,
    );
    final pay = (await PlanRepository(db).all()).single.payments.single;
    await PlanRepository(db).setPaid(pay.id, paid: true);
    final lock = (await _publisher(db).build()).days.first.lock!;
    expect(lock.line, 'Yaklaşan ödeme yok.');
    expect(lock.centerKind, LockCenter.logo);
    expect((lock.center, lock.count), ('', ''));
  });

  test('setup and no payments: one text, no amount', () async {
    final setup = await _publisher(db).build();
    expect(setup.lock.message, "Kurulumu bitirmek için Kalan'ı aç.");
    expect(setup.lock.messageInline, "Kalan'ı aç");
    await seedSettings(db, incomeMinor: 2435000);
    final none = await _publisher(db, showLeft: true).build();
    expect(none.lock.message, 'Yaklaşan ödeme yok.');
    expect(none.lock.messageInline, 'Yaklaşan ödeme yok.');
    expect(none.days, isEmpty);
  });

  test('privacy: no payment amount anywhere on the Lock Screen', () async {
    await _example1(db);
    // Every option that allows an amount.
    final s = await _publisher(db, showLeft: true).build();
    final text = _lockStrings(s).join('\n');
    for (final minor in [140000, 150000, 900000]) {
      expect(text, isNot(contains(_money(minor))), reason: '$minor');
    }
    // Only "Kalan {left}" carries a figure, on its own line.
    final withAmount = [
      for (final line in _lockStrings(s))
        if (line.contains('₺')) line,
    ];
    expect(withAmount, everyElement(startsWith('Kalan ')));
  });

  test('no income: no "left" line even with the option on', () async {
    await seedSettings(db);
    await _plan(db, 'Telefon taksiti', LocalDate(2026, 11, 22), 140000);
    final s = await _publisher(db, showLeft: true).build();
    expect(s.days.first.lock!.left, isEmpty);
    expect(_lockStrings(s).join(), isNot(contains('₺')));
  });

  group('choices in the app', () {
    late FakeWidgetGateway gateway;
    late ProviderContainer container;

    Future<void> settle() async {
      for (var i = 0; i < 5; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await container.read(widgetSyncProvider).idle;
      }
    }

    Map<String, Object?> last() =>
        jsonDecode(gateway.published.last) as Map<String, Object?>;
    bool pro() => (last()['lock']! as Map)['pro'] as bool;
    String left() =>
        (((last()['days'] as List).first as Map)['lock'] as Map)['left']
            as String;

    Future<void> setDebugPro(bool on) async {
      await (db.update(db.appSettings)..where((s) => s.id.equals(1))).write(
        AppSettingsCompanion(debugPro: Value(on)),
      );
      await settle();
    }

    setUp(() async {
      gateway = FakeWidgetGateway();
      await _example1(db);
      await (db.update(db.appSettings)..where((s) => s.id.equals(1))).write(
        const AppSettingsCompanion(localeCode: Value('tr')),
      );
      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          widgetGatewayProvider.overrideWithValue(gateway),
          reminderDebounceProvider.overrideWithValue(Duration.zero),
          clockProvider.overrideWithValue(() => DateTime(2026, 11, 20, 8)),
          appLocalesProvider.overrideWithValue(appLocales),
          amountsHiddenStoreProvider.overrideWithValue(
            MemoryAmountsHiddenStore(),
          ),
          widgetAmountsStoreProvider.overrideWithValue(
            MemoryWidgetAmountsStore(),
          ),
          lockScreenLeftStoreProvider.overrideWithValue(
            MemoryLockScreenLeftStore(),
          ),
          proStatusStoreProvider.overrideWithValue(MemoryProStatusStore()),
          // An iPhone.
          lockScreenWidgetSupportedProvider.overrideWithValue(true),
          appLockStoreProvider.overrideWithValue(MemoryAppLockStore()),
          deviceLockGatewayProvider.overrideWithValue(FakeDeviceLock()),
          appIsActiveProvider.overrideWithValue(() => false),
        ],
      );
      addTearDown(container.dispose);
      container.listen(widgetSyncProvider, (_, _) {});
      container.read(widgetSyncProvider).request();
      await settle();
    });

    test('Pro on and off (a refund): the widget is written again', () async {
      expect(pro(), isFalse);
      expect((last()['days'] as List).first as Map, isNot(contains('lock')));
      // The Settings test switch stands in for the store's signal.
      await setDebugPro(true);
      expect(pro(), isTrue);
      expect(
        (((last()['days'] as List).first as Map)['lock'] as Map)['line'],
        '2 gün sonra 1 ödeme',
      );
      await setDebugPro(false);
      expect(pro(), isFalse);
      expect((last()['days'] as List).first as Map, isNot(contains('lock')));
    });

    test('"Show what\'s left": off by default; every condition', () async {
      await setDebugPro(true);
      expect(left(), isEmpty);
      await container.read(lockScreenLeftProvider.notifier).set(true);
      await settle();
      expect(left(), 'Kalan ${_money(1245000)}');

      // Example 3: "Hide amounts" on: the line goes, and its amount.
      await container.read(amountsHiddenProvider.notifier).set(true);
      await settle();
      expect(left(), isEmpty);
      expect(
        jsonEncode(last()['lock']) +
            jsonEncode([
              for (final d in last()['days']! as List) (d as Map)['lock'],
            ]),
        isNot(contains('12.450')),
      );
      await container.read(amountsHiddenProvider.notifier).set(false);
      await settle();
      expect(left(), isNotEmpty);

      // App lock on: only with "Show amounts in widget" (31) on too.
      await container.read(appLockProvider.notifier).enable();
      await settle();
      expect(left(), isEmpty);
      await container.read(widgetAmountsProvider.notifier).set(true);
      await settle();
      expect(left(), isNotEmpty);

      await container.read(lockScreenLeftProvider.notifier).set(false);
      await settle();
      expect(left(), isEmpty);
    });
  });

  test('"Show what\'s left" is off by default, on this device only', () {
    expect(MemoryLockScreenLeftStore().read(), isFalse);
    final columns = [
      for (final table in db.allTables)
        for (final column in table.$columns) column.name.toLowerCase(),
    ];
    expect(columns.where((c) => c.contains('lock_screen')), isEmpty);
  });

  test('not an iPhone: never what\'s left', () {
    final android = ProviderContainer(
      overrides: [
        lockScreenWidgetSupportedProvider.overrideWithValue(false),
        lockScreenLeftStoreProvider.overrideWithValue(
          MemoryLockScreenLeftStore(true),
        ),
        amountsHiddenStoreProvider.overrideWithValue(
          MemoryAmountsHiddenStore(),
        ),
        widgetAmountsStoreProvider.overrideWithValue(
          MemoryWidgetAmountsStore(),
        ),
        appLockStoreProvider.overrideWithValue(MemoryAppLockStore()),
        deviceLockGatewayProvider.overrideWithValue(FakeDeviceLock()),
        databaseProvider.overrideWithValue(db),
      ],
    );
    addTearDown(android.dispose);
    expect(android.read(lockScreenOptionsProvider).showLeft, isFalse);
  });

  test('a widget link: the Pro note opens Pro, anything else home', () {
    expect(
      widgetTapOf(Uri.parse('kalan://widget/pro?homeWidget')),
      WidgetTap.pro,
    );
    expect(widgetTapOf(Uri.parse('kalan://widget?homeWidget')), WidgetTap.home);
    expect(widgetTapOf(Uri()), WidgetTap.home);
    expect(widgetTapOf(null), WidgetTap.home);
  });
}
