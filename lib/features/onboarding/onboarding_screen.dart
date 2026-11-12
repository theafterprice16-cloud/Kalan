import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/format.dart';
import '../../app/providers.dart';
import '../../core/money/currency.dart';
import '../../core/money/money_format.dart';
import '../../data/db/app_database.dart';
import '../currency/currency_picker.dart';
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
            netIncomeMinor: Value(_parsedIncome),
          ),
        );
    // The router redirects to home once settings exist.
  }

  /// Suggested from the device region until the user picks one.
  Currency get _currencyOrDefault =>
      _currency ?? Currency.forRegion(ref.read(deviceRegionProvider));

  int? get _parsedIncome => _income.text.trim().isEmpty
      ? null
      : parseAmount(
          _income.text,
          _currencyOrDefault,
          localeName: context.localeName,
        );

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
              CurrencyField(
                value: _currencyOrDefault,
                onChanged: (c) => setState(() => _currency = c),
              ),
              const SizedBox(height: 24),
              PayFields(value: _pay, onChanged: () => setState(() {})),
              const SizedBox(height: 24),
              OptionalAmountField(
                fieldKey: const ValueKey('net-income'),
                controller: _income,
                currency: _currencyOrDefault,
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
