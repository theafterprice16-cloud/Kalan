import 'package:drift/drift.dart';

import '../db/app_database.dart';

class SettingsRepository {
  SettingsRepository(this._db);

  final AppDatabase _db;

  /// Null until onboarding is finished.
  Stream<SettingsRow?> watch() =>
      _db.select(_db.appSettings).watchSingleOrNull();

  Future<SettingsRow?> get() => _db.select(_db.appSettings).getSingleOrNull();

  Future<void> save(AppSettingsCompanion settings) => _db
      .into(_db.appSettings)
      .insertOnConflictUpdate(settings.copyWith(id: const Value(1)));

  /// Updates fields of the existing row. No-op before onboarding.
  Future<void> update(AppSettingsCompanion changes) => (_db.update(
    _db.appSettings,
  )..where((s) => s.id.equals(1))).write(changes);
}
