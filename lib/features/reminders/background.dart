import 'dart:ui' show DartPluginRegistrant;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../app/locale.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/settings_repository.dart';
import '../../l10n/generated/app_localizations.dart';
import 'local_notifications.dart';
import 'reminder_scheduler.dart';

/// Loads the time zone database once and points tz.local at the device's
/// current zone. Call again on resume: the user may have travelled.
Future<void> refreshLocalTimeZone() async {
  tzdata.initializeTimeZones();
  try {
    final info = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(info.identifier));
  } on Object {
    // Unknown zone name: keep the previous (or UTC) location.
  }
}

/// Sets up what a background isolate needs and runs [body] with a
/// scheduler on the shared database.
Future<void> runReminderTask(
  Future<void> Function(ReminderScheduler scheduler) body,
) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  await refreshLocalTimeZone();
  final db = AppDatabase();
  try {
    final settings = await SettingsRepository(db).get();
    final l10n = lookupAppLocalizations(appLocale(settings?.localeCode));
    final gateway = await LocalNotificationsGateway.initialize(
      l10n: l10n,
      onBackground: onNotificationBackgroundResponse,
    );
    await body(
      ReminderScheduler(
        db: db,
        gateway: gateway,
        location: () => tz.local,
        now: DateTime.now,
        localeFor: (s) => appLocale(s.localeCode),
      ),
    );
  } finally {
    await db.close();
  }
}

/// "Paid" pressed on a notification while the app is closed.
@pragma('vm:entry-point')
Future<void> onNotificationBackgroundResponse(
  NotificationResponse response,
) async {
  if (response.actionId != ReminderIds.paidAction) return;
  await runReminderTask(
    (scheduler) => handlePaidAction(
      payload: response.payload,
      notificationId: response.id,
      scheduler: scheduler,
    ),
  );
}

/// Android: boot, clock or time zone change (ReminderRescheduleReceiver).
Future<void> rescheduleRemindersInBackgroundTask() async {
  try {
    await runReminderTask((scheduler) => scheduler.rescheduleAll());
  } finally {
    await const MethodChannel('kalan/background').invokeMethod<void>('done');
  }
}
