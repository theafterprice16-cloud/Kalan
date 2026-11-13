import 'package:kalan/features/reminders/notification_gateway.dart';

/// Records what would be handed to the operating system.
class FakeNotificationGateway implements NotificationGateway {
  FakeNotificationGateway({this.granted = true, this.supported = true});

  @override
  final bool supported;

  bool granted;
  int permissionRequests = 0;
  int replaceCalls = 0;
  int openSettingsCalls = 0;
  final cancelled = <int>[];
  String? testText;
  List<ScheduledNotification> pending = const [];

  List<String> get texts => [for (final n in pending) n.text];

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return granted;
  }

  @override
  Future<bool> permissionGranted() async => granted;

  @override
  Future<void> replaceAll(List<ScheduledNotification> notifications) async {
    replaceCalls++;
    pending = List.of(notifications);
  }

  @override
  Future<void> cancel(int id) async {
    cancelled.add(id);
    pending = [
      for (final n in pending)
        if (n.id != id) n,
    ];
  }

  @override
  Future<void> showTest(String text, Duration delay) async => testText = text;

  @override
  Future<void> openSystemSettings() async => openSettingsCalls++;
}
