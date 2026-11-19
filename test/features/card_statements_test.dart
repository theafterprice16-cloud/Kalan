import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/engine/engine.dart';
import 'package:kalan/core/money/currency.dart';
import 'package:kalan/core/money/money_format.dart';
import 'package:kalan/core/routing/router.dart';
import 'package:kalan/core/routing/routes.dart';
import 'package:kalan/data/db/app_database.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/app_harness.dart';
import '../helpers/statement_seed.dart';

String tl(int minor) =>
    formatMoney(minor, Currency.fromCode('TRY'), localeName: 'tr');

void main() {
  late StatementCards cards;

  Future<AppDatabase> open(
    WidgetTester tester, {
    String route = Routes.sources,
    Locale locale = const Locale('tr', 'TR'),
  }) => pumpApp(
    tester,
    locale: locale,
    today: statementToday,
    seed: (db) async => cards = await seedStatements(db),
    overrides: [initialRouteProvider.overrideWithValue(route)],
  );

  Finder inSection(int cardId, Finder f) => find.descendant(
    of: find.byKey(ValueKey('card-statements-$cardId')),
    matching: f,
  );

  testWidgets('example 1: the closed 14 Nov statement and five more', (
    tester,
  ) async {
    await open(tester);
    final first = find.byKey(ValueKey('card-statement-${cards.ada}-0'));
    expect(
      find.descendant(of: first, matching: find.text('14 Kas ekstresi')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: first, matching: find.text('Kesildi')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: first,
        matching: find.text('3 taksit · Son ödeme 24 Kas'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: first, matching: find.text(tl(415000))),
      findsOneWidget,
    );
    for (final title in [
      '14 Ara ekstresi',
      '14 Oca ekstresi',
      '14 Şub ekstresi',
      '14 Mar ekstresi',
      '14 Nis ekstresi',
    ]) {
      expect(inSection(cards.ada, find.text(title)), findsOneWidget);
    }
    // Only the cut statement says "Closed".
    expect(inSection(cards.ada, find.text('Kesildi')), findsOneWidget);
    // Sunday 24 Jan moves to Monday.
    expect(
      inSection(cards.ada, find.text('3 taksit · Son ödeme 25 Oca')),
      findsNothing,
    );
    expect(
      inSection(cards.ada, find.textContaining('Son ödeme 25 Oca')),
      findsOneWidget,
    );
    expect(
      inSection(cards.ada, find.text("Yalnızca Kalan'a girdiğin taksitler.")),
      findsOneWidget,
    );
  });

  testWidgets('a statement without installments has no total', (tester) async {
    await open(tester);
    // Ada Kart, 14 Mar: Telefon ended in Feb, the others earlier.
    final march = find.byKey(ValueKey('card-statement-${cards.ada}-4'));
    expect(
      find.descendant(
        of: march,
        matching: find.text('Taksit yok · Son ödeme 24 Mar'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: march, matching: find.byType(Text)),
      findsNWidgets(2),
    );
  });

  testWidgets('no section on a card without installments or a provider', (
    tester,
  ) async {
    await open(tester);
    await tester.scrollUntilVisible(
      find.text('Yedek Kart'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.byKey(ValueKey('card-statements-${cards.yedek}')),
      findsNothing,
    );
    expect(find.byKey(ValueKey('card-statements-${cards.gece}')), findsOne);
    expect(find.textContaining('Klarna'), findsOneWidget); // its own card
    expect(find.text("Yalnızca Kalan'a girdiğin taksitler."), findsNWidgets(2));
  });

  testWidgets('tapping a statement lists its installments (examples 2-4)', (
    tester,
  ) async {
    await open(tester);
    final first = find.byKey(ValueKey('card-statement-${cards.ada}-0'));
    await tester.ensureVisible(first);
    await tester.pumpAndSettle();
    await tester.tap(first);
    await tester.pumpAndSettle();

    expect(find.text('14 Kas ekstresi'), findsOneWidget); // title
    expect(find.text('3 taksit · ${tl(415000)}'), findsOneWidget);
    expect(find.text('Hesap kesim 14 Kas 2026'), findsOneWidget);
    expect(find.text('Son ödeme 24 Kas 2026'), findsOneWidget);
    expect(find.text('Kesildi'), findsOneWidget);
    expect(find.text("Yalnızca Kalan'a girdiğin taksitler."), findsOneWidget);

    Finder row(String name) => find.ancestor(
      of: find.text(name),
      matching: find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith(
              'statement-installment-',
            ),
      ),
    );
    // Example 3: paid, still on the statement.
    expect(
      find.descendant(of: row('Telefon'), matching: find.text('3/6')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: row('Telefon'), matching: find.text('Ödendi')),
      findsOneWidget,
    );
    // Example 2: bought on the statement day, first installment here.
    expect(
      find.descendant(of: row('Ayakkabı'), matching: find.text('1/2')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: row('Kulaklık'), matching: find.text('1/3')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: row('Kulaklık'), matching: find.text('Ödendi')),
      findsNothing,
    );
    // Example 4: the "Pay later" plan paid from the card is not here.
    expect(find.textContaining('Klarna'), findsNothing);
    expect(find.textContaining('Sonra öde'), findsNothing);
  });

  testWidgets('the card route opens the sources scrolled to its card', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(780, 1000);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    // Gece Kart is below Ada Kart's statements at first.
    await open(tester, route: Routes.cardStatements(cards.gece));
    final list = find.byKey(const ValueKey('sources-list'));
    final position = tester
        .state<ScrollableState>(
          find.descendant(of: list, matching: find.byType(Scrollable)),
        )
        .position;
    expect(position.pixels, greaterThan(0));
    // The card's statements are on screen.
    final next = find.byKey(ValueKey('card-statement-${cards.gece}-0'));
    expect(tester.getRect(next).bottom, lessThan(500));
  });

  testWidgets('the statement route opens one statement in English', (
    tester,
  ) async {
    await open(
      tester,
      locale: const Locale('en', 'US'),
      route: Routes.cardStatement(1, LocalDate(2026, 11, 14).epochDay),
    );
    expect(find.text('Nov 14 statement'), findsOneWidget);
    expect(find.text('Closed'), findsOneWidget);
    expect(find.text('Statement date Nov 14, 2026'), findsOneWidget);
    expect(find.text('Due Nov 24, 2026'), findsOneWidget);
    expect(find.text('Only installments you added to Kalan.'), findsOneWidget);
    expect(find.text('Paid'), findsOneWidget);
  });

  testWidgets('installments paid before Kalan count but are one line', (
    tester,
  ) async {
    // Telefon (plan 1) was 3 installments in when it was added.
    final db = await open(
      tester,
      route: Routes.cardStatement(1, LocalDate(2026, 11, 14).epochDay),
    );
    await tester.runAsync(
      () =>
          (db.update(db.payments)..where(
                (p) => p.planId.equals(1) & p.seq.isSmallerOrEqualValue(3),
              ))
              .write(const PaymentsCompanion(paidBeforeKalan: Value(true))),
    );
    await tester.pumpAndSettle();
    expect(find.text('3 taksit · ${tl(415000)}'), findsOneWidget);
    expect(find.text('3/6'), findsNothing);
    expect(
      find.text("1 taksit Kalan'dan önce ödendi · ${tl(120000)}"),
      findsOneWidget,
    );
  });

  for (final (name, route) in [
    ('sources', Routes.sources),
    ('statement', Routes.cardStatement(1, LocalDate(2026, 11, 14).epochDay)),
  ]) {
    testWidgets('large text on a small phone does not overflow: $name', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await open(tester, route: route);
      expect(tester.takeException(), isNull);
    });
  }
}
