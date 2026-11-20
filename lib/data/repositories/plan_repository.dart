import 'package:drift/drift.dart';

import '../../core/engine/engine.dart';
import '../../core/reminders/reminder_models.dart' show ReminderRepeat;
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
        leftOuterJoin(
          _db.sources,
          _db.sources.id.equalsExp(_db.plans.sourceId),
        ),
      ])..orderBy([
        OrderingTerm.asc(_db.plans.id),
        OrderingTerm.asc(_db.payments.seq),
      ]);

  List<PlanWithPayments> _group(List<TypedResult> rows) {
    final plans = <int, (PlanRow, SourceRow?)>{};
    final payments = <int, List<PaymentRow>>{};
    for (final row in rows) {
      final plan = row.readTable(_db.plans);
      plans.putIfAbsent(
        plan.id,
        () => (plan, row.readTableOrNull(_db.sources)),
      );
      payments.putIfAbsent(plan.id, () => []).add(row.readTable(_db.payments));
    }
    return [
      for (final MapEntry(key: id, value: (plan, source)) in plans.entries)
        PlanWithPayments(
          plan: plan,
          source: source,
          allPayments: payments[id]!,
        ),
    ];
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

  /// Plans with an unpaid payment that are not closed: plans on hold
  /// count (Decision 1). The same as `PlanWithPayments.isOpen`.
  Future<int> countOpenPlans() async {
    final query =
        _db.selectOnly(_db.payments, distinct: true).join([
            innerJoin(_db.plans, _db.plans.id.equalsExp(_db.payments.planId)),
          ])
          ..addColumns([_db.payments.planId])
          ..where(
            _db.payments.paidAt.isNull() &
                _db.plans.status.equalsValue(PlanStatus.closed).not(),
          );
    return (await query.get()).length;
  }

  /// Stores a confirmed draft. Returns the new plan id. The draft's first
  /// [PlanDraft.paidBeforeCount] payments are stored as paid before Kalan.
  Future<int> saveDraft(
    PlanDraft draft, {
    required int? sourceId,
    required PlanOrigin origin,
    String? title,
    PaymentMethod? paymentMethod,
    int? chargeSourceId,
    DateTime? now,
  }) => _db.transaction(() async {
    final paidAt = now ?? DateTime.now();
    final trimmed = title?.trim();
    final planId = await _db
        .into(_db.plans)
        .insert(
          PlansCompanion.insert(
            sourceId: Value(sourceId),
            title: Value((trimmed?.isEmpty ?? true) ? null : trimmed),
            kind: draft.kind,
            installmentCount: draft.installmentCount,
            purchaseDay: Value(draft.purchaseDate?.epochDay),
            deferMonths: Value(draft.deferMonths),
            isCashAdvance: Value(draft.isCashAdvance),
            origin: origin,
            payLaterRule: Value(draft.payLaterRule?.kind),
            payLaterValue: Value(draft.payLaterRule?.value),
            intervalDays: Value(draft.interval?.days),
            paymentMethod: Value(paymentMethod),
            chargeSourceId: Value(
              paymentMethod == PaymentMethod.automatic ? chargeSourceId : null,
            ),
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

  /// Nothing is marked or unmarked on a closed plan: its history stays as
  /// it was when it was closed (19).
  Future<void> setPaid(int paymentId, {required bool paid, DateTime? now}) =>
      (_db.update(
        _db.payments,
      )..where((p) => p.id.equals(paymentId) & _onUnclosedPlan(p))).write(
        PaymentsCompanion(
          paidAt: Value(paid ? (now ?? DateTime.now()) : null),
          // Unmarking forgets the past-due choice too.
          paidOnDay: paid ? const Value.absent() : const Value(null),
        ),
      );

  /// "Paid" from the past-due list: [paidOn] is today (counts in this
  /// period) or the due date (counts in its own period).
  Future<void> setPaidOn(int paymentId, LocalDate paidOn, {DateTime? now}) =>
      (_db.update(
        _db.payments,
      )..where((p) => p.id.equals(paymentId) & _onUnclosedPlan(p))).write(
        PaymentsCompanion(
          paidAt: Value(now ?? DateTime.now()),
          paidOnDay: Value(paidOn.epochDay),
        ),
      );

  Expression<bool> _onUnclosedPlan($PaymentsTable p) => p.planId.isInQuery(
    _db.selectOnly(_db.plans)
      ..addColumns([_db.plans.id])
      ..where(_db.plans.status.equalsValue(PlanStatus.closed).not()),
  );

  /// An update of [planId]'s own row that never touches a closed plan.
  UpdateStatement<$PlansTable, PlanRow> _unclosedPlan(int planId) =>
      _db.update(_db.plans)..where(
        (p) =>
            p.id.equals(planId) & p.status.equalsValue(PlanStatus.closed).not(),
      );

  Future<PlanRow> _plan(int planId) =>
      (_db.select(_db.plans)..where((p) => p.id.equals(planId))).getSingle();

  /// Closed plans are read-only (closing cannot be undone).
  Future<void> _requireNotClosed(int planId) async {
    if ((await _plan(planId)).status == PlanStatus.closed) {
      throw StateError('plan $planId is closed');
    }
  }

  Future<List<PaymentRow>> _rows(int planId) =>
      (_db.select(_db.payments)
            ..where((p) => p.planId.equals(planId))
            ..orderBy([(p) => OrderingTerm.asc(p.seq)]))
          .get();

  /// "Put on hold" (19): the unpaid payments leave every total, period,
  /// past-due list and reminder until the plan is reopened or closed.
  Future<void> hold(int planId, {required LocalDate today}) =>
      _db.transaction(() async {
        final plan = await _plan(planId);
        if (plan.status != PlanStatus.open) {
          throw StateError('plan $planId is not open');
        }
        await (_db.update(_db.plans)..where((p) => p.id.equals(planId))).write(
          PlansCompanion(
            status: const Value(PlanStatus.onHold),
            heldSinceDay: Value(today.epochDay),
            holdCheckDay: Value(today.epochDay),
            reopenedDay: const Value(null),
          ),
        );
      });

  /// "Reopen": undoes "Put on hold". Payments come back on their own
  /// dates; the hold day stays, so payments whose date passed meanwhile
  /// can be counted ([PlanWithPayments.passedWhileHeld]).
  Future<void> reopen(int planId, {required LocalDate today}) =>
      _db.transaction(() async {
        final plan = await _plan(planId);
        if (plan.status != PlanStatus.onHold) {
          throw StateError('plan $planId is not on hold');
        }
        await (_db.update(_db.plans)..where((p) => p.id.equals(planId))).write(
          PlansCompanion(
            status: const Value(PlanStatus.open),
            holdCheckDay: const Value(null),
            reopenedDay: Value(today.epochDay),
          ),
        );
      });

  /// "Keep on hold": the 30 days start again from [today].
  Future<void> keepOnHold(int planId, {required LocalDate today}) =>
      (_db.update(_db.plans)..where(
            (p) =>
                p.id.equals(planId) & p.status.equalsValue(PlanStatus.onHold),
          ))
          .write(PlansCompanion(holdCheckDay: Value(today.epochDay)));

  /// "Close" (19), from open or on hold: the plan goes to the archive with
  /// its [reason]. Unpaid payments leave every total and reminder; paid
  /// ones stay in their periods. Nothing is deleted.
  Future<void> close(
    int planId, {
    required CloseReason reason,
    required LocalDate today,
  }) => _db.transaction(() async {
    await _requireNotClosed(planId);
    await (_db.update(_db.plans)..where((p) => p.id.equals(planId))).write(
      PlansCompanion(
        status: const Value(PlanStatus.closed),
        closeReason: Value(reason),
        closedDay: Value(today.epochDay),
        holdCheckDay: const Value(null),
      ),
    );
  });

  /// "Adjust amount" (19): a lower total for an open or held plan
  /// ([adjustPlanTotal]). Only unpaid amounts change; the status does not.
  /// Returns the reason when nothing is stored.
  Future<AdjustRejection?> adjustTotal(int planId, int newTotalMinor) =>
      _db.transaction(() async {
        await _requireNotClosed(planId);
        final rows = await _rows(planId);
        final result = adjustPlanTotal([
          for (final r in rows) r.toState(),
        ], newTotalMinor);
        switch (result) {
          case AdjustRejected(:final reason):
            return reason;
          case AdjustApplied(:final payments):
            for (final (i, r) in rows.indexed) {
              final amount = payments[i].amountMinor;
              if (amount == r.amountMinor) continue;
              await (_db.update(_db.payments)..where((p) => p.id.equals(r.id)))
                  .write(PaymentsCompanion(amountMinor: Value(amount)));
            }
            return null;
        }
      });

  /// "Change date" (20): payment [seq] moves to [newDate]; with
  /// [shiftLater], every later unpaid payment moves by the same number of
  /// days ([movedDates]). Each moved payment keeps its first original date
  /// ([originalDateAfterMove]). One transaction; nothing else changes
  /// (amounts, numbers, "edited"). Returns the reason when nothing is
  /// stored ([moveRejection], the screen's own check).
  Future<MoveRejection?> movePayment({
    required int planId,
    required int seq,
    required LocalDate newDate,
    required bool shiftLater,
    required LocalDate today,
  }) => _db.transaction(() async {
    final plan = await _plan(planId);
    final rows = await _rows(planId);
    final payments = [for (final r in rows) r.toMovable()];
    final rejection = moveRejection(
      payments,
      seq: seq,
      newDate: newDate,
      shiftLater: shiftLater,
      today: today,
      status: plan.status,
      kind: plan.kind,
    );
    if (rejection != null) return rejection;
    final moved = movedDates(
      payments,
      seq: seq,
      newDate: newDate,
      shiftLater: shiftLater,
    );
    for (final r in rows) {
      final date = moved[r.seq];
      if (date == null) continue;
      final original = originalDateAfterMove(
        current: r.date,
        stored: r.originalDate,
        newDate: date,
      );
      await (_db.update(_db.payments)..where((p) => p.id.equals(r.id))).write(
        PaymentsCompanion(
          dueDay: Value(date.epochDay),
          originalDay: Value(original?.epochDay),
        ),
      );
    }
    return null;
  });

  /// Stores [amountMinor] and [note] as [paymentId]'s extra fee (21),
  /// replacing the one it has: one fee per payment. Re-checks the rule
  /// ([extraFeeRejection]) in one transaction; returns the reason when
  /// nothing is stored. The payment's amount, date and paid state never
  /// change; reminders follow from the payments stream (`ReminderSync`).
  Future<ExtraFeeRejection?> setExtraFee(
    int paymentId, {
    required int amountMinor,
    String? note,
  }) => _db.transaction(() async {
    final found = await _paymentWithPlan(paymentId);
    if (found == null) return ExtraFeeRejection.notFound;
    final (payment, plan) = found;
    final rejection = extraFeeRejection(
      status: plan.status,
      isPaid: payment.isPaid,
      paidBeforeKalan: payment.paidBeforeKalan,
      amountMinor: amountMinor,
      note: note,
    );
    if (rejection != null) return rejection;
    await (_db.update(
      _db.payments,
    )..where((p) => p.id.equals(paymentId))).write(
      PaymentsCompanion(
        extraFeeMinor: Value(amountMinor),
        extraFeeNote: Value(normalizeExtraFeeNote(note)),
      ),
    );
    return null;
  });

  /// Removes [paymentId]'s extra fee (21) and returns it, so "Undo" can
  /// store it again with [setExtraFee]. Null when there was none or the
  /// payment cannot change ([canHaveExtraFee]: a closed plan keeps its
  /// fees).
  Future<({int amountMinor, String? note})?> removeExtraFee(int paymentId) =>
      _db.transaction(() async {
        final found = await _paymentWithPlan(paymentId);
        if (found == null) return null;
        final (payment, plan) = found;
        final fee = payment.extraFeeMinor;
        if (fee == null ||
            !canHaveExtraFee(
              status: plan.status,
              isPaid: payment.isPaid,
              paidBeforeKalan: payment.paidBeforeKalan,
            )) {
          return null;
        }
        await (_db.update(
          _db.payments,
        )..where((p) => p.id.equals(paymentId))).write(
          const PaymentsCompanion(
            extraFeeMinor: Value(null),
            extraFeeNote: Value(null),
          ),
        );
        return (amountMinor: fee, note: payment.extraFeeNote);
      });

  Future<(PaymentRow, PlanRow)?> _paymentWithPlan(int paymentId) async {
    final payment = await (_db.select(
      _db.payments,
    )..where((p) => p.id.equals(paymentId))).getSingleOrNull();
    if (payment == null) return null;
    return (payment, await _plan(payment.planId));
  }

  /// Changes one payment; returns the reason when the edit is not allowed.
  Future<EditRejection?> editPayment({
    required int planId,
    required int seq,
    required LocalDate date,
    required int amountMinor,
  }) => _db.transaction(() async {
    await _requireNotClosed(planId);
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
              // Back on the date it had before "Change date" (20): the
              // note goes. Otherwise the original date stays as it is.
              originalDay: before.originalDay == after.date.epochDay
                  ? const Value(null)
                  : const Value.absent(),
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
  }) => _unclosedPlan(planId).write(
    PlansCompanion(
      remindersEnabled: Value(enabled),
      reminderLeadDays: Value(leadDays),
    ),
  );

  /// Changes a "Pay later" plan: its name and source always; amount,
  /// purchase date and rule only while its payment is unpaid (a paid one
  /// is never changed). The due date follows the rule from the purchase
  /// date; a chosen date stays [chosenDate].
  Future<void> editPayLater(
    int planId, {
    required String? title,
    required int? sourceId,
    required int amountMinor,
    required LocalDate purchaseDate,
    required PayLaterRule rule,
    LocalDate? chosenDate,
  }) => _db.transaction(() async {
    final plan = await _plan(planId);
    if (plan.status == PlanStatus.closed) {
      throw StateError('plan $planId is closed');
    }
    final payment = await (_db.select(
      _db.payments,
    )..where((p) => p.planId.equals(planId))).getSingle();
    final trimmed = title?.trim();
    final paid = payment.isPaid;
    // A date recorded with "Change date" (20) stays until the purchase
    // date, the rule or a picked date changes; then the rule decides
    // again and the note goes.
    final keepsMove =
        payment.originalDay != null &&
        keepsMovedPayLaterDate(
          movedDate: payment.date,
          storedPurchase: plan.purchaseDay == null
              ? null
              : LocalDate.fromEpochDay(plan.purchaseDay!),
          storedRule: PayLaterRule.from(plan.payLaterRule, plan.payLaterValue),
          purchase: purchaseDate,
          rule: rule,
          chosen: chosenDate,
        );
    await (_db.update(_db.plans)..where((p) => p.id.equals(planId))).write(
      PlansCompanion(
        title: Value((trimmed?.isEmpty ?? true) ? null : trimmed),
        sourceId: Value(sourceId),
        purchaseDay: paid ? const Value.absent() : Value(purchaseDate.epochDay),
        payLaterRule: paid ? const Value.absent() : Value(rule.kind),
        payLaterValue: paid ? const Value.absent() : Value(rule.value),
      ),
    );
    if (paid) return;
    final due = keepsMove
        ? payment.date
        : payLaterDueDate(
            purchase: purchaseDate,
            rule: rule,
            chosen: chosenDate ?? LocalDate.fromEpochDay(payment.dueDay),
          );
    await (_db.update(
      _db.payments,
    )..where((p) => p.id.equals(payment.id))).write(
      PaymentsCompanion(
        amountMinor: Value(amountMinor),
        dueDay: Value(due.epochDay),
        originalDay: keepsMove ? const Value.absent() : const Value(null),
      ),
    );
  });

  /// The plan's payment method (null: not set) and, for an automatic one,
  /// where it is taken from (null: not chosen, or a card plan's own card).
  /// Any other method forgets the source.
  Future<void> setPaymentMethod(
    int planId,
    PaymentMethod? method, {
    int? chargeSourceId,
  }) => _unclosedPlan(planId).write(
    PlansCompanion(
      paymentMethod: Value(method),
      chargeSourceId: Value(
        method == PaymentMethod.automatic ? chargeSourceId : null,
      ),
    ),
  );

  /// The plan's repeat reminders; null follows the global setting.
  Future<void> setRepeatMode(int planId, ReminderRepeat? mode) =>
      _unclosedPlan(planId).write(PlansCompanion(repeatMode: Value(mode)));

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
    await _requireNotClosed(planId);
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
      // Edited by hand or moved with "Change date" (20): the date stays.
      final pinned = r.isEdited || r.originalDay != null;
      final date = dates != null && !pinned ? dates[i] : r.date;
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
    await _requireNotClosed(planId);
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

  /// The plan edit screen's save: the installment count, "already
  /// underway" and the payment interval together, in the order that keeps
  /// them valid. Nothing is stored when the change is rejected.
  ///
  /// "Monthly installments" and "Pay in 4" follow their own interval: a
  /// new [interval] is stored and redates the payments after the anchor
  /// that are unpaid and not edited by hand. The anchor is the first
  /// unpaid payment not edited by hand from number `paidBefore + 1` on; it
  /// keeps its date, so no unpaid payment moves into the past; payments
  /// paid before Kalan follow the new rule backwards. With [nextDate],
  /// payment number `paidBefore + 1` moves there and the rest follow it
  /// ([setPaidBefore]). Other kinds use [pattern] and ignore [interval].
  Future<ResizeRejection?> editPlan(
    int planId, {
    required int count,
    required int paidBefore,
    LocalDate? nextDate,
    UnderwayPattern? pattern,
    PaymentInterval? interval,
  }) => _db
      .transaction<ResizeRejection?>(() async {
        if (paidBefore < 0 || paidBefore >= count) {
          throw ArgumentError.value(paidBefore, 'paidBefore');
        }
        await _requireNotClosed(planId);
        final current = await (_db.select(
          _db.plans,
        )..where((p) => p.id.equals(planId))).getSingle();
        final hasInterval =
            current.kind == PlanKind.monthly || current.kind == PlanKind.payIn4;
        final stored = PaymentInterval.fromDays(current.intervalDays);
        final chosen = hasInterval ? interval ?? stored : null;
        if (chosen != null && !chosen.isValid) {
          throw ArgumentError.value(interval, 'interval');
        }
        final newInterval = chosen != null && chosen != stored;
        final datePattern = chosen != null ? IntervalPattern(chosen) : pattern;

        if (count >= current.installmentCount) {
          final rejected = await resize(
            planId,
            count: count,
            pattern: datePattern,
          );
          if (rejected != null) throw _Rollback(rejected);
          await _underwayAndInterval(
            planId,
            paidBefore: paidBefore,
            nextDate: nextDate,
            pattern: datePattern,
            redate: newInterval,
          );
        } else {
          await _underwayAndInterval(
            planId,
            paidBefore: paidBefore,
            nextDate: nextDate,
            pattern: datePattern,
            redate: newInterval,
          );
          final rejected = await resize(
            planId,
            count: count,
            pattern: datePattern,
          );
          if (rejected != null) throw _Rollback(rejected);
        }
        if (newInterval) {
          await (_db.update(_db.plans)..where((p) => p.id.equals(planId)))
              .write(PlansCompanion(intervalDays: Value(chosen.days)));
        }
        return null;
      })
      .catchError(
        (Object e) => (e as _Rollback).reason,
        test: (e) => e is _Rollback,
      );

  /// [setPaidBefore], then, for a new interval without a new next date,
  /// the payments after the anchor (see [editPlan]) and the ones paid
  /// before Kalan follow [pattern] from the anchor.
  Future<void> _underwayAndInterval(
    int planId, {
    required int paidBefore,
    required LocalDate? nextDate,
    required UnderwayPattern? pattern,
    required bool redate,
  }) async {
    await setPaidBefore(
      planId,
      count: paidBefore,
      nextDate: nextDate,
      pattern: nextDate == null ? null : pattern,
    );
    if (!redate || nextDate != null || pattern == null) return;
    final rows =
        await (_db.select(_db.payments)
              ..where((p) => p.planId.equals(planId))
              ..orderBy([(p) => OrderingTerm.asc(p.seq)]))
            .get();
    // Moved with "Change date" (20): kept like a date edited by hand.
    bool free(PaymentRow r) =>
        !r.isPaid && !r.isEdited && r.originalDay == null;
    var anchor = paidBefore;
    while (anchor < rows.length && !free(rows[anchor])) {
      anchor++;
    }
    if (anchor >= rows.length) return;
    final dates = underwayDates(
      nextDate: rows[anchor].date,
      paidCount: anchor,
      totalCount: rows.length,
      pattern: pattern,
    );
    // Payments paid before Kalan follow the plan's rule backwards
    // ([underwayDates]); payments marked paid in Kalan never move.
    bool moves(int i) =>
        i > anchor && free(rows[i]) ||
        i < paidBefore && rows[i].paidBeforeKalan && !rows[i].isEdited;
    for (var i = 0; i < rows.length; i++) {
      final r = rows[i];
      if (!moves(i) || r.dueDay == dates[i].epochDay) continue;
      await (_db.update(_db.payments)..where((p) => p.id.equals(r.id))).write(
        PaymentsCompanion(dueDay: Value(dates[i].epochDay)),
      );
    }
  }

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
                  p.kind.equalsValue(PlanKind.card) &
                  // A closed plan never changes (19); one on hold can be
                  // reopened, so its dates follow the card.
                  p.status.equalsValue(PlanStatus.closed).not(),
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
