import 'package:drift/drift.dart' show Value;

import '../../core/reminders/reminder_models.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/settings_repository.dart';

extension ReminderSettingsRowX on SettingsRow {
  ReminderSettings get reminderSettings => ReminderSettings(
    enabled: remindersEnabled,
    leadDays: reminderLeadDays,
    minuteOfDay: reminderMinute,
    showAmounts: !hideAmountsInNotifications,
    repeatMode: repeatMode,
    paydaySummary: paydaySummaryEnabled,
  );
}

/// A plan's or recurring payment's stored reminder choice: the on/off
/// column and the optional own "days before".
ReminderChoice reminderChoiceOf({required bool enabled, int? leadDays}) =>
    !enabled
    ? ReminderChoice.disabled
    : leadDays == null
    ? ReminderChoice.general
    : ReminderChoice.days(leadDays);

/// The columns that store [choice]: (remindersEnabled, reminderLeadDays).
(bool, int?) reminderColumnsOf(ReminderChoice choice) =>
    (!choice.off, choice.off ? null : choice.leadDays);

/// Reads and writes the global reminder settings (in the settings row).
class ReminderSettingsStore {
  ReminderSettingsStore(this._settings);

  final SettingsRepository _settings;

  Future<void> setEnabled(bool on) =>
      _settings.update(AppSettingsCompanion(remindersEnabled: Value(on)));

  Future<void> setLeadDays(int days) {
    assert(leadDayChoices.contains(days), 'unsupported: $days');
    return _settings.update(
      AppSettingsCompanion(reminderLeadDays: Value(days)),
    );
  }

  Future<void> setRepeatMode(ReminderRepeat mode) =>
      _settings.update(AppSettingsCompanion(repeatMode: Value(mode)));

  Future<void> setPaydaySummary(bool on) =>
      _settings.update(AppSettingsCompanion(paydaySummaryEnabled: Value(on)));

  Future<void> setMinuteOfDay(int minute) =>
      _settings.update(AppSettingsCompanion(reminderMinute: Value(minute)));

  /// The permission sheet was shown; it never comes back. Reminders stay
  /// on: without permission Settings shows a calm status line instead.
  Future<void> markPromptShown() => _settings.update(
    const AppSettingsCompanion(reminderPromptShown: Value(true)),
  );
}

/// The one place for "show amounts" choices. Notifications use it today;
/// the app-wide "hide amounts" switch from the backlog will live here too.
class PrivacySettings {
  PrivacySettings(this._settings);

  final SettingsRepository _settings;

  bool showAmountsInNotifications(SettingsRow row) =>
      !row.hideAmountsInNotifications;

  Future<void> setShowAmountsInNotifications(bool show) => _settings.update(
    AppSettingsCompanion(hideAmountsInNotifications: Value(!show)),
  );
}
