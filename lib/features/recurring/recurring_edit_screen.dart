import 'package:material_ui/material_ui.dart';

import '../../app/format.dart';

/// Placeholder until this screen lands.
class RecurringEditScreen extends StatelessWidget {
  const RecurringEditScreen({super.key, this.recurringId});

  final int? recurringId;

  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: AppBar(title: Text(context.l10n.recurringNewTitle)));
}
