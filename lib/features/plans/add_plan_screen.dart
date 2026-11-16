import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/format.dart';
import '../../app/providers.dart';
import '../../core/design/form_fields.dart';
import '../../core/design/widgets.dart';
import '../../core/engine/engine.dart';
import '../../core/routing/routes.dart';
import '../../core/routing/tab_messengers.dart';
import '../../core/theme/kalan_theme.dart';
import '../../data/db/app_database.dart';
import '../../data/models.dart';
import '../../entitlement/entitlement.dart';
import '../reminders/reminder_prompt.dart';
import 'interval_field.dart';
import 'pay_later_form.dart';
import 'payment_method_ui.dart';

/// Ways to add a plan. The first three are templates: one screen, at most
/// four fields. Any of them can be "already underway". "Pay later" is one
/// payment: its own short form, never "underway".
enum AddMode { payIn4, monthly, card, manual, payLater }

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

  /// One installment, typed instead of the total ([AmountEntry.installment]).
  final _installment = TextEditingController();

  /// Focus of the two amount fields: switching between them keeps the
  /// keyboard open.
  final _totalFocus = FocusNode();
  final _installmentFocus = FocusNode();
  final _count = TextEditingController();
  final _paid = TextEditingController();
  final _step = TextEditingController(text: '1');
  final _defer = TextEditingController(text: '0');
  final _title = TextEditingController();

  AddMode _mode = AddMode.payIn4;

  /// The amount typed for plans with several payments; it starts with the
  /// one used last (the total until a plan is saved).
  late AmountEntry _entry;
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

  /// The payment method once chosen; until then a card plan is taken
  /// automatically and every other plan is "not set" ([_paymentMethod]).
  PaymentMethod? _method;
  bool _methodTouched = false;

  /// Where an automatic payment is taken from; null is "not chosen" (a
  /// card plan: its own card).
  int? _chargeSourceId;

  PaymentMethod? get _paymentMethod => _methodTouched
      ? _method
      : _mode == AddMode.card
      ? PaymentMethod.automatic
      : null;

  int? get _ownCardId => _mode == AddMode.card ? _cardId : null;

  /// The "Pay later" form; it starts with the rule used last.
  late final PayLaterInput _payLater;

  /// Payment interval, kept per type: each starts with its own default.
  final _payIn4Interval = IntervalInput(PaymentInterval.biweekly);
  final _monthlyInterval = IntervalInput(PaymentInterval.sameDay);

  IntervalInput? get _intervalInput => switch (_mode) {
    AddMode.payIn4 => _payIn4Interval,
    AddMode.monthly => _monthlyInterval,
    _ => null,
  };

  @override
  void initState() {
    super.initState();
    final today = ref.read(todayProvider);
    _today = today;
    _firstDate = today;
    _purchaseDate = today;
    _nextDate = today;
    for (final c in [
      _source,
      _total,
      _installment,
      _count,
      _paid,
      _step,
      _defer,
    ]) {
      c.addListener(_refresh);
    }
    _entry = lastAmountEntryOf(ref.read(settingsProvider).value);
    _payLater = PayLaterInput(
      purchaseDate: today,
      rule: lastPayLaterRuleOf(ref.read(settingsProvider).value),
    );
    for (final c in _payLater.controllers) {
      c.addListener(_refresh);
    }
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    for (final c in [
      _source,
      _total,
      _installment,
      _count,
      _paid,
      _step,
      _defer,
      _title,
    ]) {
      c.dispose();
    }
    _sourceFocus.dispose();
    _totalFocus.dispose();
    _installmentFocus.dispose();
    _payLater.dispose();
    _payIn4Interval.dispose();
    _monthlyInterval.dispose();
    super.dispose();
  }

  int? _int(TextEditingController c) => int.tryParse(c.text.trim());
  int? _amount(TextEditingController c) => ref.parseMoney(context, c.text);

  /// The payment count: always 4 for Pay in 4.
  int? get _countValue => _mode == AddMode.payIn4 ? 4 : _int(_count);

  /// The plan's total: typed, or one installment times the count. Null
  /// while incomplete or invalid.
  int? get _totalValue {
    switch (_entry) {
      case AmountEntry.total:
        return _amount(_total);
      case AmountEntry.installment:
        final installment = _amount(_installment);
        final count = _countValue;
        if (installment == null || count == null) return null;
        try {
          return totalFromInstallment(
            installmentMinor: installment,
            count: count,
            maxTotalMinor: ref.maxAmountMinor,
          );
        } on InvalidPlanInput {
          return null;
        }
    }
  }

  /// The last value written by [_switchEntry]: into which field, the
  /// text, and the count it was worked out with.
  ({AmountEntry entry, String text, int? count})? _carried;

  /// Switches between typing the total and one installment. The count
  /// stays; the amount field gets the value worked out from the other
  /// one (an uneven total gives its equal share, rounded down).
  ///
  /// Nothing typed is lost: a field is left as it is when nothing can be
  /// worked out, or when the user only looked at the other one (same
  /// carried text, same count) and came back.
  void _switchEntry(AmountEntry entry) {
    if (entry == _entry) return;
    final count = _countValue;
    final source = _entry == AmountEntry.total ? _total : _installment;
    final target = entry == AmountEntry.total ? _total : _installment;
    final carried = _carried;
    final onlyLooked =
        carried != null &&
        carried.entry == _entry &&
        carried.text == source.text &&
        carried.count == count;
    if (!onlyLooked) {
      final value = switch (entry) {
        AmountEntry.installment => _splitOf(_amount(_total), count)?.others,
        AmountEntry.total => _totalValue,
      };
      if (value != null) {
        target.text = ref.moneyInput(context, value);
      } else if (source.text.trim().isEmpty) {
        target.clear();
      }
    }
    _carried = onlyLooked
        ? null
        : (entry: entry, text: target.text, count: count);
    final typing =
        (_entry == AmountEntry.total ? _totalFocus : _installmentFocus)
            .hasFocus;
    setState(() => _entry = entry);
    if (typing) {
      // The new field is built in the next frame; the keyboard stays.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        (entry == AmountEntry.total ? _totalFocus : _installmentFocus)
            .requestFocus();
      });
    }
  }

  /// How [total] is shared over [count] installments, or null.
  InstallmentSplit? _splitOf(int? total, int? count) {
    if (total == null || count == null) return null;
    try {
      return installmentSplit(totalMinor: total, count: count);
    } on InvalidPlanInput {
      return null;
    }
  }

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
      if (_mode == AddMode.payLater) return _payLaterDraft();
      final total = _totalValue;
      if (total == null) return null;
      final count = _countValue;
      if (count == null) return null;
      final interval = _intervalInput?.interval;
      if (_intervalInput != null && interval == null) return null;
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
          interval: interval,
        );
      }
      final draft = switch (_mode) {
        AddMode.payIn4 => PlanCalculator.payIn4(
          firstDate: _firstDate,
          totalMinor: total,
          interval: interval!,
        ),
        AddMode.monthly => PlanCalculator.monthly(
          firstDate: _firstDate,
          totalMinor: total,
          count: count,
          interval: interval!,
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
        AddMode.payLater => null,
      };
      if (draft == null || !_underway) return draft;
      final paid = _int(_paid);
      return paid == null ? null : markPaidBefore(draft, paid);
    } on InvalidPlanInput {
      return null;
    }
  }

  PlanDraft? _payLaterDraft() {
    final total = _amount(_payLater.amount);
    final rule = _payLater.rule;
    if (total == null || total < 1 || rule == null) return null;
    if (_payLater.dueDate == null) return null;
    return PlanCalculator.payLater(
      purchaseDate: _payLater.purchaseDate,
      rule: rule,
      totalMinor: total,
      chosenDate: _payLater.chosenDate,
    );
  }

  /// "Pay later": saving needs only a valid amount (the rule has a
  /// default, the purchase date is today, the rest is optional).
  bool get _payLaterAmountValid {
    final total = _amount(_payLater.amount);
    return total != null && total >= 1;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final draft = _buildDraft();
    if (draft == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final tabs = ref.read(tabMessengersProvider);
    final l10n = context.l10n;
    final router = GoRouter.of(context);
    if (!_canAdd) return;
    setState(() => _saving = true);
    final int? sourceId;
    final payLater = _mode == AddMode.payLater;
    final sourceName = payLater ? _payLater.source.text : _source.text;
    if (_mode == AddMode.card) {
      sourceId = _cardId!;
    } else if (payLater && sourceName.trim().isEmpty) {
      // A "Pay later" source is optional, for information only.
      sourceId = null;
    } else {
      sourceId =
          findSourceByName(_sources, sourceName)?.id ??
          await ref
              .read(sourceRepositoryProvider)
              .findOrCreateProvider(sourceName);
    }
    await ref
        .read(planRepositoryProvider)
        .saveDraft(
          draft,
          sourceId: sourceId,
          origin: _mode == AddMode.manual
              ? PlanOrigin.manual
              : PlanOrigin.template,
          title: payLater ? _payLater.store.text : _title.text,
          paymentMethod: _paymentMethod,
          chargeSourceId: storedChargeSourceId(
            _chargeSourceId ?? _ownCardId,
            _ownCardId,
          ),
        );
    final settings = ref.read(settingsRepositoryProvider);
    if (payLater) {
      await settings.rememberPayLaterRule(draft.payLaterRule!);
    } else {
      await settings.rememberAmountEntry(_entry);
    }
    if (mounted) await askForRemindersIfNeeded(context, ref);
    router.popWithMessage(
      SnackBar(content: Text(l10n.planSaved)),
      fallback: messenger,
      tabs: tabs,
    );
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
    if (total == null || total < 1) return ref.amountError(context, v);
    final count = _countValue;
    if (count != null && count > 0 && total < count) {
      return context.l10n.errorTotalTooSmall;
    }
    return null;
  }

  String? _installmentValidator(String? v) {
    if (v == null || v.trim().isEmpty) return context.l10n.errorRequired;
    final installment = ref.parseMoney(context, v);
    if (installment == null || installment < 1) {
      return ref.amountError(context, v);
    }
    // Only a total too large to keep is refused here; a wrong count has
    // its own message.
    final count = _countValue;
    if (count != null &&
        count >= 1 &&
        count <= PlanCalculator.maxInstallments &&
        _totalValue == null) {
      return context.l10n.errorTotalTooLarge;
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
                      (AddMode.payLater, l10n.kindPayLater),
                    ],
                    onSelected: (m) => setState(() {
                      _mode = m;
                      _suggestNextDate();
                    }),
                  ),
                  if (_mode == AddMode.payLater) ...[
                    const SizedBox(height: 8),
                    Text(
                      l10n.kindPayLaterHint,
                      key: const ValueKey('pay-later-hint'),
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: context.colors.textMuted),
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (_mode == AddMode.payLater)
                  // One payment: the due date line is the preview.
                  ...[
                    PayLaterFields(input: _payLater, onChanged: _refresh),
                    const SizedBox(height: 8),
                    _details(context),
                  ] else ...[
                    ..._fields(context),
                    const SizedBox(height: 8),
                    _details(context),
                    const SizedBox(height: 8),
                    _Preview(draft: _buildDraft()),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    key: const ValueKey('save-plan'),
                    onPressed:
                        _saving ||
                            (_mode == AddMode.payLater && !_payLaterAmountValid)
                        ? null
                        : _save,
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
    Widget amount(
      TextEditingController c,
      String label,
      Key key, {
      FocusNode? focusNode,
    }) => TextFormField(
      key: key,
      controller: c,
      focusNode: focusNode,
      keyboardType: ref.amountKeyboard,
      inputFormatters: ref.amountFormatters(context),
      decoration: InputDecoration(labelText: label),
      validator: c == _total
          ? _totalValidator
          : c == _installment
          ? _installmentValidator
          : (v) =>
                _required(v) ??
                ((ref.parseMoney(context, v!) ?? 0) < 1
                    ? ref.amountError(context, v)
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

    final source = SourceNameField(
      controller: _source,
      focusNode: _sourceFocus,
      sources: ref.watch(sourcesProvider).value ?? const [],
      validator: (v) => _required(v) == null ? null : l10n.errorNameRequired,
    );
    // The total, or one installment: a choice above one amount field and
    // a line below it with the other value, worked out. Still one field.
    final total = _AmountEntrySection(
      entry: _entry,
      onChanged: _switchEntry,
      field: switch (_entry) {
        AmountEntry.total => amount(
          _total,
          l10n.fieldTotal,
          const ValueKey('total'),
          focusNode: _totalFocus,
        ),
        AmountEntry.installment => amount(
          _installment,
          l10n.fieldInstallmentAmount,
          const ValueKey('installment'),
          focusNode: _installmentFocus,
        ),
      },
      computed: _computedLine(context),
    );
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
    // Below the date: the dates before and after it follow this choice.
    final interval = switch (_intervalInput) {
      final input? => IntervalField(input: input, onChanged: _refresh),
      null => null,
    };

    switch (_mode) {
      case AddMode.payIn4:
        return [
          source,
          gap,
          total,
          gap,
          underway,
          gap,
          dateField ?? firstDate,
          gap,
          interval!,
        ];
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
          gap,
          interval!,
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
      case AddMode.payLater:
        return const [];
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

  /// The value worked out from the typed amount and the count, or null
  /// while they are incomplete.
  String? _computedLine(BuildContext context) {
    final l10n = context.l10n;
    final count = _countValue;
    // One payment: the installment is the total; nothing to work out.
    if (count == 1) return null;
    switch (_entry) {
      case AmountEntry.total:
        final split = _splitOf(_amount(_total), count);
        if (split == null) return null;
        return split.isEven
            ? l10n.amountComputedInstallment(ref.money(context, split.first))
            : l10n.amountComputedSplit(
                split.othersCount,
                ref.money(context, split.first),
                ref.money(context, split.others),
              );
      case AmountEntry.installment:
        final total = _totalValue;
        return total == null
            ? null
            : l10n.amountComputedTotal(ref.money(context, total));
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
        // "Pay later" has its own store name field.
        if (_mode != AddMode.payLater)
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
        const SizedBox(height: 8),
        PaymentMethodFields(
          method: _paymentMethod,
          chargeSourceId: _chargeSourceId,
          ownCardId: _ownCardId,
          onMethodChanged: (m) => setState(() {
            _method = m;
            _methodTouched = true;
          }),
          onChargeSourceChanged: (id) => setState(() => _chargeSourceId = id),
        ),
      ],
    );
  }
}

/// Free-text source with plain-text suggestions.
class SourceNameField extends StatelessWidget {
  const SourceNameField({
    required this.controller,
    required this.focusNode,
    required this.sources,
    required this.validator,
    super.key,
    this.label,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final List<SourceRow> sources;
  final FormFieldValidator<String> validator;

  /// Defaults to "Source".
  final String? label;

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
              labelText: label ?? l10n.fieldSource,
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
              if (monthsWithSeveral(listed.map((p) => p.date)) case final months
                  when months.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    l10n.previewSameMonth(
                      months
                          .map(
                            (m) => l10n.previewSameMonthItem(
                              context.monthYear(m.year, m.month),
                              m.count,
                            ),
                          )
                          .join(l10n.previewMonthSeparator),
                    ),
                    key: const ValueKey('preview-same-month'),
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

/// Which amount is typed (total or one installment), its field, and the
/// other value worked out below it, muted and marked "calculated".
class _AmountEntrySection extends StatelessWidget {
  const _AmountEntrySection({
    required this.entry,
    required this.onChanged,
    required this.field,
    required this.computed,
  });

  final AmountEntry entry;
  final ValueChanged<AmountEntry> onChanged;
  final Widget field;
  final String? computed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final line = computed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: l10n.amountEntryLabel,
          container: true,
          child: SegmentedButton<AmountEntry>(
            key: const ValueKey('amount-entry'),
            segments: [
              ButtonSegment(
                value: AmountEntry.total,
                label: Text(l10n.amountEntryTotal),
              ),
              ButtonSegment(
                value: AmountEntry.installment,
                label: Text(l10n.amountEntryInstallment),
              ),
            ],
            selected: {entry},
            onSelectionChanged: (s) => onChanged(s.single),
          ),
        ),
        const SizedBox(height: 12),
        field,
        if (line != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 12, top: 4),
            child: Text(
              line,
              key: const ValueKey('amount-computed'),
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: context.colors.textMuted),
            ),
          ),
      ],
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
