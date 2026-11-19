import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:kalan/core/engine/engine.dart';
import 'package:kalan/data/db/app_database.dart';
import 'package:kalan/data/repositories/plan_repository.dart';
import 'package:kalan/data/repositories/source_repository.dart';

import 'app_harness.dart';

/// "Today" for the statement examples (16): Thursday 19 November 2026.
final statementToday = LocalDate(2026, 11, 19);

/// Card ids of [seedStatements].
typedef StatementCards = ({int ada, int gece, int yedek});

/// Aylin's cards on 19 Nov 2026 (16, Examples 1-4):
///
/// - "Ada Kart", statement 14, due 24, weekend shift on. Its 14 Nov
///   statement is cut and due Tue 24 Nov with three installments,
///   ₺4.150: Telefon 3/6 ₺1.200 (paid), Kulaklık 1/3 ₺1.500 (bought
///   20 Oct) and Ayakkabı 1/2 ₺1.450 (bought on the statement day,
///   14 Nov). A "Pay later" plan paid from the card (Klarna) is not on it.
/// - "Gece Kart", statement 25, due 5: Laptop 12 × ₺2.000 from 10 Nov,
///   first on the 25 Nov statement (due Mon 7 Dec).
/// - "Yedek Kart": a card without installments, no statements shown.
Future<StatementCards> seedStatements(AppDatabase db) async {
  await seedSettings(db, incomeMinor: 4500000);
  final plans = PlanRepository(db);
  final sources = SourceRepository(db, plans);
  final ada = await sources.create(
    name: 'Ada Kart',
    kind: SourceKind.card,
    statementDay: 14,
    dueDay: 24,
  );
  final gece = await sources.create(
    name: 'Gece Kart',
    kind: SourceKind.card,
    statementDay: 25,
    dueDay: 5,
  );
  final yedek = await sources.create(
    name: 'Yedek Kart',
    kind: SourceKind.card,
    statementDay: 1,
    dueDay: 11,
  );
  const adaTerms = CardTerms(statementDay: 14, dueDay: 24);
  const geceTerms = CardTerms(statementDay: 25, dueDay: 5);

  Future<int> card(
    String title,
    int cardId,
    CardTerms terms,
    LocalDate purchase,
    int totalMinor,
    int count,
  ) => plans.saveDraft(
    PlanCalculator.card(
      purchaseDate: purchase,
      totalMinor: totalMinor,
      count: count,
      terms: terms,
    ),
    sourceId: cardId,
    origin: PlanOrigin.template,
    title: title,
  );

  final telefon = await card(
    'Telefon',
    ada,
    adaTerms,
    LocalDate(2026, 9, 1),
    720000,
    6,
  );
  await card('Kulaklık', ada, adaTerms, LocalDate(2026, 10, 20), 450000, 3);
  await card('Ayakkabı', ada, adaTerms, LocalDate(2026, 11, 14), 290000, 2);
  await card('Laptop', gece, geceTerms, LocalDate(2026, 11, 10), 2400000, 12);

  // Telefon's first three installments are paid, the third early.
  await (db.update(db.payments)..where(
        (p) => p.planId.equals(telefon) & p.seq.isSmallerOrEqualValue(3),
      ))
      .write(PaymentsCompanion(paidAt: Value(DateTime(2026, 11, 18))));

  // "Pay later" at Klarna, taken from Ada Kart: not a card installment.
  await plans.saveDraft(
    PlanCalculator.payLater(
      purchaseDate: LocalDate(2026, 11, 2),
      rule: const PayLaterRule.days(30),
      totalMinor: 100000,
    ),
    sourceId: await sources.findOrCreateProvider('Klarna'),
    origin: PlanOrigin.template,
    paymentMethod: PaymentMethod.automatic,
    chargeSourceId: ada,
  );
  return (ada: ada, gece: gece, yedek: yedek);
}
