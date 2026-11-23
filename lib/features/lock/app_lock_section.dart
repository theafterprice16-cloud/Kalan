import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/format.dart';
import '../../core/design/choice_dialog.dart';
import '../../core/design/widgets.dart';
import '../../core/lock/app_lock_machine.dart';
import '../../core/theme/kalan_theme.dart';
import '../../data/db/app_database.dart';
import '../reminders/reminder_providers.dart';
import 'app_lock_controller.dart';
import 'app_lock_store.dart';
import 'device_lock_gateway.dart';

/// "Immediately", "After 1 minute", "After 5 minutes".
String relockDelayLabel(BuildContext context, RelockDelay delay) {
  final l10n = context.l10n;
  return switch (delay) {
    RelockDelay.immediately => l10n.appLockRelockImmediately,
    RelockDelay.oneMinute => l10n.appLockRelockAfterMinutes(1),
    RelockDelay.fiveMinutes => l10n.appLockRelockAfterMinutes(5),
  };
}

/// Settings > Privacy: the app lock (Roadmap 27). Phones only.
class AppLockSection extends ConsumerStatefulWidget {
  const AppLockSection({required this.settings, super.key});

  final SettingsRow settings;

  @override
  ConsumerState<AppLockSection> createState() => _AppLockSectionState();
}

class _AppLockSectionState extends ConsumerState<AppLockSection> {
  /// Why Kalan turned its lock off, shown while Settings stays open.
  AppLockNotice? _notice;

  /// The last try to turn it on found no screen lock on the phone.
  bool _needsScreenLock = false;

  /// Back from the phone's settings (a screen lock may be set now).
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // onShow, not onResume: the notification shade only makes Kalan
    // inactive; the phone's settings hide it.
    _lifecycle = AppLifecycleListener(
      onShow: () {
        if (mounted && _needsScreenLock) {
          setState(() => _needsScreenLock = false);
        }
      },
    );
    _show(ref.read(appLockProvider).notice);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  /// Once: cleared from storage after this frame, kept on screen while
  /// Settings stays open.
  void _show(AppLockNotice? notice) {
    if (notice == null) return;
    _notice = notice;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(appLockProvider.notifier).takeNotice();
    });
  }

  Future<void> _toggle(bool on) async {
    final lock = ref.read(appLockProvider.notifier);
    if (!on) {
      await lock.disable();
      return;
    }
    final result = await lock.enable();
    if (!mounted) return;
    setState(() {
      _needsScreenLock = result == AppLockEnableResult.needsScreenLock;
      if (result == AppLockEnableResult.enabled) _notice = null;
    });
  }

  Future<void> _pickDelay() async {
    final picked = await showChoiceDialog<RelockDelay>(
      context,
      title: context.l10n.appLockRelock,
      selected: ref.read(appLockProvider).delay,
      note: context.l10n.appLockRelockHelp,
      options: [
        for (final d in RelockDelay.values) (d, relockDelayLabel(context, d)),
      ],
    );
    if (picked == null) return;
    await ref.read(appLockProvider.notifier).setDelay(picked.value);
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(deviceLockGatewayProvider).supported) {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n;
    final colors = context.colors;
    final muted = Theme.of(context).textTheme.bodyMedium
        ?.copyWith(color: colors.textMuted);
    final lock = ref.watch(appLockProvider);
    // Turned off while Settings was open (under the lock screen).
    ref.listen(appLockProvider.select((s) => s.notice), (_, notice) {
      if (notice != null) setState(() => _show(notice));
    });
    final privacy = ref.read(privacySettingsProvider);
    // The suggestion only where amounts really show: reminders on, amounts
    // on. A tap hides them; the lock itself never changes that setting.
    final amountsShow =
        ref.watch(notificationGatewayProvider).supported &&
        widget.settings.remindersEnabled &&
        privacy.showAmountsInNotifications(widget.settings);

    Widget note(String text, Key key) => ListTile(
      key: key,
      leading: Icon(Icons.info_outline, color: colors.textMuted),
      title: Text(text, style: muted),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(l10n.settingsPrivacySection),
        SwitchListTile.adaptive(
          key: const ValueKey('app-lock'),
          title: Text(l10n.appLock),
          subtitle: Text(l10n.appLockHint, style: muted),
          value: lock.enabled,
          onChanged: lock.authenticating ? null : (v) => unawaited(_toggle(v)),
        ),
        if (!lock.enabled && _needsScreenLock)
          note(
            l10n.appLockNeedsScreenLock,
            const ValueKey('app-lock-needs-screen-lock'),
          ),
        if (!lock.enabled && _notice != null)
          note(switch (_notice!) {
            AppLockNotice.noScreenLock => l10n.appLockTurnedOff,
            AppLockNotice.unavailable => l10n.appLockTurnedOffUnavailable,
          }, const ValueKey('app-lock-turned-off')),
        if (lock.enabled && amountsShow)
          ListTile(
            key: const ValueKey('app-lock-amounts'),
            leading: Icon(
              Icons.visibility_off_outlined,
              color: colors.textMuted,
            ),
            title: Text(l10n.appLockAmountsVisible, style: muted),
            onTap: () =>
                unawaited(privacy.setShowAmountsInNotifications(false)),
          ),
        if (lock.enabled)
          ListTile(
            key: const ValueKey('app-lock-delay'),
            title: Text(l10n.appLockRelock),
            subtitle: Text(relockDelayLabel(context, lock.delay), style: muted),
            trailing: const Icon(Icons.chevron_right),
            onTap: _pickDelay,
          ),
      ],
    );
  }
}
