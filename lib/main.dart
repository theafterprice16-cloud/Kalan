import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:material_ui/material_ui.dart';

import 'app/app.dart';
import 'core/routing/router.dart';
import 'core/theme/theme_mode.dart';
import 'features/reminders/background.dart';
import 'features/reminders/local_notifications.dart';
import 'features/reminders/notification_gateway.dart';
import 'features/reminders/reminder_providers.dart';
import 'l10n/generated/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final overrides = <Override>[
    themeModeStoreProvider.overrideWithValue(await PrefsThemeModeStore.open()),
  ];
  if (!kIsWeb) {
    await refreshLocalTimeZone();
    final gateway = await LocalNotificationsGateway.initialize(
      l10n: lookupAppLocalizations(appLocale(null)),
      onBackground: onNotificationBackgroundResponse,
    );
    overrides.add(notificationGatewayProvider.overrideWithValue(gateway));
    // Opened by tapping a reminder: start on that day's payments.
    final launch = await gateway.launchResponse();
    final route = launch?.actionId == ReminderIds.paidAction
        ? null
        : NotificationPayload.decode(launch?.payload)?.route;
    if (route != null) {
      overrides.add(initialRouteProvider.overrideWithValue(route));
    }
  }
  runApp(ProviderScope(overrides: overrides, child: const KalanApp()));
}

/// Android: started by ReminderRescheduleReceiver after a reboot or a
/// clock or time zone change. Must stay in this library (main entrypoint).
@pragma('vm:entry-point')
Future<void> rescheduleRemindersInBackground() =>
    rescheduleRemindersInBackgroundTask();
