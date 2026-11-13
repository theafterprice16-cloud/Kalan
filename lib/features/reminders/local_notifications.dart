import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../core/reminders/reminder_models.dart';
import '../../core/theme/kalan_colors.dart';
import '../../l10n/generated/app_localizations.dart';
import 'background.dart';
import 'notification_gateway.dart';
import 'reminder_actions.dart';

/// Identifiers shared with the platform setup.
abstract final class ReminderIds {
  static const channel = 'payment_reminders';
  static const androidIcon = 'ic_stat_kalan';

  /// Far from reminder ids (fire day × 2 + kind) and snoozed ones (2^30 +
  /// snooze id).
  static const testNotification = 2147480000;

  /// The debug "test reminder with buttons".
  static const testReminder = 2147480001;
}

/// Taps (and, should a platform send them here, buttons) on a
/// notification while the app runs.
final notificationTaps = StreamController<NotificationResponse>.broadcast();

/// Button names in [l10n], for the iOS categories.
Map<ReminderAction, String> reminderButtonTitles(AppLocalizations l10n) => {
  ReminderAction.paid: l10n.reminderActionPaid,
  ReminderAction.allPaid: l10n.reminderActionAllPaid,
  ReminderAction.remindTonight: l10n.reminderActionRemindTonight,
  ReminderAction.remindTomorrow: l10n.reminderActionRemindTomorrow,
};

/// iOS: one category per button combination. "Paid" and "All paid" ask
/// for the phone to be unlocked first (Face ID, Touch ID or the code);
/// none of the buttons opens the app.
List<DarwinNotificationCategory> reminderCategories(
  Map<ReminderAction, String> titles,
) => [
  for (final actions in ReminderActionIds.combinations)
    DarwinNotificationCategory(
      ReminderActionIds.category(actions)!,
      actions: [
        for (final a in actions)
          DarwinNotificationAction.plain(
            ReminderActionIds.of(a),
            titles[a]!,
            options: a.marksPaid
                ? const {DarwinNotificationActionOption.authenticationRequired}
                : const {},
          ),
      ],
    ),
];

/// Android: the buttons run in the background without opening the app
/// and close the notification.
List<AndroidNotificationAction> reminderAndroidActions(
  List<ReminderButton> buttons,
) => [
  for (final b in buttons)
    AndroidNotificationAction(
      ReminderActionIds.of(b.action),
      b.title,
      // Stated on purpose (both are the plugin's defaults today).
      showsUserInterface: false,
      cancelNotification: true,
    ),
];

/// flutter_local_notifications behind [NotificationGateway]. Local only:
/// no push service, no network.
class LocalNotificationsGateway implements NotificationGateway {
  LocalNotificationsGateway._(this._plugin, this._l10n, this._titles);

  final FlutterLocalNotificationsPlugin _plugin;
  final AppLocalizations _l10n;

  /// Button names the iOS categories were last registered with.
  Map<ReminderAction, String> _titles;

  static const _system = MethodChannel('kalan/system');

  /// Sets up the plugin, the iOS button categories and the Android
  /// channel. A tap opens the app on the home screen, whether it was
  /// running or closed; a button runs [reminderActionInBackground].
  static Future<LocalNotificationsGateway> initialize({
    required AppLocalizations l10n,
  }) async {
    final plugin = FlutterLocalNotificationsPlugin();
    final titles = reminderButtonTitles(l10n);
    await _initialize(plugin, titles);
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
    return LocalNotificationsGateway._(plugin, l10n, titles);
  }

  static Future<void> _initialize(
    FlutterLocalNotificationsPlugin plugin,
    Map<ReminderAction, String> titles,
  ) => plugin.initialize(
    settings: InitializationSettings(
      android: const AndroidInitializationSettings(ReminderIds.androidIcon),
      iOS: DarwinInitializationSettings(
        // Permission is asked later, after Kalan's own explanation.
        requestAlertPermission: false,
        requestSoundPermission: false,
        requestBadgePermission: false,
        notificationCategories: reminderCategories(titles),
      ),
    ),
    onDidReceiveNotificationResponse: notificationTaps.add,
    onDidReceiveBackgroundNotificationResponse: reminderActionInBackground,
  );

  NotificationDetails _details(
    String expanded, {
    List<ReminderButton> buttons = const [],
  }) => NotificationDetails(
    android: AndroidNotificationDetails(
      ReminderIds.channel,
      _l10n.reminderChannelName,
      channelDescription: _l10n.reminderChannelDescription,
      icon: ReminderIds.androidIcon,
      // Accent from docs/DESIGN_TOKENS.md (light theme), via KalanColors.
      color: KalanColors.light.accent,
      styleInformation: BigTextStyleInformation(expanded),
      actions: reminderAndroidActions(buttons),
      // Android cannot ask for the phone to be unlocked before a button
      // runs, so a reminder with buttons is not shown on a secure lock
      // screen at all; it is in the shade once the phone is unlocked
      // (see DECISIONS, "Bildirimden ödendi").
      visibility: buttons.isEmpty ? null : NotificationVisibility.secret,
    ),
    iOS: DarwinNotificationDetails(
      // Shown while Kalan is in the foreground too.
      presentAlert: true,
      presentBanner: true,
      presentList: true,
      presentSound: true,
      threadIdentifier: ReminderIds.channel,
      categoryIdentifier: ReminderActionIds.category(
        buttons.map((b) => b.action),
      ),
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

  /// iOS keeps button names in categories registered up front. The app
  /// language can differ from the phone's (and can change), so the
  /// categories are registered again when the names change.
  Future<void> _updateCategories(List<PlannedReminder> reminders) async {
    final titles = {
      ..._titles,
      for (final r in reminders)
        for (final b in r.buttons) b.action: b.title,
    };
    if (mapEquals(titles, _titles)) return;
    _titles = titles;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _initialize(_plugin, titles);
    }
  }

  Future<void> _schedule(PlannedReminder r) => _plugin.zonedSchedule(
    id: r.id,
    title: r.title,
    // iOS shows the long body when the notification is expanded;
    // Android shows the short one and the big text when expanded.
    body: defaultTargetPlatform == TargetPlatform.iOS ? r.expandedBody : r.body,
    scheduledDate: r.fireAt,
    notificationDetails: _details(r.expandedBody, buttons: r.buttons),
    // Inexact on purpose: no exact-alarm permission (see DECISIONS).
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    // The buttons' data; a tap still opens the home screen.
    payload: r.data?.encode() ?? r.payload,
  );

  @override
  Future<void> replaceAll(List<PlannedReminder> reminders) async {
    await _updateCategories(reminders);
    // Pending only: reminders already shown stay in the notification tray.
    await _plugin.cancelAllPendingNotifications();
    for (final r in reminders) {
      await _schedule(r);
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
  Future<void> showTestReminder(PlannedReminder reminder) async {
    await _updateCategories([reminder]);
    await _schedule(reminder);
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
