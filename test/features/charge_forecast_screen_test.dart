import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/engine/engine.dart';
import 'package:kalan/core/money/currency.dart';
import 'package:kalan/core/money/money_format.dart';
import 'package:kalan/core/routing/router.dart';
import 'package:kalan/core/routing/routes.dart';
import 'package:kalan/core/theme/kalan_theme.dart';
import 'package:kalan/data/db/app_database.dart';
import 'package:kalan/data/repositories/plan_repository.dart';
import 'package:kalan/features/home/home_view.dart';
import 'package:kalan/features/plans/add_plan_screen.dart' show SourceNameField;
import 'package:kalan/features/sources/charge_forecast_view.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/app_harness.dart';
import '../helpers/charge_seed.dart';
import '../helpers/pump.dart';

String tl(int minor) =>
    formatMoney(minor, Currency.fromCode('TRY'), localeName: 'tr');

void main() {
  late ChargeSeed ids;

  Future<AppDatabase> open(
    WidgetTester tester, {
    LocalDate? today,
    Locale locale = const Locale('tr', 'TR'),
    String currency = 'TRY',
    Future<void> Function(AppDatabase db)? more,
  }) => pumpApp(
    tester,
    locale: locale,
    today: today ?? chargeToday,
    seed: (db) async {
      ids = await seedCharges(db, currency: currency);
      if (more != null) await more(db);
    },
    overrides: [initialRouteProvider.overrideWithValue(Routes.sources)],
  );

  Finder inSection(int id, Finder f) => find.descendant(
    of: find.byKey(ValueKey('charge-section-$id')),
    matching: f,
  );

  Future<void> tapKey(WidgetTester tester, String key) async {
    final f = find.byKey(ValueKey(key));
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  testWidgets('example 1: bank account summary and the running list', (
    tester,
  ) async {
    await open(tester);
    expect(inSection(ids.maas, find.text('Hesapta bulunsun')), findsOneWidget);
    expect(
      inSection(ids.maas, find.text('Sıradaki çekim: 18 Kas · ${tl(240000)}')),
      findsOneWidget,
    );
    expect(
      inSection(ids.maas, find.text('14 Ara tarihine kadar · ${tl(390000)}')),
      findsOneWidget,
    );
    // Details are closed until tapped.
    expect(find.byKey(ValueKey('charge-row-${ids.maas}-0')), findsNothing);
    await tapKey(tester, 'charge-details-${ids.maas}');
    final first = find.byKey(ValueKey('charge-row-${ids.maas}-0'));
    expect(
      find.descendant(of: first, matching: find.text('18 Kas tarihine kadar')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: first, matching: find.text(tl(240000))),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: first,
        matching: find.text('Spor salonu, Telefon taksiti'),
      ),
      findsOneWidget,
    );
    expect(
      inSection(ids.maas, find.text('25 Kas tarihine kadar')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(ValueKey('charge-row-${ids.maas}-1')),
        matching: find.text(tl(390000)),
      ),
      findsOneWidget,
    );
    // Paid by hand: in no total, in no list.
    expect(find.textContaining('Kulaklık'), findsNothing);
    // Recurring payments have no source: never here.
    expect(inSection(ids.maas, find.textContaining('Kira')), findsNothing);
  });

  testWidgets('example 2: a paid day is muted and ticked, not in the total', (
    tester,
  ) async {
    await open(
      tester,
      today: LocalDate(2026, 11, 19),
      more: (db) async {
        final telefon = (await (db.select(
          db.plans,
        )..where((p) => p.title.equals('Telefon taksiti'))).getSingle()).id;
        await payFirstTelefon(db, telefon);
        // Spor salonu was taken on 18 Nov too.
        final spor = (await (db.select(
          db.plans,
        )..where((p) => p.title.equals('Spor salonu'))).getSingle()).id;
        await (db.update(db.payments)..where((p) => p.planId.equals(spor)))
            .write(PaymentsCompanion(paidAt: Value(DateTime(2026, 11, 18))));
      },
    );
    expect(
      inSection(ids.maas, find.text('Sıradaki çekim: 25 Kas · ${tl(150000)}')),
      findsOneWidget,
    );
    expect(
      inSection(ids.maas, find.text('14 Ara tarihine kadar · ${tl(150000)}')),
      findsOneWidget,
    );
    await tapKey(tester, 'charge-details-${ids.maas}');
    final paid = find.byKey(ValueKey('charge-row-${ids.maas}-0'));
    expect(
      find.descendant(of: paid, matching: find.text('18 Kas · ödendi')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: paid, matching: find.text(tl(240000))),
      findsOneWidget,
    );
    expect(
      find.descendant(of: paid, matching: find.byIcon(Icons.check)),
      findsOneWidget,
    );
    expect(
      inSection(ids.maas, find.text('25 Kas tarihine kadar')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(ValueKey('charge-row-${ids.maas}-1')),
        matching: find.text(tl(150000)),
      ),
      findsOneWidget,
    );
  });

  testWidgets('past due and unpaid: today, with a clock in ink', (
    tester,
  ) async {
    await open(tester, today: LocalDate(2026, 11, 20));
    await tapKey(tester, 'charge-details-${ids.maas}');
    final today = find.byKey(ValueKey('charge-row-${ids.maas}-0'));
    expect(
      find.descendant(of: today, matching: find.text('20 Kas tarihine kadar')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: today, matching: find.text(tl(240000))),
      findsOneWidget,
    );
    final clock = tester.widget<Icon>(
      find.descendant(of: today, matching: find.byIcon(Icons.schedule)),
    );
    final context = tester.element(today);
    expect(clock.color, context.colors.text);
  });

  testWidgets('example 4: a card shows only other plans taken from it', (
    tester,
  ) async {
    await open(tester);
    expect(
      inSection(ids.bonus, find.text('Bu karta yansıyacak')),
      findsOneWidget,
    );
    expect(
      inSection(ids.bonus, find.text('Sıradaki çekim: 5 Ara · ${tl(60000)}')),
      findsOneWidget,
    );
    expect(
      inSection(ids.bonus, find.text('14 Ara tarihine kadar · ${tl(60000)}')),
      findsOneWidget,
    );
    await tapKey(tester, 'charge-details-${ids.bonus}');
    expect(inSection(ids.bonus, find.text('Klarna')), findsOneWidget);
    expect(
      inSection(ids.bonus, find.textContaining('Kart taksidi')),
      findsNothing,
    );
  });

  testWidgets('next period: closed, opens its own list', (tester) async {
    await open(tester);
    expect(find.byKey(ValueKey('charge-next-row-${ids.maas}-0')), findsNothing);
    await tapKey(tester, 'charge-next-period-${ids.maas}');
    final row = find.byKey(ValueKey('charge-next-row-${ids.maas}-0'));
    expect(
      find.descendant(of: row, matching: find.text('18 Ara tarihine kadar')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: row, matching: find.text(tl(140000))),
      findsOneWidget,
    );
    // An account with nothing: one calm line, next period empty too.
    expect(
      inSection(
        ids.bos,
        find.text('Bu dönem bu kaynaktan çıkacak otomatik ödeme yok.'),
      ),
      findsOneWidget,
    );
    await tapKey(tester, 'charge-next-period-${ids.bos}');
    expect(
      find.byKey(ValueKey('charge-next-empty-${ids.bos}')),
      findsOneWidget,
    );
  });

  testWidgets('without a source: their own card, a row opens the plan', (
    tester,
  ) async {
    await open(tester);
    final card = find.byKey(const ValueKey('charge-unassigned'));
    await tester.ensureVisible(card);
    expect(
      find.descendant(
        of: card,
        matching: find.text('Kaynağı seçilmemiş otomatik ödemeler'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: card,
        matching: find.text('Sıradaki: 2 Ara · ${tl(45000)}'),
      ),
      findsOneWidget,
    );
    await tapKey(tester, 'charge-unassigned-${ids.ayakkabi}');
    expect(find.text('Ayakkabı'), findsWidgets);
    expect(find.byKey(const ValueKey('charge-unassigned')), findsNothing);
  });

  testWidgets('English titles and amounts', (tester) async {
    await open(tester, locale: const Locale('en', 'US'));
    String usd(int m) =>
        formatMoney(m, Currency.fromCode('TRY'), localeName: 'en');
    expect(inSection(ids.maas, find.text('Keep in account')), findsOneWidget);
    expect(
      inSection(ids.bonus, find.text('Coming to this card')),
      findsOneWidget,
    );
    expect(
      inSection(
        ids.maas,
        find.text('Next withdrawal: Nov 18 · ${usd(240000)}'),
      ),
      findsOneWidget,
    );
    expect(
      inSection(ids.maas, find.text('By Dec 14 · ${usd(390000)}')),
      findsOneWidget,
    );
  });

  testWidgets('a currency without decimals (IDR)', (tester) async {
    await open(tester, currency: 'IDR');
    final idr = Currency.fromCode('IDR');
    final amount = formatMoney(240000, idr, localeName: 'tr');
    expect(amount, isNot(contains(',')));
    expect(
      inSection(ids.maas, find.text('Sıradaki çekim: 18 Kas · $amount')),
      findsOneWidget,
    );
  });

  testWidgets('the same period as the home screen', (tester) async {
    await open(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(Scaffold).first),
    );
    final home = container.read(homeViewProvider)!;
    final charges = container.read(chargeForecastProvider)!;
    expect(charges.current, home.summary.period);
  });

  testWidgets('tap targets are at least 48x48', (tester) async {
    await open(tester);
    await tapKey(tester, 'charge-details-${ids.maas}');
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  });

  testWidgets('a bank account is not offered as a provider name', (
    tester,
  ) async {
    SourceRow row(int id, String name, SourceKind kind) => SourceRow(
      id: id,
      name: name,
      kind: kind,
      shiftDueToBusinessDay: true,
      shiftDueForHolidays: true,
      createdAt: DateTime(2026),
      statementReminderEnabled: false,
      statementReminderDays: 2,
    );
    final controller = TextEditingController();
    final focus = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focus.dispose);
    await pumpLocalized(
      tester,
      SourceNameField(
        controller: controller,
        focusNode: focus,
        sources: [
          row(1, 'Maaşım', SourceKind.account),
          row(2, 'Maaşkart', SourceKind.card),
        ],
        validator: (_) => null,
      ),
    );
    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'Maa');
    await tester.pumpAndSettle();
    expect(find.text('Maaşkart'), findsOneWidget);
    expect(find.text('Maaşım'), findsNothing);
  });

  testWidgets('open and closed are heard by screen readers', (tester) async {
    final handle = tester.ensureSemantics();
    await open(tester);
    for (final key in [
      'charge-details-${ids.maas}',
      'charge-next-period-${ids.maas}',
    ]) {
      final f = find.byKey(ValueKey(key));
      await tester.ensureVisible(f);
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(f),
        matchesSemantics(
          isButton: true,
          hasExpandedState: true,
          isExpanded: false,
          hasTapAction: true,
          isFocusable: true,
          hasFocusAction: true,
          label: key.startsWith('charge-details')
              ? 'Sıradaki çekim: 18 Kas · ${tl(240000)}\n'
                    '14 Ara tarihine kadar · ${tl(390000)}\nAyrıntı'
              : 'Sonraki dönem\n15 Ara – 14 Oca',
        ),
      );
      await tester.tap(f);
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(f),
        isSemantics(isExpanded: true, hasExpandedState: true),
      );
    }
    handle.dispose();
  });

  testWidgets('no source at all: the card shows, without the note', (
    tester,
  ) async {
    await pumpApp(
      tester,
      today: chargeToday,
      seed: (db) async {
        await seedSettings(db);
        await PlanRepository(db).saveDraft(
          PlanCalculator.payLater(
            purchaseDate: chargeToday,
            rule: const PayLaterRule.days(14),
            totalMinor: 30000,
          ),
          sourceId: null,
          origin: PlanOrigin.template,
          title: 'Ayakkabı',
          paymentMethod: PaymentMethod.automatic,
        );
      },
      overrides: [initialRouteProvider.overrideWithValue(Routes.sources)],
    );
    expect(find.byKey(const ValueKey('charge-unassigned')), findsOneWidget);
    expect(find.text('Sıradaki: 29 Kas · ${tl(30000)}'), findsOneWidget);
    expect(
      find.text('Çekildiği yeri planın ayrıntısından seçebilirsin.'),
      findsNothing,
    );
  });

  testWidgets('twice the text size: nothing overflows', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await open(tester);
    for (final key in [
      'charge-details-${ids.maas}',
      'charge-next-period-${ids.maas}',
    ]) {
      await tapKey(tester, key);
    }
    await tester.ensureVisible(find.byKey(const ValueKey('charge-unassigned')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
