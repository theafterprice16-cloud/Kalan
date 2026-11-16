import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/engine/engine.dart';
import 'package:kalan/data/db/app_database.dart';
import 'package:kalan/data/models.dart';
import 'package:kalan/data/repositories/plan_repository.dart';
import 'package:kalan/data/repositories/source_repository.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/app_harness.dart';

/// Mehmet's day: Friday 13 November 2026, paid on the 1st (period 1–30 Nov).
final today = LocalDate(2026, 11, 13);

Future<AppDatabase> pumpMehmet(
  WidgetTester tester, {
  Future<void> Function(AppDatabase db)? extra,
}) => pumpApp(
  tester,
  today: today,
  seed: (db) async {
    await seedSettings(db, incomeMinor: 5000000, payDay: 1);
    await extra?.call(db);
  },
);

Future<void> openAddPlan(WidgetTester tester) async {
  await tester.tap(find.text('Plan ekle'));
  await tester.pumpAndSettle();
}

Future<void> chooseMode(WidgetTester tester, String label) async {
  await tester.tap(find.widgetWithText(ChoiceChip, label));
  await tester.pumpAndSettle();
}

Future<void> tapKey(WidgetTester tester, String key) async {
  final f = find.byKey(ValueKey(key));
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

/// Saves the edit screen. A focused field would scroll itself back into
/// view, so the keyboard is closed first.
Future<void> saveEdit(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tapKey(tester, 'save-plan-edit');
}

/// Types a date into the platform picker ("05.12.2026" in Turkish).
Future<void> pickDate(WidgetTester tester, String key, String text) async {
  await tapKey(tester, key);
  await tester.tap(find.byIcon(Icons.edit_outlined));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField).last, text);
  await tester.tap(find.text('Tamam'));
  await tester.pumpAndSettle();
}

Future<List<PaymentRow>> paymentsOf(AppDatabase db) =>
    (db.select(db.payments)..orderBy([(p) => OrderingTerm.asc(p.seq)])).get();

void main() {
  testWidgets('switch off: the add screen is as before', (tester) async {
    await pumpMehmet(tester);
    await openAddPlan(tester);
    for (final mode in ['4 ödemeli plan', 'Aylık taksit', 'Elle giriş']) {
      await chooseMode(tester, mode);
      final toggle = find.byKey(const ValueKey('underway'));
      expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
      expect(find.text('Bu plan zaten sürüyor'), findsOneWidget);
      expect(find.byKey(const ValueKey('paid-count')), findsNothing);
      expect(find.byKey(const ValueKey('next-date')), findsNothing);
      expect(find.byKey(const ValueKey('first-date')), findsOneWidget);
    }
  });

  testWidgets('Mehmet: 10 payments, 3 paid before Kalan, 7 to go', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final db = await pumpMehmet(tester);
    await openAddPlan(tester);
    await chooseMode(tester, 'Aylık taksit');
    await tester.enterText(find.byKey(const ValueKey('source')), 'Telefon');
    await tester.enterText(find.byKey(const ValueKey('total')), '8500');
    await tester.enterText(find.byKey(const ValueKey('count')), '10');
    await tapKey(tester, 'underway');
    expect(
      find.text('Daha önce ödediğin taksitleri tek tek girmen gerekmez.'),
      findsOneWidget,
    );
    expect(find.text('Toplam taksit'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('paid-count')), '3');
    await pickDate(tester, 'next-date', '05.12.2026');
    expect(find.text('Sıradaki ödeme tarihi'), findsOneWidget);
    expect(find.byKey(const ValueKey('first-date')), findsNothing);

    // The preview lists the 7 to go and sums up the 3 paid, without dates.
    await scrollTo(tester, find.byKey(const ValueKey('preview-summary')));
    expect(find.text('7 ödeme, toplam ₺5.950.'), findsOneWidget);
    expect(
      find.text("3 taksit Kalan'dan önce ödendi · ₺2.550"),
      findsOneWidget,
    );
    expect(find.text('1/10'), findsNothing);
    expect(find.text('4/10'), findsOneWidget);

    await scrollTo(tester, find.byKey(const ValueKey('save-plan')));
    await tester.tap(find.byKey(const ValueKey('save-plan')));
    await tester.pumpAndSettle();

    final rows = await paymentsOf(db);
    expect(rows, hasLength(10));
    expect(
      [for (final r in rows) r.paidBeforeKalan],
      [
        true, true, true, false, false, false, false, false, false, false, //
      ],
    );
    expect(
      [for (final r in rows.take(4)) LocalDate.fromEpochDay(r.dueDay)],
      [
        LocalDate(2026, 9, 5),
        LocalDate(2026, 10, 5),
        LocalDate(2026, 11, 5),
        LocalDate(2026, 12, 5),
      ],
    );
    expect(rows.every((r) => r.amountMinor == 85000), isTrue);

    // Home: 5 Nov (paid before Kalan) counts in this period's spoken-for
    // total but is not listed; nothing is overdue.
    expect(find.text('Söz verilmiş ₺850'), findsOneWidget);
    expect(find.text('Telefon'), findsNothing);
    expect(find.byKey(const ValueKey('overdue-badge')), findsNothing);
    expect(find.text('Gecikti'), findsNothing);

    // Plans list: progress as on the statement.
    await openTab(tester, 'Planlar');
    expect(find.text('3/10 ödendi'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('10 taksitten 3 tanesi ödendi')),
      findsWidgets,
    );

    // Plan detail: one summary line, 7 payment rows.
    await tester.tap(find.text('Telefon'));
    await tester.pumpAndSettle();
    expect(find.text('3/10 ödendi'), findsOneWidget);
    await scrollTo(tester, find.byKey(const ValueKey('paid-before-summary')));
    expect(
      find.text("3 taksit Kalan'dan önce ödendi · ₺2.550"),
      findsOneWidget,
    );
    expect(find.text('1/10'), findsNothing);
    expect(find.text('3/10'), findsNothing);
    await scrollTo(tester, find.text('10/10'));
    expect(find.text('4/10'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('validation: at least 1, fewer than the total', (tester) async {
    await pumpMehmet(tester);
    await openAddPlan(tester);
    await chooseMode(tester, 'Aylık taksit');
    await tester.enterText(find.byKey(const ValueKey('source')), 'Telefon');
    await tester.enterText(find.byKey(const ValueKey('total')), '8500');
    await tester.enterText(find.byKey(const ValueKey('count')), '10');
    await tapKey(tester, 'underway');
    for (final (input, message) in [
      ('10', 'Bütün taksitler ödendiyse bu planı eklemene gerek yok.'),
      ('12', 'Bütün taksitler ödendiyse bu planı eklemene gerek yok.'),
      ('0', 'Kaç taksit ödediğini yaz, en az 1.'),
      ('', 'Kaç taksit ödediğini yaz, en az 1.'),
    ]) {
      await scrollTo(tester, find.byKey(const ValueKey('paid-count')));
      await tester.enterText(find.byKey(const ValueKey('paid-count')), input);
      await scrollTo(tester, find.byKey(const ValueKey('save-plan')));
      await tester.tap(find.byKey(const ValueKey('save-plan')));
      await tester.pumpAndSettle();
      await scrollTo(tester, find.text(message));
      expect(find.text(message), findsOneWidget, reason: input);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 3000));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('card: the next date comes from the card, and can change', (
    tester,
  ) async {
    final db = await pumpMehmet(tester, extra: seedCard);
    await openAddPlan(tester);
    await chooseMode(tester, 'Kredi kartı taksidi');
    await tester.tap(find.byKey(const ValueKey('card')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bonus').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('total')), '9000');
    await tester.enterText(find.byKey(const ValueKey('count')), '9');
    expect(find.byKey(const ValueKey('purchase-date')), findsOneWidget);
    await tapKey(tester, 'underway');
    expect(find.byKey(const ValueKey('purchase-date')), findsNothing);
    // Statement 25th, due 5th: 5 Dec 2026 is a Saturday -> Monday 7 Dec.
    expect(find.text('7 Ara 2026'), findsOneWidget);
    expect(find.text('Kartının kesim gününe göre önerildi.'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('paid-count')), '4');
    await tester.pumpAndSettle();

    await pickDate(tester, 'next-date', '05.01.2027');
    expect(find.text('Kartının kesim gününe göre önerildi.'), findsNothing);
    await scrollTo(tester, find.byKey(const ValueKey('save-plan')));
    await tester.tap(find.byKey(const ValueKey('save-plan')));
    await tester.pumpAndSettle();
    final rows = await paymentsOf(db);
    expect(rows, hasLength(9));
    expect(rows.where((r) => r.paidBeforeKalan), hasLength(4));
    expect(LocalDate.fromEpochDay(rows[4].dueDay), LocalDate(2027, 1, 5));
    final plan = await db.select(db.plans).getSingle();
    expect((plan.kind, plan.purchaseDay), (PlanKind.card, null));
  });

  testWidgets('Pay in 4: no total field, 1 to 3 paid', (tester) async {
    final db = await pumpMehmet(tester);
    await openAddPlan(tester);
    await tester.enterText(find.byKey(const ValueKey('source')), 'Klarna');
    await tester.enterText(find.byKey(const ValueKey('total')), '400');
    await tapKey(tester, 'underway');
    expect(find.byKey(const ValueKey('count')), findsNothing);
    expect(find.byKey(const ValueKey('paid-count')), findsNothing);
    for (final n in ['1', '2', '3']) {
      expect(find.widgetWithText(ChoiceChip, n), findsOneWidget);
    }
    await tester.tap(find.widgetWithText(ChoiceChip, '2'));
    await pickDate(tester, 'next-date', '20.11.2026');
    await scrollTo(tester, find.byKey(const ValueKey('save-plan')));
    await tester.tap(find.byKey(const ValueKey('save-plan')));
    await tester.pumpAndSettle();
    final rows = await paymentsOf(db);
    expect(
      [for (final r in rows) LocalDate.fromEpochDay(r.dueDay)],
      [
        LocalDate(2026, 10, 23),
        LocalDate(2026, 11, 6),
        LocalDate(2026, 11, 20),
        LocalDate(2026, 12, 4),
      ],
    );
    expect(
      [for (final r in rows) r.paidBeforeKalan],
      [true, true, false, false],
    );
    await openTab(tester, 'Planlar');
    expect(find.text('2/4 ödendi'), findsOneWidget);
  });

  testWidgets('manual entry: only the paid field; dates as entered', (
    tester,
  ) async {
    final db = await pumpMehmet(tester);
    await openAddPlan(tester);
    await chooseMode(tester, 'Elle giriş');
    await tester.enterText(find.byKey(const ValueKey('source')), 'Mağaza');
    await tester.enterText(find.byKey(const ValueKey('total')), '600');
    await tester.enterText(find.byKey(const ValueKey('count')), '6');
    await tapKey(tester, 'underway');
    expect(find.byKey(const ValueKey('paid-count')), findsOneWidget);
    expect(find.byKey(const ValueKey('count')), findsOneWidget);
    expect(find.byKey(const ValueKey('step')), findsOneWidget);
    expect(find.byKey(const ValueKey('next-date')), findsNothing);
    expect(find.byKey(const ValueKey('first-date')), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('paid-count')), '2');
    await tester.pumpAndSettle();
    await scrollTo(tester, find.byKey(const ValueKey('save-plan')));
    await tester.tap(find.byKey(const ValueKey('save-plan')));
    await tester.pumpAndSettle();
    final rows = await paymentsOf(db);
    expect(LocalDate.fromEpochDay(rows.first.dueDay), today);
    expect(
      [for (final r in rows) r.paidBeforeKalan],
      [
        true, true, false, false, false, false, //
      ],
    );
  });

  testWidgets('the free limit applies to plans already underway too', (
    tester,
  ) async {
    await pumpMehmet(
      tester,
      extra: (db) async {
        final plans = PlanRepository(db);
        final source = await SourceRepository(
          db,
          plans,
        ).findOrCreateProvider('Klarna');
        for (var i = 0; i < 4; i++) {
          await plans.saveDraft(
            underwayPlan(
              kind: PlanKind.monthly,
              totalMinor: 10000,
              count: 10,
              paidCount: 3,
              nextDate: LocalDate(2026, 12, 5),
            ),
            sourceId: source,
            origin: PlanOrigin.template,
          );
        }
      },
    );
    await openAddPlan(tester);
    expect(
      find.text(
        'Ücretsiz sürümde en çok 4 açık plan olur. '
        'Bir plan bitince yenisini ekleyebilirsin.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('underway')), findsNothing);
  });

  group('editing', () {
    /// Example 5: 10 payments, 3 paid before Kalan, the 4th marked paid.
    Future<AppDatabase> pumpExample5(WidgetTester tester) => pumpMehmet(
      tester,
      extra: (db) async {
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
        );
        final fourth = (await paymentsOf(db))[3];
        await plans.setPaid(fourth.id, paid: true, now: DateTime(2026, 11, 2));
      },
    );

    Future<void> openEdit(WidgetTester tester) async {
      await openTab(tester, 'Planlar');
      await tester.tap(find.text('Telefon'));
      await tester.pumpAndSettle();
      expect(find.text('4/10 ödendi'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('plan-edit')));
      await tester.pumpAndSettle();
      expect(find.text('Planı düzenle'), findsOneWidget);
    }

    testWidgets('filled in; at most the payments not marked in Kalan', (
      tester,
    ) async {
      final db = await pumpExample5(tester);
      await openEdit(tester);
      final toggle = find.byKey(const ValueKey('underway'));
      expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
      expect(find.text('3'), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('paid-count')), '4');
      await saveEdit(tester);
      await tester.ensureVisible(find.byKey(const ValueKey('paid-count')));
      await tester.pumpAndSettle();
      expect(find.text('Burada en fazla 3 olabilir.'), findsOneWidget);
      final rows = await paymentsOf(db);
      expect(rows.where((r) => r.paidBeforeKalan), hasLength(3));
    });

    testWidgets('lowering asks first and never touches the 4th', (
      tester,
    ) async {
      final db = await pumpExample5(tester);
      final marked = (await paymentsOf(db))[3].paidAt;
      await openEdit(tester);
      await tester.enterText(find.byKey(const ValueKey('paid-count')), '1');
      await saveEdit(tester);
      expect(
        find.text('2 taksit ödenmemiş olarak geri gelecek.'),
        findsOneWidget,
      );
      // Cancel keeps everything.
      await tester.tap(find.text('Vazgeç'));
      await tester.pumpAndSettle();
      expect(
        (await paymentsOf(db)).where((r) => r.paidBeforeKalan),
        hasLength(3),
      );

      await tapKey(tester, 'save-plan-edit');
      await tester.tap(find.byKey(const ValueKey('underway-revert-confirm')));
      await tester.pumpAndSettle();
      final rows = await paymentsOf(db);
      expect(
        [for (final r in rows.take(4)) r.paidBeforeKalan],
        [true, false, false, false],
      );
      expect(rows[3].paidAt, marked);
      expect(find.text('2/10 ödendi'), findsOneWidget);
      // Back as unpaid in the past: shown as overdue by the usual rule.
      await tester.tap(find.byType(BackButtonIcon));
      await tester.pumpAndSettle();
      await openTab(tester, 'Bu dönem');
      expect(find.text('Günü geçen 2 ödeme'), findsOneWidget);
    });

    testWidgets('switching it off brings all of them back', (tester) async {
      final db = await pumpExample5(tester);
      await openEdit(tester);
      await tapKey(tester, 'underway');
      await tapKey(tester, 'save-plan-edit');
      expect(
        find.text('3 taksit ödenmemiş olarak geri gelecek.'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('underway-revert-confirm')));
      await tester.pumpAndSettle();
      final rows = await paymentsOf(db);
      expect(rows.where((r) => r.paidBeforeKalan), isEmpty);
      expect(rows[3].paidAt, isNotNull);
    });

    testWidgets('the total installments change; the plan total stays', (
      tester,
    ) async {
      final db = await pumpExample5(tester);
      await openEdit(tester);
      expect(
        find.text(
          'Plan toplamı aynı kalır; ödenmemiş taksitler yeniden bölünür.',
        ),
        findsOneWidget,
      );
      // Below the payment marked paid in Kalan (the 4th): refused.
      await tester.enterText(
        find.byKey(const ValueKey('total-installments')),
        '4',
      );
      await tapKey(tester, 'save-plan-edit');
      expect(
        find.text('Burada en az 5 olabilir; ödenmiş taksitler kalır.'),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const ValueKey('total-installments')),
        '12',
      );
      await tapKey(tester, 'save-plan-edit');
      final rows = await paymentsOf(db);
      expect(rows, hasLength(12));
      expect(rows.fold(0, (s, r) => s + r.amountMinor), 850000);
      expect(find.text('4/12 ödendi'), findsOneWidget);
      expect(find.text('Toplam ₺8.500'), findsOneWidget);
    });

    testWidgets('the interval changes only what is not paid in Kalan', (
      tester,
    ) async {
      final db = await pumpExample5(tester);
      await openEdit(tester);
      final sameDay = find.widgetWithText(ChoiceChip, 'Her ayın aynı günü');
      await tester.ensureVisible(sameDay);
      expect(tester.widget<ChoiceChip>(sameDay).selected, isTrue);
      expect(
        find.text('Yalnızca ödenmemiş taksitlerin tarihi değişir.'),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(ChoiceChip, '30 günde bir'));
      await tester.pumpAndSettle();
      await tapKey(tester, 'save-plan-edit');
      final rows = await paymentsOf(db);
      // The 4th (5 Dec, marked paid in Kalan) stays; the rest follow it.
      expect(rows.map((r) => r.date), [
        LocalDate(2026, 9, 6),
        LocalDate(2026, 10, 6),
        LocalDate(2026, 11, 5),
        LocalDate(2026, 12, 5),
        LocalDate(2027, 1, 4),
        LocalDate(2027, 2, 3),
        LocalDate(2027, 3, 5),
        LocalDate(2027, 4, 4),
        LocalDate(2027, 5, 4),
        LocalDate(2027, 6, 3),
      ]);
      expect(rows.where((r) => r.isPaid), hasLength(4));
      final plan = await db.select(db.plans).getSingle();
      expect(plan.intervalDays, 30);
    });

    testWidgets('a plain plan can be marked as underway later', (tester) async {
      final db = await pumpMehmet(
        tester,
        extra: (db) => seedPayIn4(db, first: LocalDate(2026, 10, 1)),
      );
      await openTab(tester, 'Planlar');
      await tester.tap(find.text('Klarna'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('plan-edit')));
      await tester.pumpAndSettle();
      await tapKey(tester, 'underway');
      await tester.tap(find.widgetWithText(ChoiceChip, '2'));
      await tester.pumpAndSettle();
      await tapKey(tester, 'save-plan-edit');
      final rows = await paymentsOf(db);
      expect(
        [for (final r in rows) r.paidBeforeKalan],
        [true, true, false, false],
      );
      expect(find.text('2/4 ödendi'), findsOneWidget);
    });
  });
}
