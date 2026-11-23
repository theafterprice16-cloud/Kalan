import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/backup/backup_reminder.dart';
import 'package:kalan/core/date/local_date.dart';

void main() {
  final start = LocalDate(2026, 3, 1);

  bool due(int days, {LocalDate? backup, LocalDate? plan, bool on = true}) =>
      backupNoteDue(
        enabled: on,
        today: start.addDays(days),
        lastBackup: backup,
        firstPlanSaved: plan,
      );

  test('no backup yet: from the 30th day after the first plan', () {
    expect(due(29, plan: start), isFalse);
    expect(due(30, plan: start), isTrue);
    expect(due(400, plan: start), isTrue);
  });

  test('after a backup: from the 90th day (across a clock change)', () {
    // 1 March + 89 days crosses the spring daylight saving change.
    expect(due(89, backup: start, plan: start), isFalse);
    expect(due(90, backup: start, plan: start), isTrue);
  });

  test('switch off, nothing saved, or a date in the future: no note', () {
    expect(due(200, backup: start, on: false), isFalse);
    expect(due(200), isFalse);
    expect(due(-5, backup: start), isFalse);
    expect(due(-40, plan: start), isFalse);
  });

  test('months: whole 30-day months (91 days is 3)', () {
    expect(monthsSince(start, start.addDays(91)), 3);
    expect(monthsSince(start, start.addDays(90)), 3);
    expect(monthsSince(start, start.addDays(120)), 4);
  });
}
