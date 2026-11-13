import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/format.dart';
import '../../core/date/local_date.dart';
import '../../core/design/form_fields.dart';
import '../../core/engine/pay_period.dart';
import '../../core/money/currency.dart';
import '../../core/money/money_format.dart';
import '../../data/db/app_database.dart';

/// Pay settings being edited, shared by onboarding and Settings.
class PayFormValue {
  PayFormValue({
    required this.frequency,
    required this.monthDay,
    required this.lastPayday,
    required this.weekday,
    required this.today,
  });

  factory PayFormValue.initial(LocalDate today) => PayFormValue(
    frequency: PayFrequency.monthly,
    monthDay: 1,
    lastPayday: today,
    weekday: DateTime.friday,
    today: today,
  );

  factory PayFormValue.fromSettings(SettingsRow s, LocalDate today) {
    final anchor = s.payAnchorDay == null
        ? today
        : LocalDate.fromEpochDay(s.payAnchorDay!);
    return PayFormValue(
      frequency: s.payFrequency,
      monthDay: s.payDay ?? 1,
      lastPayday: anchor,
      weekday: anchor.weekday,
      today: today,
    );
  }

  PayFrequency frequency;
  int monthDay;
  LocalDate lastPayday;
  int weekday;
  final LocalDate today;

  /// The most recent day on or before today that falls on [weekday].
  LocalDate get weeklyAnchor => today.addDays(-((today.weekday - weekday) % 7));

  AppSettingsCompanion toCompanion() => AppSettingsCompanion(
    payFrequency: Value(frequency),
    payDay: Value(frequency == PayFrequency.monthly ? monthDay : null),
    payAnchorDay: Value(switch (frequency) {
      PayFrequency.monthly => null,
      PayFrequency.biweekly => lastPayday.epochDay,
      PayFrequency.weekly => weeklyAnchor.epochDay,
    }),
  );
}

/// Frequency and payday fields.
class PayFields extends StatelessWidget {
  const PayFields({required this.value, required this.onChanged, super.key});

  final PayFormValue value;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // 2 Nov 2026 is a Monday; used only to get localized weekday names.
    final monday = LocalDate(2026, 11, 2);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ChoiceField<PayFrequency>(
          label: l10n.fieldPayFrequency,
          selected: value.frequency,
          options: [
            (PayFrequency.monthly, l10n.frequencyMonthly),
            (PayFrequency.biweekly, l10n.frequencyBiweekly),
            (PayFrequency.weekly, l10n.frequencyWeekly),
          ],
          onSelected: (f) {
            value.frequency = f;
            onChanged();
          },
        ),
        const SizedBox(height: 16),
        switch (value.frequency) {
          PayFrequency.monthly => DropdownButtonFormField<int>(
            key: const ValueKey('pay-day'),
            initialValue: value.monthDay,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: l10n.fieldPayDay,
              helperText: l10n.payDayHelp,
              helperMaxLines: 2,
            ),
            items: [
              for (var d = 1; d <= 31; d++)
                DropdownMenuItem(value: d, child: Text('$d')),
            ],
            onChanged: (d) {
              if (d == null) return;
              value.monthDay = d;
              onChanged();
            },
          ),
          PayFrequency.biweekly => DateField(
            key: const ValueKey('last-payday'),
            label: l10n.fieldLastPayday,
            value: value.lastPayday,
            format: context.longDate,
            lastDate: value.today.addDays(31),
            onChanged: (d) {
              value.lastPayday = d;
              onChanged();
            },
          ),
          PayFrequency.weekly => DropdownButtonFormField<int>(
            key: const ValueKey('pay-weekday'),
            initialValue: value.weekday,
            isExpanded: true,
            decoration: InputDecoration(labelText: l10n.fieldPayWeekday),
            items: [
              for (var w = 1; w <= 7; w++)
                DropdownMenuItem(
                  value: w,
                  child: Text(context.weekdayName(monday.addDays(w - 1))),
                ),
            ],
            onChanged: (w) {
              if (w == null) return;
              value.weekday = w;
              onChanged();
            },
          ),
        },
      ],
    );
  }
}

/// Optional amount field: empty is allowed, otherwise must parse.
class OptionalAmountField extends ConsumerWidget {
  const OptionalAmountField({
    required this.controller,
    required this.label,
    super.key,
    this.helperText,
    this.fieldKey,
    this.currency,
  });

  final TextEditingController controller;
  final String label;
  final String? helperText;
  final Key? fieldKey;

  /// Overrides the saved currency (onboarding, before it is saved).
  final Currency? currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = currency ?? ref.currency;
    return TextFormField(
      key: fieldKey,
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: c.decimals > 0),
      inputFormatters: amountInputFormatters(c, localeName: context.localeName),
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        helperMaxLines: 3,
      ),
      validator: (text) {
        if (text == null || text.trim().isEmpty) return null;
        return parseAmount(text, c, localeName: context.localeName) == null
            ? context.l10n.errorAmountInvalid(
                amountInputExample(c, localeName: context.localeName),
              )
            : null;
      },
    );
  }
}

/// Required amount field (at least one minor unit).
class AmountField extends ConsumerWidget {
  const AmountField({
    required this.controller,
    required this.label,
    super.key,
    this.onChanged,
    this.fieldKey,
  });

  final TextEditingController controller;
  final String label;
  final ValueChanged<String>? onChanged;
  final Key? fieldKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextFormField(
      key: fieldKey,
      controller: controller,
      keyboardType: ref.amountKeyboard,
      inputFormatters: ref.amountFormatters(context),
      decoration: InputDecoration(labelText: label),
      onChanged: onChanged,
      validator: (text) {
        if (text == null || text.trim().isEmpty) {
          return context.l10n.errorRequired;
        }
        final v = ref.parseMoney(context, text);
        return v == null || v < 1 ? ref.amountError(context) : null;
      },
    );
  }
}
