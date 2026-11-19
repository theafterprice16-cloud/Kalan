// Golden screenshots of every main screen in light and dark themes.
// Images live in screenshots/. Update with:
//   flutter test test/golden --update-goldens
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/app/app.dart';
import 'package:kalan/core/engine/engine.dart';
import 'package:kalan/core/reminders/reminder_models.dart' show ReminderRepeat;
import 'package:kalan/core/routing/router.dart';
import 'package:kalan/core/routing/routes.dart';
import 'package:kalan/core/theme/theme_mode.dart';
import 'package:kalan/data/db/app_database.dart';
import 'package:kalan/data/repositories/plan_repository.dart';
import 'package:kalan/data/repositories/source_repository.dart';
import 'package:kalan/entitlement/pro_controller.dart';
import 'package:kalan/entitlement/pro_rules.dart';
import 'package:kalan/entitlement/pro_status_store.dart';
import 'package:kalan/entitlement/store_gateway.dart';
import 'package:kalan/features/reminders/reminder_providers.dart';
import 'package:kalan/features/roadmap/roadmap.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../helpers/app_harness.dart';
import '../helpers/calendar_seed.dart';
import '../helpers/fake_notifications.dart';
import '../helpers/fake_store.dart';

/// Real fonts from the Flutter SDK so screenshots are readable.
Future<void> loadFonts() async {
  var dir = File(Platform.resolvedExecutable).parent;
  Directory? fonts;
  for (var i = 0; i < 8 && fonts == null; i++) {
    final candidate = Directory(
      '${dir.path}/bin/cache/artifacts/material_fonts',
    );
    if (candidate.existsSync()) fonts = candidate;
    final env = Platform.environment['FLUTTER_ROOT'];
    if (fonts == null && env != null) {
      final fromEnv = Directory('$env/bin/cache/artifacts/material_fonts');
      if (fromEnv.existsSync()) fonts = fromEnv;
    }
    dir = dir.parent;
  }
  if (fonts == null) return;
  Future<void> family(String name, List<String> files) async {
    final loader = FontLoader(name);
    for (final f in files) {
      final bytes = File('${fonts!.path}/$f').readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }

  const roboto = ['Roboto-Regular.ttf', 'Roboto-Medium.ttf', 'Roboto-Bold.ttf'];
  await family('Roboto', roboto);
  // iOS text styles ask for the system font; Roboto stands in for it.
  await family('CupertinoSystemText', roboto);
  await family('CupertinoSystemDisplay', roboto);
  await family('MaterialIcons', ['MaterialIcons-Regular.otf']);
}

/// A plan with a past unpaid payment (overdue), a card plan, rent.
Future<void> seedRich(AppDatabase db, {required int? incomeMinor}) async {
  await seedSettings(db, incomeMinor: incomeMinor, thresholdMinor: 500000);
  await seedPayIn4(db, totalMinor: 240000, title: 'Kulaklık');
  await seedPayIn4(
    db,
    first: LocalDate(2026, 10, 30),
    totalMinor: 180000,
    source: 'Afterpay',
    title: 'Mont',
  );
  final card = await seedCard(db);
  final draft = PlanCalculator.card(
    purchaseDate: LocalDate(2026, 10, 10),
    totalMinor: 1200000,
    count: 6,
    terms: const CardTerms(statementDay: 25, dueDay: 5),
  );
  final planId = await db
      .into(db.plans)
      .insert(
        PlansCompanion.insert(
          sourceId: Value(card),
          title: const Value('Telefon'),
          kind: PlanKind.card,
          installmentCount: 6,
          origin: PlanOrigin.template,
        ),
      );
  for (final p in draft.payments) {
    await db
        .into(db.payments)
        .insert(
          PaymentsCompanion.insert(
            planId: planId,
            seq: p.seq,
            dueDay: p.date.epochDay,
            amountMinor: p.amountMinor,
            paidAt: Value(p.seq == 1 ? DateTime(2026, 11, 5) : null),
          ),
        );
  }
  await seedRent(db);
}

/// One single-payment plan.
Future<void> seedOne(
  AppDatabase db,
  String name,
  LocalDate due,
  int minor,
) async {
  final plans = PlanRepository(db);
  final source = await SourceRepository(db, plans).findOrCreateProvider(name);
  await plans.saveDraft(
    PlanCalculator.monthly(firstDate: due, totalMinor: minor, count: 1),
    sourceId: source,
    origin: PlanOrigin.template,
  );
}

/// Zeynep on 1 Nov 2026: 850 from 28 Oct unpaid; [more] adds three older
/// ones.
Future<void> seedPastDue(AppDatabase db, {bool more = false}) async {
  await seedSettings(db, incomeMinor: 3000000, payDay: 1);
  await seedOne(db, 'Telefon', LocalDate(2026, 11, 10), 1200000);
  await seedOne(db, 'Klarna', LocalDate(2026, 10, 28), 85000);
  if (more) {
    await seedOne(db, 'Afterpay', LocalDate(2026, 9, 20), 45000);
    await seedOne(db, 'Zip', LocalDate(2026, 10, 12), 30000);
    await seedOne(db, 'Kart', LocalDate(2026, 10, 25), 125000);
  }
}

/// A phone already 3 of 10 installments in when it was added.
Future<void> seedUnderway(AppDatabase db) async {
  final plans = PlanRepository(db);
  final source = await SourceRepository(
    db,
    plans,
  ).findOrCreateProvider('Telefon');
  await plans.saveDraft(
    underwayPlan(
      kind: PlanKind.monthly,
      totalMinor: 850000,
      count: 10,
      paidCount: 3,
      nextDate: LocalDate(2026, 12, 5),
    ),
    sourceId: source,
    origin: PlanOrigin.template,
    title: 'Tablet',
    now: DateTime(2026, 11, 20),
  );
}

Future<void> shoot(WidgetTester tester, String name) async {
  await tester.pumpAndSettle();
  await expectLater(
    find.byType(KalanApp),
    matchesGoldenFile('../../screenshots/$name.png'),
  );
}

void main() {
  setUpAll(() async {
    await loadFonts();
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
  });

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    final theme = mode.name;

    Future<void> start(
      WidgetTester tester, {
      int? income = 4500000,
      bool onboarded = true,
      List<Override> extra = const [],
      String? route,
      Locale locale = const Locale('tr', 'TR'),
      FakeNotificationGateway? gateway,
      bool underway = false,
      Future<void> Function(AppDatabase db)? seed,
      LocalDate? today,
    }) async {
      tester.view.physicalSize = const Size(780, 1688);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await pumpApp(
        tester,
        locale: locale,
        today: today,
        seed:
            seed ??
            (onboarded
                ? (db) async {
                    await seedRich(db, incomeMinor: income);
                    if (underway) await seedUnderway(db);
                  }
                : null),
        overrides: [
          themeModeStoreProvider.overrideWithValue(MemoryThemeModeStore(mode)),
          notificationGatewayProvider.overrideWithValue(
            gateway ?? FakeNotificationGateway(),
          ),
          clockProvider.overrideWithValue(() => DateTime.utc(2026, 11, 20, 5)),
          if (route != null) initialRouteProvider.overrideWithValue(route),
          ...extra,
        ],
      );
    }

    group(theme, () {
      testWidgets('onboarding', (tester) async {
        await start(tester, onboarded: false);
        await shoot(tester, '01-onboarding-$theme');
      });

      testWidgets('home, left positive', (tester) async {
        await start(tester);
        await shoot(tester, '02-home-positive-$theme');
      });

      testWidgets('home, left negative', (tester) async {
        await start(tester, income: 1500000);
        await shoot(tester, '03-home-negative-$theme');
      });

      // Coming pay periods (12): the home strip and its screen, with
      // income, without it and with short periods.
      testWidgets('home, no income', (tester) async {
        await start(tester, income: null);
        await shoot(tester, '51-home-no-income-$theme');
      });

      for (final (name, income) in [
        ('positive', 4500000),
        ('negative', 1900000),
        ('no-income', null),
      ]) {
        testWidgets('coming periods, $name', (tester) async {
          await start(tester, income: income);
          await tester.tap(find.byKey(const ValueKey('coming-periods-strip')));
          await shoot(tester, '52-coming-periods-$name-$theme');
        });
      }

      testWidgets('coming periods, next period selected, en', (tester) async {
        await start(tester, locale: const Locale('en', 'US'));
        await tester.tap(find.byKey(const ValueKey('coming-periods-strip')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('coming-period-1')));
        await shoot(tester, '53-coming-periods-next-en-$theme');
      });

      // Calendar (13): November 2026 with Examples 1 and 3, a day open,
      // a day without payments. Turkish and English (US: Sunday first).
      for (final (lang, locale) in [
        ('tr', const Locale('tr', 'TR')),
        ('en', const Locale('en', 'US')),
      ]) {
        Future<void> openCalendar(WidgetTester tester) async {
          await start(
            tester,
            locale: locale,
            seed: seedCalendar,
            today: calendarToday,
          );
          await tester.tap(find.byKey(const ValueKey('coming-periods-strip')));
          await tester.pumpAndSettle();
          await tester.tap(find.text(lang == 'tr' ? 'Takvim' : 'Calendar'));
          await tester.pumpAndSettle();
        }

        testWidgets('calendar, november, $lang', (tester) async {
          await openCalendar(tester);
          await shoot(tester, '54-calendar-november-$lang-$theme');
        });

        testWidgets('calendar, day open, $lang', (tester) async {
          await openCalendar(tester);
          await tester.tap(find.byKey(const ValueKey('calendar-cell-14')));
          await tester.pumpAndSettle();
          await tester.drag(
            find.byKey(const ValueKey('payment-calendar')),
            const Offset(0, -400),
          );
          await shoot(tester, '55-calendar-day-$lang-$theme');
        });

        testWidgets('calendar, day without payments, $lang', (tester) async {
          await openCalendar(tester);
          await tester.tap(find.byKey(const ValueKey('calendar-cell-15')));
          await shoot(tester, '56-calendar-empty-day-$lang-$theme');
        });
      }

      // Busy week (14): Example 1, the December period selected: the tag
      // beside its bar and the one line in its summary.
      for (final (lang, locale) in [
        ('tr', const Locale('tr', 'TR')),
        ('en', const Locale('en', 'US')),
      ]) {
        testWidgets('busy week, chart, $lang', (tester) async {
          await start(
            tester,
            locale: locale,
            seed: seedBusyWeek,
            today: busyWeekToday,
          );
          await tester.tap(find.byKey(const ValueKey('coming-periods-strip')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('coming-period-1')));
          await shoot(tester, '57-busy-week-chart-$lang-$theme');
        });
      }

      testWidgets('add plan', (tester) async {
        await start(tester);
        await tester.tap(find.text('Plan ekle'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(ChoiceChip, 'Aylık taksit'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byKey(const ValueKey('source')), 'Zip');
        await tester.enterText(find.byKey(const ValueKey('total')), '6000');
        await tester.enterText(find.byKey(const ValueKey('count')), '3');
        FocusManager.instance.primaryFocus?.unfocus();
        await shoot(tester, '04-add-plan-$theme');
      });

      testWidgets('plans', (tester) async {
        await start(tester);
        await openTab(tester, 'Planlar');
        await shoot(tester, '05-plans-$theme');
      });

      testWidgets('plan detail', (tester) async {
        await start(tester);
        await openTab(tester, 'Planlar');
        await tester.tap(find.text('Mont'));
        await shoot(tester, '06-plan-detail-$theme');
      });

      testWidgets('recurring payment', (tester) async {
        await start(tester);
        await openTab(tester, 'Planlar');
        await tester.tap(find.text('Sabit'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Kira'));
        await shoot(tester, '07-recurring-$theme');
      });

      testWidgets('settings', (tester) async {
        await start(tester);
        await openTab(tester, 'Ayarlar');
        await shoot(tester, '08-settings-$theme');
      });

      testWidgets('roadmap', (tester) async {
        // The documented example, read synchronously for a stable shot.
        final doc = File('docs/ROADMAP_CONTENT.md').readAsStringSync();
        final example = RegExp(
          r'```json\n(.*?)```',
          dotAll: true,
        ).firstMatch(doc)!.group(1)!;
        await start(
          tester,
          extra: [roadmapSourceProvider.overrideWith((ref) async => example)],
          route: Routes.roadmap,
        );
        await shoot(tester, '09-roadmap-$theme');
      });

      testWidgets('currency change', (tester) async {
        await start(tester);
        await openTab(tester, 'Ayarlar');
        await scrollTo(tester, find.text('Para birimi'));
        await tester.tap(find.text('Para birimi'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('currency-search')),
          'IDR',
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('currency-IDR')));
        await shoot(tester, '10-currency-change-$theme');
      });

      testWidgets('currency picker', (tester) async {
        await start(tester);
        await openTab(tester, 'Ayarlar');
        await scrollTo(tester, find.text('Para birimi'));
        await tester.tap(find.text('Para birimi'));
        await shoot(tester, '15-currency-picker-$theme');
      });

      testWidgets('currency search, right-to-left symbols', (tester) async {
        await start(tester);
        await openTab(tester, 'Ayarlar');
        await scrollTo(tester, find.text('Para birimi'));
        await tester.tap(find.text('Para birimi'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('currency-search')),
          'dinar',
        );
        FocusManager.instance.primaryFocus?.unfocus();
        await shoot(tester, '16-currency-search-$theme');
      });

      testWidgets('reminders help', (tester) async {
        await start(tester, route: Routes.remindersHelp);
        await shoot(tester, '13-reminders-help-$theme');
      });

      // Past-due payments in both languages.
      for (final (lang, locale, paid) in [
        ('tr', const Locale('tr', 'TR'), 'Ödendi'),
        ('en', const Locale('en', 'US'), 'Paid'),
      ]) {
        final nov1 = LocalDate(2026, 11, 1);

        testWidgets('home, one past due, $lang', (tester) async {
          await start(tester, locale: locale, today: nov1, seed: seedPastDue);
          await shoot(tester, '23-home-past-due-$lang-$theme');
        });

        testWidgets('home, four past due, $lang', (tester) async {
          await start(
            tester,
            locale: locale,
            today: nov1,
            seed: (db) => seedPastDue(db, more: true),
          );
          await shoot(tester, '24-home-past-due-four-$lang-$theme');
        });

        testWidgets('when did you pay, $lang', (tester) async {
          await start(tester, locale: locale, today: nov1, seed: seedPastDue);
          await tester.tap(find.text(paid).first);
          await shoot(tester, '25-paid-when-$lang-$theme');
        });

        testWidgets('marked paid with undo, $lang', (tester) async {
          await start(tester, locale: locale, today: nov1, seed: seedPastDue);
          await tester.tap(find.text(paid).first);
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('paid-when-today')));
          await shoot(tester, '26-marked-paid-undo-$lang-$theme');
        });
      }

      // "Already underway" in both languages.
      for (final (lang, locale, plansTab, addPlan, monthly, cardKind) in [
        (
          'tr',
          const Locale('tr', 'TR'),
          'Planlar',
          'Plan ekle',
          'Aylık taksit',
          'Kredi kartı taksidi',
        ),
        (
          'en',
          const Locale('en', 'US'),
          'Plans',
          'Add plan',
          'Monthly installments',
          'Card installments',
        ),
      ]) {
        Future<void> showUnderway(WidgetTester tester) async {
          const key = ValueKey('underway');
          await scrollTo(tester, find.byKey(key));
          await tester.tap(find.byKey(key));
          await tester.pumpAndSettle();
          final top = tester.getTopLeft(find.byKey(key)).dy;
          await tester.drag(
            find.byType(Scrollable).first,
            Offset(0, 260 - top),
          );
          FocusManager.instance.primaryFocus?.unfocus();
          await tester.pumpAndSettle();
        }

        testWidgets('add plan underway, monthly, $lang', (tester) async {
          await start(tester, locale: locale);
          await tester.tap(find.text(addPlan));
          await tester.pumpAndSettle();
          await tester.tap(find.widgetWithText(ChoiceChip, monthly));
          await tester.pumpAndSettle();
          await tester.enterText(find.byKey(const ValueKey('source')), 'Zip');
          await tester.enterText(find.byKey(const ValueKey('total')), '8500');
          await tester.enterText(find.byKey(const ValueKey('count')), '10');
          await tester.pumpAndSettle();
          await showUnderway(tester);
          await tester.enterText(find.byKey(const ValueKey('paid-count')), '3');
          FocusManager.instance.primaryFocus?.unfocus();
          await shoot(tester, '18-underway-add-monthly-$lang-$theme');
        });

        testWidgets('add plan underway, card, $lang', (tester) async {
          await start(tester, locale: locale);
          await tester.tap(find.text(addPlan));
          await tester.pumpAndSettle();
          await tester.tap(find.widgetWithText(ChoiceChip, cardKind));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('card')));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Bonus').last);
          await tester.pumpAndSettle();
          await tester.enterText(find.byKey(const ValueKey('total')), '9000');
          await tester.enterText(find.byKey(const ValueKey('count')), '9');
          await tester.pumpAndSettle();
          await showUnderway(tester);
          await tester.enterText(find.byKey(const ValueKey('paid-count')), '4');
          FocusManager.instance.primaryFocus?.unfocus();
          await shoot(tester, '19-underway-add-card-$lang-$theme');
        });

        testWidgets('plan detail underway, $lang', (tester) async {
          await start(tester, locale: locale, underway: true);
          await openTab(tester, plansTab);
          await tester.tap(find.text('Tablet'));
          await shoot(tester, '20-underway-plan-detail-$lang-$theme');
        });

        testWidgets('plan edit, $lang', (tester) async {
          await start(tester, locale: locale, underway: true);
          await openTab(tester, plansTab);
          await tester.tap(find.text('Tablet'));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('plan-edit')));
          await shoot(tester, '22-plan-edit-$lang-$theme');
        });

        testWidgets('plans list underway, $lang', (tester) async {
          await start(tester, locale: locale, underway: true);
          await openTab(tester, plansTab);
          await shoot(tester, '21-underway-plans-$lang-$theme');
        });
      }

      // Payment interval: Marta, 3 installments every 30 days from 1 Aug.
      for (final (lang, locale, addPlan, monthly, every30) in [
        (
          'tr',
          const Locale('tr', 'TR'),
          'Plan ekle',
          'Aylık taksit',
          '30 günde bir',
        ),
        (
          'en',
          const Locale('en', 'US'),
          'Add plan',
          'Monthly installments',
          'Every 30 days',
        ),
      ]) {
        testWidgets('add plan, every 30 days, $lang', (tester) async {
          await start(tester, locale: locale, today: LocalDate(2027, 8, 1));
          await tester.tap(find.text(addPlan));
          await tester.pumpAndSettle();
          await tester.tap(find.widgetWithText(ChoiceChip, monthly));
          await tester.pumpAndSettle();
          await tester.enterText(find.byKey(const ValueKey('source')), 'Zip');
          await tester.enterText(find.byKey(const ValueKey('total')), '3000');
          await tester.enterText(find.byKey(const ValueKey('count')), '3');
          FocusManager.instance.primaryFocus?.unfocus();
          await tester.pumpAndSettle();
          final chip = find.widgetWithText(ChoiceChip, every30);
          await tester.ensureVisible(chip);
          await tester.tap(chip);
          await tester.pumpAndSettle();
          await tester.ensureVisible(
            find.byKey(const ValueKey('preview-same-month')),
          );
          await tester.pumpAndSettle();
          await shoot(tester, '33-interval-add-$lang-$theme');
        });
      }

      // Total or installment: 1,000 / 3 does not divide evenly; Deniz
      // knows only "850 a month, 9 months".
      for (final (lang, locale, addPlan, monthly, installment) in [
        ('tr', const Locale('tr', 'TR'), 'Plan ekle', 'Aylık taksit', 'Taksit'),
        (
          'en',
          const Locale('en', 'US'),
          'Add plan',
          'Monthly installments',
          'Installment',
        ),
      ]) {
        for (final (entry, amount, count) in [
          ('total', '1000', '3'),
          ('installment', '850', '9'),
        ]) {
          testWidgets('add plan, $entry entry, $lang', (tester) async {
            await start(tester, locale: locale);
            await tester.tap(find.text(addPlan));
            await tester.pumpAndSettle();
            await tester.tap(find.widgetWithText(ChoiceChip, monthly));
            await tester.pumpAndSettle();
            if (entry == 'installment') {
              await tester.tap(
                find.descendant(
                  of: find.byKey(const ValueKey('amount-entry')),
                  matching: find.text(installment),
                ),
              );
              await tester.pumpAndSettle();
            }
            await tester.enterText(find.byKey(const ValueKey('source')), 'Zip');
            await tester.enterText(find.byKey(ValueKey(entry)), amount);
            await tester.enterText(find.byKey(const ValueKey('count')), count);
            FocusManager.instance.primaryFocus?.unfocus();
            await tester.pumpAndSettle();
            await shoot(tester, '34-amount-entry-$entry-$lang-$theme');
          });
        }
      }

      // "Pay later" in both languages (today: 20 November 2026).
      for (final (lang, locale, plansTab, addPlan, payLater, nextMonth, auto)
          in [
            (
              'tr',
              const Locale('tr', 'TR'),
              'Planlar',
              'Plan ekle',
              'Sonra öde',
              'Gelecek ayın …',
              'Sonra öde · 20 Ara',
            ),
            (
              'en',
              const Locale('en', 'US'),
              'Plans',
              'Add plan',
              'Pay later',
              'Next month on day …',
              'Pay later · Dec 20',
            ),
          ]) {
        Future<void> openForm(WidgetTester tester) async {
          await start(tester, locale: locale);
          await tester.tap(find.text(addPlan));
          await tester.pumpAndSettle();
          await tester.tap(find.widgetWithText(ChoiceChip, payLater));
          await tester.pumpAndSettle();
          await tester.enterText(find.byKey(const ValueKey('total')), '79');
          await tester.pumpAndSettle();
        }

        Future<void> withPayLater(AppDatabase db) async {
          await seedRich(db, incomeMinor: 4500000);
          await PlanRepository(db).saveDraft(
            PlanCalculator.payLater(
              purchaseDate: testToday,
              rule: defaultPayLaterRule,
              totalMinor: 7900,
            ),
            sourceId: null,
            origin: PlanOrigin.template,
          );
        }

        testWidgets('pay later form, $lang', (tester) async {
          await openForm(tester);
          await shoot(tester, '29-pay-later-form-$lang-$theme');
        });

        testWidgets('pay later, next month, $lang', (tester) async {
          await openForm(tester);
          await tester.tap(find.widgetWithText(ChoiceChip, nextMonth));
          await tester.pumpAndSettle();
          await tester.enterText(
            find.byKey(const ValueKey('pay-later-number')),
            '27',
          );
          FocusManager.instance.primaryFocus?.unfocus();
          await shoot(tester, '30-pay-later-next-month-$lang-$theme');
        });

        testWidgets('plans list, pay later, $lang', (tester) async {
          await start(tester, locale: locale, seed: withPayLater);
          await openTab(tester, plansTab);
          await shoot(tester, '31-plans-pay-later-$lang-$theme');
        });

        testWidgets('pay later detail, $lang', (tester) async {
          await start(tester, locale: locale, seed: withPayLater);
          await openTab(tester, plansTab);
          await tester.tap(find.text(auto));
          await shoot(tester, '32-pay-later-detail-$lang-$theme');
        });
      }

      // Reminder screens in both languages.
      for (final (lang, locale, settingsTab, plansTab, addPlan) in [
        ('tr', const Locale('tr', 'TR'), 'Ayarlar', 'Planlar', 'Plan ekle'),
        ('en', const Locale('en', 'US'), 'Settings', 'Plans', 'Add plan'),
      ]) {
        Future<void> openReminders(WidgetTester tester) async {
          await openTab(tester, settingsTab);
          // Put the section near the top of the screen.
          const key = ValueKey('reminders-enabled');
          await scrollTo(tester, find.byKey(key));
          final top = tester.getTopLeft(find.byKey(key)).dy;
          await tester.drag(
            find.byType(Scrollable).first,
            Offset(0, 140 - top),
          );
          await tester.pump(const Duration(milliseconds: 400));
        }

        testWidgets('settings, reminders section, $lang', (tester) async {
          await start(tester, locale: locale);
          await openReminders(tester);
          await shoot(tester, '11-reminders-settings-$lang-$theme');
        });

        testWidgets('settings, reminders, permission off, $lang', (
          tester,
        ) async {
          await start(
            tester,
            locale: locale,
            gateway: FakeNotificationGateway(granted: false),
          );
          await openReminders(tester);
          await shoot(tester, '12-reminders-permission-off-$lang-$theme');
        });

        testWidgets('permission sheet, $lang', (tester) async {
          await start(
            tester,
            locale: locale,
            gateway: FakeNotificationGateway(granted: false),
          );
          await tester.tap(find.text(addPlan));
          await tester.pumpAndSettle();
          await tester.enterText(find.byKey(const ValueKey('source')), 'Zip');
          await tester.enterText(find.byKey(const ValueKey('total')), '400');
          await tester.pumpAndSettle();
          await scrollTo(tester, find.byKey(const ValueKey('save-plan')));
          await tester.tap(find.byKey(const ValueKey('save-plan')));
          await shoot(tester, '14-reminder-sheet-$lang-$theme');
        });

        testWidgets('repeat reminders choice, $lang', (tester) async {
          await start(tester, locale: locale);
          await openReminders(tester);
          await tester.tap(find.byKey(const ValueKey('reminder-repeat')));
          await shoot(tester, '27-repeat-choice-$lang-$theme');
        });

        testWidgets('plans list, repeat icon, $lang', (tester) async {
          await start(
            tester,
            locale: locale,
            seed: (db) async {
              await seedRich(db, incomeMinor: 4500000);
              // One plan repeats every day; the global setting stays off.
              final mont = await (db.select(
                db.plans,
              )..where((p) => p.title.equals('Mont'))).getSingle();
              await (db.update(
                db.plans,
              )..where((p) => p.id.equals(mont.id))).write(
                const PlansCompanion(repeatMode: Value(ReminderRepeat.daily)),
              );
            },
          );
          await openTab(tester, plansTab);
          await shoot(tester, '28-plans-repeat-$lang-$theme');
        });

        testWidgets('plan reminder choice, $lang', (tester) async {
          await start(tester, locale: locale);
          await openTab(tester, plansTab);
          await tester.tap(find.text('Mont'));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('item-reminders')));
          await shoot(tester, '17-plan-reminder-choice-$lang-$theme');
        });
      }

      // iPhone behaviour, Kalan look: switches stay ink (never Apple
      // green); dialogs are flat Kalan surfaces in Apple's arrangement.
      final ios = TargetPlatformVariant.only(TargetPlatform.iOS);

      testWidgets('ios, settings switches', variant: ios, (tester) async {
        await start(tester);
        await openTab(tester, 'Ayarlar');
        const key = ValueKey('reminders-enabled');
        await scrollTo(tester, find.byKey(key));
        final top = tester.getTopLeft(find.byKey(key)).dy;
        await tester.drag(find.byType(Scrollable).first, Offset(0, 140 - top));
        await tester.pump(const Duration(milliseconds: 400));
        await shoot(tester, '40-ios-settings-switches-$theme');
      });

      testWidgets('ios, delete plan', variant: ios, (tester) async {
        await start(tester);
        await openTab(tester, 'Planlar');
        await tester.tap(find.text('Mont'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Planı sil'));
        await shoot(tester, '41-ios-delete-plan-$theme');
      });

      testWidgets('ios, edit payment', variant: ios, (tester) async {
        await start(tester);
        await openTab(tester, 'Planlar');
        await tester.tap(find.text('Kulaklık'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('4 Ara 2026'));
        await shoot(tester, '42-ios-edit-payment-$theme');
      });

      testWidgets('ios, theme choice', variant: ios, (tester) async {
        await start(tester);
        await openTab(tester, 'Ayarlar');
        await scrollTo(tester, find.text('Tema'));
        await tester.tap(find.text('Tema'));
        await shoot(tester, '43-ios-theme-choice-$theme');
      });

      // Kalan Pro: the store's price (a fake store here), the note when
      // the price cannot be loaded, Pro on, and the fifth-plan sheet.
      Future<void> fourPlans(AppDatabase db) async {
        await seedRich(db, incomeMinor: 4500000);
        await seedPayIn4(db, source: 'Zip', title: 'Ayakkabı');
      }

      List<Override> proStore({
        String? price = '249,99 ₺',
        ProStatus status = ProStatus.notPro,
      }) => [
        storeGatewayProvider.overrideWithValue(
          FakeStoreGateway()
            ..price = price == null
                ? const PriceUnavailable()
                : PriceLoaded(price),
        ),
        proStatusStoreProvider.overrideWithValue(MemoryProStatusStore(status)),
      ];

      Future<void> limitSheet(WidgetTester tester, Locale locale) async {
        await start(
          tester,
          locale: locale,
          seed: fourPlans,
          extra: proStore(),
          route: Routes.addPlan,
        );
        await tester.enterText(find.byKey(const ValueKey('source')), 'Klarna');
        await tester.enterText(find.byKey(const ValueKey('total')), '400');
        await tester.pumpAndSettle();
        await scrollTo(tester, find.byKey(const ValueKey('save-plan')));
        await tester.tap(find.byKey(const ValueKey('save-plan')));
      }

      for (final (lang, locale, price) in [
        ('tr', const Locale('tr', 'TR'), '249,99 ₺'),
        ('en', const Locale('en', 'US'), r'$14.99'),
      ]) {
        testWidgets('pro screen, free, $lang', (tester) async {
          await start(
            tester,
            locale: locale,
            extra: proStore(price: price),
            route: Routes.pro(),
          );
          await shoot(tester, '44-pro-free-$lang-$theme');
        });

        testWidgets('fifth plan sheet, $lang', (tester) async {
          await limitSheet(tester, locale);
          await shoot(tester, '47-pro-limit-sheet-$lang-$theme');
        });
      }

      testWidgets('pro screen, price not loaded', (tester) async {
        await start(tester, extra: proStore(price: null), route: Routes.pro());
        await shoot(tester, '45-pro-price-unavailable-$theme');
      });

      testWidgets('pro screen, Pro on', (tester) async {
        await start(
          tester,
          extra: proStore(status: ProStatus.pro),
          route: Routes.pro(),
        );
        await shoot(tester, '46-pro-active-$theme');
      });

      testWidgets('settings, Kalan Pro rows', (tester) async {
        await start(tester, extra: proStore());
        await openTab(tester, 'Ayarlar');
        const key = ValueKey('settings-restore');
        await scrollTo(tester, find.byKey(key));
        final top = tester.getTopLeft(find.byKey(key)).dy;
        await tester.drag(find.byType(Scrollable).first, Offset(0, 400 - top));
        await tester.pump(const Duration(milliseconds: 400));
        await shoot(tester, '48-settings-pro-$theme');
      });

      testWidgets('ios, pro screen', variant: ios, (tester) async {
        await start(tester, extra: proStore(), route: Routes.pro());
        await shoot(tester, '49-ios-pro-free-$theme');
      });

      testWidgets('ios, fifth plan sheet', variant: ios, (tester) async {
        await limitSheet(tester, const Locale('tr', 'TR'));
        await shoot(tester, '50-ios-pro-limit-sheet-$theme');
      });

      // Payment method: add plan (More details open), plan details, home.
      for (final (lang, locale, plansTab, addPlan, cardKind, details) in [
        (
          'tr',
          const Locale('tr', 'TR'),
          'Planlar',
          'Plan ekle',
          'Kredi kartı taksidi',
          'Ayrıntı ekle',
        ),
        (
          'en',
          const Locale('en', 'US'),
          'Plans',
          'Add plan',
          'Card installments',
          'More details',
        ),
      ]) {
        /// Telefon (card) automatic, Kulaklık manual, Mont not set.
        Future<void> withMethods(AppDatabase db) async {
          await seedRich(db, incomeMinor: 4500000);
          for (final (title, method) in [
            ('Telefon', PaymentMethod.automatic),
            ('Kulaklık', PaymentMethod.manual),
          ]) {
            await (db.update(db.plans)..where((p) => p.title.equals(title)))
                .write(PlansCompanion(paymentMethod: Value(method)));
          }
        }

        testWidgets('add plan, payment method, $lang', (tester) async {
          await start(tester, locale: locale);
          await tester.tap(find.text(addPlan));
          await tester.pumpAndSettle();
          await tester.tap(find.widgetWithText(ChoiceChip, cardKind));
          await tester.pumpAndSettle();
          await pickDropdown(tester, const ValueKey('card'), 'Bonus');
          await tester.enterText(find.byKey(const ValueKey('total')), '12000');
          await tester.enterText(find.byKey(const ValueKey('count')), '6');
          FocusManager.instance.primaryFocus?.unfocus();
          await scrollTo(tester, find.text(details));
          await tester.tap(find.text(details));
          await tester.pumpAndSettle();
          await scrollTo(
            tester,
            find.byWidgetPredicate((w) => '${w.key}'.contains('charge-source')),
          );
          await shoot(tester, '35-add-plan-payment-method-$lang-$theme');
        });

        testWidgets('plan detail, payment method, $lang', (tester) async {
          await start(tester, locale: locale, seed: withMethods);
          await openTab(tester, plansTab);
          await tester.tap(find.text('Telefon'));
          await tester.pumpAndSettle();
          await scrollTo(
            tester,
            find.byKey(const ValueKey('item-payment-method')),
          );
          await shoot(tester, '36-plan-detail-payment-method-$lang-$theme');
        });

        testWidgets('home, payment method icons, $lang', (tester) async {
          await start(tester, locale: locale, seed: withMethods);
          // The period's payments at the top: manual, not set, automatic.
          await tester.drag(
            find.byType(Scrollable).first,
            const Offset(0, -560),
          );
          await tester.pump(const Duration(milliseconds: 400));
          await shoot(tester, '37-home-payment-method-$lang-$theme');
        });
      }
    });
  }
}
