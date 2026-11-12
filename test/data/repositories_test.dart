import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/engine/engine.dart';
import 'package:kalan/data/db/app_database.dart';
import 'package:kalan/data/models.dart';
import 'package:kalan/data/repositories/plan_repository.dart';
import 'package:kalan/data/repositories/recurring_repository.dart';
import 'package:kalan/data/repositories/settings_repository.dart';
import 'package:kalan/data/repositories/source_repository.dart';

import '../core/date/local_date_test.dart' show d;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late PlanRepository plans;
  late SourceRepository sources;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    plans = PlanRepository(db);
    sources = SourceRepository(db, plans);
  });
  tearDown(() => db.close());

  Future<int> savePayIn4({int total = 10000, String source = 'Klarna'}) async {
    final sourceId = await sources.findOrCreateProvider(source);
    return plans.saveDraft(
      PlanCalculator.payIn4(firstDate: d('2026-11-20'), totalMinor: total),
      sourceId: sourceId,
      origin: PlanOrigin.template,
    );
  }

  test('settings are null until saved, then update', () async {
    final repo = SettingsRepository(db);
    expect(await repo.get(), isNull);
    await repo.save(
      AppSettingsCompanion.insert(
        currencyCode: 'TRY',
        payFrequency: PayFrequency.monthly,
        payDay: const Value(15),
      ),
    );
    await repo.update(
      const AppSettingsCompanion(netIncomeMinor: Value(5000000)),
    );
    final s = await repo.get();
    expect(s!.currencyCode, 'TRY');
    expect(s.payDay, 15);
    expect(s.netIncomeMinor, 5000000);
  });

  test('findOrCreateProvider matches names case-insensitively', () async {
    final a = await sources.findOrCreateProvider('Klarna');
    final b = await sources.findOrCreateProvider(' klarna ');
    expect(a, b);
    expect((await sources.watchAll().first).length, 1);
  });

  test('saved draft round-trips with source and seq order', () async {
    final id = await savePayIn4(total: 10001);
    final all = await plans.watchAll().first;
    expect(all, hasLength(1));
    final p = all.single;
    expect(p.plan.id, id);
    expect(p.displayName, 'Klarna');
    expect(p.payments.map((x) => x.seq), [1, 2, 3, 4]);
    expect(p.payments.map((x) => x.amountMinor), [2501, 2500, 2500, 2500]);
    expect(p.totalMinor, 10001);
    expect(p.isOpen, isTrue);
  });

  test('plan closes when every payment is paid; open count follows', () async {
    await savePayIn4();
    await savePayIn4(source: 'Afterpay');
    expect(await plans.countOpenPlans(), 2);
    final p = (await plans.watchAll().first).first;
    for (final pay in p.payments) {
      await plans.setPaid(pay.id, paid: true);
    }
    expect(await plans.countOpenPlans(), 1);
    final reloaded = (await plans.watchAll().first).first;
    expect(reloaded.isOpen, isFalse);
    expect(reloaded.paidCount, 4);
    await plans.setPaid(reloaded.payments.last.id, paid: false);
    expect(await plans.countOpenPlans(), 2);
  });

  test('editPayment keeps the total and reports rejections', () async {
    final id = await savePayIn4();
    expect(
      await plans.editPayment(
        planId: id,
        seq: 1,
        date: d('2026-11-21'),
        amountMinor: 4000,
      ),
      isNull,
    );
    var p = (await plans.watchAll().first).single;
    expect(p.payments.map((x) => x.amountMinor), [4000, 2000, 2000, 2000]);
    expect(p.payments.first.isEdited, isTrue);
    expect(p.payments.first.date, d('2026-11-21'));
    expect(p.totalMinor, 10000);

    expect(
      await plans.editPayment(
        planId: id,
        seq: 4,
        date: d('2027-01-01'),
        amountMinor: 1,
      ),
      EditRejection.noAbsorbers,
    );
    p = (await plans.watchAll().first).single;
    expect(p.totalMinor, 10000);
  });

  test('changing card days moves unpaid, unedited card payments', () async {
    final cardId = await sources.create(
      name: 'Bonus',
      kind: SourceKind.card,
      statementDay: 25,
      dueDay: 5,
    );
    final card = (await sources.byId(cardId))!;
    final planId = await plans.saveDraft(
      PlanCalculator.card(
        purchaseDate: d('2026-11-20'),
        totalMinor: 30000,
        count: 3,
        terms: card.cardTerms!,
      ),
      sourceId: cardId,
      origin: PlanOrigin.template,
    );
    var p = (await plans.watchAll().first).single;
    expect(p.payments.map((x) => x.date), [
      d('2026-12-07'),
      d('2027-01-05'),
      d('2027-02-05'),
    ]);
    await plans.setPaid(p.payments[0].id, paid: true);
    await plans.editPayment(
      planId: planId,
      seq: 2,
      date: d('2027-01-06'),
      amountMinor: 10000,
    );

    await sources.update(card.copyWith(dueDay: const Value(15)));
    p = (await plans.watchAll().first).single;
    expect(p.payments.map((x) => x.date), [
      d('2026-12-07'), // paid: unchanged
      d('2027-01-06'), // edited: unchanged
      d('2027-02-15'), // moved
    ]);
  });

  test('source with plans cannot be deleted', () async {
    await savePayIn4();
    final source = (await sources.watchAll().first).single;
    expect(await sources.delete(source.id), isFalse);
    final other = await sources.findOrCreateProvider('Zip');
    expect(await sources.delete(other), isTrue);
  });

  test('provider sources drop card days on update', () async {
    final id = await sources.create(
      name: 'Kart',
      kind: SourceKind.card,
      statementDay: 1,
      dueDay: 10,
    );
    final row = (await sources.byId(id))!;
    await sources.update(row.copyWith(kind: SourceKind.provider));
    final updated = (await sources.byId(id))!;
    expect(updated.statementDay, isNull);
    expect(updated.cardTerms, isNull);
  });

  test('recurring payments and paid marks', () async {
    final repo = RecurringRepository(db);
    final id = await repo.create(
      RecurringPaymentsCompanion.insert(
        name: 'Kira',
        amountMinor: 1500000,
        recurrence: Recurrence.monthly,
        startDay: d('2026-01-31').epochDay,
      ),
    );
    final day = d('2026-02-28').epochDay;
    await repo.setPaid(id, day, paid: true);
    var all = await repo.watchAll().first;
    expect(all.single.paidDays, {day});
    expect(all.single.occurrences(d('2026-02-01'), d('2026-04-01')), [
      d('2026-02-28'),
      d('2026-03-31'),
    ]);
    await repo.setPaid(id, day, paid: false);
    all = await repo.watchAll().first;
    expect(all.single.paidDays, isEmpty);
    await repo.delete(id);
    expect(await repo.watchAll().first, isEmpty);
  });
}
