import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../app/locale.dart';
import '../../app/providers.dart';
import 'notification_gateway.dart';
import 'reminder_scheduler.dart';
import 'reminder_settings_store.dart';

/// Overridden in main() with the real gateway; no-op on web and in tests.
final notificationGatewayProvider = Provider<NotificationGateway>(
  (ref) => const NoopNotificationGateway(),
);

/// Wall clock "now"; overridden in tests.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final reminderSettingsStoreProvider = Provider(
  (ref) => ReminderSettingsStore(ref.watch(settingsRepositoryProvider)),
);

final privacySettingsProvider = Provider(
  (ref) => PrivacySettings(ref.watch(settingsRepositoryProvider)),
);

final reminderSchedulerProvider = Provider((ref) {
  // Read now, not inside the closures: the scheduler outlives this build.
  final region = ref.watch(deviceRegionProvider);
  return ReminderScheduler(
    db: ref.watch(databaseProvider),
    gateway: ref.watch(notificationGatewayProvider),
    location: () => tz.local,
    now: ref.watch(clockProvider),
    localeFor: (s) => appLocale(s.localeCode),
    region: () => region,
  );
});

/// Whether the system allows notifications; refreshed on resume.
final notificationPermissionProvider = FutureProvider<bool>(
  (ref) => ref.watch(notificationGatewayProvider).permissionGranted(),
);

/// Reschedules every reminder whenever plans, payments, recurring payments
/// or settings change. One central listener instead of calls from screens.
final reminderSyncProvider = Provider<ReminderSync>((ref) {
  final sync = ReminderSync(ref.watch(reminderSchedulerProvider));
  ref.listen(plansProvider, (_, _) => sync.request());
  ref.listen(recurringProvider, (_, _) => sync.request());
  ref.listen(settingsProvider, (_, _) => sync.request());
  ref.onDispose(sync.dispose);
  return sync;
});

/// Coalesces bursts of changes into at most one running reschedule plus
/// one queued.
class ReminderSync {
  ReminderSync(this._scheduler);

  final ReminderScheduler _scheduler;
  Future<void>? _running;
  bool _again = false;
  bool _disposed = false;

  /// Completes when no reschedule is running.
  Future<void> get idle => _running ?? Future.value();

  void request() {
    if (_disposed) return;
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
  }

  void dispose() => _disposed = true;
}
