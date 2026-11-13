import 'package:drift/drift.dart';

import '../db/app_database.dart';
import '../models.dart';

class RecurringRepository {
  RecurringRepository(this._db);

  final AppDatabase _db;

  JoinedSelectStatement<HasResultSet, dynamic> _allQuery() =>
      _db.select(_db.recurringPayments).join([
        leftOuterJoin(
          _db.recurringMarks,
          _db.recurringMarks.recurringId.equalsExp(_db.recurringPayments.id),
        ),
      ])..orderBy([
        OrderingTerm.asc(_db.recurringPayments.name.collate(Collate.noCase)),
      ]);

  List<RecurringWithMarks> _group(List<TypedResult> rows) {
    final items = <int, RecurringPaymentRow>{};
    final marks = <int, Set<int>>{};
    for (final row in rows) {
      final item = row.readTable(_db.recurringPayments);
      items[item.id] = item;
      final mark = row.readTableOrNull(_db.recurringMarks);
      final set = marks.putIfAbsent(item.id, () => <int>{});
      if (mark != null) set.add(mark.occurrenceDay);
    }
    return [
      for (final item in items.values)
        RecurringWithMarks(item: item, paidDays: marks[item.id]!),
    ];
  }

  Stream<List<RecurringWithMarks>> watchAll() =>
      _allQuery().watch().map(_group);

  /// One-off read (reminders, background isolates).
  Future<List<RecurringWithMarks>> all() async =>
      _group(await _allQuery().get());

  Future<RecurringPaymentRow?> byId(int id) => (_db.select(
    _db.recurringPayments,
  )..where((r) => r.id.equals(id))).getSingleOrNull();

  Future<int> create(RecurringPaymentsCompanion entry) =>
      _db.into(_db.recurringPayments).insert(entry);

  Future<void> update(RecurringPaymentRow row) =>
      _db.update(_db.recurringPayments).replace(row);

  Future<void> delete(int id) =>
      (_db.delete(_db.recurringPayments)..where((r) => r.id.equals(id))).go();

  Future<void> setPaid(
    int recurringId,
    int occurrenceDay, {
    required bool paid,
    DateTime? now,
  }) async {
    if (paid) {
      await _db
          .into(_db.recurringMarks)
          .insertOnConflictUpdate(
            RecurringMarksCompanion.insert(
              recurringId: recurringId,
              occurrenceDay: occurrenceDay,
              paidAt: now ?? DateTime.now(),
            ),
          );
    } else {
      await (_db.delete(_db.recurringMarks)..where(
            (m) =>
                m.recurringId.equals(recurringId) &
                m.occurrenceDay.equals(occurrenceDay),
          ))
          .go();
    }
  }
}
