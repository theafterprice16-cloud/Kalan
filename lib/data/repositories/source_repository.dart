import 'package:drift/drift.dart';

import '../db/app_database.dart';
import '../models.dart';
import 'holiday_repository.dart';
import 'plan_repository.dart';

class SourceRepository {
  SourceRepository(this._db, this._plans);

  final AppDatabase _db;
  final PlanRepository _plans;

  Stream<List<SourceRow>> watchAll() =>
      (_db.select(
            _db.sources,
          )..orderBy([(s) => OrderingTerm.asc(s.name.collate(Collate.noCase))]))
          .watch();

  Future<SourceRow?> byId(int id) => (_db.select(
    _db.sources,
  )..where((s) => s.id.equals(id))).getSingleOrNull();

  Future<int> create({
    required String name,
    required SourceKind kind,
    int? statementDay,
    int? dueDay,
    bool shiftDueToBusinessDay = true,
    bool shiftDueForHolidays = true,
    bool statementReminderEnabled = false,
    int statementReminderDays = 2,
  }) => _db
      .into(_db.sources)
      .insert(
        SourcesCompanion.insert(
          name: name.trim(),
          kind: kind,
          statementDay: Value(kind == SourceKind.card ? statementDay : null),
          dueDay: Value(kind == SourceKind.card ? dueDay : null),
          shiftDueToBusinessDay: Value(shiftDueToBusinessDay),
          shiftDueForHolidays: Value(shiftDueForHolidays),
          statementReminderEnabled: Value(
            kind == SourceKind.card &&
                statementDay != null &&
                dueDay != null &&
                statementReminderEnabled,
          ),
          statementReminderDays: Value(statementReminderDays),
        ),
      );

  /// Finds a provider by name (case-insensitive) or creates it.
  Future<int> findOrCreateProvider(String name) async {
    final trimmed = name.trim();
    final existing =
        await (_db.select(_db.sources)
              ..where((s) => s.name.lower().equals(trimmed.toLowerCase()))
              ..limit(1))
            .getSingleOrNull();
    if (existing != null) return existing.id;
    return create(name: trimmed, kind: SourceKind.provider);
  }

  /// Saves changes. When a card's days or weekend switch change, unpaid
  /// and unedited payments of its card plans are moved to the new dates
  /// (DECISIONS 12); when only its holiday switch changes, only the dates
  /// the card's rule gave move (26, [PlanRepository.reshiftCardPlans]).
  Future<void> update(SourceRow updated) => _db.transaction(() async {
    final old = await byId(updated.id);
    final holidays = await appliedHolidaysOf(_db);
    var normalized = updated.kind == SourceKind.card
        ? updated
        : updated.copyWith(
            statementDay: const Value(null),
            dueDay: const Value(null),
            statementReminderEnabled: false,
          );
    // The closing reminder needs the card's days.
    if (normalized.cardTermsIn(holidays) == null) {
      normalized = normalized.copyWith(statementReminderEnabled: false);
    }
    await _db.update(_db.sources).replace(normalized);
    final oldTerms = old?.cardTermsIn(holidays);
    final newTerms = normalized.cardTermsIn(holidays);
    if (oldTerms == null || newTerms == null) return;
    if (oldTerms.statementDay != newTerms.statementDay ||
        oldTerms.dueDay != newTerms.dueDay ||
        oldTerms.shiftDueToBusinessDay != newTerms.shiftDueToBusinessDay) {
      await _plans.recomputeCardPlans(
        sourceId: updated.id,
        oldTerms: oldTerms,
        newTerms: newTerms,
      );
    } else if (oldTerms.shiftDueForHolidays != newTerms.shiftDueForHolidays) {
      await _plans.reshiftCardPlans(
        sourceId: updated.id,
        oldTerms: oldTerms,
        newTerms: newTerms,
      );
    }
  });

  /// Deletes a source with no plans. Returns false when plans use it.
  Future<bool> delete(int id) => _db.transaction(() async {
    final used =
        await (_db.selectOnly(_db.plans)
              ..addColumns([_db.plans.id.count()])
              ..where(_db.plans.sourceId.equals(id)))
            .map((r) => r.read(_db.plans.id.count()) ?? 0)
            .getSingle();
    if (used > 0) return false;
    await (_db.delete(_db.sources)..where((s) => s.id.equals(id))).go();
    return true;
  });
}
