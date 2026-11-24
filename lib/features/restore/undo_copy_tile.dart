import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/format.dart';
import '../../core/design/haptics.dart';
import '../../core/design/kalan_dialog.dart';
import '../../core/theme/kalan_theme.dart';
import 'restore_service.dart';

/// Settings > Data: "Go back to previous data · 19 Nov 2026" for 30 days
/// after a restore (Roadmap 30, decision 14). Asks first; the data on the
/// phone then becomes the new copy.
class UndoCopyTile extends ConsumerStatefulWidget {
  const UndoCopyTile({super.key});

  @override
  ConsumerState<UndoCopyTile> createState() => _UndoCopyTileState();
}

class _UndoCopyTileState extends ConsumerState<UndoCopyTile> {
  bool _busy = false;

  Future<void> _goBack(String date) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showKalanDialog<bool>(
      context: context,
      builder: (context) => KalanAlertDialog(
        title: Text(l10n.undoConfirmTitle),
        content: Text(l10n.undoConfirmBody(date)),
        actions: [
          KalanDialogAction(
            label: l10n.actionCancel,
            onPressed: () => Navigator.pop(context, false),
          ),
          KalanDialogAction(
            key: const ValueKey('undo-confirm'),
            label: l10n.undoConfirmButton,
            primary: true,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    String message;
    try {
      await ref.read(restoreServiceProvider).goBack();
      KalanHaptics.success();
      message = l10n.undoDone;
    } on RestoreException catch (e) {
      message = e.failure == RestoreFailure.copyFailed
          ? l10n.restoreErrorCopy
          : l10n.undoFailed;
    } on Object {
      message = l10n.undoFailed;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final copy = ref.watch(undoCopyProvider).value;
    if (copy == null) return const SizedBox.shrink();
    final colors = context.colors;
    final date = context.longDate(copy.copiedOn);
    return ListTile(
      key: const ValueKey('settings-undo-copy'),
      title: Text(context.l10n.undoRow(date)),
      subtitle: Text(
        context.l10n.undoRowHint,
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: colors.textMuted),
      ),
      trailing: _busy
          ? SizedBox.square(
              dimension: KalanSpace.md,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.textMuted,
              ),
            )
          : null,
      onTap: _busy ? null : () => unawaited(_goBack(date)),
    );
  }
}
