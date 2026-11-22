import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/format.dart';
import '../../app/providers.dart';
import '../../core/design/form_fields.dart';
import '../../core/reminders/reminder_models.dart'
    show initialStatementLeadDays, statementLeadDayChoices;
import '../../core/routing/tab_messengers.dart';
import '../../core/theme/kalan_theme.dart';
import '../../data/db/app_database.dart';
import '../holidays/holiday_providers.dart';

/// Create or edit a provider or card. Pops with the source id on save.
class SourceEditScreen extends ConsumerStatefulWidget {
  const SourceEditScreen({super.key, this.sourceId, this.startAsCard = false});

  final int? sourceId;
  final bool startAsCard;

  @override
  ConsumerState<SourceEditScreen> createState() => _SourceEditScreenState();
}

class _SourceEditScreenState extends ConsumerState<SourceEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  SourceKind _kind = SourceKind.provider;
  int? _statementDay;
  int? _dueDay;
  bool _shift = true;
  bool _holidayShift = true;
  bool _closingReminder = false;
  int _closingDays = initialStatementLeadDays;
  SourceRow? _existing;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _kind = widget.startAsCard ? SourceKind.card : SourceKind.provider;
    if (widget.sourceId == null) {
      _loaded = true;
    } else {
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    final s = await ref.read(sourceRepositoryProvider).byId(widget.sourceId!);
    if (!mounted || s == null) return;
    setState(() {
      _existing = s;
      _name.text = s.name;
      _kind = s.kind;
      _statementDay = s.statementDay;
      _dueDay = s.dueDay;
      _shift = s.shiftDueToBusinessDay;
      _holidayShift = s.shiftDueForHolidays;
      _closingReminder = s.statementReminderEnabled;
      _closingDays = s.statementReminderDays;
      _loaded = true;
    });
  }

  /// The statement closing reminder needs the card's days (as its
  /// statements do).
  bool get _hasCardDays => _statementDay != null && _dueDay != null;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final repo = ref.read(sourceRepositoryProvider);
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final tabs = ref.read(tabMessengersProvider);
    final l10n = context.l10n;
    final int id;
    final existing = _existing;
    if (existing == null) {
      id = await repo.create(
        name: _name.text,
        kind: _kind,
        statementDay: _statementDay,
        dueDay: _dueDay,
        shiftDueToBusinessDay: _shift,
        shiftDueForHolidays: _holidayShift,
        statementReminderEnabled: _closingReminder,
        statementReminderDays: _closingDays,
      );
    } else {
      id = existing.id;
      await repo.update(
        existing.copyWith(
          name: _name.text.trim(),
          kind: _kind,
          statementDay: Value(_statementDay),
          dueDay: Value(_dueDay),
          shiftDueToBusinessDay: _shift,
          shiftDueForHolidays: _holidayShift,
          statementReminderEnabled: _closingReminder && _hasCardDays,
          statementReminderDays: _closingDays,
        ),
      );
    }
    router.popWithMessage(
      SnackBar(content: Text(l10n.sourceSaved)),
      fallback: messenger,
      tabs: tabs,
      result: id,
    );
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final tabs = ref.read(tabMessengersProvider);
    final ok = await ref.read(sourceRepositoryProvider).delete(_existing!.id);
    if (ok) {
      router.popWithMessage(
        SnackBar(content: Text(l10n.sourceDeleted)),
        fallback: messenger,
        tabs: tabs,
      );
    } else {
      messenger.showSnackBar(SnackBar(content: Text(l10n.sourceInUse)));
    }
  }

  Widget _dayField(
    String label,
    String help,
    int? value,
    ValueChanged<int?> onChanged,
    Key key,
  ) => DropdownButtonFormField<int>(
    key: key,
    initialValue: value,
    isExpanded: true,
    decoration: InputDecoration(
      labelText: label,
      helperText: help,
      helperMaxLines: 3,
    ),
    items: [
      for (var d = 1; d <= 31; d++)
        DropdownMenuItem(value: d, child: Text('$d')),
    ],
    onChanged: onChanged,
    validator: (v) => v == null ? context.l10n.errorDayInvalid : null,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(_existing == null ? l10n.addSource : l10n.editSource),
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
                padding: const EdgeInsets.all(KalanSpace.md),
                children: [
                  TextFormField(
                    key: const ValueKey('source-name'),
                    controller: _name,
                    maxLength: 60,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(labelText: l10n.fieldName),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? l10n.errorNameRequired
                        : null,
                  ),
                  const SizedBox(height: KalanSpace.xs),
                  ChoiceField<SourceKind>(
                    label: l10n.fieldSourceKind,
                    selected: _kind,
                    options: [
                      (SourceKind.provider, l10n.sourceKindProvider),
                      (SourceKind.card, l10n.sourceKindCard),
                      (SourceKind.account, l10n.sourceKindAccount),
                    ],
                    onSelected: (k) => setState(() => _kind = k),
                  ),
                  if (_kind == SourceKind.card) ...[
                    const SizedBox(height: KalanSpace.md),
                    _dayField(
                      l10n.fieldStatementDay,
                      l10n.statementDayHelp,
                      _statementDay,
                      (d) => setState(() => _statementDay = d),
                      const ValueKey('statement-day'),
                    ),
                    const SizedBox(height: KalanSpace.md),
                    _dayField(
                      l10n.fieldDueDay,
                      l10n.dueDayHelp,
                      _dueDay,
                      (d) => setState(() => _dueDay = d),
                      const ValueKey('due-day'),
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.fieldShiftWeekend),
                      value: _shift,
                      onChanged: (v) => setState(() => _shift = v),
                    ),
                    // Public holidays (26): right under the weekend switch,
                    // the same switch; the note says how far the list goes.
                    SwitchListTile.adaptive(
                      key: const ValueKey('holiday-shift'),
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.fieldShiftHolidays),
                      subtitle: Text(
                        switch (ref.watch(appliedHolidaysProvider)) {
                          final calendar? => l10n.holidayListUntil(
                            calendar.lastYear,
                          ),
                          null => l10n.holidayNoCountry,
                        },
                        key: const ValueKey('holiday-list-note'),
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: context.colors.textMuted),
                      ),
                      value: _holidayShift,
                      onChanged: (v) => setState(() => _holidayShift = v),
                    ),
                    if (_existing != null)
                      Text(
                        l10n.cardDaysChangeNote,
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: context.colors.textMuted),
                      ),
                    // Only with the card's days: the reminder is about its
                    // statement date.
                    if (_hasCardDays) ...[
                      const SizedBox(height: KalanSpace.xs),
                      SwitchListTile.adaptive(
                        key: const ValueKey('statement-reminder'),
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.statementReminderToggle),
                        subtitle: Text(
                          l10n.statementReminderToggleHint,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: context.colors.textMuted),
                        ),
                        value: _closingReminder,
                        onChanged: (v) => setState(() => _closingReminder = v),
                      ),
                      if (_closingReminder) ...[
                        const SizedBox(height: KalanSpace.xs),
                        ChoiceField<int>(
                          key: const ValueKey('statement-reminder-days'),
                          label: l10n.statementReminderDays,
                          selected: _closingDays,
                          options: [
                            for (final days in statementLeadDayChoices)
                              (days, l10n.reminderLeadDaysValue(days)),
                          ],
                          onSelected: (d) => setState(() => _closingDays = d),
                        ),
                      ],
                    ],
                  ],
                  const SizedBox(height: KalanSpace.lg),
                  FilledButton(
                    key: const ValueKey('save-source'),
                    onPressed: _save,
                    child: Text(l10n.actionSave),
                  ),
                ],
              ),
            ),
    );
  }
}
