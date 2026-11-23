import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/format.dart';
import '../../core/theme/kalan_theme.dart';
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
