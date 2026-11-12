import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/date/local_date.dart';
import 'package:kalan/core/money/currency.dart';
import 'package:kalan/core/reminders/reminder_models.dart';
import 'package:kalan/features/reminders/reminder_messages.dart';
import 'package:kalan/l10n/generated/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

PlannedReminder reminder(ReminderOffset offset, List<ReminderPayment> ps) =>
    PlannedReminder(
      id: 1,
      fireDate: LocalDate(2026, 11, 12),
      minuteOfDay: 540,
      offset: offset,
      dueDate: LocalDate(2026, 11, 12),
      payments: ps,
    );

ReminderPayment p(int amount, {String name = 'Klarna', int? seq = 3}) =>
    ReminderPayment(
      ref: const PlanPaymentRef(1),
      name: name,
      date: LocalDate(2026, 11, 12),
      amountMinor: amount,
      seq: seq,
      count: seq == null ? null : 4,
    );

void main() {
  final tr = lookupAppLocalizations(const Locale('tr'));
  final en = lookupAppLocalizations(const Locale('en'));

  // locale, currency, offset, payments, hide amounts, expected text
  final cases =
      <
        (
          AppLocalizations,
          String,
          ReminderOffset,
          List<ReminderPayment>,
          bool,
          String,
        )
      >[
        (
          tr,
          'TRY',
          ReminderOffset.days1,
          [p(62000)],
          false,
          'Yarın: Klarna 3/4 · ₺620',
        ),
        (
          tr,
          'TRY',
          ReminderOffset.days3,
          [p(62000)],
          false,
          '3 gün sonra: Klarna 3/4 · ₺620',
        ),
        (
          tr,
          'TRY',
          ReminderOffset.sameDay,
          [p(62000)],
          false,
          'Bugün: Klarna 3/4 · ₺620',
        ),
        (
          tr,
          'TRY',
          ReminderOffset.days7,
          [p(62050)],
          false,
          '7 gün sonra: Klarna 3/4 · ₺620,50',
        ),
        (
          tr,
          'TRY',
          ReminderOffset.days3,
          [p(100000), p(50000, name: 'Zip'), p(95000, name: 'Kira', seq: null)],
          false,
          '3 gün sonra 3 ödemen var · toplam ₺2.450',
        ),
        (
          tr,
          'TRY',
          ReminderOffset.sameDay,
          [p(62000)],
          true,
          'Bugün 1 ödemen var',
        ),
        (
          tr,
          'TRY',
          ReminderOffset.days1,
          [p(1), p(2, name: 'Zip')],
          true,
          'Yarın 2 ödemen var',
        ),
        (
          tr,
          'TRY',
          ReminderOffset.sameDay,
          [p(150000, name: 'Kira', seq: null)],
          false,
          'Bugün: Kira · ₺1.500',
        ),
        (
          en,
          'USD',
          ReminderOffset.days1,
          [p(6200)],
          false,
          r'Tomorrow: Klarna 3/4 · $62',
        ),
        (
          en,
          'USD',
          ReminderOffset.days3,
          [p(6205)],
          false,
          r'In 3 days: Klarna 3/4 · $62.05',
        ),
        (
          en,
          'USD',
          ReminderOffset.sameDay,
          [p(100000), p(145000, name: 'Zip')],
          false,
          r'Today you have 2 payments · $2,450 in total',
        ),
        (
          en,
          'USD',
          ReminderOffset.sameDay,
          [p(1)],
          true,
          'Today you have 1 payment',
        ),
        (
          en,
          'EUR',
          ReminderOffset.days7,
          [p(1), p(2), p(3)],
          true,
          'In 7 days you have 3 payments',
        ),
        (
          en,
          'IDR',
          ReminderOffset.days1,
          [p(125000)],
          false,
          'Tomorrow: Klarna 3/4 · Rp125,000',
        ),
      ];

  for (final (l10n, code, offset, payments, hide, expected) in cases) {
    test('${l10n.localeName} $code ${offset.name} -> $expected', () {
      expect(
        reminderText(
          reminder(offset, payments),
          l10n: l10n,
          currency: Currency.fromCode(code),
          hideAmounts: hide,
        ),
        expected,
      );
    });
  }

  test('reminder texts stay calm', () {
    for (final l10n in [tr, en]) {
      for (final offset in ReminderOffset.values) {
        final text = reminderText(
          reminder(offset, [p(100), p(200)]),
          l10n: l10n,
          currency: Currency.fromCode('TRY'),
          hideAmounts: false,
        );
        expect(text, isNot(contains('!')));
        expect(text.toLowerCase(), isNot(contains('acil')));
        expect(text.toLowerCase(), isNot(contains('urgent')));
      }
    }
  });
}
