import 'package:drift/drift.dart' show Value;

import '../../core/reminders/reminder_models.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/settings_repository.dart';

extension ReminderSettingsRowX on SettingsRow {
  ReminderSettings get reminderSettings => ReminderSettings(
    enabled: remindersEnabled,
    offsets: {
      if (remindDays7) ReminderOffset.days7,
      if (remindDays3) ReminderOffset.days3,
      if (remindDays1) ReminderOffset.days1,
      if (remindSameDay) ReminderOffset.sameDay,
    },
    minuteOfDay: reminderMinute,
    hideAmounts: hideAmountsInNotifications,
  );
}

/// Reads and writes reminder settings (kept in the settings row).
class ReminderSettingsStore {
  ReminderSettingsStore(this._settings);

  final SettingsRepository _settings;

  Future<void> setEnabled(bool on) =>
      _settings.update(AppSettingsCompanion(remindersEnabled: Value(on)));

  Future<void> setOffset(ReminderOffset offset, bool on) => _settings.update(
    switch (offset) {
      ReminderOffset.days7 => AppSettingsCompanion(remindDays7: Value(on)),
      ReminderOffset.days3 => AppSettingsCompanion(remindDays3: Value(on)),
      ReminderOffset.days1 => AppSettingsCompanion(remindDays1: Value(on)),
      ReminderOffset.sameDay => AppSettingsCompanion(remindSameDay: Value(on)),
    },
  );

  Future<void> setMinuteOfDay(int minute) =>
      _settings.update(AppSettingsCompanion(reminderMinute: Value(minute)));

  /// The in-app prompt was answered; it is never shown again.
  Future<void> markPromptAnswered({required bool remind}) => _settings.update(
    AppSettingsCompanion(
      reminderPromptShown: const Value(true),
      remindersEnabled: Value(remind),
    ),
  );
}

/// The one place for "hide amounts" choices. Notifications use it today;
/// the app-wide "hide amounts" switch from the backlog will live here too.
class PrivacySettings {
  PrivacySettings(this._settings);

  final SettingsRepository _settings;

  bool hideAmountsInNotifications(SettingsRow row) =>
      row.hideAmountsInNotifications;

  Future<void> setHideAmountsInNotifications(bool hide) => _settings.update(
    AppSettingsCompanion(hideAmountsInNotifications: Value(hide)),
  );
}
