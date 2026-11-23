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

/// "Hide amounts" (28) in notification text: an amount only while "Show
/// amount in notifications" is on and "Hide amounts" is off. 2025: 14
/// November is a Friday.
LocalDate d(int m, int day) => LocalDate(2025, m, day);

late tz.Location istanbul;

const maas = ChargeAccount(1, 'Maaş hesabı');

ReminderPayment pay(
  String name,
  int amount, {
  required int ref,
  LocalDate? date,
  ReminderRepeat? repeat,
}) => ReminderPayment(
  name: name,
  date: date ?? d(11, 14),
  amountMinor: amount,
  method: PaymentMethod.automatic,
  account: maas,
  ref: PlanPaymentRef(ref),
  repeat: repeat,
);

ReminderTexts texts() => L10nReminderTexts(
  l10n: lookupAppLocalizations(const Locale('tr')),
  currency: Currency.fromCode('TRY'),
);

tz.TZDateTime at(LocalDate date, int hour) =>
    tz.TZDateTime(istanbul, date.year, date.month, date.day, hour);

/// The four combinations of the two switches and whether amounts show.
const combinations = [
  (show: true, hide: false, amounts: true),
  (show: true, hide: true, amounts: false),
  (show: false, hide: false, amounts: false),
  (show: false, hide: true, amounts: false),
];

void main() {
  setUpAll(() async {
    tzdata.initializeTimeZones();
    istanbul = tz.getLocation('Europe/Istanbul');
    await initializeDateFormatting();
  });

  for (final c in combinations) {
    final settings = ReminderSettings(
      showAmounts: c.show,
      hideAmounts: c.hide,
      repeatMode: ReminderRepeat.daily,
    );
    final label =
        'show amount in notifications ${c.show ? 'on' : 'off'}, '
        'hide amounts ${c.hide ? 'on' : 'off'}';

    group(label, () {
      test('the one rule', () {
        expect(settings.amountsInText, c.amounts);
        // "Hide amounts" never changes the other switch.
        expect(settings.showAmounts, c.show);
      });

      test('combined, repeat and "keep in account" reminders', () {
        final list = planReminders(
          payments: [
            pay('Telefon taksiti', 140000, ref: 1),
            pay('Spor salonu', 100000, ref: 2),
          ],
          settings: settings,
          now: at(d(11, 10), 20),
          texts: texts(),
        );
        // Ahead, on the day and the daily repeats until 7 days after.
        expect(list.length, greaterThan(4));
        expect(
          list.where((r) => r.payments.length == 2),
          hasLength(list.length),
          reason: 'every reminder combines both payments',
        );
        for (final r in list) {
          expect(r.body.contains('₺'), c.amounts, reason: r.body);
          expect(
            r.expandedBody.contains('₺'),
            c.amounts,
            reason: r.expandedBody,
          );
        }
        final ahead = list.firstWhere((r) => r.kind == ReminderKind.ahead);
        expect(
          ahead.body,
          c.amounts
              ? '14 Kasım Cuma günü 2 ödeme var, toplam ₺2.400. '
                    'Otomatik çekilir. Maaş hesabı: ₺2.400 bulunsun.'
              : '14 Kasım Cuma günü 2 ödeme var. '
                    'Otomatik çekilir; tutar hesabında bulunsun.',
        );
        final onDay = list.firstWhere((r) => r.kind == ReminderKind.onDay);
        expect(
          onDay.body.startsWith(
            c.amounts
                ? 'Bugün 2 ödeme var, toplam ₺2.400'
                : 'Bugün 2 ödeme var',
          ),
          isTrue,
          reason: onDay.body,
        );
        expect(list.where((r) => r.kind == ReminderKind.overdue), isNotEmpty);
      });

      test('payday summary', () {
        final list = withPaydaySummary(
          const [],
          payday: PaydaySummary(
            date: d(12, 15),
            paymentCount: 6,
            totalMinor: 830000,
            leftMinor: -120000,
          ),
          settings: settings,
          now: at(d(11, 20), 8),
          texts: texts(),
        );
        expect(
          list.single.body,
          c.amounts
              ? 'Yeni dönem başladı. Bu dönem 6 ödeme, toplam ₺8.300. '
                    'Bu dönem ₺1.200 eksik kalıyor.'
              : 'Yeni dönem başladı. Bu dönem 6 ödeme var.',
        );
      });
    });
  }
}
