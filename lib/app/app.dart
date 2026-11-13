import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/routing/router.dart';
import '../core/routing/routes.dart';
import '../core/theme/kalan_theme.dart';
import '../core/theme/theme_mode.dart';
import '../features/reminders/background.dart';
import '../features/reminders/local_notifications.dart';
import '../features/reminders/reminder_providers.dart';
import '../l10n/generated/app_localizations.dart';
import 'locale.dart';
import 'providers.dart';

export 'locale.dart';

class KalanApp extends ConsumerStatefulWidget {
  const KalanApp({super.key});

  @override
  ConsumerState<KalanApp> createState() => _KalanAppState();
}

class _KalanAppState extends ConsumerState<KalanApp> {
  late final AppLifecycleListener _lifecycle;
  StreamSubscription<NotificationResponse>? _taps;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _onResume);
    _taps = notificationTaps.stream.listen(_onTap);
    // App start: schedule from the stored data right away.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(reminderSyncProvider).request();
    });
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    unawaited(_taps?.cancel());
    super.dispose();
  }

  /// Back in the foreground: the zone or the date may have changed, and
  /// the user may have changed notification permission.
  Future<void> _onResume() async {
    if (ref.read(notificationGatewayProvider).supported) {
      await refreshLocalTimeZone();
    }
    if (!mounted) return;
    ref.invalidate(notificationPermissionProvider);
    ref.read(reminderSyncProvider).request();
  }

  /// A tapped reminder opens the home screen.
  void _onTap(NotificationResponse response) =>
      ref.read(routerProvider).go(Routes.home);

  @override
  Widget build(BuildContext context) {
    // Keeps reminders in step with every change to payments or settings.
    ref.watch(reminderSyncProvider);
    final router = ref.watch(routerProvider);
    final localeCode = ref.watch(
      settingsProvider.select((s) => s.value?.localeCode),
    );
    return MaterialApp.router(
      routerConfig: router,
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: KalanTheme.light(),
      darkTheme: KalanTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      locale: localeCode == null ? null : Locale(localeCode),
      localeResolutionCallback: resolveLocale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      debugShowCheckedModeBanner: false,
    );
  }
}
