import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/format.dart';
import '../../app/providers.dart';
import '../../core/design/form_fields.dart';
import '../../core/engine/engine.dart';
import '../../core/theme/kalan_theme.dart';
import '../../data/db/app_database.dart';
import '../../data/models.dart';
import 'add_plan_screen.dart' show SourceNameField;

/// The "When will you pay?" chips.
enum PayLaterChoice { days14, days30, nextMonth, customDays, pickDate }

/// What the user has typed and picked on a "Pay later" form, shared by
/// the add and the edit screen.
class PayLaterInput {
  PayLaterInput({
    required this.purchaseDate,
    PayLaterRule rule = defaultPayLaterRule,
    this.chosenDate,
  }) {
    setRule(rule);
  }

  final amount = TextEditingController();
  final store = TextEditingController();
  final number = TextEditingController();
  final source = TextEditingController();
  final sourceFocus = FocusNode();
  PayLaterChoice choice = PayLaterChoice.days30;
  LocalDate purchaseDate;

  /// The picked due date ("Pick a date").
  LocalDate? chosenDate;

  /// Shows [rule] as the selected chip (and its number).
  void setRule(PayLaterRule rule) {
    switch (rule.kind) {
      case PayLaterRuleKind.days when rule.value == 14:
        choice = PayLaterChoice.days14;
      case PayLaterRuleKind.days when rule.value == 30:
        choice = PayLaterChoice.days30;
      case PayLaterRuleKind.days:
        choice = PayLaterChoice.customDays;
        number.text = '${rule.value}';
      case PayLaterRuleKind.nextMonthDay:
        choice = PayLaterChoice.nextMonth;
        number.text = '${rule.value}';
      case PayLaterRuleKind.chosenDate:
        choice = PayLaterChoice.pickDate;
    }
  }

  int? get _number => int.tryParse(number.text.trim());

  /// The rule for the current inputs; null while a number is missing or
  /// out of range.
  PayLaterRule? get rule {
    final rule = switch (choice) {
      PayLaterChoice.days14 => const PayLaterRule.days(14),
      PayLaterChoice.days30 => const PayLaterRule.days(30),
      PayLaterChoice.customDays => switch (_number) {
        final n? => PayLaterRule.days(n),
        null => null,
      },
      PayLaterChoice.nextMonth => switch (_number) {
        final n? => PayLaterRule.nextMonthDay(n),
        null => null,
      },
      PayLaterChoice.pickDate => const PayLaterRule.chosenDate(),
    };
    return rule != null && rule.isValid ? rule : null;
  }

  /// The due date for the current inputs, or null while incomplete.
  LocalDate? get dueDate {
    final rule = this.rule;
    if (rule == null) return null;
    if (rule.kind == PayLaterRuleKind.chosenDate && chosenDate == null) {
      return null;
    }
    return payLaterDueDate(
      purchase: purchaseDate,
      rule: rule,
      chosen: chosenDate,
    );
  }

  /// Every controller, to listen to.
  List<TextEditingController> get controllers => [
    amount,
    store,
    number,
    source,
  ];

  void dispose() {
    for (final c in controllers) {
      c.dispose();
    }
    sourceFocus.dispose();
  }
}

/// The "Pay later" fields: amount, store name, when to pay (with the
/// computed due date, updated as you type), purchase date and an optional
/// source. With [locked] (a paid plan) only the name and source change.
class PayLaterFields extends ConsumerWidget {
  const PayLaterFields({
    required this.input,
    required this.onChanged,
    super.key,
    this.locked = false,
  });

  final PayLaterInput input;
  final VoidCallback onChanged;
  final bool locked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final today = ref.watch(todayProvider);
    const gap = SizedBox(height: KalanSpace.md);
    final day = int.tryParse(input.number.text.trim());
    final nextMonthLabel =
        input.choice == PayLaterChoice.nextMonth &&
            day != null &&
            day >= 1 &&
            day <= 31
        ? l10n.payLaterNextMonthDay(day)
        : l10n.payLaterNextMonthChip;
    final due = input.dueDate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          key: const ValueKey('total'),
          controller: input.amount,
          enabled: !locked,
          keyboardType: ref.amountKeyboard,
          inputFormatters: ref.amountFormatters(context),
          decoration: InputDecoration(labelText: l10n.payLaterAmount),
          validator: (v) {
            if (locked) return null;
            final amount = v == null ? null : ref.parseMoney(context, v);
            if (v == null || v.trim().isEmpty) return l10n.errorRequired;
            return amount == null || amount < 1
                ? ref.amountError(context, v)
                : null;
          },
        ),
        gap,
        TextFormField(
          key: const ValueKey('store'),
          controller: input.store,
          maxLength: 80,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(labelText: l10n.payLaterStore),
        ),
        const SizedBox(height: KalanSpace.xs),
        IgnorePointer(
          ignoring: locked,
          child: ChoiceField<PayLaterChoice>(
            key: const ValueKey('pay-later-when'),
            label: l10n.payLaterWhen,
            selected: input.choice,
            options: [
              (PayLaterChoice.days14, l10n.payLaterDaysChip(14)),
              (PayLaterChoice.days30, l10n.payLaterDaysChip(30)),
              (PayLaterChoice.nextMonth, nextMonthLabel),
              (PayLaterChoice.customDays, l10n.payLaterCustomDays),
              (PayLaterChoice.pickDate, l10n.payLaterPickDate),
            ],
            onSelected: (c) {
              if (c != input.choice) {
                input
                  ..choice = c
                  ..number.clear();
                if (c == PayLaterChoice.pickDate) {
                  input.chosenDate ??= input.dueDate ?? today;
                }
              }
              onChanged();
            },
          ),
        ),
        if (input.choice == PayLaterChoice.nextMonth ||
            input.choice == PayLaterChoice.customDays) ...[
          gap,
          TextFormField(
            key: const ValueKey('pay-later-number'),
            controller: input.number,
            enabled: !locked,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: input.choice == PayLaterChoice.nextMonth
                  ? l10n.payLaterDayOfMonth
                  : l10n.payLaterCustomDays,
            ),
            validator: (v) {
              if (locked) return null;
              final n = int.tryParse(v?.trim() ?? '');
              return input.choice == PayLaterChoice.nextMonth
                  ? (n == null || n < 1 || n > 31
                        ? l10n.errorPayLaterDay
                        : null)
                  : (n == null || n < 1 || n > PayLaterRule.maxDays
                        ? l10n.errorPayLaterDays
                        : null);
            },
          ),
        ],
        if (input.choice == PayLaterChoice.pickDate) ...[
          gap,
          IgnorePointer(
            ignoring: locked,
            child: DateField(
              key: const ValueKey('pay-later-due-date'),
              label: l10n.payLaterDueDate,
              value: input.chosenDate,
              format: context.longDate,
              onChanged: (d) {
                input.chosenDate = d;
                onChanged();
              },
            ),
          ),
        ],
        if (due != null) ...[
          gap,
          PayLaterDueLine(key: const ValueKey('pay-later-due'), due: due),
        ],
        gap,
        IgnorePointer(
          ignoring: locked,
          child: DateField(
            key: const ValueKey('purchase-date'),
            label: l10n.payLaterPurchaseDate,
            value: input.purchaseDate,
            format: (d) =>
                d == today ? l10n.payLaterToday : context.longDate(d),
            onChanged: (d) {
              input.purchaseDate = d;
              onChanged();
            },
          ),
        ),
        gap,
        SourceNameField(
          controller: input.source,
          focusNode: input.sourceFocus,
          sources: ref.watch(sourcesProvider).value ?? const <SourceRow>[],
          label: l10n.payLaterSource,
          validator: (_) => null,
        ),
      ],
    );
  }
}

/// "Due on 14 December 2026" in text, and "In 30 days" (or "4 days ago")
/// in textMuted. [short] uses "14 December" (lists).
class PayLaterDueLine extends ConsumerWidget {
  const PayLaterDueLine({
    required this.due,
    super.key,
    this.showDaysLeft = true,
    this.short = false,
  });

  final LocalDate due;
  final bool showDaysLeft;
  final bool short;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final days = ref.watch(todayProvider).daysUntil(due);
    final date = short ? context.dayMonth(due) : context.longDate(due);
    return Wrap(
      spacing: KalanSpace.xs,
      children: [
        Text(
          l10n.payLaterDueOn(date),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: context.colors.text,
          ),
        ),
        if (showDaysLeft)
          Text(
            days >= 0
                ? l10n.payLaterDaysLeft(days)
                : l10n.pastDueDaysAgo(-days),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: context.colors.textMuted,
            ),
          ),
      ],
    );
  }
}

/// "30 days later", "Next month on day 27", "Chosen date".
String payLaterRuleLabel(BuildContext context, PayLaterRule rule) {
  final l10n = context.l10n;
  return switch (rule.kind) {
    PayLaterRuleKind.days => l10n.payLaterRuleDays(rule.value!),
    PayLaterRuleKind.nextMonthDay => l10n.payLaterNextMonthDay(rule.value!),
    PayLaterRuleKind.chosenDate => l10n.payLaterRuleChosen,
  };
}

/// Plan detail: due date, the rule and the source of a "Pay later" plan
/// (the purchase date is on the card already).
class PayLaterSummary extends StatelessWidget {
  const PayLaterSummary({required this.plan, super.key});

  final PlanWithPayments plan;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final muted = Theme.of(context).textTheme.bodyMedium
        ?.copyWith(color: context.colors.textMuted);
    final rule = plan.payLaterRule;
    return Column(
      key: const ValueKey('pay-later-summary'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PayLaterDueLine(
          due: plan.allPayments.first.date,
          showDaysLeft: plan.isOpen,
        ),
        if (rule != null)
          Text(
            l10n.payLaterRuleLine(payLaterRuleLabel(context, rule)),
            style: muted,
          ),
        if (plan.source case final source?)
          Text(l10n.payLaterSourceLine(source.name), style: muted),
      ],
    );
  }
}
