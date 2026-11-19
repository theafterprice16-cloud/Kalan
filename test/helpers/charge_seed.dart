import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:kalan/core/engine/engine.dart';
import 'package:kalan/data/db/app_database.dart';
import 'package:kalan/data/repositories/plan_repository.dart';
import 'package:kalan/data/repositories/recurring_repository.dart';
import 'package:kalan/data/repositories/source_repository.dart';

import 'app_harness.dart';

/// "Today" of the "keep in account" examples (18): Sunday 15 November
/// 2026, the first day of the 15 Nov - 14 Dec pay period.
final chargeToday = LocalDate(2026, 11, 15);

/// Source and plan ids of [seedCharges].
typedef ChargeSeed = ({
  int maas,
  int bonus,
  int bos,
  int telefon,
  int ayakkabi,
});

/// Naz on 15 Nov 2026 (18, Examples 1 and 4):
///
/// - "Maaş hesabı", a bank account: Telefon taksiti ₺1.400 and Spor
///   salonu ₺1.000 on 18 Nov, Laptop taksiti ₺1.500 on 25 Nov, all
///   automatic; Kulaklık taksiti ₺800 on 20 Nov paid by hand (not
///   counted). Telefon's second installment, 18 Dec, is next period's.
///   Spor salonu is a "Pay later" plan here: recurring payments have no
///   payment method or source, so they never count (decision 4); the
///   recurring "Kira" on 1 Dec shows that.
/// - "Bonus Kart": a "Pay later" plan at Klarna taken from it on 5 Dec,
///   ₺600, and the card's own installments (on its statements, not here).
/// - "Boş hesap": a bank account nothing is taken from.
/// - "Ayakkabı": automatic, no source chosen.
Future<ChargeSeed> seedCharges(
  AppDatabase db, {
  String currency = 'TRY',
}) async {
  await seedSettings(db, currency: currency);
  final plans = PlanRepository(db);
  final sources = SourceRepository(db, plans);
  final maas = await sources.create(
    name: 'Maaş hesabı',
    kind: SourceKind.account,
  );
  final bonus = await sources.create(
    name: 'Bonus Kart',
    kind: SourceKind.card,
    statementDay: 14,
    dueDay: 24,
  );
  final bos = await sources.create(name: 'Boş hesap', kind: SourceKind.account);
  final provider = await sources.findOrCreateProvider('Klarna');

  Future<int> once(
    String title,
    LocalDate due,
    int minor, {
    PaymentMethod? method = PaymentMethod.automatic,
    int? from,
  }) => plans.saveDraft(
    PlanCalculator.payLater(
      purchaseDate: chargeToday.addDays(-1),
      rule: const PayLaterRule.chosenDate(),
      chosenDate: due,
      totalMinor: minor,
    ),
    sourceId: provider,
    origin: PlanOrigin.template,
    title: title,
    paymentMethod: method,
    chargeSourceId: from,
  );

  final telefon = await plans.saveDraft(
    PlanCalculator.monthly(
      firstDate: LocalDate(2026, 11, 18),
      totalMinor: 420000,
      count: 3,
    ),
    sourceId: provider,
    origin: PlanOrigin.template,
    title: 'Telefon taksiti',
    paymentMethod: PaymentMethod.automatic,
    chargeSourceId: maas,
  );
  await once('Spor salonu', LocalDate(2026, 11, 18), 100000, from: maas);
  await once('Laptop taksiti', LocalDate(2026, 11, 25), 150000, from: maas);
  await once(
    'Kulaklık taksiti',
    LocalDate(2026, 11, 20),
    80000,
    method: PaymentMethod.manual,
    from: null,
  );
  await once('Klarna', LocalDate(2026, 12, 5), 60000, from: bonus);
  await plans.saveDraft(
    PlanCalculator.card(
      purchaseDate: LocalDate(2026, 11, 2),
      totalMinor: 300000,
      count: 3,
      terms: const CardTerms(statementDay: 14, dueDay: 24),
    ),
    sourceId: bonus,
    origin: PlanOrigin.template,
    title: 'Kart taksidi',
    paymentMethod: PaymentMethod.automatic,
  );
  final ayakkabi = await once('Ayakkabı', LocalDate(2026, 12, 2), 45000);
  await RecurringRepository(db).create(
    RecurringPaymentsCompanion.insert(
      name: 'Kira',
      amountMinor: 1200000,
      recurrence: Recurrence.monthly,
      startDay: LocalDate(2026, 12, 1).epochDay,
    ),
  );
  return (
    maas: maas,
    bonus: bonus,
    bos: bos,
    telefon: telefon,
    ayakkabi: ayakkabi,
  );
}

/// Example 2: Telefon taksiti's 18 Nov installment is paid (the day is
/// then 19 Nov).
Future<void> payFirstTelefon(AppDatabase db, int telefon) =>
    (db.update(db.payments)
          ..where((p) => p.planId.equals(telefon) & p.seq.equals(1)))
        .write(PaymentsCompanion(paidAt: Value(DateTime(2026, 11, 18))));
