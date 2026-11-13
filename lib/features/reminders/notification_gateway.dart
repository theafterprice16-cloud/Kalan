import '../../core/reminders/reminder_models.dart';

/// The operating system's notification service, behind an interface so the
/// rules stay testable without a device. Local notifications only.
abstract interface class NotificationGateway {
  /// Whether this platform can show notifications at all (false on web).
  bool get supported;

  /// Asks the system for permission (iOS alert/sound/badge, Android 13+;
  /// Android 12 and older grant it without a dialog).
  Future<bool> requestPermission();

  /// Whether the system currently allows Kalan's notifications.
  Future<bool> permissionGranted();

  /// Cancels Kalan's pending reminders and schedules [reminders].
  Future<void> replaceAll(List<PlannedReminder> reminders);

  /// Debug builds only: a sample notification after [delay].
  Future<void> showTest({
    required String title,
    required String body,
    required Duration delay,
  });

  /// Debug builds only: [reminder] with its buttons, at its time.
  Future<void> showTestReminder(PlannedReminder reminder);

  /// Opens the system's notification settings for Kalan.
  Future<void> openSystemSettings();
}

/// Web and tests: nothing is scheduled.
class NoopNotificationGateway implements NotificationGateway {
  const NoopNotificationGateway();

  @override
  bool get supported => false;

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<bool> permissionGranted() async => false;

  @override
  Future<void> replaceAll(List<PlannedReminder> reminders) async {}

  @override
  Future<void> showTest({
    required String title,
    required String body,
    required Duration delay,
  }) async {}

  @override
  Future<void> showTestReminder(PlannedReminder reminder) async {}

  @override
  Future<void> openSystemSettings() async {}
}
