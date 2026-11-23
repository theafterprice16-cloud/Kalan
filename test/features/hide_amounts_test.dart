import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/semantics.dart' show SemanticsNode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/app/app.dart';
import 'package:kalan/app/format.dart';
import 'package:kalan/app/providers.dart';
import 'package:kalan/core/engine/engine.dart';
import 'package:kalan/core/money/currency.dart';
import 'package:kalan/core/money/money_format.dart';
import 'package:kalan/core/routing/router.dart';
import 'package:kalan/core/routing/routes.dart';
import 'package:kalan/core/theme/kalan_theme.dart';
import 'package:kalan/data/db/app_database.dart';
import 'package:kalan/data/repositories/plan_repository.dart';
import 'package:kalan/data/repositories/source_repository.dart';
import 'package:kalan/features/lock/app_lock_controller.dart';
import 'package:kalan/features/lock/app_lock_store.dart';
import 'package:kalan/features/lock/device_lock_gateway.dart';
import 'package:kalan/features/periods/period_chart.dart';
import 'package:kalan/features/plans/installment_fee_fields.dart';
import 'package:kalan/features/privacy/amounts_hidden.dart';
import 'package:kalan/features/reminders/reminder_providers.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/app_harness.dart';
import '../helpers/calendar_seed.dart';
import '../helpers/charge_seed.dart';
import '../helpers/fake_device_lock.dart';
import '../helpers/fake_notifications.dart';
import '../helpers/pump.dart';
import '../helpers/statement_seed.dart';

/// Roadmap 28: "Hide amounts". One tap on the eye masks every amount the
/// app shows with the same "•••"; names, dates, counts and states stay.

const mask = '•••';

/// A tall phone: the home screen's rows fit without scrolling.
void tallPhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Today 20 Nov 2026, payday 15: this period 15 Nov - 14 Dec. Income
/// ₺10.000, "tight" below ₺5.000. Klarna 4 × ₺100 from 20 Nov, rent
/// ₺15.000 on 1 Dec, and "Telefon": 12 × ₺2.000 from 10 Dec with a ₺50
/// fee per payment, a ₺20.000 product price and a ₺6 extra fee on its
/// first payment. Four payments this period, which is short.
Future<int> seedAll(AppDatabase db) async {
  await seedSettings(db, incomeMinor: 1000000, thresholdMinor: 500000);
  await seedPayIn4(db);
  await seedRent(db);
  final plans = PlanRepository(db);
  final telefon = await plans.saveDraft(
    PlanCalculator.monthly(
          firstDate: LocalDate(2026, 12, 10),
          totalMinor: 2400000,
          count: 12,
        )
        .withInstallmentFee(5000, InstallmentFeeScope.everyPayment)
        .withProductPrice(2000000),
    sourceId: await SourceRepository(db, plans).findOrCreateProvider('Kredivo'),
    origin: PlanOrigin.template,
    title: 'Telefon',
  );
  final first =
      await (db.select(db.payments)
            ..where((p) => p.planId.equals(telefon))
            ..orderBy([(p) => OrderingTerm.asc(p.seq)])
            ..limit(1))
          .getSingle();
  await plans.setExtraFee(first.id, amountMinor: 600);
  return telefon;
}

/// Scrolls either way until [finder] is on screen.
Future<void> reveal(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

/// Every label, value and tooltip a screen reader can reach.
FinderBase<SemanticsNode> spokenWith(String part) => find.semantics.byPredicate(
  (n) =>
      n.label.contains(part) ||
      n.value.contains(part) ||
      n.tooltip.contains(part) ||
      n.hint.contains(part),
);

void main() {
  late MemoryAmountsHiddenStore store;
  late int telefon;

  setUp(() => store = MemoryAmountsHiddenStore());

  Future<AppDatabase> start(
    WidgetTester tester, {
    bool hidden = false,
    String? route,
    LocalDate? today,
    Future<void> Function(AppDatabase db)? seed,
    List<Override> extra = const [],
  }) async {
    await store.write(hidden);
    return pumpApp(
      tester,
      today: today,
      seed: seed ?? (db) async => telefon = await seedAll(db),
      overrides: [
        amountsHiddenStoreProvider.overrideWithValue(store),
        if (route != null) initialRouteProvider.overrideWithValue(route),
        ...extra,
      ],
    );
  }

  final eye = find.byKey(const ValueKey('hide-amounts'));
  final hideSwitch = find.byKey(
    const ValueKey('hide-amounts-switch'),
    skipOffstage: false,
  );

  String homeNumber(WidgetTester tester) => tester
      .widget<Text>(
        find.descendant(
          of: find.byKey(const ValueKey('home-number')),
          matching: find.byType(Text),
        ),
      )
      .data!;

  /// Hides or shows amounts from outside the screen in view.
  Future<void> setHidden(WidgetTester tester, bool hidden) async {
    await ProviderScope.containerOf(tester.element(find.byType(KalanApp)))
        .read(amountsHiddenProvider.notifier)
        .set(hidden);
    await tester.pumpAndSettle();
  }

  testWidgets('Example 1: the eye masks home; names and dates stay; '
      'nothing moves', (tester) async {
    tallPhone(tester);
    await start(tester);
    expect(find.textContaining('₺'), findsWidgets);
    expect(find.byTooltip('Tutarları gizle'), findsOneWidget);
    final strip = find.byKey(const ValueKey('coming-periods-strip'));
    final stripTop = tester.getTopLeft(strip);
    final numberHeight = tester
        .getSize(find.byKey(const ValueKey('home-number')))
        .height;
    final firstRow = tester.getTopLeft(find.text('Klarna').first);
    final shown = homeNumber(tester);
    expect(shown, startsWith('-₺'));

    await tester.tap(eye);
    await tester.pumpAndSettle();

    expect(store.read(), isTrue);
    expect(homeNumber(tester), mask);
    expect(find.textContaining('₺'), findsNothing);
    // Names, dates, counts and the state stay.
    expect(find.text('Klarna'), findsWidgets);
    expect(find.text('Kira'), findsOneWidget);
    expect(find.text('1/4'), findsOneWidget);
    expect(find.text('Bugün'), findsOneWidget);
    expect(find.text('20 Kas'), findsOneWidget);
    // Example 5: the sentence keeps its words, color and icon.
    expect(find.text('Bu dönem $mask eksik kalıyor.'), findsOneWidget);
    expect(find.byKey(const ValueKey('status-negative')), findsOneWidget);
    expect(find.text('Bu dönem 4 ödeme var. Toplam $mask.'), findsOneWidget);
    final number = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('home-number')),
        matching: find.byType(Text),
      ),
    );
    expect(number.style!.color, KalanColors.light.negative);
    // The eye: crossed out, still textMuted, says what a tap does.
    expect(find.byTooltip('Tutarları göster'), findsOneWidget);
    final icon = tester.widget<Icon>(
      find.descendant(of: eye, matching: find.byType(Icon)),
    );
    expect(icon.icon, Icons.visibility_off_outlined);
    expect(icon.color, KalanColors.light.textMuted);
    // The layout stays where it was.
    expect(tester.getTopLeft(strip), stripTop);
    expect(
      tester.getSize(find.byKey(const ValueKey('home-number'))).height,
      numberHeight,
    );
    expect(tester.getTopLeft(find.text('Klarna').first), firstRow);

    await tester.tap(eye);
    await tester.pumpAndSettle();
    expect(store.read(), isFalse);
    expect(homeNumber(tester), shown);
    expect(find.byTooltip('Tutarları gizle'), findsOneWidget);
    expect(
      tester
          .widget<Icon>(find.descendant(of: eye, matching: find.byType(Icon)))
          .icon,
      Icons.visibility_outlined,
    );
  });

  testWidgets('the eye is textMuted in the dark theme too, 48x48', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await start(tester);
    for (final _ in [1, 2]) {
      final icon = tester.widget<Icon>(
        find.descendant(of: eye, matching: find.byType(Icon)),
      );
      expect(icon.color, KalanColors.dark.textMuted);
      expect(icon.color, isNot(KalanColors.dark.accent));
      final size = tester.getSize(eye);
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
      await tester.tap(eye);
      await tester.pumpAndSettle();
    }
  });

  testWidgets('Example 2: hidden after the app is closed and opened', (
    tester,
  ) async {
    await start(tester, hidden: true);
    expect(homeNumber(tester), mask);
    expect(find.textContaining('₺'), findsNothing);
    expect(find.byTooltip('Tutarları göster'), findsOneWidget);
  });

  testWidgets('a mask never tells the sign, the currency or the length', (
    tester,
  ) async {
    final seen = <(int, String, String, String)>[];
    await pumpLocalized(
      tester,
      ProviderScope(
        overrides: [
          amountsHiddenStoreProvider.overrideWithValue(
            MemoryAmountsHiddenStore(true),
          ),
          currencyProvider.overrideWithValue(Currency.fromCode('TRY')),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            for (final minor in [0, 1, -510000, 123456789012, -5]) {
              seen.add((
                minor,
                ref.money(context, minor),
                ref.moneyShort(context, minor),
                ref.draftMoney(context, minor),
              ));
            }
            return const SizedBox();
          },
        ),
      ),
    );
    expect(seen, isNotEmpty);
    for (final (minor, money, short, draft) in seen) {
      expect(money, mask, reason: '$minor');
      expect(short, mask, reason: '$minor');
      // The flow where an amount is typed shows it as it is.
      expect(draft, isNot(mask), reason: '$minor');
    }
    expect(seen[2].$4, '-₺5.100');
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  group('plan details, hidden', () {
    testWidgets('Example 3', (tester) async {
      tallPhone(tester);
      await start(tester, hidden: true, route: Routes.home);
      final router = ProviderScope.containerOf(
        tester.element(find.byType(KalanApp)),
      ).read(routerProvider);
      unawaited(router.push(Routes.plan(telefon)));
      await tester.pumpAndSettle();

      expect(find.text('Telefon'), findsWidgets);
      expect(find.textContaining('₺'), findsNothing);
      expect(find.text('0/12 ödendi'), findsOneWidget);
      expect(find.text('10 Ara 2026'), findsOneWidget);
      expect(find.text('Toplam geri ödeme'), findsOneWidget);
      expect(find.text('Fark'), findsOneWidget);
      expect(find.text('Ek ücret: $mask'), findsOneWidget);
      expect(find.text(mask), findsWidgets);

      // "Edit payment": its field and the fee note show real values.
      await tester.tap(find.text('10 Ara 2026'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('payment-edit')));
      await tester.pumpAndSettle();
      final tl = Currency.fromCode('TRY');
      expect(
        find.text(formatMinorForInput(200000, tl, localeName: 'tr')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(Dialog),
          matching: find.textContaining('₺50'),
        ),
        findsOneWidget,
      );
    });
  });

  group('more screens, hidden', () {
    Future<void> open(WidgetTester tester, String route) async {
      final router = ProviderScope.containerOf(
        tester.element(find.byType(KalanApp)),
      ).read(routerProvider);
      unawaited(router.push(route));
      await tester.pumpAndSettle();
    }

    void noAmount() {
      expect(find.textContaining('₺'), findsNothing);
      expect(find.textContaining(mask), findsWidgets);
      expect(spokenWith('₺'), findsNothing);
      expect(spokenWith('•'), findsNothing);
      expect(spokenWith('Tutar gizli'), findsWidgets);
    }

    testWidgets('plans: recurring and finished tabs', (tester) async {
      tallPhone(tester);
      final semantics = tester.ensureSemantics();
      await start(
        tester,
        hidden: true,
        route: Routes.plans,
        seed: (db) async {
          telefon = await seedAll(db);
          final plans = PlanRepository(db);
          final saat = await plans.saveDraft(
            PlanCalculator.monthly(
              firstDate: LocalDate(2026, 10, 5),
              totalMinor: 90000,
              count: 1,
            ),
            sourceId: null,
            origin: PlanOrigin.manual,
            title: 'Saat',
          );
          final pay = await (db.select(
            db.payments,
          )..where((p) => p.planId.equals(saat))).getSingle();
          await plans.setPaid(pay.id, paid: true);
        },
      );
      noAmount();
      await tester.tap(find.text('Sabit'));
      await tester.pumpAndSettle();
      expect(find.text('Kira'), findsOneWidget);
      noAmount();
      await tester.tap(find.text('Biten'));
      await tester.pumpAndSettle();
      expect(find.text('Saat'), findsOneWidget);
      noAmount();
      semantics.dispose();
    });

    testWidgets('change date: its lines, period rows and the fee option', (
      tester,
    ) async {
      tallPhone(tester);
      final semantics = tester.ensureSemantics();
      await start(tester, hidden: true, route: Routes.home);
      await open(tester, Routes.plan(telefon));
      await tester.tap(find.text('10 Ara 2026'));
      await tester.pumpAndSettle();
      // The payment sheet: "Extra fee: •••" under its option.
      expect(find.text('Ek ücret: $mask'), findsWidgets);
      expect(spokenWith('₺'), findsNothing);
      expect(spokenWith('•'), findsNothing);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      // Into the next period: the period rows show what changes.
      await open(
        tester,
        Routes.paymentDate(telefon, 1, LocalDate(2027, 1, 20)),
      );
      expect(find.text('1/12 · $mask'), findsOneWidget);
      noAmount();
      semantics.dispose();
    });

    testWidgets('the fee summary: masked on a plan, shown in a preview', (
      tester,
    ) async {
      await pumpLocalized(
        tester,
        ProviderScope(
          overrides: [
            amountsHiddenStoreProvider.overrideWithValue(
              MemoryAmountsHiddenStore(true),
            ),
            currencyProvider.overrideWithValue(Currency.fromCode('TRY')),
          ],
          child: const Column(
            children: [
              InstallmentFeeSummary(
                key: ValueKey('plan'),
                planMinor: 2400000,
                feesMinor: 60000,
              ),
              InstallmentFeeSummary(
                key: ValueKey('preview'),
                planMinor: 2400000,
                feesMinor: 60000,
                draft: true,
              ),
            ],
          ),
        ),
      );
      Finder inside(String key, Finder f) =>
          find.descendant(of: find.byKey(ValueKey(key)), matching: f);
      expect(inside('plan', find.text(mask)), findsNWidgets(3));
      expect(inside('plan', find.textContaining('₺')), findsNothing);
      expect(inside('preview', find.text('₺24.600')), findsOneWidget);
      expect(inside('preview', find.text(mask)), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });
  });

  testWidgets('Example 4: coming periods keep their bars, labels masked', (
    tester,
  ) async {
    await start(tester, route: Routes.comingPeriods());
    List<Rect> bars() => [
      for (final e in find.byType(ComingBar).evaluate())
        tester.getRect(find.byWidget(e.widget)),
    ];
    final before = bars();
    expect(before, isNotEmpty);
    expect(find.textContaining('₺'), findsWidgets);

    await setHidden(tester, true);
    expect(bars(), before);
    expect(find.textContaining('₺'), findsNothing);
    expect(find.text(mask), findsWidgets);
    // This period's short line, in words.
    expect(find.text('Bu dönem $mask eksik kalıyor.'), findsOneWidget);
  });

  group('no real amount on screen while hidden', () {
    for (final (name, route, today, seed)
        in <
          (String, String, LocalDate?, Future<Object?> Function(AppDatabase)?)
        >[
          ('home', Routes.home, null, null),
          ('plans', Routes.plans, null, null),
          ('coming periods', Routes.comingPeriods(), null, null),
          (
            'sources and statements',
            Routes.sources,
            statementToday,
            seedStatements,
          ),
          (
            'one statement',
            Routes.cardStatement(1, LocalDate(2026, 11, 14).epochDay),
            statementToday,
            seedStatements,
          ),
          ('keep in account', Routes.sources, chargeToday, seedCharges),
        ]) {
      testWidgets(name, (tester) async {
        tallPhone(tester);
        final semantics = tester.ensureSemantics();
        await start(
          tester,
          hidden: true,
          route: route,
          today: today,
          seed: seed == null ? null : (db) async => await seed(db),
        );
        expect(find.textContaining('₺'), findsNothing);
        expect(find.text(mask), findsWidgets);
        // Example 7: never the amount, never the dots: "Tutar gizli".
        expect(spokenWith('₺'), findsNothing);
        expect(spokenWith(mask), findsNothing);
        expect(spokenWith('•'), findsNothing);
        expect(spokenWith('Tutar gizli'), findsWidgets);
        semantics.dispose();
      });
    }

    testWidgets('calendar day', (tester) async {
      tallPhone(tester);
      await start(
        tester,
        hidden: true,
        today: calendarToday,
        seed: seedCalendar,
      );
      await tester.tap(find.byKey(const ValueKey('coming-periods-strip')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Takvim'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('calendar-cell-14')));
      await tester.pumpAndSettle();
      expect(find.textContaining('₺'), findsNothing);
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('calendar-day-total')))
            .data,
        contains(mask),
      );
    });
  });

  testWidgets('Example 7: the screen reader on home and plan details', (
    tester,
  ) async {
    tallPhone(tester);
    final semantics = tester.ensureSemantics();
    await start(tester, hidden: true);
    expect(spokenWith('₺'), findsNothing);
    expect(spokenWith('•'), findsNothing);
    expect(spokenWith('Tutar gizli'), findsWidgets);
    expect(spokenWith('Tutarları göster'), findsOneWidget);
    final router = ProviderScope.containerOf(
      tester.element(find.byType(KalanApp)),
    ).read(routerProvider);
    unawaited(router.push(Routes.plan(telefon)));
    await tester.pumpAndSettle();
    expect(spokenWith('₺'), findsNothing);
    expect(spokenWith('•'), findsNothing);
    expect(spokenWith('Tutar gizli'), findsWidgets);
    semantics.dispose();
  });

  testWidgets('amounts shown: nothing reads "Amount hidden"', (tester) async {
    tallPhone(tester);
    final semantics = tester.ensureSemantics();
    await start(tester);
    expect(spokenWith('Tutar gizli'), findsNothing);
    expect(spokenWith('₺'), findsWidgets);
    expect(spokenWith('Tutarları gizle'), findsOneWidget);
    semantics.dispose();
  });

  group('the flow where an amount is typed is never masked', () {
    testWidgets('adding a plan: fields and preview', (tester) async {
      await start(tester, hidden: true, seed: seedSettings);
      await tester.tap(find.text('Plan ekle'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('source')), 'Klarna');
      await tester.enterText(find.byKey(const ValueKey('total')), '400,01');
      await tester.pumpAndSettle();
      await scrollTo(tester, find.text('1 Oca 2027'));
      expect(find.text('4 ödeme, toplam ₺400,01.'), findsOneWidget);
      expect(find.text('₺100,01'), findsOneWidget);
      expect(find.text(mask), findsNothing);
    });

    testWidgets('"Adjust amount": the totals it works with', (tester) async {
      await start(tester, hidden: true, route: Routes.home);
      final router = ProviderScope.containerOf(
        tester.element(find.byType(KalanApp)),
      ).read(routerProvider);
      unawaited(router.push(Routes.planAdjust(telefon)));
      await tester.pumpAndSettle();
      expect(find.textContaining('₺24.000'), findsOneWidget);
      expect(find.text(mask), findsNothing);
    });
  });

  group('Settings > Privacy', () {
    Future<void> openPrivacy(WidgetTester tester) async {
      await openTab(tester, 'Ayarlar');
      await scrollTo(tester, hideSwitch);
    }

    bool switchValue(WidgetTester tester) =>
        tester.widget<SwitchListTile>(hideSwitch).value;

    testWidgets('the switch and the eye share one value', (tester) async {
      await start(
        tester,
        extra: [
          deviceLockGatewayProvider.overrideWithValue(
            const UnsupportedDeviceLock(),
          ),
        ],
      );
      await openPrivacy(tester);
      // The section title right above it.
      final title = find.text('Gizlilik', skipOffstage: false);
      await tester.ensureVisible(title);
      await tester.pumpAndSettle();
      expect(title, findsOneWidget);
      expect(
        tester.getTopLeft(title).dy,
        lessThan(tester.getTopLeft(hideSwitch).dy),
      );
      expect(find.text('Tutarları gizle'), findsOneWidget);
      expect(
        find.text(
          'Tutarlar ekranlarda ve bildirimlerde gizlenir; tutar yazarken '
          'görünür.',
        ),
        findsOneWidget,
      );
      expect(switchValue(tester), isFalse);
      // Where the phone has no lock to offer (web, desktop; the default
      // gateway, also set below): the section
      // and "Hide amounts", without the app lock rows.
      expect(find.byKey(const ValueKey('app-lock')), findsNothing);
      await tester.tap(hideSwitch);
      await tester.pumpAndSettle();
      expect(switchValue(tester), isTrue);
      expect(store.read(), isTrue);
      // Income and "tight" in Settings are masked too.
      await reveal(tester, find.text('Net tutar', skipOffstage: false));
      expect(find.text(mask), findsNWidgets(2));

      await openTab(tester, 'Bu dönem');
      expect(homeNumber(tester), mask);
      expect(find.byTooltip('Tutarları göster'), findsOneWidget);
      await tester.tap(eye);
      await tester.pumpAndSettle();
      await openPrivacy(tester);
      expect(switchValue(tester), isFalse);
    });

    testWidgets('app lock: no "amounts show" row while amounts are hidden', (
      tester,
    ) async {
      final db = await start(
        tester,
        extra: [
          deviceLockGatewayProvider.overrideWithValue(FakeDeviceLock()),
          appIsActiveProvider.overrideWithValue(() => true),
          appLockStoreProvider.overrideWithValue(MemoryAppLockStore()),
          notificationGatewayProvider.overrideWithValue(
            FakeNotificationGateway(),
          ),
        ],
      );
      await openPrivacy(tester);
      await scrollTo(tester, find.byKey(const ValueKey('app-lock')));
      await tester.tap(find.byKey(const ValueKey('app-lock')));
      await tester.pumpAndSettle();
      final row = find.byKey(const ValueKey('app-lock-amounts'));
      expect(row, findsOneWidget);
      await reveal(tester, hideSwitch);
      await tester.tap(hideSwitch);
      await tester.pumpAndSettle();
      expect(row, findsNothing);
      // "Show amount in notifications" keeps its value.
      final settings = await db.select(db.appSettings).getSingle();
      expect(settings.hideAmountsInNotifications, isFalse);
    });
  });

  testWidgets('a choice that could not be saved goes back on screen', (
    tester,
  ) async {
    final failing = _FailingStore();
    await pumpApp(
      tester,
      seed: seedAll,
      overrides: [amountsHiddenStoreProvider.overrideWithValue(failing)],
    );
    await tester.tap(eye);
    await tester.pumpAndSettle();
    // Not stored: the screen shows what the reminders read.
    expect(failing.read(), isFalse);
    expect(homeNumber(tester), isNot(mask));
    expect(find.byTooltip('Tutarları gizle'), findsOneWidget);
  });

  testWidgets('amounts shown: a name with dots reads as itself', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await start(
      tester,
      seed: (db) async {
        await seedSettings(db, incomeMinor: 1000000);
        await seedPayIn4(db, title: 'Plan $mask');
      },
    );
    expect(find.text('Plan $mask'), findsWidgets);
    expect(spokenWith('Tutar gizli'), findsNothing);
    expect(spokenWith('Plan $mask'), findsWidgets);
    semantics.dispose();
  });

  testWidgets('kept on this device only: not in the database', (tester) async {
    final db = await start(tester, hidden: true);
    final columns = db.appSettings.$columns.map((c) => c.name).toList();
    expect(columns.where((c) => c.contains('hide')), [
      'hide_amounts_in_notifications',
    ]);
    expect(columns.where((c) => c.contains('privacy')), isEmpty);
    final row = await db.select(db.appSettings).getSingle();
    expect(row.hideAmountsInNotifications, isFalse);
  });

  test('the eye never uses accent; no new color', () {
    final source = File('lib/features/privacy/hide_amounts_ui.dart')
        .readAsStringSync();
    expect(source, isNot(contains('.accent')));
    expect(source, contains('colors.textMuted'));
  });
}

/// Its writes fail; it keeps what it had.
class _FailingStore implements AmountsHiddenStore {
  @override
  bool read() => false;

  @override
  Future<void> write(bool hidden) async => throw StateError('disk full');
}
