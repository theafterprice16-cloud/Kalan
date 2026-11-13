import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../core/theme/kalan_colors.dart';
import '../../l10n/generated/app_localizations.dart';
import 'notification_gateway.dart';

/// Identifiers shared with the platform setup.
abstract final class ReminderIds {
  static const channel = 'payment_reminders';
  static const paidAction = 'paid';
  static const paidCategory = 'payment_due';
  static const androidIcon = 'ic_stat_kalan';
  static const testNotification = 2147480000;
}

/// Taps and foreground "Paid" presses, delivered to the running app.
final notificationResponses =
    StreamController<NotificationResponse>.broadcast();

/// flutter_local_notifications behind [NotificationGateway]. Local only:
/// no push service, no network.
class LocalNotificationsGateway implements NotificationGateway {
  LocalNotificationsGateway._(this._plugin, this._l10n);

  final FlutterLocalNotificationsPlugin _plugin;
  final AppLocalizations _l10n;

  static const _system = MethodChannel('kalan/system');

  /// Sets up channels and the "Paid" action. [onBackground] must be a
  /// top-level function marked `@pragma('vm:entry-point')`.
  static Future<LocalNotificationsGateway> initialize({
    required AppLocalizations l10n,
    DidReceiveBackgroundNotificationResponseCallback? onBackground,
  }) async {
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(
      settings: InitializationSettings(
        android: const AndroidInitializationSettings(ReminderIds.androidIcon),
        iOS: DarwinInitializationSettings(
          // Permission is asked later, after Kalan's own explanation.
          requestAlertPermission: false,
          requestSoundPermission: false,
          requestBadgePermission: false,
          notificationCategories: [
            DarwinNotificationCategory(
              ReminderIds.paidCategory,
              actions: [
                DarwinNotificationAction.plain(
                  ReminderIds.paidAction,
                  l10n.notificationPaidAction,
                ),
              ],
            ),
          ],
        ),
      ),
      onDidReceiveNotificationResponse: notificationResponses.add,
      onDidReceiveBackgroundNotificationResponse: onBackground,
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

  /// The notification that launched the app, if any.
  Future<NotificationResponse?> launchResponse() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    return details?.didNotificationLaunchApp ?? false
        ? details!.notificationResponse
        : null;
  }

  NotificationDetails _details({required bool paidAction}) =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          ReminderIds.channel,
          _l10n.reminderChannelName,
          channelDescription: _l10n.reminderChannelDescription,
          icon: ReminderIds.androidIcon,
          color: KalanColors.light.accent,
          actions: paidAction
              ? [
                  AndroidNotificationAction(
                    ReminderIds.paidAction,
                    _l10n.notificationPaidAction,
                  ),
                ]
              : null,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBanner: true,
          presentList: true,
          presentSound: true,
          threadIdentifier: ReminderIds.channel,
          categoryIdentifier: paidAction ? ReminderIds.paidCategory : null,
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
  Future<void> replaceAll(List<ScheduledNotification> notifications) async {
    // Pending only: reminders already shown stay in the notification tray.
    await _plugin.cancelAllPendingNotifications();
    for (final n in notifications) {
      await _plugin.zonedSchedule(
        id: n.id,
        title: n.text,
        scheduledDate: n.fireAt,
        notificationDetails: _details(paidAction: n.hasPaidAction),
        // Inexact on purpose: no exact-alarm permission (see DECISIONS).
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: n.payload.encode(),
      );
    }
  }

  @override
  Future<void> cancel(int id) => _plugin.cancel(id: id);

  @override
  Future<void> showTest(String text, Duration delay) => _plugin.zonedSchedule(
    id: ReminderIds.testNotification,
    title: text,
    scheduledDate: tz.TZDateTime.now(tz.local).add(delay),
    notificationDetails: _details(paidAction: false),
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    payload: NotificationPayload(route: '/day/${_today()}').encode(),
  );

  static String _today() {
    final now = tz.TZDateTime.now(tz.local);
    String two(int v) => v.toString().padLeft(2, '0');
    return '${now.year}-${two(now.month)}-${two(now.day)}';
  }

  @override
  Future<void> openSystemSettings() async {
    try {
      await _system.invokeMethod<void>('openNotificationSettings');
    } on PlatformException {
      // Nothing else to do; the help page explains the manual path.
    }
  }
}
