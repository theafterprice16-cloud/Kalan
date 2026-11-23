import 'package:drift/drift.dart' show Value;

import '../../core/reminders/reminder_models.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/settings_repository.dart';
import '../privacy/amounts_hidden.dart';

extension ReminderSettingsRowX on SettingsRow {
  ReminderSettings get reminderSettings =>
      reminderSettingsWith(hideAmounts: false);

  /// The settings the planner works with; [hideAmounts] is the app-wide
  /// "Hide amounts" (28), kept on the device, not in this row.
  ReminderSettings reminderSettingsWith({required bool hideAmounts}) =>
      ReminderSettings(
        enabled: remindersEnabled,
        leadDays: reminderLeadDays,
        minuteOfDay: reminderMinute,
        showAmounts: !hideAmountsInNotifications,
        hideAmounts: hideAmounts,
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

/// The one place for "show amounts" choices: "Show amount in
/// notifications" (in the settings row) and the app-wide "Hide amounts"
/// (Roadmap 28; on this device only, outside the database).
class PrivacySettings {
  PrivacySettings(this._settings, this._amounts);

  final SettingsRepository _settings;
  final AmountsHiddenStore _amounts;

  /// The "Show amount in notifications" switch itself. Whether a
  /// notification really carries an amount: [notificationAmountsShown].
  bool showAmountsInNotifications(SettingsRow row) =>
      !row.hideAmountsInNotifications;

  Future<void> setShowAmountsInNotifications(bool show) => _settings.update(
    AppSettingsCompanion(hideAmountsInNotifications: Value(!show)),
  );

  /// "Hide amounts": every amount on screen and in notifications masked.
  bool get amountsHidden => _amounts.read();

  /// Changes only this choice; "Show amount in notifications" keeps its
  /// value (the planner combines the two: [ReminderSettings.amountsInText]).
  Future<void> setAmountsHidden(bool hidden) => _amounts.write(hidden);

  /// Amounts in notification text: only while both choices allow it.
  bool notificationAmountsShown(SettingsRow row) =>
      showAmountsInNotifications(row) && !amountsHidden;
}
