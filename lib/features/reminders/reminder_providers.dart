import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../app/locale.dart';
import '../../app/providers.dart';
import '../privacy/amounts_hidden.dart';
import 'notification_gateway.dart';
import 'reminder_scheduler.dart';
import 'reminder_settings_store.dart';

/// Overridden in main() with the real gateway; no-op on web and in tests.
final notificationGatewayProvider = Provider<NotificationGateway>(
  (ref) => const NoopNotificationGateway(),
);

/// The payload of the notification whose tap launched the app (main()
/// reads it); null otherwise. A payment reminder opens home, where the
/// app starts anyway; a statement closing reminder opens its card.
final launchPayloadProvider = Provider<String?>((ref) => null);

/// Wall clock "now"; overridden in tests.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final reminderSettingsStoreProvider = Provider(
  (ref) => ReminderSettingsStore(ref.watch(settingsRepositoryProvider)),
);

final privacySettingsProvider = Provider(
  (ref) => PrivacySettings(
    ref.watch(settingsRepositoryProvider),
    ref.watch(amountsHiddenStoreProvider),
  ),
);

final reminderSchedulerProvider = Provider((ref) {
  final privacy = ref.watch(privacySettingsProvider);
  return ReminderScheduler(
    db: ref.watch(databaseProvider),
    gateway: ref.watch(notificationGatewayProvider),
    location: () => tz.local,
    now: ref.watch(clockProvider),
    localeFor: (s) => appLocale(s.localeCode, ref.watch(appLocalesProvider)),
    // "Hide amounts" (28): read at each run, as the switch stands then.
    amountsHidden: () => privacy.amountsHidden,
  );
});

/// Whether the system allows notifications; refreshed on resume.
final notificationPermissionProvider = FutureProvider<bool>(
  (ref) => ref.watch(notificationGatewayProvider).permissionGranted(),
);

/// Quiet time before a reschedule, so a burst of changes runs it once.
final reminderDebounceProvider = Provider<Duration>(
  (ref) => const Duration(milliseconds: 300),
);

/// Reschedules every reminder whenever plans, payments, recurring payments,
/// sources (cards) or settings (reminder settings, language, currency)
/// change. One central listener instead of calls from screens; the app
/// also requests a run on start and when it comes back to the foreground.
final reminderSyncProvider = Provider<ReminderSync>((ref) {
  final sync = ReminderSync(
    ref.watch(reminderSchedulerProvider),
    debounce: ref.watch(reminderDebounceProvider),
  );
  ref.listen(plansProvider, (_, _) => sync.request());
  ref.listen(recurringProvider, (_, _) => sync.request());
  // Card days and the statement closing reminder.
  ref.listen(sourcesProvider, (_, _) => sync.request());
  ref.listen(settingsProvider, (_, _) => sync.request());
  // "Hide amounts" (28) lives outside the settings row.
  ref.listen(amountsHiddenProvider, (_, _) => sync.request());
  ref.onDispose(sync.dispose);
  return sync;
});

/// Debounces requests and runs at most one reschedule at a time, in the
/// background (the work is asynchronous; the UI never waits for it).
class ReminderSync {
  ReminderSync(this._scheduler, {required this.debounce});

  final ReminderScheduler _scheduler;
  final Duration debounce;
  Timer? _timer;
  Future<void>? _running;
  bool _again = false;
  bool _disposed = false;
  Completer<void>? _idle;

  /// Completes when no reschedule is waiting or running.
  Future<void> get idle => _idle?.future ?? Future.value();

  void request() {
    if (_disposed) return;
    _idle ??= Completer<void>();
    _timer?.cancel();
    _timer = Timer(debounce, _start);
  }

  void _start() {
    _timer = null;
    if (_running != null) {
      _again = true;
      return;
    }
    _running = _run();
  }

  Future<void> _run() async {
    do {
      _again = false;
      try {
        await _scheduler.rescheduleAll();
      } on Object {
        // A failed run (e.g. the database closing) must not break the app;
        // the next change or resume tries again.
        if (_disposed) break;
      }
    } while (_again && !_disposed);
    _running = null;
    if (_timer == null) _finish();
  }

  void _finish() {
    final idle = _idle;
    _idle = null;
    if (idle != null && !idle.isCompleted) idle.complete();
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    _finish();
  }
}
