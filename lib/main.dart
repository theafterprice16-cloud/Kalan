import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';

import 'app/app.dart';
import 'core/theme/theme_mode.dart';
import 'entitlement/iap_store_gateway.dart';
import 'entitlement/pro_controller.dart';
import 'entitlement/pro_status_store.dart';
import 'features/export/backup_prefs.dart';
import 'features/export/export_service.dart';
import 'features/lock/app_lock_store.dart';
import 'features/lock/device_lock_gateway.dart';
import 'features/privacy/amounts_hidden.dart';
import 'features/reminders/background.dart';
import 'features/reminders/local_notifications.dart';
import 'features/reminders/reminder_providers.dart';
import 'l10n/generated/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Dates of every locale, before Flutter loads its own (Roadmap 24).
  await loadLocaleData();
  final overrides = <Override>[
    themeModeStoreProvider.overrideWithValue(await PrefsThemeModeStore.open()),
    // The last known Pro state, read before the first frame: Pro works
    // offline and the store is checked in the background.
    proStatusStoreProvider.overrideWithValue(await PrefsProStatusStore.open()),
    // App lock (27): read before the first frame, so a locked app never
    // shows a frame of data.
    appLockStoreProvider.overrideWithValue(await PrefsAppLockStore.open()),
    // "Hide amounts" (28): read before the first frame, so hidden amounts
    // never flash on screen.
    amountsHiddenStoreProvider.overrideWithValue(
      await PrefsAmountsHiddenStore.open(),
    ),
    // Last full backup and its reminder switch (29): this device's own.
    backupPrefsStoreProvider.overrideWithValue(
      await SharedBackupPrefsStore.open(),
    ),
  ];
  final phone =
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);
  if (phone) {
    overrides
      ..add(storeGatewayProvider.overrideWithValue(IapStoreGateway()))
      ..add(deviceLockGatewayProvider.overrideWithValue(LocalAuthDeviceLock()));
  }
  if (!kIsWeb) {
    await refreshLocalTimeZone();
    // A tapped reminder that launches the app opens the home screen,
    // which is where the app starts anyway; a statement closing reminder
    // opens its card over it (KalanApp).
    final gateway = await LocalNotificationsGateway.initialize(
      l10n: lookupAppLocalizations(appLocale(null)),
    );
    overrides
      ..add(notificationGatewayProvider.overrideWithValue(gateway))
      ..add(
        launchPayloadProvider.overrideWithValue(await gateway.launchPayload()),
      );
  }
  runApp(ProviderScope(overrides: overrides, child: const KalanApp()));
  // Nothing of an earlier export outlives a new start (29).
  if (phone) {
    unawaited(
      getTemporaryDirectory()
          .then(cleanUpExportFiles)
          // Best effort: the next export cleans up again.
          .catchError((Object _) {}),
    );
  }
}

/// Android: started by ReminderRescheduleReceiver after a reboot or a
/// clock or time zone change. Must stay in this library (main entrypoint).
@pragma('vm:entry-point')
Future<void> rescheduleRemindersInBackground() =>
    rescheduleRemindersInBackgroundTask();
