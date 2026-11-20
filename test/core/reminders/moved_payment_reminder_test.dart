import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kalan/core/engine/engine.dart';
import 'package:kalan/core/money/currency.dart';
import 'package:kalan/core/reminders/reminder_models.dart';
import 'package:kalan/core/reminders/reminder_planner.dart';
import 'package:kalan/features/reminders/reminder_texts.dart';
import 'package:kalan/l10n/generated/app_localizations.dart';
import 'package:material_ui/material_ui.dart' show Locale;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// "Change date" (20): reminders follow the stored date. The planner
/// itself is unchanged except that a snoozed reminder no longer speaks of
/// a payment whose date moved away from it.
void main() {
  late tz.Location istanbul;
  LocalDate d(int m, int day) => LocalDate(2025, m, day);
  tz.TZDateTime at(LocalDate date, int hour) =>
      tz.TZDateTime(istanbul, date.year, date.month, date.day, hour);

  setUpAll(() async {
    tzdata.initializeTimeZones();
    istanbul = tz.getLocation('Europe/Istanbul');
    await initializeDateFormatting('tr');
  });

  ReminderPayment pay(LocalDate date, int id, {ReminderChoice? choice}) =>
      ReminderPayment(
        name: 'Afterpay',
        date: date,
        amountMinor: 6000,
        isPaid: false,
        choice: choice ?? ReminderChoice.general,
        ref: PlanPaymentRef(id),
      );

  List<PlannedReminder> plan(
    List<ReminderPayment> payments, {
    List<ReminderSnooze> snoozes = const [],
    int limit = maxScheduledReminders,
  }) => planReminders(
    payments: payments,
    settings: const ReminderSettings(),
    now: at(d(11, 10), 10),
    texts: L10nReminderTexts(
      l10n: lookupAppLocalizations(const Locale('tr')),
      currency: Currency.fromCode('USD'),
    ),
    snoozes: snoozes,
    limit: limit,
  );

  test('a moved payment is reminded on its new date only', () {
    final before = plan([pay(d(11, 20), 1)]);
    final after = plan([pay(d(11, 27), 1)]);
    expect(before.map((r) => r.fireDate), [d(11, 18), d(11, 20)]);
    expect(after.map((r) => r.fireDate), [d(11, 25), d(11, 27)]);
  });

  test('the plan\'s own choice is kept', () {
    final r = plan([pay(d(11, 27), 1, choice: ReminderChoice.days(5))]);
    expect(r.map((x) => (x.fireDate, x.kind)), [
      (d(11, 22), ReminderKind.ahead),
      (d(11, 27), ReminderKind.onDay),
    ]);
  });

  test('never more than the limit', () {
    final many = [for (var i = 0; i < 80; i++) pay(d(11, 12).addDays(i), i)];
    expect(plan(many), hasLength(maxScheduledReminders));
  });

  group('snoozes', () {
    ReminderSnooze snooze(ReminderKind kind, LocalDate fire) => ReminderSnooze(
      id: 7,
      kind: kind,
      fireDate: fire,
      minuteOfDay: 20 * 60,
      refs: const [PlanPaymentRef(1)],
    );
    int snoozed(List<PlannedReminder> r) => r.where((x) => x.isSnoozed).length;

    test('"remind this evening" on the due date: gone once moved', () {
      final s = snooze(ReminderKind.onDay, d(11, 20));
      expect(snoozed(plan([pay(d(11, 20), 1)], snoozes: [s])), 1);
      expect(snoozed(plan([pay(d(11, 27), 1)], snoozes: [s])), 0);
    });

    test('"remind tomorrow" before the due date: gone once moved earlier '
        'than it', () {
      final s = snooze(ReminderKind.ahead, d(11, 18));
      expect(snoozed(plan([pay(d(11, 20), 1)], snoozes: [s])), 1);
      expect(snoozed(plan([pay(d(11, 27), 1)], snoozes: [s])), 1);
      expect(snoozed(plan([pay(d(11, 18), 1)], snoozes: [s])), 0);
    });

    test('snoozeStillFits', () {
      final fire = d(11, 18);
      expect(
        snoozeStillFits(ReminderKind.ahead, fireDate: fire, due: d(11, 19)),
        isTrue,
      );
      expect(
        snoozeStillFits(ReminderKind.ahead, fireDate: fire, due: fire),
        isFalse,
      );
      expect(
        snoozeStillFits(ReminderKind.onDay, fireDate: fire, due: fire),
        isTrue,
      );
      expect(
        snoozeStillFits(ReminderKind.onDay, fireDate: fire, due: d(11, 19)),
        isFalse,
      );
      expect(
        snoozeStillFits(ReminderKind.overdue, fireDate: fire, due: d(11, 10)),
        isTrue,
      );
    });
  });
}
