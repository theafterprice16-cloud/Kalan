import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/format.dart';
import '../../app/providers.dart';
import '../../core/design/form_fields.dart';
import '../../core/engine/engine.dart';
import '../../data/db/app_database.dart';
import '../onboarding/pay_form.dart';
import '../plans/plan_labels.dart';

/// Rent, bills, subscriptions. No categories.
class RecurringEditScreen extends ConsumerStatefulWidget {
  const RecurringEditScreen({super.key, this.recurringId});

  final int? recurringId;

  @override
  ConsumerState<RecurringEditScreen> createState() =>
      _RecurringEditScreenState();
}

class _RecurringEditScreenState extends ConsumerState<RecurringEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _amount = TextEditingController();
  Recurrence _recurrence = Recurrence.monthly;
  late LocalDate _start;
  LocalDate? _end;
  RecurringPaymentRow? _existing;
  bool _loaded = false;
  String? _endError;

  @override
  void initState() {
    super.initState();
    _start = ref.read(todayProvider);
    if (widget.recurringId == null) {
      _loaded = true;
    } else {
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    final r = await ref
        .read(recurringRepositoryProvider)
        .byId(widget.recurringId!);
    if (!mounted || r == null) return;
    setState(() {
      _existing = r;
      _name.text = r.name;
      _amount.text = ref.moneyInput(context, r.amountMinor);
      _recurrence = r.recurrence;
      _start = LocalDate.fromEpochDay(r.startDay);
      _end = r.endDay == null ? null : LocalDate.fromEpochDay(r.endDay!);
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final endOk = _end == null || _end! >= _start;
    setState(() => _endError = endOk ? null : context.l10n.errorEndBeforeStart);
    if (!_formKey.currentState!.validate() || !endOk) return;
    final repo = ref.read(recurringRepositoryProvider);
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final amount = ref.parseMoney(context, _amount.text)!;
    final existing = _existing;
    if (existing == null) {
      await repo.create(
        RecurringPaymentsCompanion.insert(
          name: _name.text.trim(),
          amountMinor: amount,
          recurrence: _recurrence,
          startDay: _start.epochDay,
          endDay: Value(_end?.epochDay),
        ),
      );
    } else {
      await repo.update(
        existing.copyWith(
          name: _name.text.trim(),
          amountMinor: amount,
          recurrence: _recurrence,
          startDay: _start.epochDay,
          endDay: Value(_end?.epochDay),
        ),
      );
    }
    messenger.showSnackBar(SnackBar(content: Text(l10n.recurringSaved)));
    router.pop();
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.recurringDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(recurringRepositoryProvider).delete(_existing!.id);
    messenger.showSnackBar(SnackBar(content: Text(l10n.recurringDeleted)));
    router.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _existing == null ? l10n.recurringNewTitle : l10n.recurringEditTitle,
        ),
        actions: [
          if (_existing != null)
            IconButton(
              tooltip: l10n.actionDelete,
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    key: const ValueKey('recurring-name'),
                    controller: _name,
                    maxLength: 60,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: l10n.fieldName,
                      hintText: l10n.fieldRecurringNameHint,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? l10n.errorNameRequired
                        : null,
                  ),
                  const SizedBox(height: 8),
                  AmountField(
                    fieldKey: const ValueKey('recurring-amount'),
                    controller: _amount,
                    label: l10n.fieldAmount,
                  ),
                  const SizedBox(height: 16),
                  ChoiceField<Recurrence>(
                    label: l10n.fieldRecurrence,
                    selected: _recurrence,
                    options: [
                      for (final r in Recurrence.values)
                        (r, recurrenceLabel(context, r)),
                    ],
                    onSelected: (r) => setState(() => _recurrence = r),
                  ),
                  const SizedBox(height: 16),
                  DateField(
                    label: l10n.fieldFirstDate,
                    value: _start,
                    format: context.longDate,
                    onChanged: (d) => setState(() => _start = d),
                  ),
                  const SizedBox(height: 16),
                  DateField(
                    label: l10n.fieldEndDate,
                    value: _end,
                    format: context.longDate,
                    helperText:
                        _endError ?? (_end == null ? l10n.noEndDate : null),
                    onChanged: (d) => setState(() => _end = d),
                    trailing: _end == null
                        ? null
                        : IconButton(
                            tooltip: l10n.clearEndDate,
                            onPressed: () => setState(() => _end = null),
                            icon: const Icon(Icons.close),
                          ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const ValueKey('save-recurring'),
                    onPressed: _save,
                    child: Text(l10n.actionSave),
                  ),
                ],
              ),
            ),
    );
  }
}
