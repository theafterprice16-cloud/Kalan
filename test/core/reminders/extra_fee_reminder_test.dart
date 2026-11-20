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

/// Extra fee (21, decision 10): an unpaid payment's reminder says its
/// amount plus its extra fee; without a fee, every reminder is exactly as
/// before. 2025: 14 November is a Friday.
LocalDate d(int m, int day) => LocalDate(2025, m, day);

late tz.Location istanbul;

ReminderPayment pay(
  int amount, {
  int? fee,
  int? planFee,
  String name = 'Klarna',
  PaymentMethod? method,
  ChargeAccount? account,
  int ref = 1,
}) => ReminderPayment(
  name: name,
  date: d(11, 14),
  amountMinor: amount,
  extraFeeMinor: fee,
  installmentFeeMinor: planFee,
  method: method,
  account: account,
  ref: PlanPaymentRef(ref),
);

List<PlannedReminder> plan(
  List<ReminderPayment> payments, {
  String lang = 'tr',
  String currency = 'EUR',
}) => planReminders(
  payments: payments,
  settings: const ReminderSettings(),
  now: tz.TZDateTime(istanbul, 2025, 11, 10, 20),
  texts: L10nReminderTexts(
    l10n: lookupAppLocalizations(Locale(lang)),
    currency: Currency.fromCode(currency),
  ),
);

PlannedReminder kindOf(List<PlannedReminder> r, ReminderKind kind) =>
    r.firstWhere((x) => x.kind == kind);

void main() {
  setUpAll(() async {
    tzdata.initializeTimeZones();
    istanbul = tz.getLocation('Europe/Istanbul');
    await initializeDateFormatting();
  });

  test('dueMinor is the amount plus the fee; the amount alone without', () {
    expect(pay(6000, fee: 600).dueMinor, 6600);
    expect(pay(6000).dueMinor, 6000);
  });

  // Cents, so the formatted amounts always show their decimals.
  test('example 2: 60,50 € with a 6,25 € fee is reminded as 66,75 €', () {
    final r = plan([pay(6050, fee: 625)]);
    final ahead = kindOf(r, ReminderKind.ahead);
    final onDay = kindOf(r, ReminderKind.onDay);
    expect(ahead.body, contains('66,75'));
    expect(ahead.body, isNot(contains('60,50')));
    expect(onDay.body, contains('66,75'));
    expect(ahead.totalMinor, 6675);
    final en = kindOf(
      plan([pay(6050, fee: 625)], lang: 'en'),
      ReminderKind.ahead,
    );
    expect(en.body, contains('66.75'));
  });

  test('the fee joins the day total of a grouped reminder', () {
    final r = plan([pay(6050, fee: 625, ref: 1), pay(4000, ref: 2)]);
    expect(kindOf(r, ReminderKind.ahead).totalMinor, 10675);
    expect(kindOf(r, ReminderKind.ahead).body, contains('106,75'));
  });

  test('IDR, no minor digits: Rp500.000 + Rp25.000', () {
    final r = plan([pay(500000, fee: 25000)], currency: 'IDR');
    expect(kindOf(r, ReminderKind.ahead).body, contains('525.000'));
  });

  test('"keep in account" (18) says the amount with the fee', () {
    final r = plan([
      pay(
        6050,
        fee: 625,
        method: PaymentMethod.automatic,
        account: const ChargeAccount(1, 'Maaş hesabı'),
      ),
    ]);
    expect(
      kindOf(r, ReminderKind.ahead).body,
      contains(RegExp(r'Maaş hesabı: \S*66,75\S* bulunsun\.')),
    );
  });

  test('without a fee every reminder is exactly as before', () {
    final withField = plan([pay(6000, ref: 1), pay(4000, ref: 2)]);
    final before = plan([
      ReminderPayment(
        name: 'Klarna',
        date: d(11, 14),
        amountMinor: 6000,
        ref: const PlanPaymentRef(1),
      ),
      ReminderPayment(
        name: 'Klarna',
        date: d(11, 14),
        amountMinor: 4000,
        ref: const PlanPaymentRef(2),
      ),
    ]);
    expect(
      [for (final r in withField) (r.id, r.fireAt, r.title, r.body)],
      [for (final r in before) (r.id, r.fireAt, r.title, r.body)],
    );
  });

  // Fee per payment (22, decision 10).
  test('example 1: 2.500 ¥ with a 390 ¥ fee per payment says 2.890 ¥', () {
    final r = plan([pay(2500, planFee: 390)], currency: 'JPY');
    final ahead = kindOf(r, ReminderKind.ahead);
    expect(ahead.totalMinor, 2890);
    expect(ahead.body, contains('2.890'));
    expect(kindOf(r, ReminderKind.onDay).body, contains('2.890'));
  });

  test('a fee per payment and an extra fee together', () {
    final r = plan([pay(4000, planFee: 250, fee: 600)]);
    expect(kindOf(r, ReminderKind.ahead).totalMinor, 4850);
    expect(kindOf(r, ReminderKind.ahead).body, contains('48,50'));
  });
}
