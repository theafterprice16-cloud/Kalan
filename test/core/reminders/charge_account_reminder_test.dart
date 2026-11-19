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

/// "Keep in account" in the reminder before a payment (18, decisions 3,
/// 11 and 12). 2025: 14 November is a Friday.
LocalDate d(int m, int day) => LocalDate(2025, m, day);

late tz.Location istanbul;

const maas = ChargeAccount(1, 'Maaş hesabı');
const ek = ChargeAccount(2, 'Ek hesap');
const auto = PaymentMethod.automatic;

ReminderPayment pay(
  String name,
  int amount, {
  LocalDate? date,
  ChargeAccount? account = maas,
  PaymentMethod? method = auto,
  int ref = 1,
}) => ReminderPayment(
  name: name,
  date: date ?? d(11, 14),
  amountMinor: amount,
  method: method,
  account: account,
  ref: PlanPaymentRef(ref),
);

List<PlannedReminder> plan(
  List<ReminderPayment> payments, {
  String lang = 'tr',
  bool showAmounts = true,
  ReminderSettings? settings,
  List<ReminderSnooze> snoozes = const [],
}) => planReminders(
  payments: payments,
  settings: settings ?? ReminderSettings(showAmounts: showAmounts),
  now: tz.TZDateTime(istanbul, 2025, 11, 10, 20),
  texts: L10nReminderTexts(
    l10n: lookupAppLocalizations(Locale(lang)),
    currency: Currency.fromCode('TRY'),
  ),
  snoozes: snoozes,
);

PlannedReminder aheadOf(List<PlannedReminder> r) =>
    r.firstWhere((x) => x.kind == ReminderKind.ahead);
PlannedReminder onDayOf(List<PlannedReminder> r) =>
    r.firstWhere((x) => x.kind == ReminderKind.onDay);

void main() {
  setUpAll(() async {
    tzdata.initializeTimeZones();
    istanbul = tz.getLocation('Europe/Istanbul');
    await initializeDateFormatting();
  });

  final example = [
    pay('Telefon taksiti', 140000, ref: 1),
    pay('Spor salonu', 100000, ref: 2),
  ];

  test('example 3: one account, the day total after the first sentence', () {
    final r = plan(example);
    expect(
      aheadOf(r).body,
      '14 Kasım Cuma günü 2 ödeme var, toplam ₺2.400. '
      'Otomatik çekilir. Maaş hesabı: ₺2.400 bulunsun.',
    );
    final en = plan(example, lang: 'en');
    expect(aheadOf(en).body, endsWith('Keep ₺2,400 in Maaş hesabı.'));
  });

  test('only before the payment: on the day keeps the general note', () {
    expect(
      onDayOf(plan(example)).body,
      'Bugün 2 ödeme var, toplam ₺2.400. '
      'Otomatik çekilir; tutar hesabında bulunsun.',
    );
  });

  test('a card, a provider or no source: no sentence', () {
    final r = plan([pay('Klarna', 60000, account: null)]);
    expect(aheadOf(r).body, isNot(contains('Maaş')));
    expect(aheadOf(r).body, endsWith('tutar hesabında bulunsun.'));
  });

  test('amounts hidden: no sentence, the note as before', () {
    final r = plan(example, showAmounts: false);
    expect(aheadOf(r).body, isNot(contains('Maaş')));
    expect(aheadOf(r).body, isNot(contains('2.400')));
    expect(
      aheadOf(r).body,
      endsWith(
        'Otomatik çekilir; tutar hesabında '
        'bulunsun.',
      ),
    );
  });

  test('different accounts in one notification: no sentence', () {
    final r = plan([
      pay('Telefon taksiti', 140000, ref: 1),
      pay('Laptop', 150000, account: ek, ref: 2),
    ]);
    expect(aheadOf(r).body, isNot(contains('Maaş')));
    expect(aheadOf(r).body, isNot(contains('Ek hesap')));
  });

  test('a recurring or manual payment in the group: no sentence', () {
    for (final other in [
      pay('Kira', 500000, account: null, method: null, ref: 3),
      pay('Market', 50000, method: PaymentMethod.manual, ref: 3),
    ]) {
      final r = plan([...example, other]);
      expect(aheadOf(r).body, isNot(contains('Maaş hesabı:')));
    }
  });

  test('two due dates in one "ahead" notification: no sentence', () {
    // 2 days before 14 Nov and 3 days before 15 Nov: both on 12 Nov.
    ReminderPayment p(String name, int day, int lead, int ref) =>
        ReminderPayment(
          name: name,
          date: d(11, day),
          amountMinor: 10000,
          method: auto,
          account: maas,
          ref: PlanPaymentRef(ref),
          choice: ReminderChoice.days(lead),
        );
    final r = plan([p('A', 14, 2, 1), p('B', 15, 3, 2)]);
    final merged = r.where((x) => x.kind == ReminderKind.ahead).toList();
    expect(merged, hasLength(1));
    expect(merged.single.body, isNot(contains('Maaş hesabı:')));
    expect(merged.single.body, endsWith('tutar hesabında bulunsun.'));
  });

  test('no new notification: same moments, ids and buttons', () {
    List<PlannedReminder> run(ChargeAccount? account) => plan([
      pay('Telefon taksiti', 140000, account: account, ref: 1),
      pay('Spor salonu', 100000, account: account, ref: 2),
      pay('Laptop', 150000, date: d(11, 25), account: account, ref: 3),
    ]);
    Object shape(PlannedReminder r) =>
        (r.id, r.fireAt, r.kind, '${r.buttons}', r.isSnoozed);
    final without = run(null);
    final withAccount = run(maas);
    expect(withAccount.map(shape).toList(), without.map(shape).toList());
  });

  test('a snoozed "ahead" reminder keeps the sentence', () {
    final snooze = ReminderSnooze(
      id: 1,
      kind: ReminderKind.ahead,
      fireDate: d(11, 13),
      minuteOfDay: 600,
      refs: const [PlanPaymentRef(1), PlanPaymentRef(2)],
    );
    final r = plan(example, snoozes: [snooze]);
    final snoozed = r.where((x) => x.isSnoozed).toList();
    expect(snoozed, hasLength(1));
    expect(snoozed.single.body, endsWith('Maaş hesabı: ₺2.400 bulunsun.'));
  });

  test('reminderAccountOf: ahead, amounts shown, one account', () {
    final group = [pay('A', 1), pay('B', 2)];
    expect(
      reminderAccountOf(ReminderKind.ahead, group, showAmounts: true),
      maas,
    );
    expect(
      reminderAccountOf(ReminderKind.onDay, group, showAmounts: true),
      isNull,
    );
    expect(
      reminderAccountOf(ReminderKind.overdue, group, showAmounts: true),
      isNull,
    );
    expect(
      reminderAccountOf(ReminderKind.ahead, group, showAmounts: false),
      isNull,
    );
  });
}
