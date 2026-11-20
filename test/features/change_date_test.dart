import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/engine/engine.dart';
import 'package:kalan/core/money/currency.dart';
import 'package:kalan/core/money/money_format.dart';
import 'package:kalan/data/db/app_database.dart';
import 'package:kalan/data/repositories/plan_repository.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/app_harness.dart';

/// "Change date" (20): the brief's examples. USD, payday 25, income set,
/// today 15 Nov; Tom's 240 $ in 4 × 60 $: 20 Nov, 4 Dec, 18 Dec, 1 Jan.
final usd = Currency.fromCode('USD');
String tr(int minor) => formatMoney(minor, usd, localeName: 'tr');
final today = LocalDate(2026, 11, 15);

Future<int> seedTom(AppDatabase db, {int? income = 100000}) async {
  await seedSettings(db, currency: 'USD', payDay: 25, incomeMinor: income);
  return seedPayIn4(
    db,
    first: LocalDate(2026, 11, 20),
    totalMinor: 24000,
    source: 'Afterpay',
    title: 'Tom',
  );
}

Future<List<PaymentRow>> rows(AppDatabase db) =>
    (db.select(db.payments)..orderBy([(p) => OrderingTerm.asc(p.seq)])).get();

Future<void> openTom(WidgetTester tester) async {
  await openTab(tester, 'Planlar');
  await tester.tap(find.text('Tom'));
  await tester.pumpAndSettle();
}

Future<void> tapPayment(WidgetTester tester, String date) async {
  await tester.tap(find.text(date));
  await tester.pumpAndSettle();
}

/// From the sheet: "Change date", then [day] in the picker's month.
Future<void> changeTo(WidgetTester tester, int day, {int months = 0}) async {
  await tester.tap(find.byKey(const ValueKey('payment-changeDate')));
  await tester.pumpAndSettle();
  for (var i = 0; i < months; i++) {
    await tester.tap(find.byTooltip('Sonraki ay'));
    await tester.pumpAndSettle();
  }
  await tester.tap(find.text('$day'));
  await tester.tap(find.text('Tamam'));
  await tester.pumpAndSettle();
}

void expectTarget(WidgetTester tester, Finder f) {
  final size = tester.getSize(f);
  expect(size.width, greaterThanOrEqualTo(48));
  expect(size.height, greaterThanOrEqualTo(48));
}

void main() {
  testWidgets('example 1 and 2: preview, switch, save, note', (tester) async {
    final db = await pumpApp(tester, today: today, seed: seedTom);
    await openTom(tester);
    await tapPayment(tester, '20 Kas 2026');
    expect(find.byKey(const ValueKey('payment-sheet')), findsOneWidget);
    expect(find.text('1/4 · 20 Kas 2026'), findsOneWidget);
    expect(find.text('Tarihi değiştir'), findsOneWidget);
    expect(find.text('Ödemeyi düzelt'), findsOneWidget);
    for (final key in ['payment-changeDate', 'payment-edit']) {
      expectTarget(tester, find.byKey(ValueKey(key)));
    }
    await changeTo(tester, 27);

    expect(find.text('Şu anki tarih: 20 Kas 2026'), findsOneWidget);
    expect(find.text('27 Kas 2026'), findsOneWidget);
    // Example 1.
    expect(find.text('25 Eki – 24 Kas'), findsOneWidget);
    expect(find.text('Kalan +${tr(6000)} ↑'), findsOneWidget);
    expect(find.text('25 Kas – 24 Ara'), findsOneWidget);
    expect(find.text('Kalan −${tr(6000)} ↓'), findsOneWidget);

    // The switch starts off; on, it is example 2.
    final shift = find.byKey(const ValueKey('change-date-shift'));
    expect(tester.widget<SwitchListTile>(shift).value, isFalse);
    expectTarget(tester, shift);
    await tester.tap(shift);
    await tester.pumpAndSettle();
    expect(find.text('25 Eki – 24 Kas'), findsOneWidget);
    expect(find.text('25 Kas – 24 Ara'), findsNothing);
    expect(find.text('25 Ara – 24 Oca'), findsOneWidget);
    await tester.tap(shift);
    await tester.pumpAndSettle();

    final save = find.byKey(const ValueKey('change-date-save'));
    expectTarget(tester, save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.text('Tarih kaydedildi.'), findsOneWidget);
    expect(find.text('Ertelendi · ilk tarih 20 Kasım'), findsOneWidget);
    expect(find.byKey(const ValueKey('move-note')), findsOneWidget);
    final stored = await rows(db);
    expect(stored.first.dueDay, LocalDate(2026, 11, 27).epochDay);
    expect(stored.first.originalDay, LocalDate(2026, 11, 20).epochDay);
    expect(stored.skip(1).map((r) => r.originalDay), everyElement(isNull));
  });

  testWidgets('example 3: no income, the committed amount', (tester) async {
    await pumpApp(
      tester,
      today: today,
      seed: (db) => seedTom(db, income: null),
    );
    await openTom(tester);
    await tapPayment(tester, '20 Kas 2026');
    await changeTo(tester, 27);
    expect(find.text('Söz verilmiş −${tr(6000)} ↓'), findsOneWidget);
    expect(find.text('Söz verilmiş +${tr(6000)} ↑'), findsOneWidget);
  });

  testWidgets('example 4: same period; back again removes the note', (
    tester,
  ) async {
    final db = await pumpApp(tester, today: today, seed: seedTom);
    await openTom(tester);
    await tapPayment(tester, '4 Ara 2026');
    await changeTo(tester, 6);
    expect(find.text('Dönem değişmiyor; kalan aynı kalıyor.'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('change-date-save')));
    await tester.pumpAndSettle();
    expect(find.text('Ertelendi · ilk tarih 4 Aralık'), findsOneWidget);

    await tapPayment(tester, '6 Ara 2026');
    await changeTo(tester, 4);
    await tester.tap(find.byKey(const ValueKey('change-date-save')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('move-note')), findsNothing);
    expect((await rows(db))[1].originalDay, isNull);
  });

  testWidgets('example 5: after the next payment; numbers kept, by date', (
    tester,
  ) async {
    await pumpApp(tester, today: today, seed: seedTom);
    await openTom(tester);
    await tapPayment(tester, '4 Ara 2026');
    await changeTo(tester, 20);
    expect(find.text('Bu tarih bir sonraki taksitten sonra.'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('change-date-save')));
    await tester.pumpAndSettle();
    final third = tester.getTopLeft(find.text('18 Ara 2026')).dy;
    final second = tester.getTopLeft(find.text('20 Ara 2026')).dy;
    expect(second, greaterThan(third));
    expect(find.text('2/4'), findsOneWidget);
    expect(find.text('Ertelendi · ilk tarih 4 Aralık'), findsOneWidget);
  });

  testWidgets('cancel anywhere: nothing changes', (tester) async {
    final db = await pumpApp(tester, today: today, seed: seedTom);
    final before = [for (final r in await rows(db)) (r.dueDay, r.originalDay)];
    await openTom(tester);
    // The sheet dismissed.
    await tapPayment(tester, '20 Kas 2026');
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('payment-sheet')), findsNothing);
    // The picker cancelled.
    await tapPayment(tester, '20 Kas 2026');
    await tester.tap(find.byKey(const ValueKey('payment-changeDate')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('İptal'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('change-date-save')), findsNothing);
    // The screen left with back.
    await tapPayment(tester, '20 Kas 2026');
    await changeTo(tester, 27);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('20 Kas 2026'), findsOneWidget);
    expect([for (final r in await rows(db)) (r.dueDay, r.originalDay)], before);
  });

  testWidgets('the picker starts at today: earlier days cannot be chosen', (
    tester,
  ) async {
    await pumpApp(
      tester,
      today: today,
      seed: (db) async {
        await seedSettings(db, currency: 'USD', payDay: 25);
        // Past due: 1 Nov.
        await seedPayIn4(
          db,
          first: LocalDate(2026, 11, 1),
          totalMinor: 24000,
          title: 'Tom',
        );
      },
    );
    await openTom(tester);
    await tapPayment(tester, '1 Kas 2026');
    await tester.tap(find.byKey(const ValueKey('payment-changeDate')));
    await tester.pumpAndSettle();
    final picker = tester.widget<CalendarDatePicker>(
      find.byType(CalendarDatePicker),
    );
    expect(LocalDate.fromDateTime(picker.firstDate), today);
    expect(LocalDate.fromDateTime(picker.initialDate!), today);
  });

  group('no "Change date"', () {
    testWidgets('a paid payment', (tester) async {
      await pumpApp(
        tester,
        today: today,
        seed: (db) async {
          await seedTom(db);
          await PlanRepository(db)
              .setPaid((await rows(db)).first.id, paid: true);
        },
      );
      await openTom(tester);
      await tapPayment(tester, '20 Kas 2026');
      expect(find.byKey(const ValueKey('payment-sheet')), findsNothing);
    });

    testWidgets('a plan on hold or closed', (tester) async {
      await pumpApp(
        tester,
        today: today,
        seed: (db) async {
          final id = await seedTom(db);
          await PlanRepository(db).hold(id, today: today);
        },
      );
      await openTom(tester);
      await tapPayment(tester, '4 Ara 2026');
      expect(find.byKey(const ValueKey('payment-sheet')), findsNothing);
    });

    testWidgets('a card installment opens the edit as before', (tester) async {
      await pumpApp(
        tester,
        today: today,
        seed: (db) async {
          await seedSettings(db, currency: 'USD', payDay: 25);
          final card = await seedCard(db);
          await PlanRepository(db).saveDraft(
            PlanCalculator.card(
              purchaseDate: LocalDate(2026, 11, 10),
              totalMinor: 30000,
              count: 3,
              terms: const CardTerms(statementDay: 25, dueDay: 5),
            ),
            sourceId: card,
            origin: PlanOrigin.template,
            title: 'Tom',
          );
        },
      );
      await openTom(tester);
      await tester.tap(find.textContaining('2026').at(1));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('payment-sheet')), findsNothing);
      expect(find.text('Ödemeyi düzelt'), findsOneWidget);
    });
  });
}
