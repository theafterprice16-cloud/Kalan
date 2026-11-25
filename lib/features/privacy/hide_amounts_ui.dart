import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/format.dart';
import '../../app/providers.dart';
import '../../core/theme/kalan_theme.dart';
import '../home_widget/lock_screen_left.dart';
import 'amounts_hidden.dart';

/// The eye on the home screen's top bar (Roadmap 28): one tap hides every
/// amount, another shows them again. An open eye while amounts show, a
/// crossed-out one while they are hidden; the shape tells the state, the
/// color stays textMuted in both (accent is only for "left").
class HideAmountsButton extends ConsumerWidget {
  const HideAmountsButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidden = ref.watch(amountsHiddenProvider);
    final l10n = context.l10n;
    return IconButton(
      key: const ValueKey('hide-amounts'),
      // Also what a screen reader says: what a tap does.
      tooltip: hidden ? l10n.amountsShow : l10n.amountsHide,
      onPressed: () =>
          unawaited(ref.read(amountsHiddenProvider.notifier).toggle()),
      icon: Icon(
        hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: context.colors.textMuted,
      ),
    );
  }
}

/// Settings > Privacy: the same choice as the eye on the home screen.
class HideAmountsTile extends ConsumerWidget {
  const HideAmountsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final muted = Theme.of(context).textTheme.bodyMedium
        ?.copyWith(color: context.colors.textMuted);
    return SwitchListTile.adaptive(
      key: const ValueKey('hide-amounts-switch'),
      title: Text(l10n.amountsHide),
      subtitle: Text(l10n.amountsHideHint, style: muted),
      value: ref.watch(amountsHiddenProvider),
      onChanged: (v) =>
          unawaited(ref.read(amountsHiddenProvider.notifier).set(v)),
    );
  }
}

/// Settings > Privacy, iPhone with Pro (Roadmap 32): what's left this
/// period on the Lock Screen widget. Off by default; it shows there only
/// while no amount is masked on the widgets ([lockScreenLeftShown]).
class LockScreenLeftTile extends ConsumerWidget {
  const LockScreenLeftTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(lockScreenWidgetSupportedProvider) ||
        !ref.watch(entitlementProvider.select((e) => e.isPro))) {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n;
    final muted = Theme.of(context).textTheme.bodyMedium
        ?.copyWith(color: context.colors.textMuted);
    return SwitchListTile.adaptive(
      key: const ValueKey('lock-screen-left'),
      title: Text(l10n.lockScreenShowLeft),
      subtitle: Text(l10n.lockScreenShowLeftHint, style: muted),
      value: ref.watch(lockScreenLeftProvider),
      onChanged: (v) =>
          unawaited(ref.read(lockScreenLeftProvider.notifier).set(v)),
    );
  }
}
