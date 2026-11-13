import 'package:drift/drift.dart';

import '../../core/engine/engine.dart';
import '../db/app_database.dart';
import '../models.dart';

class PlanRepository {
  PlanRepository(this._db);

  final AppDatabase _db;

  /// Every plan with its source and payments. Re-emits on any change to
  /// plans, payments or sources.
  JoinedSelectStatement<HasResultSet, dynamic> _allQuery() =>
      _db.select(_db.payments).join([
        innerJoin(_db.plans, _db.plans.id.equalsExp(_db.payments.planId)),
        innerJoin(_db.sources, _db.sources.id.equalsExp(_db.plans.sourceId)),
      ])..orderBy([
        OrderingTerm.asc(_db.plans.id),
        OrderingTerm.asc(_db.payments.seq),
      ]);

  List<PlanWithPayments> _group(List<TypedResult> rows) {
    final byPlan = <int, PlanWithPayments>{};
    final payments = <int, List<PaymentRow>>{};
    for (final row in rows) {
      final plan = row.readTable(_db.plans);
      byPlan.putIfAbsent(
        plan.id,
        () => PlanWithPayments(
          plan: plan,
          source: row.readTable(_db.sources),
          payments: payments.putIfAbsent(plan.id, () => []),
        ),
      );
      payments[plan.id]!.add(row.readTable(_db.payments));
    }
    return byPlan.values.toList();
  }

  /// Every plan with its source and payments. Re-emits on any change to
  /// plans, payments or sources.
  Stream<List<PlanWithPayments>> watchAll() => _allQuery().watch().map(_group);

  /// One-off read (reminders, background isolates).
  Future<List<PlanWithPayments>> all() async => _group(await _allQuery().get());

  Stream<PlanWithPayments?> watchPlan(int planId) => watchAll().map((plans) {
    for (final p in plans) {
      if (p.plan.id == planId) return p;
    }
    return null;
  });

  Future<int> countOpenPlans() async {
    final unpaid = _db.payments.paidAt.isNull();
    final query = _db.selectOnly(_db.payments, distinct: true)
      ..addColumns([_db.payments.planId])
      ..where(unpaid);
    return (await query.get()).length;
  }

  /// Stores a confirmed draft. Returns the new plan id.
  Future<int> saveDraft(
    PlanDraft draft, {
    required int sourceId,
    required PlanOrigin origin,
    String? title,
  }) => _db.transaction(() async {
    final trimmed = title?.trim();
    final planId = await _db
        .into(_db.plans)
        .insert(
          PlansCompanion.insert(
            sourceId: sourceId,
            title: Value((trimmed?.isEmpty ?? true) ? null : trimmed),
            kind: draft.kind,
            installmentCount: draft.installmentCount,
            purchaseDay: Value(draft.purchaseDate?.epochDay),
            deferMonths: Value(draft.deferMonths),
            isCashAdvance: Value(draft.isCashAdvance),
            origin: origin,
          ),
        );
    await _db.batch((b) {
      b.insertAll(_db.payments, [
        for (final p in draft.payments)
          PaymentsCompanion.insert(
            planId: planId,
            seq: p.seq,
            dueDay: p.date.epochDay,
            amountMinor: p.amountMinor,
          ),
      ]);
    });
    return planId;
  });

  Future<void> setPaid(int paymentId, {required bool paid, DateTime? now}) =>
      (_db.update(_db.payments)..where((p) => p.id.equals(paymentId))).write(
        PaymentsCompanion(paidAt: Value(paid ? (now ?? DateTime.now()) : null)),
      );

  /// Changes one payment; returns the reason when the edit is not allowed.
  Future<EditRejection?> editPayment({
    required int planId,
    required int seq,
    required LocalDate date,
    required int amountMinor,
  }) => _db.transaction(() async {
    final rows =
        await (_db.select(_db.payments)
              ..where((p) => p.planId.equals(planId))
              ..orderBy([(p) => OrderingTerm.asc(p.seq)]))
            .get();
    final result = applyPaymentEdit(
      [for (final r in rows) r.toState()],
      seq: seq,
      date: date,
      amountMinor: amountMinor,
    );
    switch (result) {
      case EditRejected(:final reason):
        return reason;
      case EditApplied(:final payments):
        for (var i = 0; i < rows.length; i++) {
          final before = rows[i];
          final after = payments[i];
          if (before.toState() == after) continue;
          await (_db.update(
            _db.payments,
          )..where((p) => p.id.equals(before.id))).write(
            PaymentsCompanion(
              dueDay: Value(after.date.epochDay),
              amountMinor: Value(after.amountMinor),
              isEdited: Value(after.isEdited),
            ),
          );
        }
        return null;
    }
  });

  /// The plan's reminder choice: off when [enabled] is false, otherwise its
  /// own [leadDays] or, when null, the global setting.
  Future<void> setReminderChoice(
    int planId, {
    required bool enabled,
    int? leadDays,
  }) => (_db.update(_db.plans)..where((p) => p.id.equals(planId))).write(
    PlansCompanion(
      remindersEnabled: Value(enabled),
      reminderLeadDays: Value(leadDays),
    ),
  );

  Future<void> deletePlan(int planId) =>
      (_db.delete(_db.plans)..where((p) => p.id.equals(planId))).go();

  /// Moves unpaid, unedited payments of a card's plans to new dates.
  Future<void> recomputeCardPlans({
    required int sourceId,
    required CardTerms oldTerms,
    required CardTerms newTerms,
  }) => _db.transaction(() async {
    final plans =
        await (_db.select(_db.plans)..where(
              (p) =>
                  p.sourceId.equals(sourceId) &
                  p.kind.equalsValue(PlanKind.card),
            ))
            .get();
    for (final plan in plans) {
      final rows =
          await (_db.select(_db.payments)
                ..where((p) => p.planId.equals(plan.id))
                ..orderBy([(p) => OrderingTerm.asc(p.seq)]))
              .get();
      final dates = PlanCalculator.recomputeCardDates(
        payments: [
          for (final r in rows)
            DraftPayment(seq: r.seq, date: r.date, amountMinor: r.amountMinor),
        ],
        installmentCount: plan.installmentCount,
        oldTerms: oldTerms,
        newTerms: newTerms,
        purchaseDate: plan.purchaseDay == null
            ? null
            : LocalDate.fromEpochDay(plan.purchaseDay!),
        deferMonths: plan.deferMonths,
      );
      for (final r in rows) {
        if (r.isPaid || r.isEdited) continue;
        final next = dates[r.seq];
        if (next == null || next.epochDay == r.dueDay) continue;
        await (_db.update(_db.payments)..where((p) => p.id.equals(r.id))).write(
          PaymentsCompanion(dueDay: Value(next.epochDay)),
        );
      }
    }
  });
}
