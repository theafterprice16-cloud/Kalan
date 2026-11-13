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
/// four fields. Any of them can be "already underway".
enum AddMode { payIn4, monthly, card, manual }

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
  final _paid = TextEditingController();
  final _step = TextEditingController(text: '1');
  final _defer = TextEditingController(text: '0');
  final _title = TextEditingController();

  AddMode _mode = AddMode.payIn4;
  late LocalDate _firstDate;
  late LocalDate _purchaseDate;
  late LocalDate _nextDate;
  late LocalDate _today;

  /// "This plan is already underway".
  bool _underway = false;

  /// Installments paid for Pay in 4 (1-3), chosen with chips.
  int _paidPayIn4 = 1;

  /// The user picked the next date; card suggestions no longer replace it.
  bool _nextDateTouched = false;
  IntervalUnit _unit = IntervalUnit.month;
  int? _cardId;
  bool _cashAdvance = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final today = ref.read(todayProvider);
    _today = today;
    _firstDate = today;
    _purchaseDate = today;
    _nextDate = today;
    for (final c in [_source, _total, _count, _paid, _step, _defer]) {
      c.addListener(_refresh);
    }
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    for (final c in [_source, _total, _count, _paid, _step, _defer, _title]) {
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

  CardTerms? get _cardTerms =>
      _sources.where((s) => s.id == _cardId).firstOrNull?.cardTerms;

  /// The card's next due date after today: the suggested next payment date.
  void _suggestNextDate() {
    final terms = _cardTerms;
    if (_mode == AddMode.card && terms != null && !_nextDateTouched) {
      _nextDate = nextCardDueAfter(_today, terms);
    }
  }

  bool get _nextDateSuggested =>
      _mode == AddMode.card && _cardTerms != null && !_nextDateTouched;

  /// The draft for the current inputs, or null while incomplete.
  PlanDraft? _buildDraft() {
    try {
      final total = _amount(_total);
      if (total == null) return null;
      final count = _mode == AddMode.payIn4 ? 4 : _int(_count);
      if (count == null) return null;
      if (_underway && _mode != AddMode.manual) {
        final paid = _mode == AddMode.payIn4 ? _paidPayIn4 : _int(_paid);
        if (paid == null) return null;
        return underwayPlan(
          kind: switch (_mode) {
            AddMode.payIn4 => PlanKind.payIn4,
            AddMode.monthly => PlanKind.monthly,
            _ => PlanKind.card,
          },
          totalMinor: total,
          count: count,
          paidCount: paid,
          nextDate: _nextDate,
          terms: _mode == AddMode.card ? _cardTerms : null,
          isCashAdvance: _cashAdvance,
        );
      }
      final draft = switch (_mode) {
        AddMode.payIn4 => PlanCalculator.payIn4(
          firstDate: _firstDate,
          totalMinor: total,
        ),
        AddMode.monthly => PlanCalculator.monthly(
          firstDate: _firstDate,
          totalMinor: total,
          count: count,
        ),
        AddMode.card => switch (_cardTerms) {
          final terms? => PlanCalculator.card(
            purchaseDate: _purchaseDate,
            totalMinor: total,
            count: count,
            terms: terms,
            deferMonths: _int(_defer) ?? 0,
            isCashAdvance: _cashAdvance,
          ),
          null => null,
        },
        AddMode.manual => switch (_int(_step)) {
          final step? => PlanCalculator.manual(
            firstDate: _firstDate,
            totalMinor: total,
            count: count,
            unit: _unit,
            step: step,
          ),
          null => null,
        },
      };
      if (draft == null || !_underway) return draft;
      final paid = _int(_paid);
      return paid == null ? null : markPaidBefore(draft, paid);
    } on InvalidPlanInput {
      return null;
    }
  }

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
          origin: _mode == AddMode.manual
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
    if (id != null) {
      setState(() {
        _cardId = id;
        _suggestNextDate();
      });
    }
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

  String? _paidValidator(String? v) {
    final l10n = context.l10n;
    final n = int.tryParse(v?.trim() ?? '');
    if (n == null || n < 1) return l10n.errorPaidMin;
    final count = _int(_count);
    if (count != null && n >= count) return l10n.errorPaidAll;
    return null;
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
                    ],
                    onSelected: (m) => setState(() {
                      _mode = m;
                      _suggestNextDate();
                    }),
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
          inputFormatters: ref.amountFormatters(context),
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
    final payments = count(
      _count,
      _underway ? l10n.fieldTotalInstallments : l10n.fieldCount,
      const ValueKey('count'),
    );
    final firstDate = date(
      l10n.fieldFirstDate,
      _firstDate,
      (d) => _firstDate = d,
      const ValueKey('first-date'),
    );
    final nextDate = DateField(
      key: const ValueKey('next-date'),
      label: l10n.fieldNextPaymentDate,
      value: _nextDate,
      format: context.longDate,
      helperText: _nextDateSuggested ? l10n.underwayCardSuggested : null,
      onChanged: (d) => setState(() {
        _nextDate = d;
        _nextDateTouched = true;
      }),
    );
    // Off: the screen is exactly as before. On: the paid count, and the
    // next payment date in place of the first or purchase date (manual
    // entry keeps its own dates).
    final underway = _UnderwaySection(
      value: _underway,
      onChanged: (on) => setState(() {
        _underway = on;
        _suggestNextDate();
      }),
      children: [
        if (_mode == AddMode.payIn4)
          ChoiceField<int>(
            key: const ValueKey('paid-payin4'),
            label: l10n.fieldPaidInstallments,
            selected: _paidPayIn4,
            options: [
              for (final n in const [1, 2, 3]) (n, context.l10n.numberValue(n)),
            ],
            onSelected: (n) => setState(() => _paidPayIn4 = n),
          )
        else
          TextFormField(
            key: const ValueKey('paid-count'),
            controller: _paid,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l10n.fieldPaidInstallments),
            validator: _paidValidator,
          ),
      ],
    );
    final dateField = !_underway || _mode == AddMode.manual ? null : nextDate;

    switch (_mode) {
      case AddMode.payIn4:
        return [source, gap, total, gap, underway, gap, dateField ?? firstDate];
      case AddMode.monthly:
        return [
          source,
          gap,
          total,
          gap,
          payments,
          gap,
          underway,
          gap,
          dateField ?? firstDate,
        ];
      case AddMode.card:
        return [
          _cardPicker(context),
          gap,
          total,
          gap,
          payments,
          gap,
          underway,
          gap,
          dateField ??
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
          underway,
          gap,
          firstDate,
          gap,
          _interval(context),
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
            onChanged: (id) => setState(() {
              _cardId = id;
              _suggestNextDate();
            }),
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
          // A plan already underway has no purchase date to defer from.
          if (!_underway)
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
    // Payments paid before Kalan are summed up, never listed with dates.
    final listed = d?.payments.skip(d.paidBeforeCount).toList() ?? const [];
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
                  listed.length,
                  ref.money(
                    context,
                    listed.fold(0, (sum, p) => sum + p.amountMinor),
                  ),
                ),
                key: const ValueKey('preview-summary'),
                style: theme.textTheme.bodyLarge,
              ),
              if (d.paidBeforeCount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    l10n.paidBeforeSummary(
                      d.paidBeforeCount,
                      ref.money(
                        context,
                        d.payments
                            .take(d.paidBeforeCount)
                            .fold(0, (sum, p) => sum + p.amountMinor),
                      ),
                    ),
                    key: const ValueKey('preview-paid-before'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: context.colors.textMuted,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              for (final p in listed)
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

/// "This plan is already underway": a switch with a short note; its fields
/// slide in below when it is on.
class _UnderwaySection extends StatelessWidget {
  const _UnderwaySection({
    required this.value,
    required this.onChanged,
    required this.children,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            key: const ValueKey('underway'),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.underwayToggle),
            subtitle: Text(
              l10n.underwayHint,
              style: TextStyle(color: context.colors.textMuted),
            ),
            value: value,
            onChanged: onChanged,
          ),
          if (value) ...[const SizedBox(height: 8), ...children],
        ],
      ),
    );
  }
}
