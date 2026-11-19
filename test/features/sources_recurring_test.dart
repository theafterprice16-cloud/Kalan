import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/engine/engine.dart';
import 'package:kalan/data/db/app_database.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/app_harness.dart';

void main() {
  testWidgets('define a card with statement and due days', (tester) async {
    final db = await pumpApp(tester, seed: seedSettings);
    await openTab(tester, 'Planlar');
    await tester.tap(find.byTooltip('Kaynaklar ve kartlar'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Henüz kaynak yok. Plan eklerken yazdığın kaynaklar burada görünür.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Kaynak ekle'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('source-name')), 'Bonus');
    await tester.tap(find.text('Kredi kartı'));
    await tester.pumpAndSettle();
    await pickDropdown(tester, const ValueKey('statement-day'), '25');
    await pickDropdown(tester, const ValueKey('due-day'), '5');
    await scrollTo(tester, find.byKey(const ValueKey('save-source')));
    await tester.tap(find.byKey(const ValueKey('save-source')));
    await tester.pumpAndSettle();

    expect(
      find.text('Kredi kartı · Ekstre günü 25, son ödeme günü 5'),
      findsOneWidget,
    );
    final card = await db.select(db.sources).getSingle();
    expect(card.kind, SourceKind.card);
    expect(card.shiftDueToBusinessDay, isTrue);
  });

  testWidgets('define a bank account (18): no days, its own empty line', (
    tester,
  ) async {
    final db = await pumpApp(tester, seed: seedSettings);
    await openTab(tester, 'Planlar');
    await tester.tap(find.byTooltip('Kaynaklar ve kartlar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kaynak ekle'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('source-name')),
      'Maaş hesabı',
    );
    await tester.tap(find.text('Banka hesabı'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('statement-day')), findsNothing);
    await scrollTo(tester, find.byKey(const ValueKey('save-source')));
    await tester.tap(find.byKey(const ValueKey('save-source')));
    await tester.pumpAndSettle();

    expect(find.text('Banka hesabı'), findsOneWidget);
    expect(find.text('Hesapta bulunsun'), findsOneWidget);
    expect(
      find.text('Bu dönem bu kaynaktan çıkacak otomatik ödeme yok.'),
      findsOneWidget,
    );
    final account = await db.select(db.sources).getSingle();
    expect(account.kind, SourceKind.account);
    expect(account.statementDay, isNull);
  });

  testWidgets('a source with plans cannot be deleted', (tester) async {
    await pumpApp(
      tester,
      seed: (db) async {
        await seedSettings(db);
        await seedPayIn4(db);
      },
    );
    await openTab(tester, 'Planlar');
    await tester.tap(find.byTooltip('Kaynaklar ve kartlar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Klarna'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Sil'));
    await tester.pumpAndSettle();
    expect(
      find.text('Bu kaynağa bağlı planlar var. Önce o planları sil.'),
      findsOneWidget,
    );
  });

  testWidgets('recurring payment shows up on home and in its tab', (
    tester,
  ) async {
    final db = await pumpApp(
      tester,
      seed: (db) => seedSettings(db, incomeMinor: 5000000),
    );
    await openTab(tester, 'Planlar');
    await tester.tap(find.text('Sabit'));
    await tester.pumpAndSettle();
    expect(
      find.text('Sabit ödeme yok. Kira, fatura ya da abonelik ekleyebilirsin.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Sabit ödeme ekle'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('recurring-name')),
      'Kira',
    );
    await tester.enterText(
      find.byKey(const ValueKey('recurring-amount')),
      '15000',
    );
    await scrollTo(tester, find.byKey(const ValueKey('save-recurring')));
    await tester.tap(find.byKey(const ValueKey('save-recurring')));
    await tester.pumpAndSettle();

    expect(find.text('Kira'), findsOneWidget);
    expect(find.text('Her ay'), findsOneWidget);
    final row = await db.select(db.recurringPayments).getSingle();
    expect(row.recurrence, Recurrence.monthly);
    expect(row.startDay, testToday.epochDay);

    await openTab(tester, 'Bu dönem');
    expect(find.text('₺35.000'), findsOneWidget);
    expect(find.text('Sabit'), findsWidgets);
  });
}
