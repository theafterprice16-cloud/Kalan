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

  /// Stores a confirmed draft. Returns the new plan id. The draft's first
  /// [PlanDraft.paidBeforeCount] payments are stored as paid before Kalan.
  Future<int> saveDraft(
    PlanDraft draft, {
    required int sourceId,
    required PlanOrigin origin,
    String? title,
    DateTime? now,
  }) => _db.transaction(() async {
    final paidAt = now ?? DateTime.now();
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
        for (final (i, p) in draft.payments.indexed)
          PaymentsCompanion.insert(
            planId: planId,
            seq: p.seq,
            dueDay: p.date.epochDay,
            amountMinor: p.amountMinor,
            paidAt: Value(i < draft.paidBeforeCount ? paidAt : null),
            paidBeforeKalan: Value(i < draft.paidBeforeCount),
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

  /// "This plan is already underway", changed later. The first [count]
  /// payments of the plan's leading run (payments not marked paid in Kalan)
  /// become paid before Kalan; the rest of that run becomes unpaid again.
  /// Payments marked paid in Kalan are never touched.
  ///
  /// With [nextDate] and [pattern], payment number `count + 1` moves to
  /// [nextDate] and the other payments that are not paid in Kalan and not
  /// edited by hand follow the plan's own pattern ([underwayDates]).
  Future<void> setPaidBefore(
    int planId, {
    required int count,
    LocalDate? nextDate,
    UnderwayPattern? pattern,
    DateTime? now,
  }) => _db.transaction(() async {
    final rows =
        await (_db.select(_db.payments)
              ..where((p) => p.planId.equals(planId))
              ..orderBy([(p) => OrderingTerm.asc(p.seq)]))
            .get();
    if (count < 0 || count > maxPaidBeforeOf(rows)) {
      throw ArgumentError.value(count, 'count', 'outside 0..max');
    }
    final paidAt = now ?? DateTime.now();
    final run = leadingRunOf(rows);
    final dates = nextDate == null || pattern == null
        ? null
        : underwayDates(
            nextDate: nextDate,
            paidCount: count,
            totalCount: rows.length,
            pattern: pattern,
          );
    for (final (i, r) in rows.indexed) {
      final markedInKalan = r.isPaid && !r.paidBeforeKalan;
      if (markedInKalan) continue;
      final before = i < run && i < count;
      final date = dates != null && !r.isEdited ? dates[i] : r.date;
      final change = PaymentsCompanion(
        paidAt: Value(before ? (r.paidBeforeKalan ? r.paidAt : paidAt) : null),
        paidBeforeKalan: Value(before),
        dueDay: Value(date.epochDay),
      );
      if (r.paidBeforeKalan == before && r.dueDay == date.epochDay) continue;
      await (_db.update(
        _db.payments,
      )..where((p) => p.id.equals(r.id))).write(change);
    }
  });

  /// Changes the plan's installment count, keeping its total ([resizePlan]):
  /// paid and hand-edited payments stay; removed payments come off the
  /// end; new ones follow [pattern] from the last payment not edited by
  /// hand. Returns the reason when the change is not possible.
  Future<ResizeRejection?> resize(
    int planId, {
    required int count,
    UnderwayPattern? pattern,
  }) => _db.transaction(() async {
    final rows =
        await (_db.select(_db.payments)
              ..where((p) => p.planId.equals(planId))
              ..orderBy([(p) => OrderingTerm.asc(p.seq)]))
            .get();
    if (count == rows.length) return null;
    if (count > rows.length && pattern == null) {
      return ResizeRejection.cannotSplit;
    }
    var anchor = rows.length - 1;
    while (anchor > 0 && rows[anchor].isEdited) {
      anchor--;
    }
    final dates = count > rows.length
        ? underwayDates(
            nextDate: rows[anchor].date,
            paidCount: anchor,
            totalCount: count,
            pattern: pattern!,
          )
        : const <LocalDate>[];
    final result = resizePlan(
      payments: [for (final r in rows) r.toState()],
      newCount: count,
      dateAt: (i) => dates[i],
    );
    switch (result) {
      case ResizeRejected(:final reason):
        return reason;
      case ResizeApplied(:final payments):
        for (final r in rows.skip(count)) {
          await (_db.delete(
            _db.payments,
          )..where((p) => p.id.equals(r.id))).go();
        }
        for (final (i, after) in payments.indexed) {
          if (i < rows.length) {
            if (rows[i].amountMinor == after.amountMinor) continue;
            await (_db.update(
              _db.payments,
            )..where((p) => p.id.equals(rows[i].id))).write(
              PaymentsCompanion(amountMinor: Value(after.amountMinor)),
            );
          } else {
            await _db
                .into(_db.payments)
                .insert(
                  PaymentsCompanion.insert(
                    planId: planId,
                    seq: after.seq,
                    dueDay: after.date.epochDay,
                    amountMinor: after.amountMinor,
                  ),
                );
          }
        }
        await (_db.update(_db.plans)..where((p) => p.id.equals(planId))).write(
          PlansCompanion(installmentCount: Value(count)),
        );
        return null;
    }
  });

  /// The plan edit screen's save: the installment count and "already
  /// underway" together, in the order that keeps both valid.
  Future<ResizeRejection?> editPlan(
    int planId, {
    required int count,
    required int paidBefore,
    LocalDate? nextDate,
    UnderwayPattern? pattern,
  }) => _db
      .transaction(() async {
        final current = await (_db.select(
          _db.plans,
        )..where((p) => p.id.equals(planId))).getSingle();
        Future<void> underway() => setPaidBefore(
          planId,
          count: paidBefore,
          nextDate: nextDate,
          pattern: nextDate == null ? null : pattern,
        );
        if (count >= current.installmentCount) {
          final rejected = await resize(planId, count: count, pattern: pattern);
          if (rejected != null) return rejected;
          await underway();
        } else {
          await underway();
          final rejected = await resize(planId, count: count, pattern: pattern);
          if (rejected != null) throw _Rollback(rejected);
        }
        return null;
      })
      .catchError(
        (Object e) => (e as _Rollback).reason,
        test: (e) => e is _Rollback,
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

/// Undoes an [PlanRepository.editPlan] whose second step was refused.
class _Rollback implements Exception {
  const _Rollback(this.reason);
  final ResizeRejection reason;
}
