import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const KalanApp());
}

/// Temporary root widget; replaced when the app shell lands.
class KalanApp extends StatelessWidget {
  const KalanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: Scaffold());
  }
}
