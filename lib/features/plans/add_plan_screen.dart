import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/format.dart';
import '../../app/providers.dart';
import '../../core/design/form_fields.dart';
import '../../core/design/widgets.dart';
import '../../core/engine/engine.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/kalan_theme.dart';
import '../../data/db/app_database.dart';
import '../../data/models.dart';
import '../../entitlement/entitlement.dart';
import '../reminders/reminder_prompt.dart';

/// Ways to add a plan. The first three are templates: one screen, at most
/// four fields.
enum AddMode { payIn4, monthly, card, manual, midway }

/// Provider names suggested as plain text. No logos.
const providerSuggestions = [
  'Klarna',
  'Afterpay',
  'Affirm',
  'PayPal',
  'Zip',
  'Sezzle',
];

SourceRow? findSourceByName(List<SourceRow> sources, String name) {
  final key = name.trim().toLowerCase();
  if (key.isEmpty) return null;
  for (final s in sources) {
    if (s.name.toLowerCase() == key) return s;
  }
  return null;
}

/// Draft → confirm → save. The payment preview below the fields is the
/// confirmation step.
class AddPlanScreen extends ConsumerStatefulWidget {
  const AddPlanScreen({super.key});

  @override
  ConsumerState<AddPlanScreen> createState() => _AddPlanScreenState();
}

class _AddPlanScreenState extends ConsumerState<AddPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _source = TextEditingController();
  final _sourceFocus = FocusNode();
  final _total = TextEditingController();
  final _count = TextEditingController();
  final _installment = TextEditingController();
  final _totalCount = TextEditingController();
  final _unpaidCount = TextEditingController();
  final _step = TextEditingController(text: '1');
  final _defer = TextEditingController(text: '0');
  final _title = TextEditingController();

  AddMode _mode = AddMode.payIn4;
  late LocalDate _firstDate;
  late LocalDate _purchaseDate;
  late LocalDate _nextDate;
  IntervalUnit _unit = IntervalUnit.month;
  int? _cardId;
  bool _cashAdvance = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final today = ref.read(todayProvider);
    _firstDate = today;
    _purchaseDate = today;
    _nextDate = today;
    for (final c in [
      _source,
      _total,
      _count,
      _installment,
      _totalCount,
      _unpaidCount,
      _step,
      _defer,
    ]) {
      c.addListener(_refresh);
    }
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    for (final c in [
      _source,
      _total,
      _count,
      _installment,
      _totalCount,
      _unpaidCount,
      _step,
      _defer,
      _title,
    ]) {
      c.dispose();
    }
    _sourceFocus.dispose();
    super.dispose();
  }

  int? _int(TextEditingController c) => int.tryParse(c.text.trim());
  int? _amount(TextEditingController c) => ref.parseMoney(context, c.text);

  List<SourceRow> get _sources => ref.read(sourcesProvider).value ?? const [];

  List<SourceRow> get _cards => [
    for (final s in ref.watch(sourcesProvider).value ?? const <SourceRow>[])
      if (s.cardTerms != null) s,
  ];

  /// The draft for the current inputs, or null while incomplete.
  PlanDraft? _buildDraft() {
    try {
      switch (_mode) {
        case AddMode.payIn4:
          final total = _amount(_total);
          if (total == null) return null;
          return PlanCalculator.payIn4(
            firstDate: _firstDate,
            totalMinor: total,
          );
        case AddMode.monthly:
          final total = _amount(_total);
          final count = _int(_count);
          if (total == null || count == null) return null;
          return PlanCalculator.monthly(
            firstDate: _firstDate,
            totalMinor: total,
            count: count,
          );
        case AddMode.card:
          final card = _sources.where((s) => s.id == _cardId).firstOrNull;
          final total = _amount(_total);
          final count = _int(_count);
          final terms = card?.cardTerms;
          if (terms == null || total == null || count == null) return null;
          return PlanCalculator.card(
            purchaseDate: _purchaseDate,
            totalMinor: total,
            count: count,
            terms: terms,
            deferMonths: _int(_defer) ?? 0,
            isCashAdvance: _cashAdvance,
          );
        case AddMode.manual:
          final total = _amount(_total);
          final count = _int(_count);
          final step = _int(_step);
          if (total == null || count == null || step == null) return null;
          return PlanCalculator.manual(
            firstDate: _firstDate,
            totalMinor: total,
            count: count,
            unit: _unit,
            step: step,
          );
        case AddMode.midway:
          final totalCount = _int(_totalCount);
          final unpaid = _int(_unpaidCount);
          final installment = _amount(_installment);
          final step = _int(_step);
          if (totalCount == null ||
              unpaid == null ||
              installment == null ||
              step == null) {
            return null;
          }
          return PlanCalculator.midway(
            totalCount: totalCount,
            remainingCount: unpaid,
            installmentMinor: installment,
            nextDate: _nextDate,
            unit: _unit,
            step: step,
            cardTerms: findSourceByName(_sources, _source.text)?.cardTerms,
          );
      }
    } on InvalidPlanInput {
      return null;
    }
  }

  bool get _midwayOnCard =>
      _mode == AddMode.midway &&
      findSourceByName(_sources, _source.text)?.cardTerms != null;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final draft = _buildDraft();
    if (draft == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final router = GoRouter.of(context);
    if (!_canAdd) return;
    setState(() => _saving = true);
    final int sourceId;
    if (_mode == AddMode.card) {
      sourceId = _cardId!;
    } else {
      sourceId =
          findSourceByName(_sources, _source.text)?.id ??
          await ref
              .read(sourceRepositoryProvider)
              .findOrCreateProvider(_source.text);
    }
    await ref
        .read(planRepositoryProvider)
        .saveDraft(
          draft,
          sourceId: sourceId,
          origin: _mode == AddMode.manual || _mode == AddMode.midway
              ? PlanOrigin.manual
              : PlanOrigin.template,
          title: _title.text,
        );
    messenger.showSnackBar(SnackBar(content: Text(l10n.planSaved)));
    if (mounted) await askForRemindersIfNeeded(context, ref);
    router.pop();
  }

  bool get _canAdd {
    final plans = ref.read(plansProvider).value ?? const <PlanWithPayments>[];
    return canAddPlan(
      openPlans: plans.where((p) => p.isOpen).length,
      entitlement: ref.read(entitlementProvider),
    );
  }

  Future<void> _addCard() async {
    final id = await context.push<int>(Routes.newSource(card: true));
    if (id != null) setState(() => _cardId = id);
  }

  // Validators -------------------------------------------------------------

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? context.l10n.errorRequired : null;

  String? _countValidator(String? v) {
    final n = int.tryParse(v?.trim() ?? '');
    return n == null || n < 1 || n > PlanCalculator.maxInstallments
        ? context.l10n.errorCountInvalid
        : null;
  }

  String? _totalValidator(String? v) {
    if (v == null || v.trim().isEmpty) return context.l10n.errorRequired;
    final total = ref.parseMoney(context, v);
    if (total == null || total < 1) return ref.amountError(context);
    final count = _mode == AddMode.payIn4 ? 4 : _int(_count);
    if (count != null && count > 0 && total < count) {
      return context.l10n.errorTotalTooSmall;
    }
    return null;
  }

  // Build ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Keep sources loaded for name matching.
    ref.watch(sourcesProvider);
    final plans = ref.watch(plansProvider).value;
    final openPlans = plans?.where((p) => p.isOpen).length ?? 0;
    final allowed = canAddPlan(
      openPlans: openPlans,
      entitlement: ref.watch(entitlementProvider),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.addPlanTitle)),
      body: !allowed
          ? Center(child: EmptyState(l10n.freeLimitReached(freeOpenPlanLimit)))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  ChoiceField<AddMode>(
                    label: l10n.addPlanTypeLabel,
                    selected: _mode,
                    options: [
                      (AddMode.payIn4, l10n.kindPayIn4),
                      (AddMode.monthly, l10n.kindMonthly),
                      (AddMode.card, l10n.kindCard),
                      (AddMode.manual, l10n.kindManual),
                      (AddMode.midway, l10n.kindMidway),
                    ],
                    onSelected: (m) => setState(() => _mode = m),
                  ),
                  const SizedBox(height: 16),
                  ..._fields(context),
                  const SizedBox(height: 8),
                  _details(context),
                  const SizedBox(height: 8),
                  _Preview(draft: _buildDraft()),
                  const SizedBox(height: 16),
                  FilledButton(
                    key: const ValueKey('save-plan'),
                    onPressed: _saving ? null : _save,
                    child: Text(l10n.actionSave),
                  ),
                ],
              ),
            ),
    );
  }

  List<Widget> _fields(BuildContext context) {
    final l10n = context.l10n;
    const gap = SizedBox(height: 16);
    Widget amount(TextEditingController c, String label, Key key) =>
        TextFormField(
          key: key,
          controller: c,
          keyboardType: ref.amountKeyboard,
          decoration: InputDecoration(labelText: label),
          validator: c == _total
              ? _totalValidator
              : (v) =>
                    _required(v) ??
                    ((ref.parseMoney(context, v!) ?? 0) < 1
                        ? ref.amountError(context)
                        : null),
        );
    Widget count(TextEditingController c, String label, Key key) =>
        TextFormField(
          key: key,
          controller: c,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: label),
          validator: _countValidator,
        );
    Widget date(
      String label,
      LocalDate value,
      ValueChanged<LocalDate> onChanged,
      Key key,
    ) => DateField(
      key: key,
      label: label,
      value: value,
      format: context.longDate,
      onChanged: (d) => setState(() => onChanged(d)),
    );

    final source = _SourceField(
      controller: _source,
      focusNode: _sourceFocus,
      sources: ref.watch(sourcesProvider).value ?? const [],
      validator: (v) => _required(v) == null ? null : l10n.errorNameRequired,
    );
    final total = amount(_total, l10n.fieldTotal, const ValueKey('total'));
    final payments = count(_count, l10n.fieldCount, const ValueKey('count'));

    switch (_mode) {
      case AddMode.payIn4:
        return [
          source,
          gap,
          total,
          gap,
          date(
            l10n.fieldFirstDate,
            _firstDate,
            (d) => _firstDate = d,
            const ValueKey('first-date'),
          ),
        ];
      case AddMode.monthly:
        return [
          source,
          gap,
          total,
          gap,
          payments,
          gap,
          date(
            l10n.fieldFirstDate,
            _firstDate,
            (d) => _firstDate = d,
            const ValueKey('first-date'),
          ),
        ];
      case AddMode.card:
        return [
          _cardPicker(context),
          gap,
          total,
          gap,
          payments,
          gap,
          date(
            l10n.fieldPurchaseDate,
            _purchaseDate,
            (d) => _purchaseDate = d,
            const ValueKey('purchase-date'),
          ),
        ];
      case AddMode.manual:
        return [
          source,
          gap,
          total,
          gap,
          payments,
          gap,
          date(
            l10n.fieldFirstDate,
            _firstDate,
            (d) => _firstDate = d,
            const ValueKey('first-date'),
          ),
          gap,
          _interval(context),
        ];
      case AddMode.midway:
        return [
          source,
          gap,
          count(
            _totalCount,
            l10n.fieldTotalCount,
            const ValueKey('total-count'),
          ),
          gap,
          TextFormField(
            key: const ValueKey('unpaid-count'),
            controller: _unpaidCount,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l10n.fieldUnpaidCount),
            validator: (v) {
              final base = _countValidator(v);
              if (base != null) return base;
              final total = _int(_totalCount);
              return total != null && int.parse(v!.trim()) > total
                  ? l10n.errorRemainingTooHigh
                  : null;
            },
          ),
          gap,
          amount(
            _installment,
            l10n.fieldInstallment,
            const ValueKey('installment'),
          ),
          gap,
          date(
            l10n.fieldNextDate,
            _nextDate,
            (d) => _nextDate = d,
            const ValueKey('next-date'),
          ),
          if (!_midwayOnCard) ...[gap, _interval(context)],
        ];
    }
  }

  Widget _interval(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            key: const ValueKey('step'),
            controller: _step,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l10n.fieldIntervalStep),
            validator: (v) {
              final n = int.tryParse(v?.trim() ?? '');
              return n == null || n < 1 || n > 365
                  ? l10n.errorStepInvalid
                  : null;
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<IntervalUnit>(
            key: const ValueKey('unit'),
            initialValue: _unit,
            isExpanded: true,
            decoration: InputDecoration(labelText: l10n.fieldIntervalUnit),
            items: [
              DropdownMenuItem(
                value: IntervalUnit.day,
                child: Text(l10n.unitDays),
              ),
              DropdownMenuItem(
                value: IntervalUnit.week,
                child: Text(l10n.unitWeeks),
              ),
              DropdownMenuItem(
                value: IntervalUnit.month,
                child: Text(l10n.unitMonths),
              ),
            ],
            onChanged: (u) => setState(() => _unit = u ?? _unit),
          ),
        ),
      ],
    );
  }

  Widget _cardPicker(BuildContext context) {
    final l10n = context.l10n;
    final cards = _cards;
    if (cards.isEmpty) {
      return Row(
        children: [
          Expanded(child: Text(l10n.noCards)),
          OutlinedButton.icon(
            onPressed: _addCard,
            icon: const Icon(Icons.add),
            label: Text(l10n.addCard),
          ),
        ],
      );
    }
    final selected = cards.any((c) => c.id == _cardId) ? _cardId : null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: DropdownButtonFormField<int>(
            key: const ValueKey('card'),
            initialValue: selected,
            isExpanded: true,
            decoration: InputDecoration(labelText: l10n.fieldCard),
            items: [
              for (final c in cards)
                DropdownMenuItem(value: c.id, child: Text(c.name)),
            ],
            onChanged: (id) => setState(() => _cardId = id),
            validator: (id) => id == null ? l10n.errorCardRequired : null,
          ),
        ),
        IconButton(
          tooltip: l10n.addCard,
          onPressed: _addCard,
          icon: const Icon(Icons.add_card),
        ),
      ],
    );
  }

  Widget _details(BuildContext context) {
    final l10n = context.l10n;
    return ExpansionTile(
      key: const ValueKey('more-details'),
      title: Text(l10n.actionMoreDetails),
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      children: [
        TextFormField(
          key: const ValueKey('title'),
          controller: _title,
          maxLength: 80,
          decoration: InputDecoration(
            labelText: l10n.fieldTitle,
            hintText: l10n.fieldTitleHint,
          ),
        ),
        if (_mode == AddMode.card) ...[
          const SizedBox(height: 8),
          TextFormField(
            key: const ValueKey('defer'),
            controller: _defer,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l10n.fieldDefer),
            validator: (v) {
              final n = int.tryParse(v?.trim() ?? '');
              return n == null || n < 0 || n > 12
                  ? l10n.errorDeferInvalid
                  : null;
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.fieldCashAdvance),
            value: _cashAdvance,
            onChanged: (v) => setState(() => _cashAdvance = v),
          ),
        ],
      ],
    );
  }
}

/// Free-text source with plain-text suggestions.
class _SourceField extends StatelessWidget {
  const _SourceField({
    required this.controller,
    required this.focusNode,
    required this.sources,
    required this.validator,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final List<SourceRow> sources;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final names = <String>{
      for (final s in sources) s.name,
      ...providerSuggestions,
    }.toList();
    return RawAutocomplete<String>(
      textEditingController: controller,
      focusNode: focusNode,
      optionsBuilder: (value) {
        final q = value.text.trim().toLowerCase();
        if (q.isEmpty) return const Iterable<String>.empty();
        return names.where(
          (n) => n.toLowerCase().contains(q) && n.toLowerCase() != q,
        );
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) =>
          TextFormField(
            key: const ValueKey('source'),
            controller: controller,
            focusNode: focusNode,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: l10n.fieldSource,
              hintText: l10n.fieldSourceHint,
            ),
            validator: validator,
            onFieldSubmitted: (_) => onSubmitted(),
          ),
      optionsViewBuilder: (context, onSelected, options) => Align(
        alignment: AlignmentDirectional.topStart,
        child: Material(
          color: Theme.of(context).colorScheme.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240, maxWidth: 360),
            child: ListView(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              children: [
                for (final o in options)
                  ListTile(
                    leading: LetterBadge(o, size: 32),
                    title: Text(o),
                    onTap: () => onSelected(o),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Live list of the payments the plan will have.
class _Preview extends ConsumerWidget {
  const _Preview({required this.draft});

  final PlanDraft? draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final d = draft;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.previewTitle,
                style: theme.textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            if (d == null)
              Text(
                l10n.previewEmpty,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: context.colors.textMuted,
                ),
              )
            else ...[
              Text(
                l10n.previewSummary(
                  d.payments.length,
                  ref.money(context, d.totalMinor),
                ),
                key: const ValueKey('preview-summary'),
                style: theme.textTheme.bodyLarge,
              ),
              if (d.startedMidway)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    l10n.planStartedMidway(d.firstTrackedSeq - 1),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: context.colors.textMuted,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              for (final p in d.payments)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 56,
                        child: Text(
                          l10n.progressLabel(p.seq, d.installmentCount),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontFeatures: AmountText.tabular,
                            color: context.colors.textMuted,
                          ),
                        ),
                      ),
                      Expanded(child: Text(context.longDate(p.date))),
                      AmountText(
                        ref.money(context, p.amountMinor),
                        size: AmountSize.small,
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
