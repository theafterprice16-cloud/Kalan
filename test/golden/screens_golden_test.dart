// Golden screenshots of every main screen in light and dark themes.
// Images live in screenshots/. Update with:
//   flutter test test/golden --update-goldens
import 'dart:io';

import 'package:drift/drift.dart' show Value;
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
import 'package:kalan/features/plans/provider_templates_ui.dart';
import 'package:kalan/features/reminders/reminder_providers.dart';
import 'package:kalan/features/roadmap/roadmap.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../helpers/app_harness.dart';
import '../helpers/calendar_seed.dart';
import '../helpers/charge_seed.dart';
import '../helpers/fake_notifications.dart';
import '../helpers/fake_store.dart';
import '../helpers/fonts.dart';
import '../helpers/statement_seed.dart';

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

/// Shortfall (15), Example 1: income ₺30.000, payday 15, rent ₺15.000 on
/// the 1st, a phone ₺4.250 a month from 5 Dec and a holiday ₺16.200 on
/// 20 Feb: the 15 Feb – 14 Mar period is ₺31.200, ₺1.200 short; every
/// other period has room left.
Future<void> seedShortfall(AppDatabase db) async {
  await seedSettings(db, incomeMinor: 3000000);
  await seedRent(db);
  final plans = PlanRepository(db);
  final sources = SourceRepository(db, plans);
  await plans.saveDraft(
    PlanCalculator.monthly(
      firstDate: LocalDate(2026, 12, 5),
      totalMinor: 1275000,
      count: 3,
    ),
    sourceId: await sources.findOrCreateProvider('Telefon'),
    origin: PlanOrigin.template,
  );
  await seedOne(db, 'Tatil', LocalDate(2027, 2, 20), 1620000);
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
      bool templates = false,
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
          // Provider templates (25) only where a shot is about them: the
          // other add plan shots stay as they were in any region.
          if (!templates) regionTemplatesProvider.overrideWithValue(const []),
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

      // Shortfall (15), Example 1: the February period selected: its bar
      // in two parts with the income line, "looks short" in its summary.
      for (final (lang, locale) in [
        ('tr', const Locale('tr', 'TR')),
        ('en', const Locale('en', 'US')),
      ]) {
        testWidgets('shortfall ahead, $lang', (tester) async {
          await start(tester, locale: locale, seed: seedShortfall);
          await tester.tap(find.byKey(const ValueKey('coming-periods-strip')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('coming-period-3')));
          await shoot(tester, '58-shortfall-ahead-$lang-$theme');
        });
      }

      // Card statements (16), Examples 1-4: two cards with statements
      // (Ada Kart's 14 Nov statement cut, ₺4.150) and the statement open.
      for (final (lang, locale, plans, sources) in [
        ('tr', const Locale('tr', 'TR'), 'Planlar', 'Kaynaklar ve kartlar'),
        ('en', const Locale('en', 'US'), 'Plans', 'Sources and cards'),
      ]) {
        Future<void> openSources(WidgetTester tester) async {
          await start(
            tester,
            locale: locale,
            seed: seedStatements,
            today: statementToday,
          );
          await openTab(tester, plans);
          await tester.tap(find.byTooltip(sources));
          await tester.pumpAndSettle();
        }

        testWidgets('card statements, $lang', (tester) async {
          await openSources(tester);
          await shoot(tester, '59-card-statements-$lang-$theme');
        });

        testWidgets('card statement detail, $lang', (tester) async {
          await openSources(tester);
          await tester.tap(find.byKey(const ValueKey('card-statement-1-0')));
          await shoot(tester, '60-card-statement-$lang-$theme');
        });

        // Statement closing reminder (17): the card's settings, the switch
        // off (the default) and on with 1 / 2 days.
        Future<void> openCardSettings(WidgetTester tester) async {
          await openSources(tester);
          await tester.tap(find.text('Ada Kart'));
          await tester.pumpAndSettle();
        }

        testWidgets('card settings, reminder off, $lang', (tester) async {
          await openCardSettings(tester);
          await shoot(tester, '61-card-settings-reminder-off-$lang-$theme');
        });

        testWidgets('card settings, reminder on, $lang', (tester) async {
          await openCardSettings(tester);
          await tester.tap(find.byKey(const ValueKey('statement-reminder')));
          await tester.pumpAndSettle();
          await scrollTo(
            tester,
            find.byKey(const ValueKey('statement-reminder-days')),
          );
          await shoot(tester, '62-card-settings-reminder-on-$lang-$theme');
        });
      }

      // Keep in account (18): a card with another plan taken from it, an
      // empty bank account, the salary account opened with its next
      // period, and automatic payments without a source.
      for (final (lang, locale, plans, sources) in [
        ('tr', const Locale('tr', 'TR'), 'Planlar', 'Kaynaklar ve kartlar'),
        ('en', const Locale('en', 'US'), 'Plans', 'Sources and cards'),
      ]) {
        late ChargeSeed ids;
        Future<void> openCharges(WidgetTester tester) async {
          await start(
            tester,
            locale: locale,
            seed: (db) async => ids = await seedCharges(db),
            today: chargeToday,
          );
          await openTab(tester, plans);
          await tester.tap(find.byTooltip(sources));
          await tester.pumpAndSettle();
        }

        testWidgets('charges, $lang', (tester) async {
          await openCharges(tester);
          await shoot(tester, '63-charges-$lang-$theme');
        });

        testWidgets('charges opened, $lang', (tester) async {
          await openCharges(tester);
          for (final key in [
            'charge-details-${ids.maas}',
            'charge-next-period-${ids.maas}',
          ]) {
            final f = find.byKey(ValueKey(key));
            await tester.ensureVisible(f);
            await tester.pumpAndSettle();
            await tester.tap(f);
            await tester.pumpAndSettle();
          }
          await tester.ensureVisible(
            find.byKey(ValueKey('charge-section-${ids.maas}')),
          );
          await tester.pumpAndSettle();
          await shoot(tester, '64-charges-opened-$lang-$theme');
        });

        testWidgets('charges without a source, $lang', (tester) async {
          await openCharges(tester);
          await scrollTo(
            tester,
            find.byKey(const ValueKey('charge-unassigned')),
          );
          await shoot(tester, '65-charges-unassigned-$lang-$theme');
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
        await tester.pumpAndSettle();
        // The payment sheet (20): the edit is its second option.
        await tester.tap(find.byKey(const ValueKey('payment-edit')));
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

      // Return or cancellation (19): Mont (Afterpay, 4 x 450 from 30 Oct)
      // with its first two payments paid.
      for (final (lang, locale, plansTab, finishedTab, adjustLabel) in [
        ('tr', const Locale('tr', 'TR'), 'Planlar', 'Biten', 'Tutarı düzelt'),
        ('en', const Locale('en', 'US'), 'Plans', 'Finished', 'Adjust amount'),
      ]) {
        Future<int> withMont(AppDatabase db) async {
          await seedRich(db, incomeMinor: 4500000);
          final mont = await (db.select(
            db.plans,
          )..where((p) => p.title.equals('Mont'))).getSingle();
          final rows = await (db.select(
            db.payments,
          )..where((p) => p.planId.equals(mont.id))).get();
          final repo = PlanRepository(db);
          for (final r in rows.take(2)) {
            await repo.setPaid(r.id, paid: true, now: DateTime(2026, 11, 1));
          }
          return mont.id;
        }

        Future<void> heldMont(AppDatabase db) async {
          final id = await withMont(db);
          await PlanRepository(db).hold(id, today: LocalDate(2026, 11, 18));
        }

        Future<void> openMont(WidgetTester tester) async {
          await openTab(tester, plansTab);
          await tester.tap(find.text('Mont'));
          await tester.pumpAndSettle();
        }

        testWidgets('refund sheet, $lang', (tester) async {
          await start(tester, locale: locale, seed: withMont);
          await openMont(tester);
          await tester.tap(find.byKey(const ValueKey('refund-action')));
          await tester.pumpAndSettle();
          await shoot(tester, '66-refund-sheet-$lang-$theme');
        });

        testWidgets('plan on hold, $lang', (tester) async {
          await start(tester, locale: locale, seed: heldMont);
          await openMont(tester);
          await shoot(tester, '67-plan-on-hold-$lang-$theme');
        });

        testWidgets('plan on hold for 30 days, $lang', (tester) async {
          await start(
            tester,
            locale: locale,
            seed: (db) async {
              final id = await withMont(db);
              await PlanRepository(db).hold(id, today: LocalDate(2026, 10, 22));
            },
          );
          await openMont(tester);
          await shoot(tester, '68-plan-hold-check-$lang-$theme');
        });

        testWidgets('plans list with a plan on hold, $lang', (tester) async {
          await start(tester, locale: locale, seed: heldMont);
          await openTab(tester, plansTab);
          await shoot(tester, '69-plans-on-hold-$lang-$theme');
        });

        testWidgets('adjust amount, $lang', (tester) async {
          await start(tester, locale: locale, seed: withMont);
          await openMont(tester);
          await tester.tap(find.byKey(const ValueKey('refund-action')));
          await tester.pumpAndSettle();
          await tester.tap(find.text(adjustLabel));
          await tester.pumpAndSettle();
          await tester.enterText(
            find.byKey(const ValueKey('adjust-total')),
            '1500',
          );
          FocusManager.instance.primaryFocus?.unfocus();
          await shoot(tester, '70-adjust-amount-$lang-$theme');
        });

        testWidgets('close dialog, $lang', (tester) async {
          await start(tester, locale: locale, seed: heldMont);
          await openMont(tester);
          await tester.tap(find.byKey(const ValueKey('refund-action')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('refund-close')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('close-reason-refund')));
          await shoot(tester, '71-close-dialog-$lang-$theme');
        });

        testWidgets('archive with a closed plan, $lang', (tester) async {
          await start(
            tester,
            locale: locale,
            seed: (db) async {
              final id = await withMont(db);
              await PlanRepository(db).close(
                id,
                reason: CloseReason.refund,
                today: LocalDate(2026, 11, 19),
              );
            },
          );
          await openTab(tester, plansTab);
          await tester.tap(find.text(finishedTab));
          await shoot(tester, '72-archive-closed-$lang-$theme');
        });
      }

      // Change date (20): Tom's 240 $ in 4 × 60 $ (20 Nov, 4 Dec, 18 Dec,
      // 1 Jan), USD, payday 25, today 15 Nov.
      final moveToday = LocalDate(2026, 11, 15);
      for (final (lang, locale, plansTab, okLabel, first, second) in [
        (
          'tr',
          const Locale('tr', 'TR'),
          'Planlar',
          'Tamam',
          '20 Kas 2026',
          '4 Ara 2026',
        ),
        (
          'en',
          const Locale('en', 'US'),
          'Plans',
          'OK',
          'Nov 20, 2026',
          'Dec 4, 2026',
        ),
      ]) {
        Future<int> seedTom(AppDatabase db, {int? income = 250000}) async {
          await seedSettings(
            db,
            currency: 'USD',
            payDay: 25,
            incomeMinor: income,
          );
          return seedPayIn4(
            db,
            first: LocalDate(2026, 11, 20),
            totalMinor: 24000,
            source: 'Afterpay',
            title: 'Tom',
          );
        }

        Future<void> openTom(WidgetTester tester) async {
          await openTab(tester, plansTab);
          await tester.tap(find.text('Tom'));
          await tester.pumpAndSettle();
        }

        Future<void> changeTo(WidgetTester tester, String row, int day) async {
          await openTom(tester);
          await tester.tap(find.text(row));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('payment-changeDate')));
          await tester.pumpAndSettle();
          await tester.tap(find.text('$day'));
          await tester.tap(find.text(okLabel));
          await tester.pumpAndSettle();
        }

        testWidgets('payment sheet, $lang', (tester) async {
          await start(tester, locale: locale, today: moveToday, seed: seedTom);
          await openTom(tester);
          await tester.tap(find.text(first));
          await shoot(tester, '73-payment-sheet-$lang-$theme');
        });

        testWidgets('change date, example 1, $lang', (tester) async {
          await start(tester, locale: locale, today: moveToday, seed: seedTom);
          await changeTo(tester, first, 27);
          await shoot(tester, '74-change-date-later-$lang-$theme');
        });

        testWidgets('change date, example 2, $lang', (tester) async {
          await start(tester, locale: locale, today: moveToday, seed: seedTom);
          await changeTo(tester, first, 27);
          await tester.tap(find.byKey(const ValueKey('change-date-shift')));
          await shoot(tester, '75-change-date-shift-$lang-$theme');
        });

        testWidgets('change date, example 3, $lang', (tester) async {
          await start(
            tester,
            locale: locale,
            today: moveToday,
            seed: (db) => seedTom(db, income: null),
          );
          await changeTo(tester, first, 27);
          await shoot(tester, '76-change-date-no-income-$lang-$theme');
        });

        testWidgets('change date, example 4, $lang', (tester) async {
          await start(tester, locale: locale, today: moveToday, seed: seedTom);
          await changeTo(tester, second, 6);
          await shoot(tester, '77-change-date-same-period-$lang-$theme');
        });

        testWidgets('plan detail, moved payments, $lang', (tester) async {
          await start(
            tester,
            locale: locale,
            today: moveToday,
            seed: (db) async {
              final id = await seedTom(db);
              final repo = PlanRepository(db);
              // Example 1, then example 5: 4 Dec past 18 Dec.
              for (final (seq, date) in [
                (1, LocalDate(2026, 11, 27)),
                (2, LocalDate(2026, 12, 20)),
              ]) {
                await repo.movePayment(
                  planId: id,
                  seq: seq,
                  newDate: date,
                  shiftLater: false,
                  today: moveToday,
                );
              }
            },
          );
          await openTom(tester);
          await shoot(tester, '78-plan-detail-moved-$lang-$theme');
        });
      }

      // Extra fee (21): EUR, payday 25, today 15 Nov; Sofia's 4 × 60 €
      // from 10 Nov, the first one past due.
      final feeToday = LocalDate(2026, 11, 15);
      for (final (lang, locale, plansTab, note) in [
        ('tr', const Locale('tr', 'TR'), 'Planlar', 'İkinci ücret'),
        ('en', const Locale('en', 'US'), 'Plans', 'Second fee'),
      ]) {
        Future<void> seedSofia(AppDatabase db, {bool fee = true}) async {
          await seedSettings(
            db,
            currency: 'EUR',
            payDay: 25,
            incomeMinor: 100000,
          );
          final plans = PlanRepository(db);
          await plans.saveDraft(
            PlanCalculator.monthly(
              firstDate: LocalDate(2026, 11, 10),
              totalMinor: 24000,
              count: 4,
            ),
            sourceId: await SourceRepository(
              db,
              plans,
            ).findOrCreateProvider('Klarna'),
            origin: PlanOrigin.template,
            title: 'Sofia',
          );
          if (!fee) return;
          final first = await (db.select(
            db.payments,
          )..where((p) => p.seq.equals(1))).getSingle();
          await plans.setExtraFee(first.id, amountMinor: 1200, note: note);
        }

        Future<void> openFeeSheet(WidgetTester tester) async {
          final action = find.byWidgetPredicate(
            (w) =>
                w.key is ValueKey<String> &&
                (w.key! as ValueKey<String>).value.startsWith(
                  'past-due-fee-action-',
                ),
          );
          await tester.ensureVisible(action);
          await tester.pumpAndSettle();
          await tester.tap(action);
          await tester.pumpAndSettle();
        }

        testWidgets('home, past due with an extra fee, $lang', (tester) async {
          await start(tester, locale: locale, today: feeToday, seed: seedSofia);
          await shoot(tester, '80-home-extra-fee-$lang-$theme');
        });

        testWidgets('extra fee sheet, empty, $lang', (tester) async {
          await start(
            tester,
            locale: locale,
            today: feeToday,
            seed: (db) => seedSofia(db, fee: false),
          );
          await openFeeSheet(tester);
          await shoot(tester, '81-extra-fee-sheet-empty-$lang-$theme');
        });

        testWidgets('extra fee sheet, filled, $lang', (tester) async {
          await start(tester, locale: locale, today: feeToday, seed: seedSofia);
          await openFeeSheet(tester);
          FocusManager.instance.primaryFocus?.unfocus();
          await shoot(tester, '82-extra-fee-sheet-filled-$lang-$theme');
        });

        testWidgets('plan detail with an extra fee, $lang', (tester) async {
          await start(tester, locale: locale, today: feeToday, seed: seedSofia);
          await openTab(tester, plansTab);
          await tester.tap(find.text('Sofia'));
          await shoot(tester, '83-plan-detail-extra-fee-$lang-$theme');
        });
      }

      // Fee per payment (22): Kenji, JPY 10.000 in 4 monthly from 10 Nov,
      // 390 ¥ on every payment (example 1); Sofia's EUR 120,00 in 3 with
      // 2,50 € on the first only (example 2); today 15 Nov.
      for (final (lang, locale, addPlan, monthly, plansTab) in [
        (
          'tr',
          const Locale('tr', 'TR'),
          'Plan ekle',
          'Aylık taksit',
          'Planlar',
        ),
        (
          'en',
          const Locale('en', 'US'),
          'Add plan',
          'Monthly installments',
          'Plans',
        ),
      ]) {
        Future<void> fillAdd(
          WidgetTester tester, {
          required String total,
          required String count,
          required String fee,
          bool firstOnly = false,
        }) async {
          await tester.tap(find.text(addPlan));
          await tester.pumpAndSettle();
          await tester.tap(find.widgetWithText(ChoiceChip, monthly));
          await tester.pumpAndSettle();
          await tester.enterText(find.byKey(const ValueKey('source')), 'Paidy');
          await tester.enterText(find.byKey(const ValueKey('total')), total);
          await tester.enterText(find.byKey(const ValueKey('count')), count);
          final details = find.byKey(const ValueKey('more-details'));
          await scrollTo(tester, details);
          await tester.tap(details);
          await tester.pumpAndSettle();
          final feeField = find.byKey(const ValueKey('installment-fee'));
          await scrollTo(tester, feeField);
          await tester.enterText(feeField, fee);
          await tester.pumpAndSettle();
          if (firstOnly) {
            final choice = find.descendant(
              of: find.byKey(const ValueKey('installment-fee-scope')),
              matching: find.byType(ChoiceChip),
            );
            await tester.tap(choice.last);
            await tester.pumpAndSettle();
          }
          FocusManager.instance.primaryFocus?.unfocus();
          await tester.pumpAndSettle();
        }

        Future<int> seedKenji(
          AppDatabase db, {
          InstallmentFeeScope scope = InstallmentFeeScope.everyPayment,
        }) async {
          await seedSettings(db, currency: 'JPY', payDay: 25);
          final plans = PlanRepository(db);
          final id = await plans.saveDraft(
            PlanCalculator.monthly(
              firstDate: LocalDate(2026, 11, 10),
              totalMinor: 10000,
              count: 4,
            ),
            sourceId: await SourceRepository(
              db,
              plans,
            ).findOrCreateProvider('Paidy'),
            origin: PlanOrigin.template,
            title: 'Kenji',
          );
          final first = await (db.select(
            db.payments,
          )..where((p) => p.seq.equals(1))).getSingle();
          await plans.setPaid(first.id, paid: true);
          await plans.editPlan(
            id,
            count: 4,
            paidBefore: 0,
            installmentFee: (feeMinor: 390, scope: scope),
          );
          return id;
        }

        testWidgets('add plan, fee open, $lang', (tester) async {
          await start(
            tester,
            locale: locale,
            today: feeToday,
            seed: (db) => seedSettings(db, currency: 'JPY', payDay: 25),
          );
          await fillAdd(tester, total: '10000', count: '4', fee: '390');
          await shoot(tester, '84-add-plan-fee-open-$lang-$theme');
        });

        testWidgets('add plan, fee preview, example 1, $lang', (tester) async {
          await start(
            tester,
            locale: locale,
            today: feeToday,
            seed: (db) => seedSettings(db, currency: 'JPY', payDay: 25),
          );
          await fillAdd(tester, total: '10000', count: '4', fee: '390');
          await scrollTo(
            tester,
            find.byKey(const ValueKey('preview-fee-summary')),
          );
          await shoot(tester, '85-add-plan-fee-preview-$lang-$theme');
        });

        testWidgets('add plan, first only, example 2, $lang', (tester) async {
          await start(
            tester,
            locale: locale,
            today: feeToday,
            seed: (db) => seedSettings(db, currency: 'EUR', payDay: 25),
          );
          await fillAdd(
            tester,
            total: lang == 'tr' ? '120,00' : '120.00',
            count: '3',
            fee: lang == 'tr' ? '2,50' : '2.50',
            firstOnly: true,
          );
          await scrollTo(
            tester,
            find.byKey(const ValueKey('preview-fee-summary')),
          );
          await shoot(tester, '86-add-plan-fee-first-$lang-$theme');
        });

        testWidgets('plan detail with fees, example 3, $lang', (tester) async {
          await start(tester, locale: locale, today: feeToday, seed: seedKenji);
          await openTab(tester, plansTab);
          await tester.tap(find.text('Kenji'));
          await shoot(tester, '87-plan-detail-fee-$lang-$theme');
        });

        testWidgets('plan edit, first paid, example 4, $lang', (tester) async {
          await start(
            tester,
            locale: locale,
            today: feeToday,
            seed: (db) =>
                seedKenji(db, scope: InstallmentFeeScope.firstPaymentOnly),
          );
          await openTab(tester, plansTab);
          await tester.tap(find.text('Kenji'));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('plan-edit')));
          await tester.pumpAndSettle();
          await scrollTo(
            tester,
            find.byKey(const ValueKey('installment-fee-first-paid')),
          );
          await shoot(tester, '88-plan-edit-fee-first-paid-$lang-$theme');
        });
      }

      // Product price (23): Putri's phone, IDR 12 × 580.000 from 10 Dec
      // with a Rp6.000.000 price, entered as "Installment" (example 1);
      // TRY 6 × 1.100,00 with a 10,00 fee per payment and a 6.000,00
      // price (example 2, monthly: card installments take no fee, 22).
      for (final (lang, locale, addPlan, monthly, installment, plansTab) in [
        (
          'tr',
          const Locale('tr', 'TR'),
          'Plan ekle',
          'Aylık taksit',
          'Taksit',
          'Planlar',
        ),
        (
          'en',
          const Locale('en', 'US'),
          'Add plan',
          'Monthly installments',
          'Installment',
          'Plans',
        ),
      ]) {
        Future<void> seedPriced(
          AppDatabase db, {
          required String currency,
          required int installment,
          required int count,
          required int price,
          int? fee,
        }) async {
          await seedSettings(db, currency: currency, payDay: 25);
          final plans = PlanRepository(db);
          await plans.saveDraft(
            PlanCalculator.monthly(
                  firstDate: LocalDate(2026, 12, 10),
                  totalMinor: installment * count,
                  count: count,
                )
                .withInstallmentFee(fee, InstallmentFeeScope.everyPayment)
                .withProductPrice(price),
            sourceId: await SourceRepository(
              db,
              plans,
            ).findOrCreateProvider('Kredivo'),
            origin: PlanOrigin.template,
            title: 'Telefon',
          );
        }

        testWidgets('add plan, product price, example 1, $lang', (
          tester,
        ) async {
          await start(
            tester,
            locale: locale,
            today: feeToday,
            seed: (db) => seedSettings(db, currency: 'IDR', payDay: 25),
          );
          await tester.tap(find.text(addPlan));
          await tester.pumpAndSettle();
          await tester.tap(find.widgetWithText(ChoiceChip, monthly));
          await tester.pumpAndSettle();
          await tester.enterText(
            find.byKey(const ValueKey('source')),
            'Kredivo',
          );
          final segment = find.descendant(
            of: find.byKey(const ValueKey('amount-entry')),
            matching: find.text(installment),
          );
          await tester.ensureVisible(segment);
          await tester.pumpAndSettle();
          await tester.tap(segment);
          await tester.pumpAndSettle();
          await tester.enterText(
            find.byKey(const ValueKey('installment')),
            '580000',
          );
          await tester.enterText(find.byKey(const ValueKey('count')), '12');
          final details = find.byKey(const ValueKey('more-details'));
          await scrollTo(tester, details);
          await tester.tap(details);
          await tester.pumpAndSettle();
          final price = find.byKey(const ValueKey('product-price'));
          await scrollTo(tester, price);
          await tester.enterText(price, '6000000');
          await tester.pumpAndSettle();
          FocusManager.instance.primaryFocus?.unfocus();
          await tester.pumpAndSettle();
          await shoot(tester, '89-add-plan-price-$lang-$theme');
          await scrollTo(
            tester,
            find.byKey(const ValueKey('preview-fee-summary')),
          );
          await shoot(tester, '90-add-plan-price-preview-$lang-$theme');
        });

        testWidgets('plan detail, product price, example 1, $lang', (
          tester,
        ) async {
          await start(
            tester,
            locale: locale,
            today: feeToday,
            seed: (db) => seedPriced(
              db,
              currency: 'IDR',
              installment: 580000,
              count: 12,
              price: 6000000,
            ),
          );
          await openTab(tester, plansTab);
          await tester.tap(find.text('Telefon'));
          await shoot(tester, '91-plan-detail-price-$lang-$theme');
        });

        testWidgets('plan detail, price and fee, example 2, $lang', (
          tester,
        ) async {
          await start(
            tester,
            locale: locale,
            today: feeToday,
            seed: (db) => seedPriced(
              db,
              currency: 'TRY',
              installment: 110000,
              count: 6,
              price: 600000,
              fee: 1000,
            ),
          );
          await openTab(tester, plansTab);
          await tester.tap(find.text('Telefon'));
          await shoot(tester, '92-plan-detail-price-fee-$lang-$theme');
        });
      }

      // Provider templates (25): region Italy, the shipped file.
      for (final (lang, locale, addPlan) in [
        ('tr', const Locale('tr', 'IT'), 'Plan ekle'),
        ('en', const Locale('en', 'IT'), 'Add plan'),
      ]) {
        Future<void> openTemplates(WidgetTester tester) async {
          await start(
            tester,
            locale: locale,
            templates: true,
            seed: (db) =>
                seedSettings(db, currency: 'EUR', incomeMinor: 180000),
          );
          await tester.tap(find.text(addPlan));
          await tester.pumpAndSettle();
        }

        testWidgets('add plan, start from a provider, $lang', (tester) async {
          await openTemplates(tester);
          await shoot(tester, '95-add-plan-provider-start-$lang-$theme');
        });

        testWidgets('template variant sheet, $lang', (tester) async {
          await openTemplates(tester);
          await tester.tap(find.byKey(const ValueKey('provider-scalapay')));
          await tester.pumpAndSettle();
          await shoot(tester, '96-template-variant-sheet-$lang-$theme');
        });

        testWidgets('add plan filled from a template, $lang', (tester) async {
          await openTemplates(tester);
          await tester.tap(find.byKey(const ValueKey('provider-scalapay')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('template-variant-0')));
          await tester.pumpAndSettle();
          await scrollTo(tester, find.byKey(const ValueKey('total')));
          await tester.enterText(find.byKey(const ValueKey('total')), '300');
          await tester.pumpAndSettle();
          FocusManager.instance.primaryFocus?.unfocus();
          await scrollTo(tester, find.byKey(const ValueKey('template-note')));
          await shoot(tester, '97-add-plan-template-filled-$lang-$theme');
        });
      }

      testWidgets('ios, change date', variant: ios, (tester) async {
        await start(
          tester,
          today: moveToday,
          seed: (db) async {
            await seedSettings(
              db,
              currency: 'USD',
              payDay: 25,
              incomeMinor: 250000,
            );
            await seedPayIn4(
              db,
              first: LocalDate(2026, 11, 20),
              totalMinor: 24000,
              source: 'Afterpay',
              title: 'Tom',
            );
          },
        );
        await openTab(tester, 'Planlar');
        await tester.tap(find.text('Tom'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('20 Kas 2026'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('payment-changeDate')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('27'));
        await tester.tap(find.text('Tamam'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('change-date-shift')));
        await shoot(tester, '79-ios-change-date-$theme');
      });
    });
  }
}
