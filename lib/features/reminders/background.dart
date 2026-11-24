import 'dart:ui' show DartPluginRegistrant;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../app/locale.dart';
import '../../core/widget/widget_snapshot.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/settings_repository.dart';
import '../../l10n/generated/app_localizations.dart';
import '../home_widget/widget_amounts.dart';
import '../home_widget/widget_gateway.dart';
import '../home_widget/widget_sync.dart';
import '../lock/app_lock_store.dart';
import '../privacy/amounts_hidden.dart';
import 'local_notifications.dart';
import 'notification_gateway.dart';
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

/// Sets up what a background isolate needs and runs [body] on the
/// shared database.
Future<void> _withDatabase(Future<void> Function(AppDatabase db) body) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  await loadLocaleData();
  await refreshLocalTimeZone();
  final db = AppDatabase();
  try {
    await body(db);
  } finally {
    await db.close();
  }
}

ReminderScheduler _schedulerFor(
  AppDatabase db,
  NotificationGateway gateway, {
  bool amountsHidden = false,
}) => ReminderScheduler(
  db: db,
  gateway: gateway,
  location: () => tz.local,
  now: DateTime.now,
  localeFor: (s) => appLocale(s.localeCode),
  amountsHidden: () => amountsHidden,
);

/// "Hide amounts" (28) from the device's storage, as the app left it.
/// Hidden when it cannot be read: a notification never shows an amount
/// by mistake.
Future<bool> _amountsHidden() async {
  try {
    return (await PrefsAmountsHiddenStore.open()).read();
  } on Object {
    return true;
  }
}

/// The home screen widget's mask (31) from the device's storage, as the
/// app left it. Masked when anything cannot be read: the widget never
/// shows an amount by mistake.
Future<bool> _widgetMasked() async {
  try {
    return widgetAmountsMasked(
      hideAmounts: (await PrefsAmountsHiddenStore.open()).read(),
      appLock: (await PrefsAppLockStore.open()).read().enabled,
      showInWidget: (await PrefsWidgetAmountsStore.open()).read(),
    );
  } on Object {
    return true;
  }
}

/// Redraws the home screen widget (31) after a notification button
/// changed what it shows. Best effort: the next app start or resume
/// redraws it anyway.
Future<void> _refreshWidget(AppDatabase db) async {
  final masked = await _widgetMasked();
  try {
    await WidgetPublisher(
      db: db,
      gateway: const HomeWidgetGateway(),
      now: DateTime.now,
      localeFor: (s) => appLocale(s?.localeCode),
      masked: () => masked,
    ).publish();
  } on Object {
    // The widget keeps its last text until the app runs.
  }
}

/// The real notification service, in the app language.
Future<NotificationGateway> _gatewayFor(AppDatabase db) async {
  final settings = await SettingsRepository(db).get();
  final l10n = lookupAppLocalizations(appLocale(settings?.localeCode));
  return LocalNotificationsGateway.initialize(l10n: l10n);
}

/// Runs [body] with a scheduler on the shared database.
Future<void> runReminderTask(
  Future<void> Function(ReminderScheduler scheduler) body,
) => _withDatabase(
  (db) async => body(
    _schedulerFor(
      db,
      await _gatewayFor(db),
      amountsHidden: await _amountsHidden(),
    ),
  ),
);

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
    await _withDatabase((db) async {
      // The change itself first: iOS gives a button only a few seconds in
      // the background, so marking (or storing the snooze) must not wait
      // for the notification service to start.
      final result =
          await ReminderActionHandler(
            _schedulerFor(db, const NoopNotificationGateway()),
          ).handle(
            actionId: response.actionId,
            payload: response.payload,
            reschedule: false,
          );
      if (result.outcome == ReminderActionOutcome.ignored) return;
      // Then the reminders. Should iOS stop Kalan before this, the next
      // app start or resume reschedules anyway.
      await _schedulerFor(
        db,
        await _gatewayFor(db),
        amountsHidden: await _amountsHidden(),
      ).rescheduleAll();
      // A payment marked paid leaves the widget's next rows (31). Last:
      // iOS may stop Kalan early, and the reminders matter more.
      if (result.outcome == ReminderActionOutcome.markedPaid) {
        await _refreshWidget(db);
      }
    });
  } on Object {
    // Nothing to show from the background; the next reschedule (app
    // start, resume) brings the reminders back in step.
  }
}
