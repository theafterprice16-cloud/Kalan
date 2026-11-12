import 'package:material_ui/material_ui.dart';

import '../../app/format.dart';

/// Placeholder until this screen lands.
class SourceEditScreen extends StatelessWidget {
  const SourceEditScreen({super.key, this.sourceId, this.startAsCard = false});

  final int? sourceId;
  final bool startAsCard;

  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: AppBar(title: Text(context.l10n.editSource)));
}
