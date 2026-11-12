import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/format.dart';
import '../../app/providers.dart';
import '../../core/design/form_fields.dart';
import '../../core/money/currency.dart';
import '../../data/db/app_database.dart';
import 'pay_form.dart';

/// One-minute setup: currency, pay schedule, optional take-home pay.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _income = TextEditingController();
  late PayFormValue _pay;
  Currency? _currency;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _pay = PayFormValue.initial(ref.read(todayProvider));
  }

  @override
  void dispose() {
    _income.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final pay = _pay.toCompanion();
    await ref
        .read(settingsRepositoryProvider)
        .save(
          AppSettingsCompanion.insert(
            currencyCode: _currencyOrDefault.code,
            payFrequency: pay.payFrequency.value,
            payDay: pay.payDay,
            payAnchorDay: pay.payAnchorDay,
            netIncomeMinor: Value(optionalMinor(_income.text)),
          ),
        );
    // The router redirects to home once settings exist.
  }

  Currency get _currencyOrDefault =>
      _currency ??
      (context.localeName.startsWith('tr') ? Currency.lira : Currency.dollar);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Semantics(
                header: true,
                child: Text(
                  l10n.onboardingTitle,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(l10n.onboardingIntro, style: theme.textTheme.bodyLarge),
              const SizedBox(height: 32),
              ChoiceField<Currency>(
                label: l10n.fieldCurrency,
                selected: _currencyOrDefault,
                options: currencyOptions(context),
                onSelected: (c) => setState(() => _currency = c),
              ),
              const SizedBox(height: 24),
              PayFields(value: _pay, onChanged: () => setState(() {})),
              const SizedBox(height: 24),
              OptionalAmountField(
                fieldKey: const ValueKey('net-income'),
                controller: _income,
                label: l10n.fieldNetIncome,
                helperText: l10n.netIncomeHelp,
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(l10n.onboardingStart),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

List<(Currency, String)> currencyOptions(BuildContext context) {
  final l10n = context.l10n;
  return [
    (Currency.lira, l10n.currencyLira),
    (Currency.dollar, l10n.currencyDollar),
    (Currency.pound, l10n.currencyPound),
    (Currency.euro, l10n.currencyEuro),
  ];
}
