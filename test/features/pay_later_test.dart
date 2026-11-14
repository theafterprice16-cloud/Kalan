import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/design/form_fields.dart';
import 'package:kalan/core/engine/engine.dart';
import 'package:kalan/core/reminders/reminder_models.dart';
import 'package:kalan/data/db/app_database.dart';
import 'package:kalan/data/models.dart';
import 'package:kalan/data/repositories/plan_repository.dart';
import 'package:kalan/data/repositories/settings_repository.dart';
import 'package:kalan/features/reminders/reminder_actions.dart';
import 'package:kalan/features/reminders/reminder_providers.dart';
import 'package:kalan/features/reminders/reminder_scheduler.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../helpers/app_harness.dart';
import '../helpers/fake_notifications.dart';

LocalDate d(int m, int day, [int y = 2026]) => LocalDate(y, m, day);

/// Lena's day: 14 November 2026.
final lenaDay = d(11, 14);

/// A saved "Pay later" plan; returns its id.
Future<int> seedPayLater(
  AppDatabase db, {
  LocalDate? purchase,
  PayLaterRule rule = const PayLaterRule.days(30),
  int amountMinor = 7900,
  String? title,
}) => PlanRepository(db).saveDraft(
  PlanCalculator.payLater(
    purchaseDate: purchase ?? lenaDay,
    rule: rule,
    totalMinor: amountMinor,
  ),
  sourceId: null,
  origin: PlanOrigin.template,
  title: title,
);

Future<void> openAddPayLater(WidgetTester tester) async {
  await tester.tap(find.text('Plan ekle'));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(ChoiceChip, 'Sonra öde'));
  await tester.pumpAndSettle();
}

Future<void> save(WidgetTester tester) async {
  final button = find.byKey(const ValueKey('save-plan'));
  await scrollTo(tester, button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Future<PlanWithPayments> onlyPlan(AppDatabase db) async =>
    (await PlanRepository(db).all()).single;

void main() {
  setUpAll(() {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  group('adding', () {
    testWidgets('Lena: type, 79, save: due 14 December 2026', (tester) async {
      final db = await pumpApp(
        tester,
        today: lenaDay,
        seed: (db) => seedSettings(db, currency: 'EUR'),
      );
      await openAddPayLater(tester);
      expect(find.text('Tek ödeme, belli bir günde'), findsOneWidget);
      // One payment: no "already underway" here.
      expect(find.byKey(const ValueKey('underway')), findsNothing);
      // Nothing to save before an amount.
      final button = find.byKey(const ValueKey('save-plan'));
      await scrollTo(tester, button);
      expect(tester.widget<FilledButton>(button).onPressed, isNull);

      await tester.enterText(find.byKey(const ValueKey('total')), '79');
      await tester.pumpAndSettle();
      expect(find.text('Son ödeme günü: 14 Ara 2026'), findsOneWidget);
      expect(find.text('30 gün sonra'), findsOneWidget);
      // The purchase date reads "Today".
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('purchase-date')),
          matching: find.text('Bugün'),
        ),
        findsOneWidget,
      );
      await save(tester);

      final plan = await tester.runAsync(() => onlyPlan(db));
      expect(plan!.plan.kind, PlanKind.payLater);
      expect(plan.plan.title, isNull);
      expect(plan.plan.sourceId, isNull);
      expect(plan.purchaseDate, lenaDay);
      expect(plan.payLaterRule, const PayLaterRule.days(30));
      expect(plan.payments.single.date, d(12, 14));
      expect(plan.payments.single.amountMinor, 7900);
      final settings = await tester.runAsync(
        () => SettingsRepository(db).get(),
      );
      expect(lastPayLaterRuleOf(settings), const PayLaterRule.days(30));

      // In the list: the automatic name, the due date, days left, no 0/1.
      await openTab(tester, 'Planlar');
      expect(find.text('Sonra öde · 14 Ara'), findsOneWidget);
      expect(find.text('Son ödeme günü: 14 Aralık'), findsOneWidget);
      expect(find.text('30 gün sonra'), findsOneWidget);
      expect(find.byKey(const ValueKey('plan-progress')), findsNothing);
    });

    testWidgets('chips: next month, number of days, pick a date', (
      tester,
    ) async {
      await pumpApp(tester, today: lenaDay, seed: seedSettings);
      await openAddPayLater(tester);
      await tester.enterText(find.byKey(const ValueKey('total')), '79');
      await tester.tap(find.widgetWithText(ChoiceChip, 'Gelecek ayın …'));
      await tester.pumpAndSettle();
      final number = find.byKey(const ValueKey('pay-later-number'));
      expect(number, findsOneWidget);
      expect(
        tester
            .widget<TextField>(
              find.descendant(of: number, matching: find.byType(TextField)),
            )
            .keyboardType,
        TextInputType.number,
      );
      await tester.enterText(number, '27');
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(ChoiceChip, 'Gelecek ayın 27. günü'),
        findsOneWidget,
      );
      expect(find.text('Son ödeme günü: 27 Ara 2026'), findsOneWidget);

      await tester.enterText(number, '32');
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('pay-later-due')), findsNothing);
      await save(tester);
      expect(find.text('Gün 1 ile 31 arasında olmalı.'), findsOneWidget);

      await scrollTo(tester, find.widgetWithText(ChoiceChip, 'Gün sayısı'));
      await tester.tap(find.widgetWithText(ChoiceChip, 'Gün sayısı'));
      await tester.pumpAndSettle();
      await tester.enterText(number, '45');
      await tester.pumpAndSettle();
      expect(find.text('Son ödeme günü: 29 Ara 2026'), findsOneWidget);
      expect(find.text('45 gün sonra'), findsOneWidget);
      await tester.enterText(number, '181');
      await save(tester);
      expect(
        find.text('Gün sayısı 1 ile 180 arasında olmalı.'),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(ChoiceChip, 'Tarih seç'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('pay-later-number')), findsNothing);
      expect(find.byKey(const ValueKey('pay-later-due-date')), findsOneWidget);
      expect(find.byType(DateField), findsNWidgets(2));
    });

    testWidgets('store name and source are optional; a name shows', (
      tester,
    ) async {
      final db = await pumpApp(tester, today: lenaDay, seed: seedSettings);
      await openAddPayLater(tester);
      await tester.enterText(find.byKey(const ValueKey('total')), '79');
      await tester.enterText(find.byKey(const ValueKey('store')), 'Zalando');
      await tester.pumpAndSettle();
      await save(tester);
      final plan = await tester.runAsync(() => onlyPlan(db));
      expect(plan!.plan.title, 'Zalando');
      expect(plan.source, isNull);
      await openTab(tester, 'Planlar');
      expect(find.text('Zalando'), findsOneWidget);
    });

    testWidgets('English: the automatic name follows the language', (
      tester,
    ) async {
      await pumpApp(
        tester,
        locale: const Locale('en', 'US'),
        today: lenaDay,
        seed: (db) async {
          await seedSettings(db);
          await seedPayLater(db);
        },
      );
      await openTab(tester, 'Plans');
      expect(find.text('Pay later · Dec 14'), findsOneWidget);
      expect(find.text('Due on December 14'), findsOneWidget);
      expect(find.text('In 30 days'), findsOneWidget);
    });

    testWidgets('the rule used last comes back; a picked date does not', (
      tester,
    ) async {
      final db = await pumpApp(tester, today: lenaDay, seed: seedSettings);
      // First time: 30 days.
      await openAddPayLater(tester);
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '30 gün'))
            .selected,
        isTrue,
      );
      await tester.enterText(find.byKey(const ValueKey('total')), '10');
      await tester.tap(find.widgetWithText(ChoiceChip, 'Gelecek ayın …'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('pay-later-number')),
        '27',
      );
      await tester.pumpAndSettle();
      await save(tester);

      await openAddPayLater(tester);
      expect(
        tester
            .widget<ChoiceChip>(
              find.widgetWithText(ChoiceChip, 'Gelecek ayın 27. günü'),
            )
            .selected,
        isTrue,
      );
      await tester.tap(find.widgetWithText(ChoiceChip, 'Tarih seç'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('total')), '20');
      await tester.pumpAndSettle();
      await save(tester);

      final settings = await tester.runAsync(
        () => SettingsRepository(db).get(),
      );
      expect(lastPayLaterRuleOf(settings), const PayLaterRule.nextMonthDay(27));
      await openAddPayLater(tester);
      expect(
        tester
            .widget<ChoiceChip>(
              find.widgetWithText(ChoiceChip, 'Gelecek ayın 27. günü'),
            )
            .selected,
        isTrue,
      );
    });
  });

  group('limit, archive, edit', () {
    testWidgets('an open "Pay later" counts towards the 4 plans', (
      tester,
    ) async {
      late int payLater;
      await pumpApp(
        tester,
        today: lenaDay,
        seed: (db) async {
          await seedSettings(db);
          for (var i = 0; i < 3; i++) {
            await seedPayIn4(db, source: 'P$i');
          }
          payLater = await seedPayLater(db, title: 'Zalando');
        },
      );
      await tester.tap(find.text('Plan ekle'));
      await tester.pumpAndSettle();
      expect(find.textContaining('en çok 4 açık plan olur'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      // Paid: off the limit, in the archive.
      await openTab(tester, 'Planlar');
      await tester.tap(find.text('Zalando'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Ödendi olarak işaretle'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Zalando'), findsNothing);
      await tester.tap(find.text('Biten'));
      await tester.pumpAndSettle();
      expect(find.text('Zalando'), findsOneWidget);
      expect(payLater, isPositive);
      await openTab(tester, 'Bu dönem');
      await tester.tap(find.text('Plan ekle'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ChoiceChip, 'Sonra öde'), findsOneWidget);
    });

    testWidgets('plan detail: purchase date, due date, rule, no 0/1', (
      tester,
    ) async {
      await pumpApp(
        tester,
        today: lenaDay,
        seed: (db) async {
          await seedSettings(db);
          await seedPayLater(db, rule: const PayLaterRule.nextMonthDay(27));
        },
      );
      await openTab(tester, 'Planlar');
      await tester.tap(find.text('Sonra öde · 27 Ara'));
      await tester.pumpAndSettle();
      expect(find.text('Alışveriş 14 Kas 2026'), findsOneWidget);
      expect(find.text('Son ödeme günü: 27 Ara 2026'), findsOneWidget);
      expect(find.text('43 gün sonra'), findsOneWidget);
      expect(find.text('Ne zaman: Gelecek ayın 27. günü'), findsOneWidget);
      expect(find.byKey(const ValueKey('plan-progress')), findsNothing);
      expect(find.text('1/1'), findsNothing);
    });

    testWidgets('edit: a new purchase date moves the due date', (tester) async {
      final db = await pumpApp(
        tester,
        today: lenaDay,
        seed: (db) async {
          await seedSettings(db);
          await seedPayLater(db, title: 'Zalando');
        },
      );
      await openTab(tester, 'Planlar');
      await tester.tap(find.text('Zalando'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('plan-edit')));
      await tester.pumpAndSettle();
      expect(find.text('Son ödeme günü: 14 Ara 2026'), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('total')), '85');
      await tester.tap(find.widgetWithText(ChoiceChip, '14 gün'));
      await tester.pumpAndSettle();
      expect(find.text('Son ödeme günü: 28 Kas 2026'), findsOneWidget);
      await scrollTo(tester, find.byKey(const ValueKey('save-plan-edit')));
      await tester.tap(find.byKey(const ValueKey('save-plan-edit')));
      await tester.pumpAndSettle();
      final plan = await tester.runAsync(() => onlyPlan(db));
      expect(plan!.payments.single.date, d(11, 28));
      expect(plan.payments.single.amountMinor, 8500);
      expect(plan.payLaterRule, const PayLaterRule.days(14));
    });
  });

  group('repository', () {
    late AppDatabase db;
    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      await seedSettings(db);
    });
    tearDown(() => db.close());

    test('a rule follows a new purchase date; a picked date stays', () async {
      final ruled = await seedPayLater(db);
      final picked = await PlanRepository(db).saveDraft(
        PlanCalculator.payLater(
          purchaseDate: lenaDay,
          rule: const PayLaterRule.chosenDate(),
          chosenDate: d(3, 3, 2027),
          totalMinor: 5000,
        ),
        sourceId: null,
        origin: PlanOrigin.template,
      );
      for (final id in [ruled, picked]) {
        final plan = (await PlanRepository(
          db,
        ).all()).firstWhere((p) => p.plan.id == id);
        await PlanRepository(db).editPayLater(
          id,
          title: null,
          sourceId: null,
          amountMinor: plan.payments.single.amountMinor,
          purchaseDate: d(12, 1),
          rule: plan.payLaterRule!,
        );
      }
      final all = await PlanRepository(db).all();
      final ruledPlan = all.firstWhere((p) => p.plan.id == ruled);
      final pickedPlan = all.firstWhere((p) => p.plan.id == picked);
      expect(ruledPlan.payments.single.date, d(12, 31));
      expect(ruledPlan.purchaseDate, d(12, 1));
      expect(pickedPlan.payments.single.date, d(3, 3, 2027));
    });

    test('a paid one keeps amount and date; name and source change', () async {
      final id = await seedPayLater(db);
      final payment = (await PlanRepository(db).all()).single.payments.single;
      await PlanRepository(db).setPaid(payment.id, paid: true);
      await PlanRepository(db).editPayLater(
        id,
        title: 'Zalando',
        sourceId: null,
        amountMinor: 1,
        purchaseDate: d(1, 1, 2027),
        rule: const PayLaterRule.days(14),
      );
      final plan = (await PlanRepository(db).all()).single;
      expect(plan.plan.title, 'Zalando');
      expect(plan.payments.single.amountMinor, 7900);
      expect(plan.payments.single.date, d(12, 14));
      expect(plan.payLaterRule, const PayLaterRule.days(30));
    });

    test('"paid", then "not paid": the plan opens again', () async {
      await seedPayLater(db);
      final payment = (await PlanRepository(db).all()).single.payments.single;
      await PlanRepository(db).setPaid(payment.id, paid: true);
      expect((await PlanRepository(db).all()).single.isOpen, isFalse);
      await PlanRepository(db).setPaid(payment.id, paid: false);
      expect((await PlanRepository(db).all()).single.isOpen, isTrue);
    });

    test('the last rule: 30 days at first, then the one used', () async {
      final settings = SettingsRepository(db);
      expect(lastPayLaterRuleOf(await settings.get()), defaultPayLaterRule);
      await settings.rememberPayLaterRule(const PayLaterRule.nextMonthDay(27));
      await settings.rememberPayLaterRule(const PayLaterRule.chosenDate());
      expect(
        lastPayLaterRuleOf(await settings.get()),
        const PayLaterRule.nextMonthDay(27),
      );
      await settings.rememberPayLaterRule(const PayLaterRule.days(45));
      expect(
        lastPayLaterRuleOf(await settings.get()),
        const PayLaterRule.days(45),
      );
    });
  });

  group('with the other items', () {
    late AppDatabase db;
    late FakeNotificationGateway gateway;
    late DateTime clock;
    late ReminderScheduler scheduler;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      gateway = FakeNotificationGateway();
      clock = DateTime.utc(2026, 11, 14, 12);
      scheduler = ReminderScheduler(
        db: db,
        gateway: gateway,
        location: () => tz.getLocation('Europe/Istanbul'),
        now: () => clock,
        localeFor: (s) => Locale(s.localeCode ?? 'tr'),
      );
      await seedSettings(db);
    });
    tearDown(() => db.close());

    test('reminders: ahead and on the day, merged with others', () async {
      await seedPayLater(db);
      await seedPayIn4(db, first: d(12, 14));
      await scheduler.rescheduleAll();
      final onDay = gateway.pending.firstWhere(
        (r) => r.kind == ReminderKind.onDay && r.fireDate == d(12, 14),
      );
      expect(onDay.payments.map((p) => p.name), [
        'Klarna',
        'Sonra öde · 14 Ara',
      ]);
      expect(
        gateway.pending.any(
          (r) => r.kind == ReminderKind.ahead && r.fireDate == d(12, 12),
        ),
        isTrue,
      );
    });

    test('"Paid" from a notification closes it', () async {
      await seedPayLater(db);
      await scheduler.rescheduleAll();
      final onDay = gateway.pending.firstWhere(
        (r) => r.kind == ReminderKind.onDay,
      );
      clock = DateTime.utc(2026, 12, 14, 7);
      await ReminderActionHandler(scheduler).handle(
        actionId: ReminderActionIds.of(ReminderAction.paid),
        payload: onDay.data!.encode(),
      );
      expect((await PlanRepository(db).all()).single.isOpen, isFalse);
      expect(gateway.pending, isEmpty);
    });

    test('repeat reminders: every day after the due date too', () async {
      await (db.update(db.appSettings)..where((s) => s.id.equals(1))).write(
        const AppSettingsCompanion(repeatMode: Value(ReminderRepeat.daily)),
      );
      await seedPayLater(db);
      clock = DateTime.utc(2026, 12, 14, 12);
      await scheduler.rescheduleAll();
      final overdue = gateway.pending.where(
        (r) => r.kind == ReminderKind.overdue,
      );
      expect(overdue, isNotEmpty);
      expect(
        overdue.first.body,
        "14 Aralık'taki 1 ödeme henüz işaretlenmedi: Sonra öde · 14 Ara, ₺79",
      );
    });

    testWidgets('home: in December, not in November; past due later', (
      tester,
    ) async {
      await pumpApp(
        tester,
        today: d(11, 20),
        seed: (db) async {
          await seedSettings(db, incomeMinor: 300000, payDay: 1);
          await seedPayLater(db);
        },
      );
      expect(find.text('Sonra öde · 14 Ara'), findsNothing);
      expect(find.text('₺3.000'), findsOneWidget);
    });

    testWidgets('home in December, then past due', (tester) async {
      await pumpApp(
        tester,
        today: d(12, 20),
        seed: (db) async {
          await seedSettings(db, incomeMinor: 300000, payDay: 1);
          await seedPayLater(db);
        },
      );
      expect(find.text('Günü geçen 1 ödeme'), findsOneWidget);
      expect(find.text('Sonra öde · 14 Ara'), findsOneWidget);
      expect(find.text('₺2.921'), findsOneWidget);
    });

    testWidgets('home in December, on the day: in the list', (tester) async {
      await pumpApp(
        tester,
        today: d(12, 1),
        overrides: [
          notificationGatewayProvider.overrideWithValue(
            FakeNotificationGateway(),
          ),
        ],
        seed: (db) async {
          await seedSettings(db, incomeMinor: 300000, payDay: 1);
          await seedPayLater(db);
        },
      );
      expect(find.text('Sonra öde · 14 Ara'), findsOneWidget);
      expect(find.text('₺2.921'), findsOneWidget);
      // One payment: its type, not "1/1".
      expect(find.text('1/1'), findsNothing);
      expect(find.text('Sonra öde'), findsOneWidget);
    });
  });
}
