import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/engine/engine.dart';
import 'package:kalan/core/money/currency.dart';
import 'package:kalan/core/money/money_format.dart';
import 'package:kalan/core/theme/kalan_colors.dart';
import 'package:kalan/data/db/app_database.dart';
import 'package:kalan/data/repositories/plan_repository.dart';
import 'package:kalan/data/repositories/source_repository.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/app_harness.dart';

/// Extra fee (21): the brief's examples. EUR, payday 25, income 1.000 €,
/// today 15 Nov 2026; Sofia's 240 € in 4 × 60 € from 10 Nov (monthly),
/// the first one past due.
final eur = Currency.fromCode('EUR');
String tr(int minor, [Currency? c]) =>
    formatMoney(minor, c ?? eur, localeName: 'tr');
final today = LocalDate(2026, 11, 15);

Future<int> seedSofia(
  AppDatabase db, {
  String currency = 'EUR',
  int total = 24000,
}) async {
  await seedSettings(db, currency: currency, payDay: 25, incomeMinor: 100000);
  final plans = PlanRepository(db);
  return plans.saveDraft(
    PlanCalculator.monthly(
      firstDate: LocalDate(2026, 11, 10),
      totalMinor: total,
      count: 4,
    ),
    sourceId: await SourceRepository(db, plans).findOrCreateProvider('Klarna'),
    origin: PlanOrigin.template,
    title: 'Sofia',
  );
}

Future<List<PaymentRow>> rows(AppDatabase db) =>
    (db.select(db.payments)..orderBy([(p) => OrderingTerm.asc(p.seq)])).get();

Future<AppDatabase> pumpSofia(
  WidgetTester tester, {
  Future<void> Function(AppDatabase db, int planId)? then,
}) => pumpApp(
  tester,
  today: today,
  seed: (db) async {
    final id = await seedSofia(db);
    await then?.call(db, id);
  },
);

Future<void> openSofia(WidgetTester tester) async {
  await openTab(tester, 'Planlar');
  await tester.tap(find.text('Sofia'));
  await tester.pumpAndSettle();
}

Future<void> tapKey(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> fillAndSave(
  WidgetTester tester,
  String amount, {
  String? note,
}) async {
  await tester.enterText(
    find.byKey(const ValueKey('extra-fee-amount')),
    amount,
  );
  if (note != null) {
    await tester.enterText(find.byKey(const ValueKey('extra-fee-note')), note);
  }
  await tapKey(tester, 'extra-fee-save');
}

void main() {
  testWidgets('example 2: "Add extra fee" on the past-due row', (tester) async {
    final db = await pumpSofia(tester);
    final first = (await rows(db)).first;
    // Left before: 1.000 € − 60 € (past due, this period).
    expect(find.text(tr(94000)), findsOneWidget);
    expect(find.text('Ek ücret ekle'), findsOneWidget);

    await tapKey(tester, 'past-due-fee-action-${first.id}');
    expect(find.byKey(const ValueKey('extra-fee-sheet')), findsOneWidget);
    expect(find.text('Ek ücret'), findsOneWidget);
    expect(find.byKey(const ValueKey('extra-fee-delete')), findsNothing);
    await fillAndSave(tester, '6');

    expect(find.text('Ek ücret kaydedildi.'), findsOneWidget);
    expect((await rows(db)).first.extraFeeMinor, 600);
    // The amount stays 60 €; the fee is a note under it.
    expect(find.byKey(ValueKey('past-due-fee-${first.id}')), findsOneWidget);
    expect(find.text('+ ${tr(600)} ek ücret'), findsOneWidget);
    expect(find.text('Ek ücreti düzelt'), findsOneWidget);
    // Left goes down by exactly the fee.
    await tester.scrollUntilVisible(
      find.text(tr(93400)),
      -100,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text(tr(93400)), findsOneWidget);
  });

  testWidgets('the fee note is textMuted, never late or accent', (
    tester,
  ) async {
    final db = await pumpSofia(
      tester,
      then: (db, _) async {
        final first = (await rows(db)).first;
        await PlanRepository(db).setExtraFee(first.id, amountMinor: 600);
      },
    );
    final first = (await rows(db)).first;
    final colors = Theme.of(
      tester.element(find.byKey(ValueKey('past-due-fee-${first.id}'))),
    ).extension<KalanColors>()!;
    final note = tester.widget<Text>(
      find.byKey(ValueKey('past-due-fee-${first.id}')),
    );
    expect(note.style?.color, colors.textMuted);
    expect(note.style?.color, isNot(colors.late));
    expect(note.style?.color, isNot(colors.accent));
  });

  testWidgets('zero and empty are not saved; the sheet stays open', (
    tester,
  ) async {
    final db = await pumpSofia(tester);
    final first = (await rows(db)).first;
    await tapKey(tester, 'past-due-fee-action-${first.id}');
    await fillAndSave(tester, '');
    expect(find.text('Bu alan gerekli.'), findsOneWidget);
    await fillAndSave(tester, '0');
    expect(find.byKey(const ValueKey('extra-fee-sheet')), findsOneWidget);
    expect((await rows(db)).first.extraFeeMinor, isNull);
    // "Too large" comes from the shared amount field.
    await fillAndSave(tester, '9' * 16);
    expect(find.byKey(const ValueKey('extra-fee-sheet')), findsOneWidget);
    expect((await rows(db)).first.extraFeeMinor, isNull);
  });

  testWidgets('the note takes at most 80 characters', (tester) async {
    final db = await pumpSofia(tester);
    final first = (await rows(db)).first;
    await tapKey(tester, 'past-due-fee-action-${first.id}');
    await fillAndSave(tester, '6', note: 'x' * 100);
    expect((await rows(db)).first.extraFeeNote, 'x' * 80);
  });

  testWidgets('example 3: correct the fee and add a note', (tester) async {
    final db = await pumpSofia(
      tester,
      then: (db, _) async {
        final first = (await rows(db)).first;
        await PlanRepository(db).setExtraFee(first.id, amountMinor: 600);
      },
    );
    final first = (await rows(db)).first;
    await tapKey(tester, 'past-due-fee-action-${first.id}');
    // Prefilled with the current fee.
    expect(find.text('6'), findsOneWidget);
    expect(find.byKey(const ValueKey('extra-fee-delete')), findsOneWidget);
    await fillAndSave(tester, '12', note: 'İkinci ücret');

    await openSofia(tester);
    expect(find.text('Ek ücret: ${tr(1200)}'), findsOneWidget);
    expect(find.text('İkinci ücret'), findsOneWidget);
    expect(find.text('Ek ücretler: ${tr(1200)}'), findsOneWidget);
    // The plan total does not change.
    expect(find.text('Toplam ${tr(24000)}'), findsOneWidget);
  });

  testWidgets('example 4: delete without asking, then undo', (tester) async {
    final db = await pumpSofia(
      tester,
      then: (db, _) async {
        final first = (await rows(db)).first;
        await PlanRepository(db)
            .setExtraFee(first.id, amountMinor: 600, note: 'Not');
      },
    );
    final first = (await rows(db)).first;
    await tapKey(tester, 'past-due-fee-action-${first.id}');
    await tapKey(tester, 'extra-fee-delete');
    expect(find.text('Ek ücret silindi.'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect((await rows(db)).first.extraFeeMinor, isNull);
    expect(find.text('Ek ücret ekle'), findsOneWidget);

    await tester.tap(find.text('Geri al'));
    await tester.pumpAndSettle();
    final back = (await rows(db)).first;
    expect((back.extraFeeMinor, back.extraFeeNote), (600, 'Not'));
    expect(find.text('+ ${tr(600)} ek ücret'), findsOneWidget);
  });

  group('plan details', () {
    testWidgets('the past-due row offers it; the sheet lists it', (
      tester,
    ) async {
      final db = await pumpSofia(tester);
      final payments = await rows(db);
      await openSofia(tester);
      expect(find.byKey(ValueKey('fee-add-${payments[0].id}')), findsOneWidget);
      // Not past due: only in the action sheet.
      expect(find.byKey(ValueKey('fee-add-${payments[1].id}')), findsNothing);
      await tester.tap(find.text('10 Ara 2026'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('payment-extraFee')), findsOneWidget);
      await tapKey(tester, 'payment-extraFee');
      await fillAndSave(tester, '6');
      expect((await rows(db))[1].extraFeeMinor, 600);
      expect(find.text('Ek ücret: ${tr(600)}'), findsOneWidget);
    });

    testWidgets('example 1: a paid payment can take one', (tester) async {
      final db = await pumpSofia(
        tester,
        then: (db, _) async {
          final first = (await rows(db)).first;
          await PlanRepository(db).setPaidOn(first.id, LocalDate(2026, 11, 13));
        },
      );
      await openSofia(tester);
      await tester.tap(find.text('10 Kas 2026'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('payment-edit')), findsNothing);
      await tapKey(tester, 'payment-extraFee');
      await fillAndSave(tester, '6');
      expect((await rows(db)).first.extraFeeMinor, 600);
      expect(find.text('Ek ücret: ${tr(600)}'), findsOneWidget);
      expect(find.text('Ek ücretler: ${tr(600)}'), findsOneWidget);
    });

    testWidgets('closed: no action, the fee stays visible', (tester) async {
      await pumpSofia(
        tester,
        then: (db, id) async {
          final plans = PlanRepository(db);
          final first = (await rows(db)).first;
          await plans.setPaid(first.id, paid: true);
          await plans.setExtraFee(first.id, amountMinor: 600);
          await plans.close(id, reason: CloseReason.refund, today: today);
        },
      );
      await openTab(tester, 'Planlar');
      await tester.tap(find.text('Biten'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sofia'));
      await tester.pumpAndSettle();
      expect(find.text('Ek ücret: ${tr(600)}'), findsOneWidget);
      await tester.tap(find.text('10 Kas 2026'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('payment-sheet')), findsNothing);
    });

    testWidgets('on hold: unpaid payments get no action', (tester) async {
      await pumpSofia(
        tester,
        then: (db, id) => PlanRepository(db).hold(id, today: today),
      );
      await openSofia(tester);
      await tester.tap(find.text('10 Ara 2026'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('payment-sheet')), findsNothing);
      expect(find.text('Ek ücret ekle'), findsNothing);
    });
  });

  testWidgets('example 5: IDR, Rp25.000', (tester) async {
    final idr = Currency.fromCode('IDR');
    await pumpApp(
      tester,
      today: today,
      seed: (db) async {
        await seedSofia(db, currency: 'IDR', total: 2000000);
        final first = (await rows(db)).first;
        await PlanRepository(db).setExtraFee(first.id, amountMinor: 25000);
      },
    );
    expect(find.text('+ ${tr(25000, idr)} ek ücret'), findsOneWidget);
    await openSofia(tester);
    expect(find.text('Ek ücret: ${tr(25000, idr)}'), findsOneWidget);
    expect(tr(25000, idr), contains('25.000'));
  });

  testWidgets('English', (tester) async {
    await pumpApp(
      tester,
      locale: const Locale('en', 'US'),
      today: today,
      seed: (db) async {
        await seedSofia(db);
        final first = (await rows(db)).first;
        await PlanRepository(db).setExtraFee(first.id, amountMinor: 600);
      },
    );
    final en = formatMoney(600, eur, localeName: 'en_US');
    expect(find.text('+ $en extra fee'), findsOneWidget);
    expect(find.text('Edit extra fee'), findsOneWidget);
  });
}
