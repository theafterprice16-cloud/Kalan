import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/format.dart';
import '../../app/providers.dart';
import '../../core/design/haptics.dart';
import '../../core/design/widgets.dart';
import '../../core/theme/kalan_theme.dart';
import '../../entitlement/entitlement.dart';
import '../../entitlement/pro_controller.dart';
import '../../entitlement/pro_rules.dart';
import '../../entitlement/store_gateway.dart';
import '../../l10n/generated/app_localizations.dart';
import '../home_widget/lock_screen_left.dart';
import 'pro_features.dart';

/// The sentence for a purchase or restore outcome; null shows nothing.
String? proOutcomeText(AppLocalizations l10n, PurchaseOutcome? outcome) =>
    switch (outcome) {
      PurchaseOutcome.unlocked => l10n.proTurnedOn,
      PurchaseOutcome.pending => l10n.proPending,
      PurchaseOutcome.failed => l10n.proPurchaseFailed,
      PurchaseOutcome.notFound => l10n.proRestoreNotFound,
      PurchaseOutcome.unreachable => l10n.proStoreUnreachable,
      PurchaseOutcome.canceled || null => null,
    };

/// "Restore purchase" from any screen: the result in one calm sentence.
Future<void> restoreProPurchase(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = context.l10n;
  final outcome = await ref.read(proControllerProvider.notifier).restore();
  if (outcome == PurchaseOutcome.unlocked) KalanHaptics.success();
  final text = proOutcomeText(l10n, outcome);
  if (text == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

/// What Pro adds, the store's price, buy and restore. Opened from Settings
/// and from the fifth-plan note; [returnOnUnlock] goes back to the
/// half-filled plan once Pro is on.
class ProScreen extends ConsumerStatefulWidget {
  const ProScreen({super.key, this.returnOnUnlock = false});

  final bool returnOnUnlock;

  @override
  ConsumerState<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends ConsumerState<ProScreen> {
  /// Shown under the buttons until the next tap.
  bool _failed = false;

  Future<void> _buy() async {
    setState(() => _failed = false);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final router = GoRouter.of(context);
    final outcome = await ref.read(proControllerProvider.notifier).buy();
    if (!mounted) return;
    switch (outcome) {
      case PurchaseOutcome.unlocked:
        KalanHaptics.success();
        if (widget.returnOnUnlock && router.canPop()) {
          router.pop(true);
        }
      case PurchaseOutcome.failed:
        setState(() => _failed = true);
      case PurchaseOutcome.pending:
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.proPending)));
      default:
        // Canceled: the store sheet was closed; nothing to say.
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final pro = ref.watch(proControllerProvider);
    final isPro = ref.watch(entitlementProvider).isPro;

    // The Pro screen sits on surface (owner decision, item 11).
    return Scaffold(
      backgroundColor: context.colors.surface,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        title: Text(l10n.proTitle),
      ),
      body: ListView(
        key: const ValueKey('pro-screen'),
        padding: const EdgeInsets.fromLTRB(
          KalanSpace.md,
          KalanSpace.xs,
          KalanSpace.md,
          KalanSpace.xl,
        ),
        children: isPro
            ? [
                Text(
                  l10n.proActive,
                  key: const ValueKey('pro-active'),
                  style: theme.textTheme.bodyLarge,
                ),
              ]
            : [
                Text(
                  l10n.proIntro(freeOpenPlanLimit),
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: KalanSpace.sm),
                for (final line in proFeatureLines(
                  l10n,
                  lockScreenWidget: ref.watch(
                    lockScreenWidgetSupportedProvider,
                  ),
                ))
                  Padding(
                    padding: const EdgeInsets.only(bottom: KalanSpace.xs),
                    child: StatusNote(
                      icon: Icons.check,
                      color: context.colors.textMuted,
                      text: line,
                    ),
                  ),
                const SizedBox(height: KalanSpace.md),
                const _PriceLine(),
                if (pro.status == ProStatus.pending) ...[
                  const SizedBox(height: KalanSpace.md),
                  StatusNote(
                    key: const ValueKey('pro-pending'),
                    icon: Icons.hourglass_empty,
                    color: context.colors.textMuted,
                    text: l10n.proPending,
                  ),
                ],
                const SizedBox(height: KalanSpace.lg),
                _BuyButton(busy: pro.busy, onPressed: _buy),
                const SizedBox(height: KalanSpace.xs),
                TextButton(
                  key: const ValueKey('pro-restore'),
                  onPressed: pro.busy == ProBusy.none
                      ? () => restoreProPurchase(context, ref)
                      : null,
                  child: pro.busy == ProBusy.restoring
                      ? const _Spinner()
                      : Text(l10n.proRestore),
                ),
                if (_failed) ...[
                  const SizedBox(height: KalanSpace.md),
                  StatusNote(
                    key: const ValueKey('pro-failed'),
                    icon: Icons.error_outline,
                    color: context.colors.late,
                    text: l10n.proPurchaseFailed,
                  ),
                ],
              ],
      ),
    );
  }
}

/// "{price} · pay once", the store's own price; or a calm note and
/// "Try again" when the store did not answer.
class _PriceLine extends ConsumerWidget {
  const _PriceLine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final price = ref.watch(proPriceProvider);
    return switch (price.value) {
      PriceLoaded(:final price) => Text(
        l10n.proPriceLine(price),
        key: const ValueKey('pro-price'),
        style: theme.textTheme.titleMedium?.copyWith(
          color: context.colors.text,
        ),
      ),
      PriceUnavailable() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.proPriceUnavailable,
            key: const ValueKey('pro-price-unavailable'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: context.colors.textMuted,
            ),
          ),
          TextButton(
            key: const ValueKey('pro-price-retry'),
            // Lined up with the note above it.
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            onPressed: () => ref.invalidate(proPriceProvider),
            child: Text(l10n.proRetry),
          ),
        ],
      ),
      null => const Align(
        alignment: AlignmentDirectional.centerStart,
        child: _Spinner(),
      ),
    };
  }
}

/// The one accent button: the price must be known before buying, and a
/// running purchase cannot be started twice.
class _BuyButton extends ConsumerWidget {
  const _BuyButton({required this.busy, required this.onPressed});

  final ProBusy busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final priceKnown = ref.watch(proPriceProvider).value is PriceLoaded;
    return FilledButton(
      key: const ValueKey('pro-buy'),
      onPressed: priceKnown && busy == ProBusy.none ? onPressed : null,
      child: busy == ProBusy.buying
          ? Semantics(label: context.l10n.proBuy, child: const _Spinner())
          : Text(context.l10n.proBuy),
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: KalanSpace.md,
    child: CircularProgressIndicator(
      strokeWidth: 2,
      color: context.colors.textMuted,
    ),
  );
}
