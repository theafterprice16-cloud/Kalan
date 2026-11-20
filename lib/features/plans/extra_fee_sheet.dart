import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/format.dart';
import '../../app/providers.dart';
import '../../core/design/haptics.dart';
import '../../core/engine/engine.dart';
import '../../core/theme/kalan_theme.dart';
import '../onboarding/pay_form.dart';

/// "1/4 · 20 Nov 2026", or the date alone for a "Pay later" payment: the
/// payment's line under the plan name, as in the installment sheet.
String paymentLabelOf(
  BuildContext context, {
  required int seq,
  required int installmentCount,
  required bool isPayLater,
  required LocalDate date,
}) {
  final day = context.longDate(date);
  return isPayLater
      ? day
      : context.l10n.paymentActionsTitle(
          context.l10n.progressLabel(seq, installmentCount),
          day,
        );
}

/// How long "Extra fee removed." with "Undo" stays on screen.
const extraFeeRemovedDuration = Duration(seconds: 6);

/// What the extra fee sheet returns: a fee to store, or "Delete".
sealed class ExtraFeeChoice {
  const ExtraFeeChoice();
}

class SaveExtraFee extends ExtraFeeChoice {
  const SaveExtraFee(this.amountMinor, this.note);

  final int amountMinor;
  final String? note;
}

class DeleteExtraFee extends ExtraFeeChoice {
  const DeleteExtraFee();
}

/// Opens the extra fee sheet (21) for [paymentId] and stores what it
/// returns. With a fee ([feeMinor]) the sheet corrects it and offers
/// "Delete": no confirmation, "Extra fee removed." with "Undo" instead.
/// Dismissing the sheet stores nothing.
Future<void> openExtraFee(
  BuildContext context,
  WidgetRef ref, {
  required int paymentId,
  required String planName,
  required String paymentLabel,
  int? feeMinor,
  String? note,
}) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  // Read now: the row can leave the tree while the sheet is open.
  final repo = ref.read(planRepositoryProvider);
  final amountError = ref.amountError(context);
  final choice = await showModalBottomSheet<ExtraFeeChoice>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => ExtraFeeSheet(
      planName: planName,
      paymentLabel: paymentLabel,
      feeMinor: feeMinor,
      note: note,
    ),
  );
  switch (choice) {
    case null:
      return;
    case SaveExtraFee(:final amountMinor, :final note):
      final rejection = await repo.setExtraFee(
        paymentId,
        amountMinor: amountMinor,
        note: note,
      );
      if (rejection == null) KalanHaptics.success();
      final message = switch (rejection) {
        null => l10n.extraFeeSaved,
        ExtraFeeRejection.nonPositiveAmount => amountError,
        ExtraFeeRejection.noteTooLong => l10n.extraFeeNoteTooLong(
          extraFeeNoteMaxLength,
        ),
        ExtraFeeRejection.notAllowed ||
        ExtraFeeRejection.notFound => l10n.extraFeeNotAllowed,
      };
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    case DeleteExtraFee():
      final removed = await repo.removeExtraFee(paymentId);
      if (removed == null) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(l10n.extraFeeRemoved),
            duration: extraFeeRemovedDuration,
            persist: false,
            action: SnackBarAction(
              label: l10n.actionUndo,
              onPressed: () => repo.setExtraFee(
                paymentId,
                amountMinor: removed.amountMinor,
                note: removed.note,
              ),
            ),
          ),
        );
  }
}

/// Amount, an optional note and "Save"; with a fee, its values and
/// "Delete" too. The amount comes through the app's one money path.
class ExtraFeeSheet extends ConsumerStatefulWidget {
  const ExtraFeeSheet({
    required this.planName,
    required this.paymentLabel,
    this.feeMinor,
    this.note,
    super.key,
  });

  final String planName;
  final String paymentLabel;
  final int? feeMinor;
  final String? note;

  @override
  ConsumerState<ExtraFeeSheet> createState() => _ExtraFeeSheetState();
}

class _ExtraFeeSheetState extends ConsumerState<ExtraFeeSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount = TextEditingController();
  late final TextEditingController _note = TextEditingController(
    text: widget.note ?? '',
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final fee = widget.feeMinor;
    if (fee != null && _amount.text.isEmpty) {
      _amount.text = ref.moneyInput(context, fee);
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      SaveExtraFee(
        ref.parseMoney(context, _amount.text)!,
        normalizeExtraFeeNote(_note.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: context.colors.textMuted,
    );
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          key: const ValueKey('extra-fee-sheet'),
          padding: const EdgeInsets.fromLTRB(
            KalanSpace.lg,
            0,
            KalanSpace.lg,
            KalanSpace.md,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    l10n.extraFeeSheetTitle,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: KalanSpace.xxs),
                Text(
                  widget.planName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium,
                ),
                Text(widget.paymentLabel, style: muted),
                const SizedBox(height: KalanSpace.sm),
                Text(l10n.extraFeeSheetHint, style: muted),
                const SizedBox(height: KalanSpace.md),
                AmountField(
                  fieldKey: const ValueKey('extra-fee-amount'),
                  controller: _amount,
                  label: l10n.fieldAmount,
                ),
                const SizedBox(height: KalanSpace.sm),
                TextFormField(
                  key: const ValueKey('extra-fee-note'),
                  controller: _note,
                  maxLength: extraFeeNoteMaxLength,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: l10n.extraFeeNoteLabel,
                  ),
                  // Measured as stored (UTF-16), as the database does: an
                  // emoji counts twice there.
                  validator: (text) =>
                      (normalizeExtraFeeNote(text)?.length ?? 0) >
                          extraFeeNoteMaxLength
                      ? l10n.extraFeeNoteTooLong(extraFeeNoteMaxLength)
                      : null,
                  onFieldSubmitted: (_) => _save(),
                ),
                const SizedBox(height: KalanSpace.md),
                FilledButton(
                  key: const ValueKey('extra-fee-save'),
                  onPressed: _save,
                  child: Text(l10n.actionSave),
                ),
                if (widget.feeMinor != null) ...[
                  const SizedBox(height: KalanSpace.xs),
                  TextButton(
                    key: const ValueKey('extra-fee-delete'),
                    onPressed: () =>
                        Navigator.pop(context, const DeleteExtraFee()),
                    child: Text(l10n.actionDelete),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
