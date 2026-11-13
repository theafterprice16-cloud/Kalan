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
import 'reminder_actions.dart';
import 'reminder_scheduler.dart';

/// Loads the time zone database once and points tz.local at the device's
/// current zone. Call again on resume: the user may have travelled.
Future<void> refreshLocalTimeZone() async {
  tzdata.initializeTimeZones();
  try {
    // Never let a slow platform answer hold back rescheduling.
    final info = await FlutterTimezone.getLocalTimezone().timeout(
      const Duration(seconds: 2),
    );
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
    final gateway = await LocalNotificationsGateway.initialize(l10n: l10n);
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

/// Android: boot, clock or time zone change (ReminderRescheduleReceiver).
Future<void> rescheduleRemindersInBackgroundTask() async {
  try {
    await runReminderTask((scheduler) => scheduler.rescheduleAll());
  } finally {
    await const MethodChannel('kalan/background').invokeMethod<void>('done');
  }
}

/// A notification button ("Paid", "All paid", "Remind tonight", "Remind
/// tomorrow"). The plugin runs it in its own background isolate whether
/// Kalan is closed, in the background or on screen; the app does not
/// open. The database is shared with the app if it is running (see
/// [AppDatabase.openShared]), so its screens update at once.
///
/// Never throws: a deleted plan or a damaged payload simply does nothing.
@pragma('vm:entry-point')
Future<void> reminderActionInBackground(NotificationResponse response) async {
  try {
    await runReminderTask(
      (scheduler) =>
          ReminderActionHandler(scheduler)
              .handle(actionId: response.actionId, payload: response.payload),
    );
  } on Object {
    // Nothing to show from the background; the next reschedule (app
    // start, resume) brings the reminders back in step.
  }
}
