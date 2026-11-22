import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/engine/engine.dart';
import 'package:kalan/data/db/app_database.dart';
import 'package:kalan/data/repositories/plan_repository.dart';
import 'package:kalan/data/repositories/source_repository.dart';
import 'package:kalan/features/plans/provider_templates_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/app_harness.dart';
import 'add_plan_test.dart' show scrollUpTo, visibleInputCount;

/// The examples of Roadmap 25, independent of the shipped file.
final fixture = jsonEncode({
  'schemaVersion': 1,
  'templates': [
    {
      'country': 'IT',
      'id': 'scalapay',
      'name': 'Scalapay',
      'sources': ['https://www.scalapay.com/it/come-funziona-scalapay'],
      'checked': '2026-11-22',
      'variants': [
        {'kind': 'monthly', 'count': 3, 'interval': 'sameDay'},
      ],
    },
    {
      'country': 'IT',
      'id': 'klarna',
      'name': 'Klarna',
      'sources': ['https://www.klarna.com/it/opzioni-di-pagamento/'],
      'checked': '2026-11-22',
      'variants': [
        {
          'kind': 'monthly',
          'count': 3,
          'interval': 'everyDays',
          'intervalDays': 30,
        },
        {'kind': 'payLater', 'payLater': 'days', 'payLaterValue': 30},
      ],
    },
    {
      'country': 'ID',
      'id': 'kredivo',
      'name': 'Kredivo',
      'sources': ['https://www.kredivo.com/faqs/'],
      'checked': '2026-11-22',
      'variants': [
        for (final n in [3, 6, 12])
          {
            'kind': 'monthly',
            'count': n,
            'interval': 'everyDays',
            'intervalDays': 30,
            'first': 'afterInterval',
          },
      ],
    },
    {
      'country': 'JP',
      'id': 'paidy',
      'name': 'Paidy',
      'sources': ['https://paidy.com/guide/'],
      'checked': '2026-11-22',
      'variants': [
        {'kind': 'payLater', 'payLater': 'nextMonthDay', 'payLaterValue': 27},
        {
          'kind': 'monthly',
          'count': 3,
          'interval': 'sameDay',
          'first': 'nextMonthDay',
          'firstDay': 27,
        },
      ],
    },
  ],
});

Future<AppDatabase> pumpRegion(
  WidgetTester tester,
  Locale locale, {
  Future<void> Function(AppDatabase db)? seed,
  bool shippedFile = false,
}) {
  // A tall phone: the section, the form and its note fit without scrolling.
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  return pumpApp(
    tester,
    locale: locale,
    seed: (db) async {
      await seedSettings(db, currency: 'EUR', incomeMinor: 200000);
      await seed?.call(db);
    },
    overrides: [
      if (!shippedFile)
        providerTemplatesSourceProvider.overrideWith((ref) async => fixture),
    ],
  );
}

Future<void> openAdd(WidgetTester tester, {String label = 'Add plan'}) async {
  await tester.tap(find.text(label).first);
  await tester.pumpAndSettle();
}

String fieldText(WidgetTester tester, String key) =>
    tester.widget<TextFormField>(find.byKey(ValueKey(key))).controller!.text;

bool chipSelected(WidgetTester tester, String label) =>
    tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, label)).selected;

Future<void> save(WidgetTester tester) async {
  await scrollTo(tester, find.byKey(const ValueKey('save-plan')));
  await tester.tap(find.byKey(const ValueKey('save-plan')));
  await tester.pumpAndSettle();
}

const note =
    'Starting values for Scalapay · Last checked: Nov\u00A02026. '
    'Change them if your terms differ.';

void main() {
  testWidgets('Example 1: Italy, English: Scalapay fills the form', (
    tester,
  ) async {
    final db = await pumpRegion(tester, const Locale('en', 'IT'));
    await openAdd(tester);
    expect(find.text('Start from a provider'), findsOneWidget);
    expect(find.text('Scalapay'), findsOneWidget);
    expect(find.text('3 payments · monthly'), findsOneWidget);
    // Sorted by name: Klarna above Scalapay.
    expect(
      tester.getTopLeft(find.text('Klarna')).dy,
      lessThan(tester.getTopLeft(find.text('Scalapay')).dy),
    );

    // The plan types stay: going on without a template.
    for (final kind in [
      'Pay in 4',
      'Monthly installments',
      'Card installments',
      'Custom',
      'Pay later',
    ]) {
      expect(find.widgetWithText(ChoiceChip, kind), findsOneWidget);
    }

    await tester.tap(find.text('Scalapay'));
    await tester.pumpAndSettle();
    expect(chipSelected(tester, 'Monthly installments'), isTrue);
    expect(fieldText(tester, 'count'), '3');
    expect(fieldText(tester, 'source'), 'Scalapay');
    // Four fields, as without a template.
    expect(visibleInputCount(tester), 4);
    await scrollTo(
      tester,
      find.widgetWithText(ChoiceChip, 'Same day each month'),
    );
    expect(chipSelected(tester, 'Same day each month'), isTrue);
    await scrollTo(tester, find.byKey(const ValueKey('template-note')));
    expect(find.text(note), findsOneWidget);

    // Only the amount is typed.
    await scrollUpTo(tester, find.byKey(const ValueKey('total')));
    await tester.enterText(find.byKey(const ValueKey('total')), '300');
    await tester.pumpAndSettle();
    await save(tester);

    final plan = await db.select(db.plans).getSingle();
    expect(plan.kind, PlanKind.monthly);
    expect(plan.installmentCount, 3);
    expect(plan.intervalDays, isNull);
    // The plan name stays empty: the source names it (DECISIONS 7).
    expect(plan.title, isNull);
    final source = await db.select(db.sources).getSingle();
    expect(source.name, 'Scalapay');
    expect(source.kind, SourceKind.provider);
    expect(plan.sourceId, source.id);
    final payments = await db.select(db.payments).get();
    expect(payments.map((p) => p.amountMinor), [10000, 10000, 10000]);
    expect(payments.first.dueDay, testToday.epochDay);
    // The plan list shows the provider.
    expect(find.text('Scalapay'), findsWidgets);
  });

  testWidgets('Turkish app language, Italian region: same list, TR note', (
    tester,
  ) async {
    await pumpRegion(tester, const Locale('tr', 'IT'));
    await openAdd(tester, label: 'Plan ekle');
    expect(find.text('Sağlayıcıdan başla'), findsOneWidget);
    expect(find.text('Klarna'), findsOneWidget);
    expect(find.text('Scalapay'), findsOneWidget);
    expect(find.text('3 taksit · aylık'), findsOneWidget);
    expect(find.text('2 seçenek'), findsOneWidget);
    await tester.tap(find.text('Scalapay'));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.byKey(const ValueKey('template-note')));
    expect(
      find.text(
        'Scalapay için başlangıç değerleri · Son kontrol: Kas\u00A02026. '
        'Koşulların farklıysa değiştir.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Example 2: Indonesia, Kredivo "6 payments" sets 6', (
    tester,
  ) async {
    await pumpRegion(tester, const Locale('en', 'ID'));
    await openAdd(tester);
    expect(find.text('Kredivo'), findsOneWidget);
    expect(find.text('3 options'), findsOneWidget);
    await tester.tap(find.text('Kredivo'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('template-variant-sheet')),
      findsOneWidget,
    );
    expect(find.text('3 payments · every 30 days'), findsOneWidget);
    expect(find.text('6 payments · every 30 days'), findsOneWidget);
    expect(find.text('12 payments · every 30 days'), findsOneWidget);
    // The first pattern carries the check before a choice.
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('template-variant-0')),
        matching: find.byIcon(Icons.check),
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('6 payments · every 30 days'));
    await tester.pumpAndSettle();
    expect(fieldText(tester, 'count'), '6');
    expect(fieldText(tester, 'source'), 'Kredivo');
    await scrollTo(tester, find.widgetWithText(ChoiceChip, 'Every 30 days'));
    expect(chipSelected(tester, 'Every 30 days'), isTrue);
    // The first payment one interval after the purchase: 20 Dec.
    expect(find.text('Dec 20, 2026'), findsWidgets);
  });

  testWidgets('a sheet closed without a choice changes nothing', (
    tester,
  ) async {
    await pumpRegion(tester, const Locale('en', 'ID'));
    await openAdd(tester);
    await tester.tap(find.text('Kredivo'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(chipSelected(tester, 'Pay in 4'), isTrue);
    expect(fieldText(tester, 'source'), isEmpty);
    expect(find.byKey(const ValueKey('template-note')), findsNothing);
  });

  testWidgets('Japan: Paidy pays next month on the 27th', (tester) async {
    final db = await pumpRegion(tester, const Locale('en', 'JP'));
    await openAdd(tester);
    await tester.tap(find.text('Paidy'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('One payment · next month on day 27'));
    await tester.pumpAndSettle();
    expect(chipSelected(tester, 'Pay later'), isTrue);
    expect(chipSelected(tester, 'Next month on day 27'), isTrue);
    expect(find.text('Due on Dec 27, 2026'), findsOneWidget);
    // The store name (the plan name) stays empty.
    expect(fieldText(tester, 'store'), isEmpty);
    expect(fieldText(tester, 'source'), 'Paidy');
    await tester.enterText(find.byKey(const ValueKey('total')), '50');
    await tester.pumpAndSettle();
    await save(tester);
    final plan = await db.select(db.plans).getSingle();
    expect(plan.kind, PlanKind.payLater);
    expect(plan.payLaterRule, PayLaterRuleKind.nextMonthDay);
    expect(plan.payLaterValue, 27);
    expect(plan.title, isNull);
    final source = await db.select(db.sources).getSingle();
    expect(source.name, 'Paidy');
    expect(plan.sourceId, source.id);
  });

  for (final locale in const [
    Locale('en', 'TR'),
    Locale('en', 'BR'),
    Locale('en'),
  ]) {
    testWidgets('Example 5: no verified template in $locale: no section', (
      tester,
    ) async {
      await pumpRegion(tester, locale, shippedFile: true);
      await openAdd(tester);
      expect(find.byKey(const ValueKey('provider-start')), findsNothing);
      expect(find.text('Start from a provider'), findsNothing);
    });
  }

  testWidgets('the shipped file: Italy lists Scalapay', (tester) async {
    await pumpRegion(tester, const Locale('en', 'IT'), shippedFile: true);
    await openAdd(tester);
    await scrollTo(tester, find.byKey(const ValueKey('provider-scalapay')));
    expect(find.byKey(const ValueKey('provider-scalapay')), findsOneWidget);
  });

  testWidgets('Example 3: an existing "scalapay" source is used', (
    tester,
  ) async {
    late int existing;
    final db = await pumpRegion(
      tester,
      const Locale('en', 'IT'),
      seed: (db) async {
        existing = await SourceRepository(
          db,
          PlanRepository(db),
        ).create(name: 'scalapay', kind: SourceKind.provider);
      },
    );
    await openAdd(tester);
    await tester.tap(find.text('Scalapay'));
    await tester.pumpAndSettle();
    expect(fieldText(tester, 'source'), 'scalapay');
    await tester.enterText(find.byKey(const ValueKey('total')), '300');
    await tester.pumpAndSettle();
    await save(tester);
    final sources = await db.select(db.sources).get();
    expect(sources, hasLength(1));
    final plan = await db.select(db.plans).getSingle();
    expect(plan.sourceId, existing);
  });

  testWidgets('a card with the provider name is not reused', (tester) async {
    final db = await pumpRegion(
      tester,
      const Locale('en', 'IT'),
      seed: (db) => seedCard(db, name: 'Scalapay'),
    );
    await openAdd(tester);
    await tester.tap(find.text('Scalapay'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('total')), '300');
    await tester.pumpAndSettle();
    await save(tester);
    final plan = await db.select(db.plans).getSingle();
    final source = await (db.select(
      db.sources,
    )..where((s) => s.id.equals(plan.sourceId!))).getSingle();
    expect(source.kind, SourceKind.provider);
    expect(await db.select(db.sources).get(), hasLength(2));
  });

  testWidgets('Example 4: leaving without saving creates no source', (
    tester,
  ) async {
    final db = await pumpRegion(tester, const Locale('en', 'IT'));
    await openAdd(tester);
    await tester.tap(find.text('Scalapay'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('total')), '300');
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(await db.select(db.sources).get(), isEmpty);
    expect(await db.select(db.plans).get(), isEmpty);
  });

  testWidgets('every field stays editable; the plan keeps what was confirmed', (
    tester,
  ) async {
    final db = await pumpRegion(tester, const Locale('en', 'IT'));
    await openAdd(tester);
    await tester.tap(find.text('Scalapay'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('count')), '5');
    await tester.enterText(find.byKey(const ValueKey('total')), '500');
    await scrollTo(tester, find.widgetWithText(ChoiceChip, 'Every 2 weeks'));
    await tester.tap(find.widgetWithText(ChoiceChip, 'Every 2 weeks'));
    await tester.pumpAndSettle();
    // The note stays while the provider is the source.
    await scrollTo(tester, find.byKey(const ValueKey('template-note')));
    expect(find.text(note), findsOneWidget);
    await save(tester);
    final plan = await db.select(db.plans).getSingle();
    expect(plan.installmentCount, 5);
    expect(plan.intervalDays, 14);
    expect(plan.title, isNull);
    final payments = await db.select(db.payments).get();
    expect(payments, hasLength(5));
    expect(payments.map((p) => p.amountMinor).toSet(), {10000});
  });

  testWidgets('another source typed: the note goes, the name is kept', (
    tester,
  ) async {
    final db = await pumpRegion(tester, const Locale('en', 'IT'));
    await openAdd(tester);
    await tester.tap(find.text('Scalapay'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('source')), 'My shop');
    await tester.enterText(find.byKey(const ValueKey('total')), '300');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('template-note')), findsNothing);
    await save(tester);
    final source = await db.select(db.sources).getSingle();
    expect(source.name, 'My shop');
  });

  testWidgets('another plan type: the note goes', (tester) async {
    await pumpRegion(tester, const Locale('en', 'IT'));
    await openAdd(tester);
    await tester.tap(find.text('Scalapay'));
    await tester.pumpAndSettle();
    await scrollUpTo(tester, find.widgetWithText(ChoiceChip, 'Pay in 4'));
    await tester.tap(find.widgetWithText(ChoiceChip, 'Pay in 4'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('template-note')), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('provider-scalapay')),
        matching: find.byIcon(Icons.check),
      ),
      findsNothing,
    );
  });
}
