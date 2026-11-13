import 'package:material_ui/material_ui.dart';

/// A picked value, so a null pick can be told apart from "dismissed".
class Choice<T> {
  const Choice(this.value);
  final T value;
}

/// A list of options; the selected one carries a check mark (color is
/// never the only sign).
class ChoiceDialog<T> extends StatelessWidget {
  const ChoiceDialog({
    required this.title,
    required this.selected,
    required this.options,
    super.key,
    this.note,
  });

  final String title;
  final T selected;
  final List<(T, String)> options;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: Text(title),
      children: [
        if (note != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(note!),
          ),
        for (final (value, label) in options)
          Semantics(
            selected: value == selected,
            child: ListTile(
              key: ValueKey('choice-$value'),
              minTileHeight: 48,
              title: Text(label),
              trailing: value == selected ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(context, Choice<T>(value)),
            ),
          ),
      ],
    );
  }
}

/// Shows a [ChoiceDialog]; null when dismissed.
Future<Choice<T>?> showChoiceDialog<T>(
  BuildContext context, {
  required String title,
  required T selected,
  required List<(T, String)> options,
  String? note,
}) => showDialog<Choice<T>>(
  context: context,
  builder: (_) => ChoiceDialog<T>(
    title: title,
    selected: selected,
    options: options,
    note: note,
  ),
);
