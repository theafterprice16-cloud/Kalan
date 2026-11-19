import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/engine/engine.dart';
import 'package:kalan/core/money/currency.dart';
import 'package:kalan/core/money/money_format.dart';
import 'package:kalan/data/db/app_database.dart';
import 'package:kalan/data/repositories/plan_repository.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/app_harness.dart';

final eur = Currency.fromCode('EUR');
String tr(int minor) => formatMoney(minor, eur, localeName: 'tr');

/// 300 EUR in 4 x 75 from 20 Nov 2026 (Example 3), the first paid.
Future<int> seedMont(AppDatabase db, {int total = 30000}) async {
  await seedSettings(db, currency: 'EUR');
  final id = await seedPayIn4(db, totalMinor: total, title: 'Mont');
  final first =
      await (db.select(db.payments)
            ..where((p) => p.planId.equals(id))
            ..orderBy([(p) => OrderingTerm.asc(p.seq)]))
          .get();
  await PlanRepository(db).setPaid(first.first.id, paid: true);
  return id;
}

Future<void> openMont(WidgetTester tester) async {
  await openTab(tester, 'Planlar');
  await tester.tap(find.text('Mont'));
  await tester.pumpAndSettle();
}

Future<void> openSheet(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('refund-action')));
  await tester.pumpAndSettle();
}

void expectTarget(WidgetTester tester, Finder f) {
  final size = tester.getSize(f);
  expect(size.width, greaterThanOrEqualTo(48));
  expect(size.height, greaterThanOrEqualTo(48));
}

void main() {
  testWidgets('the sheet: Put on hold, Adjust amount, Close; 48x48 targets', (
    tester,
  ) async {
    await pumpApp(tester, seed: seedMont);
    await openMont(tester);
    expectTarget(tester, find.byKey(const ValueKey('refund-action')));
    expect(find.byTooltip('İade ya da iptal'), findsOneWidget);
    await openSheet(tester);
    expect(find.byKey(const ValueKey('refund-sheet')), findsOneWidget);
    expect(find.text('Beklet'), findsOneWidget);
    expect(
      find.text(
        'İade, iptal ya da itirazın sonucunu beklerken kalan taksitler '
        'hesaba girmez.',
      ),
      findsOneWidget,
    );
    expect(find.text('Tutarı düzelt'), findsOneWidget);
    expect(find.text('Kapat'), findsOneWidget);
    expect(find.text('Yeniden aç'), findsNothing);
    for (final key in ['refund-hold', 'refund-adjust', 'refund-close']) {
      expectTarget(tester, find.byKey(ValueKey(key)));
    }
  });

  testWidgets('put on hold, then reopen (Example 1)', (tester) async {
    final db = await pumpApp(tester, seed: seedMont);
    await openMont(tester);
    await openSheet(tester);
    await tester.tap(find.byKey(const ValueKey('refund-hold')));
    await tester.pumpAndSettle();
    expect(find.text('Plan beklemede.'), findsOneWidget);
    // The plan and each held payment say "On hold", with the pause icon.
    expect(find.byKey(const ValueKey('on-hold-tag')), findsNWidgets(4));
    expect(find.byIcon(Icons.pause_circle_outline), findsNWidgets(4));
    expect(
      find.text('3 taksit beklemede; hesaba ve hatırlatmalara girmiyor.'),
      findsOneWidget,
    );
    final plan = await db.select(db.plans).getSingle();
    expect(plan.status, PlanStatus.onHold);

    // The sheet now offers "Reopen" in place of "Put on hold".
    await openSheet(tester);
    expect(find.text('Beklet'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('refund-reopen')));
    await tester.pumpAndSettle();
    expect(find.text('Plan yeniden açıldı.'), findsOneWidget);
    expect(find.byKey(const ValueKey('on-hold-tag')), findsNothing);
    expect((await db.select(db.plans).getSingle()).status, PlanStatus.open);
  });

  testWidgets('the plan list shows "On hold" with its icon', (tester) async {
    await pumpApp(
      tester,
      seed: (db) async {
        final id = await seedMont(db);
        await PlanRepository(db).hold(id, today: testToday);
      },
    );
    await openTab(tester, 'Planlar');
    expect(find.text('Beklemede'), findsOneWidget);
    expect(find.byIcon(Icons.pause_circle_outline), findsOneWidget);
    // No next date for a plan on hold.
    expect(find.textContaining('Sonraki ödeme'), findsNothing);
  });

  testWidgets('close: a reason first, then the archive shows it '
      '(Example 2)', (tester) async {
    final db = await pumpApp(tester, seed: seedMont);
    await openMont(tester);
    await openSheet(tester);
    await tester.tap(find.byKey(const ValueKey('refund-close')));
    await tester.pumpAndSettle();
    expect(find.text('Planı kapat'), findsOneWidget);
    expect(find.textContaining('Kapatılan plan yeniden açılmaz.'), findsOne);
    // Nothing happens until a reason is chosen.
    await tester.tap(find.byKey(const ValueKey('close-confirm')));
    await tester.pumpAndSettle();
    expect(find.text('Planı kapat'), findsOneWidget);
    expectTarget(tester, find.byKey(const ValueKey('close-reason-refund')));
    await tester.tap(find.byKey(const ValueKey('close-reason-refund')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('close-confirm')));
    await tester.pumpAndSettle();
    expect(find.text('Plan kapatıldı.'), findsOneWidget);
    expect(find.text('Kapatıldı · İade'), findsOneWidget);
    // Read-only: no edit, no return action, only the paid payment.
    expect(find.byKey(const ValueKey('plan-edit')), findsNothing);
    expect(find.byKey(const ValueKey('refund-action')), findsNothing);
    expect(find.byTooltip('Ödendi olarak işaretle'), findsNothing);
    final plan = await db.select(db.plans).getSingle();
    expect(plan.closeReason, CloseReason.refund);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Açık plan yok.'), findsOneWidget);
    await tester.tap(find.text('Biten'));
    await tester.pumpAndSettle();
    expect(find.text('Mont'), findsOneWidget);
    expect(find.text('Kapatıldı · İade'), findsOneWidget);
    // What was paid, not the old total.
    expect(find.text(tr(7500)), findsOneWidget);
  });

  group('adjust amount (Example 3)', () {
    Future<void> openAdjust(WidgetTester tester) async {
      await openMont(tester);
      await openSheet(tester);
      await tester.tap(find.byKey(const ValueKey('refund-adjust')));
      await tester.pumpAndSettle();
    }

    Future<void> type(WidgetTester tester, String text) async {
      await tester.enterText(find.byKey(const ValueKey('adjust-total')), text);
      await tester.pumpAndSettle();
    }

    testWidgets('200: preview 41,66 / 41,66 / 41,68, then saved', (
      tester,
    ) async {
      final db = await pumpApp(tester, seed: seedMont);
      await openAdjust(tester);
      expect(find.text('Şimdiki toplam ${tr(30000)}'), findsOneWidget);
      expect(find.text('Ödediğin ${tr(7500)}'), findsOneWidget);
      final save = find.byKey(const ValueKey('adjust-save'));
      expect(tester.widget<FilledButton>(save).onPressed, isNull);

      await type(tester, '200');
      expect(find.byKey(const ValueKey('adjust-preview')), findsOneWidget);
      expect(find.text(tr(4166)), findsNWidgets(2));
      expect(find.text(tr(4168)), findsOneWidget);
      // Nothing is stored before saving.
      expect(
        [for (final p in await db.select(db.payments).get()) p.amountMinor],
        [7500, 7500, 7500, 7500],
      );
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(find.text('Tutar düzeltildi.'), findsOneWidget);
      final rows = await (db.select(
        db.payments,
      )..orderBy([(p) => OrderingTerm.asc(p.seq)])).get();
      expect([for (final p in rows) p.amountMinor], [7500, 4166, 4166, 4168]);
    });

    testWidgets('150: 25,00 x 3', (tester) async {
      await pumpApp(tester, seed: seedMont);
      await openAdjust(tester);
      await type(tester, '150');
      expect(find.text(tr(2500)), findsNWidgets(3));
    });

    testWidgets('60: less than what was paid, nothing to save', (tester) async {
      await pumpApp(tester, seed: seedMont);
      await openAdjust(tester);
      await type(tester, '60');
      expect(
        find.text('Yeni toplam, ödediğin tutardan (${tr(7500)}) az olamaz.'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('adjust-preview')), findsNothing);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('adjust-save')))
            .onPressed,
        isNull,
      );
    });

    testWidgets('75: nothing left, closing is offered', (tester) async {
      final db = await pumpApp(tester, seed: seedMont);
      await openAdjust(tester);
      await type(tester, '75');
      expect(
        find.text('Kalan taksit kalmıyor. Planı kapatmak ister misin?'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('adjust-close')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('close-reason-cancel')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('close-confirm')));
      await tester.pumpAndSettle();
      final plan = await db.select(db.plans).getSingle();
      expect(plan.status, PlanStatus.closed);
      expect(plan.closeReason, CloseReason.cancel);
      expect(find.text('Kapatıldı · İptal'), findsOneWidget);
    });

    testWidgets('more than the current total is refused', (tester) async {
      await pumpApp(tester, seed: seedMont);
      await openAdjust(tester);
      await type(tester, '301');
      expect(
        find.text(
          'Yeni toplam, şimdiki toplamdan (${tr(30000)}) fazla olamaz.',
        ),
        findsOneWidget,
      );
    });
  });

  group('30 days on hold (Example 4)', () {
    Future<void> held(AppDatabase db) async {
      final id = await seedMont(db);
      // Day 1 of the hold is 22 Oct: 20 Nov is day 30.
      await PlanRepository(db).hold(id, today: LocalDate(2026, 10, 22));
    }

    testWidgets('29th day: no line', (tester) async {
      await pumpApp(tester, seed: held, today: LocalDate(2026, 11, 19));
      await openMont(tester);
      expect(find.byKey(const ValueKey('hold-check')), findsNothing);
    });

    testWidgets('30th day: the line; "Keep on hold" puts it away', (
      tester,
    ) async {
      final db = await pumpApp(tester, seed: held);
      await openMont(tester);
      expect(find.text('Hâlâ iadeyi mi bekliyorsun?'), findsOneWidget);
      expect(find.text('22 Eki tarihinden beri beklemede.'), findsOneWidget);
      for (final key in [
        'hold-check-close',
        'hold-check-reopen',
        'hold-check-keep',
      ]) {
        expectTarget(tester, find.byKey(ValueKey(key)));
      }
      await tester.tap(find.byKey(const ValueKey('hold-check-keep')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('hold-check')), findsNothing);
      expect(find.text('Plan beklemede kalıyor.'), findsOneWidget);
      final plan = await db.select(db.plans).getSingle();
      expect(plan.holdCheckDay, testToday.epochDay);
      expect(plan.status, PlanStatus.onHold);
    });

    testWidgets('"Reopen" from the line: dates that passed are counted', (
      tester,
    ) async {
      await pumpApp(tester, seed: held);
      await openMont(tester);
      await tester.tap(find.byKey(const ValueKey('hold-check-reopen')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('hold-check')), findsNothing);
      // Only 20 Nov (paid) is due by 20 Nov: nothing passed unpaid.
      expect(find.byKey(const ValueKey('passed-while-held')), findsNothing);
    });
  });

  testWidgets('after reopening, payments whose date passed are counted', (
    tester,
  ) async {
    await pumpApp(
      tester,
      today: LocalDate(2026, 12, 10),
      seed: (db) async {
        final id = await seedMont(db);
        final repo = PlanRepository(db);
        await repo.hold(id, today: LocalDate(2026, 11, 21));
        await repo.reopen(id, today: LocalDate(2026, 12, 10));
      },
    );
    await openMont(tester);
    expect(
      find.text(
        'Bekleme sırasında tarihi geçen 1 taksit var. Ödediysen '
        'işaretleyebilirsin.',
      ),
      findsOneWidget,
    );
    // The usual past-due note is back on that payment.
    expect(find.text('6 gün önce'), findsOneWidget);
  });

  testWidgets('a held payment past its date shows no past-due note', (
    tester,
  ) async {
    await pumpApp(
      tester,
      today: LocalDate(2026, 12, 10),
      seed: (db) async {
        final id = await seedMont(db);
        await PlanRepository(db).hold(id, today: LocalDate(2026, 11, 21));
      },
    );
    await openMont(tester);
    expect(find.text('6 gün önce'), findsNothing);
    expect(find.textContaining(RegExp(r'^\d+ gün önce$')), findsNothing);
  });

  testWidgets('twice the text size: nothing overflows', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpApp(
      tester,
      seed: (db) async {
        final id = await seedMont(db);
        await PlanRepository(db).hold(id, today: LocalDate(2026, 10, 22));
      },
    );
    // Plan list with "On hold", then the plan with the 30-day line.
    await openMont(tester);
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('hold-check')), findsOneWidget);
    // The sheet.
    await openSheet(tester);
    expect(tester.takeException(), isNull);
    // The close dialog (the sheet scrolls at this size).
    await tester.ensureVisible(find.byKey(const ValueKey('refund-close')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('refund-close')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();
    // Adjust amount with its preview.
    await openSheet(tester);
    await tester.tap(find.byKey(const ValueKey('refund-adjust')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('adjust-total')), '200');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('English', (tester) async {
    await pumpApp(tester, seed: seedMont, locale: const Locale('en', 'US'));
    await openTab(tester, 'Plans');
    await tester.tap(find.text('Mont'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Return or cancellation'), findsOneWidget);
    await openSheet(tester);
    expect(find.text('Put on hold'), findsOneWidget);
    expect(find.text('Adjust amount'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);
    expect(
      find.text(
        'While you wait for a return, cancellation or dispute, remaining '
        'payments are left out.',
      ),
      findsOneWidget,
    );
  });
}
