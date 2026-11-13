import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../core/reminders/reminder_models.dart';
import '../../core/theme/kalan_colors.dart';
import '../../l10n/generated/app_localizations.dart';
import 'notification_gateway.dart';

/// Identifiers shared with the platform setup.
abstract final class ReminderIds {
  static const channel = 'payment_reminders';
  static const androidIcon = 'ic_stat_kalan';

  /// Far from reminder ids (fire day × 2 + kind).
  static const testNotification = 2147480000;
}

/// Taps on a notification while the app runs.
final notificationTaps = StreamController<NotificationResponse>.broadcast();

/// flutter_local_notifications behind [NotificationGateway]. Local only:
/// no push service, no network.
class LocalNotificationsGateway implements NotificationGateway {
  LocalNotificationsGateway._(this._plugin, this._l10n);

  final FlutterLocalNotificationsPlugin _plugin;
  final AppLocalizations _l10n;

  static const _system = MethodChannel('kalan/system');

  /// Sets up the plugin and the Android channel. A tap opens the app on
  /// the home screen, whether it was running or closed.
  static Future<LocalNotificationsGateway> initialize({
    required AppLocalizations l10n,
  }) async {
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings(ReminderIds.androidIcon),
        iOS: DarwinInitializationSettings(
          // Permission is asked later, after Kalan's own explanation.
          requestAlertPermission: false,
          requestSoundPermission: false,
          requestBadgePermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: notificationTaps.add,
    );
    await plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          AndroidNotificationChannel(
            ReminderIds.channel,
            l10n.reminderChannelName,
            description: l10n.reminderChannelDescription,
          ),
        );
    return LocalNotificationsGateway._(plugin, l10n);
  }

  NotificationDetails _details(String expanded) => NotificationDetails(
    android: AndroidNotificationDetails(
      ReminderIds.channel,
      _l10n.reminderChannelName,
      channelDescription: _l10n.reminderChannelDescription,
      icon: ReminderIds.androidIcon,
      // Accent from docs/DESIGN_TOKENS.md (light theme), via KalanColors.
      color: KalanColors.light.accent,
      styleInformation: BigTextStyleInformation(expanded),
    ),
    iOS: const DarwinNotificationDetails(
      // Shown while Kalan is in the foreground too.
      presentAlert: true,
      presentBanner: true,
      presentList: true,
      presentSound: true,
      threadIdentifier: ReminderIds.channel,
    ),
  );

  @override
  bool get supported => !kIsWeb;

  @override
  Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    return await ios?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        false;
  }

  @override
  Future<bool> permissionGranted() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.areNotificationsEnabled() ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    return (await ios?.checkPermissions())?.isEnabled ?? false;
  }

  @override
  Future<void> replaceAll(List<PlannedReminder> reminders) async {
    // Pending only: reminders already shown stay in the notification tray.
    await _plugin.cancelAllPendingNotifications();
    for (final r in reminders) {
      await _plugin.zonedSchedule(
        id: r.id,
        title: r.title,
        // iOS shows the long body when the notification is expanded;
        // Android shows the short one and the big text when expanded.
        body: defaultTargetPlatform == TargetPlatform.iOS
            ? r.expandedBody
            : r.body,
        scheduledDate: r.fireAt,
        notificationDetails: _details(r.expandedBody),
        // Inexact on purpose: no exact-alarm permission (see DECISIONS).
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: r.payload,
      );
    }
  }

  @override
  Future<void> showTest({
    required String title,
    required String body,
    required Duration delay,
  }) => _plugin.zonedSchedule(
    id: ReminderIds.testNotification,
    title: title,
    body: body,
    scheduledDate: tz.TZDateTime.now(tz.local).add(delay),
    notificationDetails: _details(body),
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    payload: reminderPayload,
  );

  @override
  Future<void> openSystemSettings() async {
    try {
      await _system.invokeMethod<void>('openNotificationSettings');
    } on PlatformException {
      // Nothing else to do; the help page explains the manual path.
    }
  }
}
