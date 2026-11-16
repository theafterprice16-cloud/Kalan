import 'package:material_ui/material_ui.dart';

import '../../app/format.dart';
import '../../core/design/form_fields.dart';
import '../../core/engine/engine.dart';

/// The payment interval choices, in screen order.
enum IntervalOption { sameDay, every30Days, biweekly, weekly, custom }

/// The state of the payment interval field: a choice, and the day count
/// when "Other" is chosen.
class IntervalInput {
  IntervalInput(PaymentInterval initial) {
    set(initial);
  }

  IntervalOption option = IntervalOption.sameDay;
  final customDays = TextEditingController();

  /// Shows [interval]: a preset when it is one, otherwise "Other" with its
  /// day count.
  void set(PaymentInterval interval) {
    option = switch (interval) {
      PaymentInterval.sameDay => IntervalOption.sameDay,
      PaymentInterval.every30Days => IntervalOption.every30Days,
      PaymentInterval.biweekly => IntervalOption.biweekly,
      PaymentInterval.weekly => IntervalOption.weekly,
      _ => IntervalOption.custom,
    };
    if (option == IntervalOption.custom) {
      customDays.text = '${interval.days}';
    }
  }

  /// The chosen interval, or null while "Other" has no valid day count.
  PaymentInterval? get interval => switch (option) {
    IntervalOption.sameDay => PaymentInterval.sameDay,
    IntervalOption.every30Days => PaymentInterval.every30Days,
    IntervalOption.biweekly => PaymentInterval.biweekly,
    IntervalOption.weekly => PaymentInterval.weekly,
    IntervalOption.custom => switch (int.tryParse(customDays.text.trim())) {
      final n? when PaymentInterval.everyDays(n).isValid =>
        PaymentInterval.everyDays(n),
      _ => null,
    },
  };

  void dispose() => customDays.dispose();
}

/// "Payment interval": a choice with the day count field below it when
/// "Other" is chosen.
class IntervalField extends StatelessWidget {
  const IntervalField({
    required this.input,
    required this.onChanged,
    super.key,
  });

  final IntervalInput input;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ChoiceField<IntervalOption>(
            key: const ValueKey('interval'),
            label: l10n.fieldPaymentInterval,
            selected: input.option,
            options: [
              (IntervalOption.sameDay, l10n.intervalSameDay),
              (IntervalOption.every30Days, l10n.intervalEvery30Days),
              (IntervalOption.biweekly, l10n.intervalBiweekly),
              (IntervalOption.weekly, l10n.intervalWeekly),
              (IntervalOption.custom, l10n.intervalCustom),
            ],
            onSelected: (o) {
              input.option = o;
              onChanged();
            },
          ),
          if (input.option == IntervalOption.custom) ...[
            const SizedBox(height: 16),
            TextFormField(
              key: const ValueKey('interval-days'),
              controller: input.customDays,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.fieldIntervalDays),
              onChanged: (_) => onChanged(),
              validator: (v) {
                final n = int.tryParse(v?.trim() ?? '');
                return n == null || !PaymentInterval.everyDays(n).isValid
                    ? l10n.errorStepInvalid
                    : null;
              },
            ),
          ],
        ],
      ),
    );
  }
}
