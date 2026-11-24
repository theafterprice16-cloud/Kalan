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
import 'package:kalan/features/home_widget/widget_amounts.dart';
import 'package:kalan/features/home_widget/widget_sync.dart';
import 'package:kalan/features/lock/app_lock_controller.dart';
import 'package:kalan/features/lock/app_lock_store.dart';
import 'package:kalan/features/lock/device_lock_gateway.dart';
import 'package:kalan/features/privacy/amounts_hidden.dart';
import 'package:kalan/features/reminders/reminder_providers.dart';
import 'package:kalan/l10n/generated/app_localizations.dart';
import 'package:material_ui/material_ui.dart' show Locale;

import '../helpers/app_harness.dart' show seedSettings;
import '../helpers/fake_device_lock.dart';
import '../helpers/fake_widget.dart';

/// Home screen widget (Roadmap 31): the snapshot built from stored data,
/// as the app writes it for the native widgets.

Future<void> _plan(
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

/// Example 1's payments: 1.400 on 22 Nov, 1.500 on 25 Nov, rent on 1 Dec
/// (the period 15 Nov – 14 Dec spends 11.900).
Future<void> _example1(AppDatabase db) async {
  await _plan(db, 'Telefon taksiti', LocalDate(2026, 11, 22), 140000);
  await _plan(db, 'Laptop taksiti', LocalDate(2026, 11, 25), 150000);
  await _rent(db);
}

WidgetPublisher _publisher(
  AppDatabase db,
  FakeWidgetGateway gateway, {
  DateTime? now,
  bool masked = false,
  String locale = 'tr',
}) => WidgetPublisher(
  db: db,
  gateway: gateway,
  now: () => now ?? DateTime(2026, 11, 20, 8),
  localeFor: (_) => Locale(locale),
  masked: () => masked,
);

String _money(int minor, {String currency = 'TRY'}) =>
    formatMoney(minor, Currency.fromCode(currency), localeName: 'tr');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    await loadLocaleData();
  });

  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test(
    'example 1: left, until the period end, the next three payments',
    () async {
      await seedSettings(db, incomeMinor: 2435000);
      await _example1(db);
      final snapshot = await _publisher(db, FakeWidgetGateway()).build();
      expect(snapshot.mode, WidgetMode.days);
      final today = snapshot.days.first;
      expect(today.state, WidgetState.left);
      expect(today.title, 'Kalan');
      expect(today.number, _money(1245000));
      expect(today.number, '₺12.450');
      expect(today.until, '14 Ara tarihine kadar');
      expect(
        [for (final r in today.rows) (r.name, r.date, r.amount)],
        [
          ('Telefon taksiti', '22 Kas', _money(140000)),
          ('Laptop taksiti', '25 Kas', _money(150000)),
          ('Kira', '1 Ara', _money(900000)),
        ],
      );
      expect(
        today.spoken,
        startsWith('Kalan ₺12.450, 14 Ara tarihine kadar. Telefon taksiti'),
      );
    },
  );

  test('English: the same record in the app language', () async {
    await seedSettings(db, incomeMinor: 2435000);
    await _example1(db);
    final today = (await _publisher(
      db,
      FakeWidgetGateway(),
      locale: 'en',
    ).build()).days.first;
    expect(today.title, 'Left');
    expect(today.until, 'Until Dec 14');
    expect(today.rows.first.date, 'Nov 22');
  });

  test('example 2: a negative period, the sign from the money path', () async {
    await seedSettings(db, incomeMinor: 1105000);
    await _example1(db);
    final today = (await _publisher(
      db,
      FakeWidgetGateway(),
    ).build()).days.first;
    expect(today.state, WidgetState.negative);
    expect(today.number, _money(-85000));
  });

  test('example 3: no income, this period\'s payments', () async {
    await seedSettings(db);
    await _plan(db, 'Telefon taksiti', LocalDate(2026, 11, 22), 140000);
    await _plan(db, 'Laptop taksiti', LocalDate(2026, 11, 25), 150000);
    await _plan(db, 'Okul', LocalDate(2026, 12, 1), 585000);
    final today = (await _publisher(
      db,
      FakeWidgetGateway(),
    ).build()).days.first;
    expect(today.state, WidgetState.noIncome);
    expect(today.title, 'Bu dönem ödemeler');
    expect(today.number, _money(875000));
    expect(today.until, '14 Ara tarihine kadar');
  });

  test('eight records, one per day; each counts as on its own day', () async {
    await seedSettings(db, incomeMinor: 2435000);
    await _example1(db);
    final days = (await _publisher(db, FakeWidgetGateway()).build()).days;
    expect(
      [for (final d in days) d.date],
      [for (var i = 0; i < 8; i++) LocalDate(2026, 11, 20).addDays(i)],
    );
    // 23 Nov: the phone payment of the 22nd is still unpaid and past, so
    // it is no longer "next"; it still counts in this period.
    final day23 = days[3];
    expect(day23.rows.first.name, 'Laptop taksiti');
    expect(day23.number, _money(1245000));
    // 26 Nov: only the rent and the next phone payment are ahead.
    expect(
      [for (final r in days[6].rows) r.name],
      ['Kira', 'Telefon taksiti', 'Laptop taksiti'],
    );
  });

  test('example 6: payday tomorrow, the new period from midnight', () async {
    await seedSettings(db, incomeMinor: 2435000);
    await _example1(db);
    final days = (await _publisher(
      db,
      FakeWidgetGateway(),
      now: DateTime(2026, 11, 14, 22),
    ).build()).days;
    // 14 Nov: the period 15 Oct – 14 Nov (nothing in it).
    expect(days[0].until, '14 Kas tarihine kadar');
    // (The rent of 1 Nov counts there.)
    expect(days[0].number, _money(2435000 - 900000));
    // 15 Nov: the new period, without opening the app.
    expect(days[1].date, LocalDate(2026, 11, 15));
    expect(days[1].until, '14 Ara tarihine kadar');
    expect(days[1].number, _money(1245000));
  });

  test('paid and past-due payments are not "next"', () async {
    await seedSettings(db, incomeMinor: 2435000);
    await _plan(db, 'Eski', LocalDate(2026, 11, 18), 10000, count: 1);
    await _example1(db);
    final plans = await PlanRepository(db).all();
    final phone = plans.firstWhere((p) => p.ownName == 'Telefon taksiti');
    await PlanRepository(db).setPaid(phone.payments.first.id, paid: true);
    final today = (await _publisher(
      db,
      FakeWidgetGateway(),
    ).build()).days.first;
    expect(
      [for (final r in today.rows) r.name],
      ['Laptop taksiti', 'Kira', 'Telefon taksiti'],
    );
    // Both still count in this period, as on the home screen.
    expect(today.number, _money(2435000 - 1190000 - 10000));
  });

  test('example 8: IDR, the small size gets the short form', () async {
    await seedSettings(db, currency: 'IDR', incomeMinor: 125450000);
    await _rent(db);
    final today = (await _publisher(
      db,
      FakeWidgetGateway(),
    ).build()).days.first;
    // 125.450.000 − 9.000.000 "rent" in rupiah minor units (no decimals).
    const left = 125450000 - 900000;
    final idr = Currency.fromCode('IDR');
    expect(today.number, formatMoney(left, idr, localeName: 'tr'));
    expect(today.number.length, greaterThan(widgetSmallNumberMax));
    expect(today.numberSmall, formatMoneyShort(left, idr, localeName: 'tr'));
    expect(today.numberSmall.length, lessThanOrEqualTo(widgetSmallNumberMax));
  });

  test('no plan and no recurring payment: "Henüz ödeme yok."', () async {
    await seedSettings(db, incomeMinor: 2435000);
    final snapshot = await _publisher(db, FakeWidgetGateway()).build();
    expect(snapshot.mode, WidgetMode.noPayments);
    expect(snapshot.message, 'Henüz ödeme yok.');
    expect(snapshot.days, isEmpty);
  });

  test('setup not finished: "Kurulumu bitirmek için Kalan\'ı aç."', () async {
    final snapshot = await _publisher(db, FakeWidgetGateway()).build();
    expect(snapshot.mode, WidgetMode.setup);
    expect(snapshot.message, "Kurulumu bitirmek için Kalan'ı aç.");
  });

  test('stale text: no amount, in the app language', () async {
    await seedSettings(db, incomeMinor: 2435000);
    await _example1(db);
    final snapshot = await _publisher(db, FakeWidgetGateway()).build();
    expect(snapshot.stale, "Güncel bilgi için Kalan'ı aç.");
    final en = await _publisher(db, FakeWidgetGateway(), locale: 'en').build();
    expect(en.stale, 'Open Kalan for the latest.');
  });

  test('masked: no real amount anywhere in what is written', () async {
    await seedSettings(db, incomeMinor: 2435000);
    await _example1(db);
    final gateway = FakeWidgetGateway();
    await _publisher(db, gateway, masked: true).publish();
    final json = gateway.published.single;
    for (final amount in [1245000, 2435000, 140000, 150000, 900000]) {
      expect(json, isNot(contains(_money(amount))));
    }
    expect(json, isNot(contains('₺')));
    final today = ((jsonDecode(json) as Map)['days'] as List)[0] as Map;
    expect(today['number'], amountMask);
    expect(today['numberSmall'], amountMask);
    expect(
      [for (final r in today['rows'] as List) (r as Map)['amount']],
      [amountMask, amountMask, amountMask],
    );
    expect(
      [for (final r in today['rows'] as List) (r as Map)['name']],
      ['Telefon taksiti', 'Laptop taksiti', 'Kira'],
    );
    expect(today['spoken'], contains('Tutar gizli'));
  });

  test('an unchanged snapshot is not written twice', () async {
    await seedSettings(db, incomeMinor: 2435000);
    await _example1(db);
    final gateway = FakeWidgetGateway();
    final publisher = _publisher(db, gateway);
    await publisher.publish();
    await publisher.publish();
    expect(gateway.published, hasLength(1));
  });

  group('refresh triggers', () {
    late FakeWidgetGateway gateway;
    late ProviderContainer container;

    Future<void> settle() async {
      // Drift streams and the zero debounce.
      for (var i = 0; i < 5; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await container.read(widgetSyncProvider).idle;
      }
    }

    setUp(() async {
      gateway = FakeWidgetGateway();
      await seedSettings(db, incomeMinor: 2435000, localeCode: 'tr');
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

    Map<String, Object?> last() =>
        jsonDecode(gateway.published.last) as Map<String, Object?>;

    test('plans and payments', () async {
      final before = gateway.published.length;
      await _plan(db, 'Telefon taksiti', LocalDate(2026, 11, 22), 140000);
      await settle();
      expect(gateway.published.length, greaterThan(before));
      expect(jsonEncode(last()), contains('Telefon taksiti'));
      // Marked paid: off the next rows.
      final pay = (await PlanRepository(db).all()).single.payments.first;
      await PlanRepository(db).setPaid(pay.id, paid: true);
      await settle();
      final rows = ((last()['days'] as List).first as Map)['rows'] as List;
      expect([for (final r in rows) (r as Map)['date']], ['22 Ara']);
    });

    test('recurring payments', () async {
      await _plan(db, 'Telefon taksiti', LocalDate(2026, 11, 22), 140000);
      await settle();
      await _rent(db);
      await settle();
      expect(jsonEncode(last()), contains('Kira'));
    });

    test('settings: income, currency, language', () async {
      await _plan(db, 'Telefon taksiti', LocalDate(2026, 11, 22), 140000);
      await settle();
      Future<void> set(AppSettingsCompanion c) async {
        await (db.update(
          db.appSettings,
        )..where((s) => s.id.equals(1))).write(c);
        await settle();
      }

      await set(const AppSettingsCompanion(netIncomeMinor: Value(3000000)));
      expect(jsonEncode(last()), contains(_money(3000000 - 140000)));
      await set(const AppSettingsCompanion(currencyCode: Value('EUR')));
      expect(jsonEncode(last()), contains('€'));
      await set(const AppSettingsCompanion(localeCode: Value('en')));
      expect(jsonEncode(last()), contains('Until'));
    });

    test('privacy: hide amounts, app lock, show in widget', () async {
      await _plan(db, 'Telefon taksiti', LocalDate(2026, 11, 22), 140000);
      await settle();
      String number() =>
          ((last()['days'] as List).first as Map)['number'] as String;
      expect(number(), isNot(amountMask));

      await container.read(amountsHiddenProvider.notifier).set(true);
      await settle();
      expect(number(), amountMask);
      await container.read(amountsHiddenProvider.notifier).set(false);
      await settle();
      expect(number(), isNot(amountMask));

      // Example 4: lock on, "Show amounts in widget" off (its default).
      await container.read(appLockProvider.notifier).enable();
      await settle();
      expect(number(), amountMask);
      await container.read(widgetAmountsProvider.notifier).set(true);
      await settle();
      expect(number(), isNot(amountMask));
      // Example 5: "Hide amounts" still wins.
      await container.read(amountsHiddenProvider.notifier).set(true);
      await settle();
      expect(number(), amountMask);
    });

    test('locking and unlocking the app write nothing', () async {
      await container.read(appLockProvider.notifier).enable();
      await settle();
      final before = gateway.published.length;
      final lock = container.read(appLockProvider.notifier);
      lock.appHidden();
      await settle();
      lock.appShown();
      await settle();
      expect(gateway.published.length, before);
    });
  });

  test(
    '"Show amounts in widget" is off by default, on this device only',
    () async {
      expect(MemoryWidgetAmountsStore().read(), isFalse);
      // Not a column of the database, so never in an export or a backup.
      final columns = [
        for (final table in db.allTables)
          for (final column in table.$columns) column.name,
      ];
      expect(columns.where((c) => c.toLowerCase().contains('widget')), isEmpty);
    },
  );

  test('the English texts read as one sentence each', () {
    final l10n = lookupAppLocalizations(const Locale('en'));
    expect(l10n.widgetUntil('Dec 14'), 'Until Dec 14');
    expect(
      l10n.widgetSpokenSummary('Left', r'$1,250', 'Dec 14'),
      r'Left $1,250, until Dec 14.',
    );
  });
}
