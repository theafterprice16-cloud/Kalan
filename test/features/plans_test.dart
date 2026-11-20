import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/app_harness.dart';

void main() {
  testWidgets('edit one payment; the total stays the same', (tester) async {
    final db = await pumpApp(
      tester,
      seed: (db) async {
        await seedSettings(db);
        await seedPayIn4(db);
      },
    );
    await openTab(tester, 'Planlar');
    await tester.tap(find.text('Klarna'));
    await tester.pumpAndSettle();
    expect(find.text('0/4 ödendi'), findsOneWidget);

    await tester.tap(find.text('20 Kas 2026'));
    await tester.pumpAndSettle();
    // The payment sheet (20): the edit is its second option.
    await tester.tap(find.byKey(const ValueKey('payment-edit')));
    await tester.pumpAndSettle();
    expect(find.text('Ödemeyi düzelt'), findsOneWidget);
    // The amount only; dates change with "Change date" (20).
    expect(find.text('Ödeme tarihi'), findsNothing);
    await tester.enterText(find.byKey(const ValueKey('edit-amount')), '160');
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();

    expect(find.text('Ödeme güncellendi.'), findsOneWidget);
    expect(find.text('Düzeltildi'), findsOneWidget);
    final amounts =
        (await (db.select(
          db.payments,
        )..orderBy([(p) => OrderingTerm.asc(p.seq)])).get()).map(
          (p) => p.amountMinor,
        );
    expect(amounts, [16000, 8000, 8000, 8000]);
  });

  testWidgets('last payment cannot take a different amount', (tester) async {
    await pumpApp(
      tester,
      seed: (db) async {
        await seedSettings(db);
        await seedPayIn4(db);
      },
    );
    await openTab(tester, 'Planlar');
    await tester.tap(find.text('Klarna'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1 Oca 2027'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('payment-edit')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('edit-amount')), '50');
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Farkı alacak sonraki ödeme yok. Bu taksitin tutarı tek başına '
        'değiştirilemez.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('a fully paid plan moves to the archive', (tester) async {
    await pumpApp(
      tester,
      seed: (db) async {
        await seedSettings(db);
        await seedPayIn4(db, title: 'Telefon');
      },
    );
    await openTab(tester, 'Planlar');
    expect(find.text('Telefon'), findsOneWidget);
    await tester.tap(find.text('Telefon'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.byTooltip('Ödendi olarak işaretle').first);
      await tester.pumpAndSettle();
    }
    expect(find.text('4/4 ödendi'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Açık plan yok.'), findsOneWidget);
    await tester.tap(find.text('Biten'));
    await tester.pumpAndSettle();
    expect(find.text('Telefon'), findsOneWidget);
  });

  testWidgets('delete a plan after confirming', (tester) async {
    final db = await pumpApp(
      tester,
      seed: (db) async {
        await seedSettings(db);
        await seedPayIn4(db);
      },
    );
    await openTab(tester, 'Planlar');
    await tester.tap(find.text('Klarna'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Planı sil'));
    await tester.pumpAndSettle();
    expect(find.text('Bu plan ve bütün ödemeleri silinecek.'), findsOneWidget);
    await tester.tap(find.text('Sil'));
    await tester.pumpAndSettle();
    expect(find.text('Plan silindi.'), findsOneWidget);
    // Back on the Plans tab: above its "Add plan" button.
    expect(
      tester.getRect(find.byType(SnackBar)).bottom,
      lessThanOrEqualTo(tester.getRect(find.byType(FloatingActionButton)).top),
    );
    expect(await db.select(db.plans).get(), isEmpty);
    expect(await db.select(db.payments).get(), isEmpty);
  });
}
