import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/reminders/reminder_models.dart' show cardIdOfPayload;
import '../core/routing/router.dart';
import '../core/routing/routes.dart';
import '../core/theme/kalan_theme.dart';
import '../core/theme/theme_mode.dart';
import '../entitlement/pro_controller.dart';
import '../features/reminders/background.dart';
import '../features/reminders/local_notifications.dart';
import '../features/reminders/reminder_actions.dart';
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
    // Pro: the saved state at once, the store checked in the background,
    // and purchase updates heard from the start (before onboarding too).
    ref.read(proControllerProvider);
    // App start: schedule from the stored data right away.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(reminderSyncProvider).request();
      // Launched by tapping a statement closing reminder: over home.
      _openCard(ref.read(launchPayloadProvider));
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
    // The date may have changed (past midnight): past-due rows and their
    // "days ago" follow today.
    ref.invalidate(todayProvider);
    // A notification button may have marked payments while Kalan was in
    // the background: read them again.
    ref.invalidate(plansProvider);
    ref.invalidate(recurringProvider);
    ref.read(reminderSyncProvider).request();
    // Pro: a quiet store check (finishes an acknowledgement that failed).
    unawaited(ref.read(proControllerProvider.notifier).recheck());
  }

  /// A tapped reminder opens the home screen; a statement closing
  /// reminder opens its card's statements. A button, should the platform
  /// deliver one here, runs the same handler as in the background.
  void _onTap(NotificationResponse response) {
    if (ReminderActionIds.parse(response.actionId) != null) {
      unawaited(
        ReminderActionHandler(ref.read(reminderSchedulerProvider))
            .handle(actionId: response.actionId, payload: response.payload),
      );
      return;
    }
    if (_openCard(response.payload)) return;
    ref.read(routerProvider).go(Routes.home);
  }

  /// A statement closing reminder's [payload]: its card's statements
  /// (16) open over the current screen, so back returns there; not a
  /// second time when they are already on top (a second tap).
  bool _openCard(String? payload) {
    final card = cardIdOfPayload(payload);
    if (card == null) return false;
    final router = ref.read(routerProvider);
    final route = Routes.cardStatements(card);
    if (router.state.uri.toString() != route) {
      unawaited(router.push(route));
    }
    return true;
  }

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
