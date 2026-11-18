import 'package:material_ui/material_ui.dart';

import '../../app/format.dart';
import '../../core/theme/kalan_theme.dart';
import '../../entitlement/entitlement.dart';

/// Saving a fifth open plan on the free version: a calm note, no sales
/// talk. True for "See Pro"; "Not now" and a dismissed sheet leave the
/// form as it is.
Future<bool> showProLimitSheet(BuildContext context) async =>
    await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      // Grows with large text and scrolls instead of overflowing.
      isScrollControlled: true,
      builder: (_) => const ProLimitSheet(),
    ) ??
    false;

class ProLimitSheet extends StatelessWidget {
  const ProLimitSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: SingleChildScrollView(
        key: const ValueKey('pro-limit-sheet'),
        padding: const EdgeInsets.fromLTRB(
          KalanSpace.lg,
          0,
          KalanSpace.lg,
          KalanSpace.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.limitSheetBody(freeOpenPlanLimit),
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: KalanSpace.lg),
            OutlinedButton(
              key: const ValueKey('pro-limit-see-pro'),
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.limitSheetSeePro),
            ),
            const SizedBox(height: KalanSpace.xs),
            TextButton(
              key: const ValueKey('pro-limit-not-now'),
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.limitSheetNotNow),
            ),
          ],
        ),
      ),
    );
  }
}
