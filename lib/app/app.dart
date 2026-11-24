import 'dart:async';

import 'package:flutter/services.dart' show PredictiveBackEvent;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/reminders/reminder_models.dart' show cardIdOfPayload;
import '../core/routing/router.dart';
import '../core/routing/routes.dart';
import '../core/theme/kalan_theme.dart';
import '../core/theme/theme_mode.dart';
import '../entitlement/pro_controller.dart';
import '../features/holidays/holiday_providers.dart';
import '../features/home_widget/widget_sync.dart';
import '../features/lock/app_lock_controller.dart';
import '../features/lock/lock_screen.dart';
import '../features/plans/provider_templates_ui.dart';
import '../features/reminders/background.dart';
import '../features/reminders/local_notifications.dart';
import '../features/reminders/reminder_actions.dart';
import '../features/reminders/reminder_providers.dart';
import '../features/restore/restore_service.dart' show undoTidyProvider;
import '../l10n/generated/app_localizations.dart';
import 'locale.dart';
import 'providers.dart';

export 'locale.dart';

/// The app's texts; tests swap in longer ones (pseudo-localization).
final appLocalizationsDelegateProvider =
    Provider<LocalizationsDelegate<AppLocalizations>>(
      (ref) => AppLocalizations.delegate,
    );

class KalanApp extends ConsumerStatefulWidget {
  const KalanApp({super.key});

  @override
  ConsumerState<KalanApp> createState() => _KalanAppState();
}

class _KalanAppState extends ConsumerState<KalanApp>
    with WidgetsBindingObserver {
  late final AppLifecycleListener _lifecycle;
  StreamSubscription<NotificationResponse>? _taps;
  StreamSubscription<void>? _widgetTaps;

  @override
  void initState() {
    super.initState();
    // Before Flutter's own date formats load (Arabic: 0-9, not ٠-٩).
    useWesternDigits();
    // App lock (27): before the router's own back handling, so Android's
    // back button does nothing to the hidden screens while locked.
    WidgetsBinding.instance.addObserver(this);
    final lock = ref.read(appLockProvider.notifier);
    _lifecycle = AppLifecycleListener(
      onResume: _onResume,
      onInactive: lock.appInactive,
      onHide: lock.appHidden,
      onShow: lock.appShown,
    );
    _taps = notificationTaps.stream.listen(_onTap);
    // Home screen widget (31): a tap opens home; with the app lock on,
    // the lock screen covers it first (AppLockGate).
    _widgetTaps = ref.read(widgetGatewayProvider).taps.listen(_onWidgetTap);
    // Pro: the saved state at once, the store checked in the background,
    // and purchase updates heard from the start (before onboarding too).
    ref.read(proControllerProvider);
    // Provider templates (25) read from the app's own file now, so the
    // add plan screen opens with its section already in place.
    ref.read(providerTemplatesSourceProvider);
    // Public holidays (26): the stored card dates follow the shipped list
    // and the holiday country, now and whenever either changes.
    ref.listenManual(holidaySyncProvider, (_, _) {}, fireImmediately: true);
    // App start: schedule from the stored data right away.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(reminderSyncProvider).request();
      ref.read(widgetSyncProvider).request();
      // Restore (30): a copy older than 30 days goes; a restore stopped
      // halfway is finished.
      unawaited(ref.read(undoTidyProvider.future));
      // App lock (27): a locked cold start asks the phone once.
      unawaited(ref.read(appLockProvider.notifier).start());
      // Launched by tapping a statement closing reminder: over home.
      _openCard(ref.read(launchPayloadProvider));
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _lifecycle.dispose();
    unawaited(_taps?.cancel());
    unawaited(_widgetTaps?.cancel());
    super.dispose();
  }

  /// Back in the foreground: the zone or the date may have changed, and
  /// the user may have changed notification permission.
  Future<void> _onResume() async {
    unawaited(ref.read(appLockProvider.notifier).appResumed());
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
    // The widget's eight days start again from today.
    ref.read(widgetSyncProvider).request();
    // Pro: a quiet store check (finishes an acknowledgement that failed).
    unawaited(ref.read(proControllerProvider.notifier).recheck());
  }

  /// Android back while locked: kept by the lock screen (the screens
  /// under it stay as they are).
  @override
  Future<bool> didPopRoute() async => ref.read(appLockProvider).locked;

  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) =>
      ref.read(appLockProvider).locked;

  /// Home screen widget (31): home, once set up; during setup (and its
  /// "I have a backup") the tap only brings Kalan forward, so nothing
  /// typed there is lost.
  void _onWidgetTap(void _) {
    if (ref.read(settingsProvider).value == null) return;
    final router = ref.read(routerProvider);
    if (router.state.uri.path != Routes.home) router.go(Routes.home);
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
    // And the home screen widget (31).
    ref.watch(widgetSyncProvider);
    final router = ref.watch(routerProvider);
    final localeCode = ref.watch(
      settingsProvider.select((s) => s.value?.localeCode),
    );
    final locales = ref.watch(appLocalesProvider);
    // The picked language when it is open; otherwise the phone's, matched
    // to the reviewed locales only (a closed one is never shown).
    final chosen = chosenLocale(localeCode, locales);
    final locale = chosen == null ? null : localeOf(chosen);
    return MaterialApp.router(
      routerConfig: router,
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: KalanTheme.light(),
      darkTheme: KalanTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      locale: locale,
      // Flutter asks for the picked locale itself (this very object) and,
      // separately, for the phone's, kept for when the setting goes back
      // to the system: only the former answers with the picked one, so a
      // draft picked by hand is never kept as the phone's match.
      localeResolutionCallback: (requested, _) =>
          locale != null && identical(requested, locale)
          ? locale
          : resolveLocale(requested, locales),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: [
        ref.watch(appLocalizationsDelegateProvider),
        ...GlobalMaterialLocalizations.delegates,
      ],
      // App lock (27): the lock screen and the app switcher cover sit
      // over every screen; with the lock off this only passes through.
      builder: (context, child) =>
          AppLockGate(child: child ?? const SizedBox.shrink()),
      debugShowCheckedModeBanner: false,
    );
  }
}
