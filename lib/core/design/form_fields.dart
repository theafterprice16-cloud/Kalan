import 'package:material_ui/material_ui.dart';

import '../date/local_date.dart';

/// Read-only field that opens the platform date picker.
class DateField extends StatelessWidget {
  const DateField({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.format,
    super.key,
    this.firstDate,
    this.lastDate,
    this.trailing,
    this.helperText,
  });

  final String label;
  final LocalDate? value;
  final ValueChanged<LocalDate> onChanged;
  final String Function(LocalDate) format;
  final LocalDate? firstDate;
  final LocalDate? lastDate;
  final Widget? trailing;
  final String? helperText;

  Future<void> _pick(BuildContext context) async {
    final initial = (value ?? LocalDate.today()).toDateTime();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: (firstDate ?? LocalDate(2000, 1, 1)).toDateTime(),
      lastDate: (lastDate ?? LocalDate(2100, 12, 31)).toDateTime(),
    );
    if (picked != null) onChanged(LocalDate.fromDateTime(picked));
  }

  @override
  Widget build(BuildContext context) {
    final text = value == null ? '' : format(value!);
    return Semantics(
      button: true,
      label: label,
      value: text,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _pick(context),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            helperText: helperText,
            helperMaxLines: 3,
            suffixIcon: trailing ?? const Icon(Icons.calendar_today_outlined),
          ),
          isEmpty: value == null,
          child: Text(text),
        ),
      ),
    );
  }
}

/// A wrap of choice chips; scales with large text instead of overflowing.
class ChoiceField<T> extends StatelessWidget {
  const ChoiceField({
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final String label;
  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(label, style: Theme.of(context).textTheme.titleSmall),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (value, text) in options)
              ChoiceChip(
                label: Text(text),
                selected: value == selected,
                showCheckmark: true,
                onSelected: (_) => onSelected(value),
              ),
          ],
        ),
      ],
    );
  }
}
