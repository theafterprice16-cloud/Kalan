import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'app/app.dart';
import 'core/theme/theme_mode.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themeStore = await PrefsThemeModeStore.open();
  runApp(
    ProviderScope(
      overrides: [themeModeStoreProvider.overrideWithValue(themeStore)],
      child: const KalanApp(),
    ),
  );
}
