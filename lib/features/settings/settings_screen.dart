import 'package:material_ui/material_ui.dart';

import '../../app/format.dart';

/// Placeholder until this screen lands.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: AppBar(title: Text(context.l10n.navSettings)));
}
