import 'package:kalan/core/reminders/reminder_models.dart';
import 'package:kalan/features/reminders/notification_gateway.dart';

/// Records what would be handed to the operating system.
class FakeNotificationGateway implements NotificationGateway {
  FakeNotificationGateway({
    this.granted = true,
    this.supported = true,
    this.grantOnRequest = true,
  });

  @override
  final bool supported;

  /// Whether the system allows notifications right now.
  bool granted;

  /// What the system dialog answers.
  bool grantOnRequest;
  int permissionRequests = 0;
  int replaceCalls = 0;
  int openSettingsCalls = 0;
  String? testBody;
  PlannedReminder? testReminder;

  /// Everything handed over in the last [replaceAll].
  List<PlannedReminder> all = const [];

  /// The payment reminders in [all] (the payday summary is in [paydays],
  /// statement closing reminders in [statements]), so payment reminder
  /// tests see the same list with or without them.
  List<PlannedReminder> get pending => [
    for (final r in all)
      if (!r.isPaydaySummary && !r.isStatementClosing) r,
  ];

  /// The statement closing reminders in [all].
  List<PlannedReminder> get statements => [
    for (final r in all)
      if (r.isStatementClosing) r,
  ];

  /// The payday summary, when one is scheduled.
  List<PlannedReminder> get paydays => [
    for (final r in all)
      if (r.isPaydaySummary) r,
  ];

  List<String> get bodies => [for (final n in pending) n.body];

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    granted = grantOnRequest;
    return granted;
  }

  @override
  Future<bool> permissionGranted() async => granted;

  @override
  Future<void> replaceAll(List<PlannedReminder> reminders) async {
    replaceCalls++;
    all = List.of(reminders);
  }

  @override
  Future<void> showTest({
    required String title,
    required String body,
    required Duration delay,
  }) async => testBody = body;

  @override
  Future<void> showTestReminder(PlannedReminder reminder) async =>
      testReminder = reminder;

  @override
  Future<void> openSystemSettings() async => openSettingsCalls++;
}
