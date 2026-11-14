import 'package:drift/drift.dart';

import '../../core/date/local_date.dart';
import '../../core/reminders/reminder_models.dart';
import '../db/app_database.dart';

/// "Remind tonight" / "Remind tomorrow" chosen from a notification.
class ReminderSnoozeRepository {
  ReminderSnoozeRepository(this._db);

  final AppDatabase _db;

  Future<List<ReminderSnooze>> all() async => [
    for (final row in await _db.select(_db.reminderSnoozes).get())
      ?_toSnooze(row),
  ];

  /// Stores a snooze. The same one again (a double tap, a repeated
  /// delivery) is ignored.
  Future<void> add({
    required ReminderKind kind,
    required LocalDate fireDate,
    required int minuteOfDay,
    required List<PaymentRef> refs,
    bool skipsDay = false,
  }) => _db
      .into(_db.reminderSnoozes)
      .insert(
        ReminderSnoozesCompanion.insert(
          kind: kind.index,
          fireDay: fireDate.epochDay,
          minuteOfDay: minuteOfDay,
          refs: refs.map((r) => r.key).join(','),
          skipsDay: Value(skipsDay),
        ),
        mode: InsertMode.insertOrIgnore,
      );

  Future<void> delete(Iterable<int> ids) async {
    if (ids.isEmpty) return;
    await (_db.delete(_db.reminderSnoozes)..where((s) => s.id.isIn(ids))).go();
  }

  /// A row this code could not have written is skipped.
  static ReminderSnooze? _toSnooze(ReminderSnoozeRow row) {
    final refs = [for (final key in row.refs.split(',')) PaymentRef.parse(key)];
    if (refs.isEmpty || refs.contains(null)) return null;
    if (row.kind < 0 || row.kind >= ReminderKind.values.length) return null;
    return ReminderSnooze(
      id: row.id,
      kind: ReminderKind.values[row.kind],
      fireDate: LocalDate.fromEpochDay(row.fireDay),
      minuteOfDay: row.minuteOfDay,
      refs: List.unmodifiable(refs.cast<PaymentRef>()),
      skipsDay: row.skipsDay,
    );
  }
}
