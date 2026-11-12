import 'package:timezone/timezone.dart' as tz;

/// One notification handed to the operating system.
class ScheduledNotification {
  const ScheduledNotification({
    required this.id,
    required this.text,
    required this.fireAt,
    required this.payload,
    this.hasPaidAction = false,
  });

  final int id;
  final String text;
  final tz.TZDateTime fireAt;
  final NotificationPayload payload;
  final bool hasPaidAction;
}

/// What a notification carries: where a tap goes, and which payment the
/// "Paid" action marks. Encoded as "route|ref" ("/day/2026-11-12|p:12").
class NotificationPayload {
  const NotificationPayload({required this.route, this.paymentRef});

  static NotificationPayload? decode(String? text) {
    if (text == null || !text.startsWith('/')) return null;
    final parts = text.split('|');
    return NotificationPayload(
      route: parts.first,
      paymentRef: parts.length > 1 && parts[1].isNotEmpty ? parts[1] : null,
    );
  }

  final String route;

  /// PaymentRef.encode() of the single payment, if any.
  final String? paymentRef;

  String encode() => paymentRef == null ? route : '$route|$paymentRef';
}

/// The operating system's notification service, behind an interface so the
/// rules stay testable without a device.
abstract interface class NotificationGateway {
  /// Whether this platform can show notifications at all (false on web).
  bool get supported;

  /// Asks the system for permission (iOS alert/sound/badge, Android 13+).
  Future<bool> requestPermission();

  /// Whether the system currently allows Kalan's notifications.
  Future<bool> permissionGranted();

  /// Cancels every pending reminder and schedules [notifications].
  Future<void> replaceAll(List<ScheduledNotification> notifications);

  /// Removes one shown or pending notification.
  Future<void> cancel(int id);

  /// Debug only: a notification in [delay].
  Future<void> showTest(String text, Duration delay);

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
  Future<void> replaceAll(List<ScheduledNotification> notifications) async {}

  @override
  Future<void> cancel(int id) async {}

  @override
  Future<void> showTest(String text, Duration delay) async {}

  @override
  Future<void> openSystemSettings() async {}
}
