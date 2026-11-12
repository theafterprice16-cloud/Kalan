import 'package:material_ui/material_ui.dart';

import '../../app/format.dart';

/// Placeholder until this screen lands.
class PlanDetailScreen extends StatelessWidget {
  const PlanDetailScreen({super.key, required this.planId});

  final int planId;

  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: AppBar(title: Text(context.l10n.planPaymentsTitle)));
}
