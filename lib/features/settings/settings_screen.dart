import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/format.dart';
import '../../app/locale.dart';
import '../../app/providers.dart';
import '../../core/date/local_date.dart';
import '../../core/design/choice_dialog.dart';
import '../../core/design/kalan_dialog.dart';
import '../../core/design/widgets.dart';
import '../../core/engine/pay_period.dart';
import '../../core/money/currency.dart';
import '../../core/money/money_format.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/kalan_theme.dart';
import '../../core/theme/theme_mode.dart';
import '../../data/db/app_database.dart';
import '../../entitlement/pro_controller.dart';
import '../../entitlement/pro_rules.dart';
import '../currency/currency_picker.dart';
import '../onboarding/pay_form.dart';
import '../pro/pro_screen.dart';
import '../reminders/reminders_section.dart';

/// Opens the net income dialog and saves the answer: the same dialog as
/// the income row in Settings (also used by the coming pay periods).
Future<void> editNetIncome(BuildContext context, WidgetRef ref) async {
  final l10n = context.l10n;
  final result = await showKalanDialog<Choice<int?>>(
    context: context,
    builder: (_) => _AmountDialog(
      title: l10n.settingsNetIncome,
      help: l10n.netIncomeHelp,
      initialMinor: ref.read(settingsProvider).value?.netIncomeMinor,
      currency: ref.read(currencyProvider),
    ),
  );
  if (result != null) {
    await ref
        .read(settingsRepositoryProvider)
        .update(AppSettingsCompanion(netIncomeMinor: Value(result.value)));
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _update(WidgetRef ref, AppSettingsCompanion changes) =>
      ref.read(settingsRepositoryProvider).update(changes);

  String _paySummary(BuildContext context, SettingsRow s) {
    final l10n = context.l10n;
    return switch (s.payFrequency) {
      PayFrequency.monthly => l10n.paySummaryMonthly(s.payDay ?? 1),
      PayFrequency.biweekly => l10n.paySummaryBiweekly(
        context.longDate(LocalDate.fromEpochDay(s.payAnchorDay ?? 0)),
      ),
      PayFrequency.weekly => l10n.paySummaryWeekly(
        context.weekdayName(LocalDate.fromEpochDay(s.payAnchorDay ?? 0)),
      ),
    };
  }

  Future<void> _pickLanguage(
    BuildContext context,
    WidgetRef ref,
    SettingsRow s,
  ) async {
    final l10n = context.l10n;
    final locales = ref.read(appLocalesProvider);
    final open = openLocales(locales);
    final picked = await showKalanDialog<Choice<String?>>(
      context: context,
      builder: (_) => ChoiceDialog<String?>(
        title: l10n.settingsLanguage,
        // A saved language that is no longer open reads as the phone's.
        selected: chosenLocale(s.localeCode, locales)?.code,
        options: [
          (null, l10n.languageSystem),
          // Each language in its own words; never translated.
          for (final l in open) (l.code, pickerNameOf(l, locales)),
        ],
        notes: {
          for (final l in open)
            if (l.status == LocaleStatus.draft) l.code: l10n.languageDraft,
        },
      ),
    );
    if (picked != null) {
      await _update(ref, AppSettingsCompanion(localeCode: Value(picked.value)));
    }
  }

  Future<void> _pickTheme(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final picked = await showKalanDialog<Choice<ThemeMode>>(
      context: context,
      builder: (_) => ChoiceDialog<ThemeMode>(
        title: l10n.settingsTheme,
        selected: ref.read(themeModeProvider),
        options: [
          (ThemeMode.system, l10n.themeSystem),
          (ThemeMode.light, l10n.themeLight),
          (ThemeMode.dark, l10n.themeDark),
        ],
      ),
    );
    if (picked != null) {
      await ref.read(themeModeProvider.notifier).set(picked.value);
    }
  }

  Future<void> _pickCurrency(
    BuildContext context,
    WidgetRef ref,
    SettingsRow s,
  ) async {
    final from = Currency.fromCode(s.currencyCode);
    final to = await showCurrencyPicker(context, selected: from);
    if (to == null || to == from || !context.mounted) return;
    final ok = await showKalanDialog<bool>(
      context: context,
      builder: (_) => CurrencyChangeDialog(from: from, to: to),
    );
    if (ok != true) return;
    await ref
        .read(settingsRepositoryProvider)
        .changeCurrency(from: from, to: to);
  }

  Future<void> _editAmount(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String help,
    required int? current,
    required AppSettingsCompanion Function(int?) toChanges,
  }) async {
    final result = await showKalanDialog<Choice<int?>>(
      context: context,
      builder: (_) => _AmountDialog(
        title: title,
        help: help,
        initialMinor: current,
        currency: ref.read(currencyProvider),
      ),
    );
    if (result != null) await _update(ref, toChanges(result.value));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final s = ref.watch(settingsProvider).value;
    if (s == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final secondary = Theme.of(context).textTheme.bodyMedium
        ?.copyWith(color: context.colors.textMuted);
    String amountOrNot(int? minor) =>
        minor == null ? l10n.notSet : ref.money(context, minor);
    final currency = Currency.fromCode(s.currencyCode);
    final currencyLabel =
        '${currency.pickerLabel} · ${currencyName(context, currency)}';
    final pro = ref.watch(proControllerProvider);
    final proLabel = ref.watch(entitlementProvider).isPro
        ? l10n.settingsProOn
        : pro.status == ProStatus.pending
        ? l10n.settingsProPending
        : l10n.settingsProFree;
    final locales = ref.watch(appLocalesProvider);
    final chosen = chosenLocale(s.localeCode, locales);
    final languageLabel = chosen == null
        ? l10n.languageSystem
        : pickerNameOf(chosen, locales);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navSettings)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: KalanSpace.xl),
        children: [
          SectionTitle(l10n.settingsPay),
          ListTile(
            title: Text(l10n.settingsPay),
            subtitle: Text(_paySummary(context, s), style: secondary),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.pay),
          ),
          ListTile(
            title: Text(l10n.settingsNetIncome),
            subtitle: Text(amountOrNot(s.netIncomeMinor), style: secondary),
            onTap: () => editNetIncome(context, ref),
          ),
          ListTile(
            title: Text(l10n.settingsTight),
            subtitle: Text(
              s.tightThresholdMinor == null
                  ? l10n.off
                  : ref.money(context, s.tightThresholdMinor!),
              style: secondary,
            ),
            onTap: () => _editAmount(
              context,
              ref,
              title: l10n.settingsTight,
              help: l10n.settingsTightHelp,
              current: s.tightThresholdMinor,
              toChanges: (v) =>
                  AppSettingsCompanion(tightThresholdMinor: Value(v)),
            ),
          ),
          RemindersSection(settings: s),
          const Divider(),
          ListTile(
            title: Text(l10n.settingsCurrency),
            subtitle: Text(currencyLabel, style: secondary),
            onTap: () => _pickCurrency(context, ref, s),
          ),
          ListTile(
            title: Text(l10n.settingsLanguage),
            subtitle: Text(languageLabel, style: secondary),
            onTap: () => _pickLanguage(context, ref, s),
          ),
          ListTile(
            title: Text(l10n.settingsTheme),
            subtitle: Text(switch (ref.watch(themeModeProvider)) {
              ThemeMode.system => l10n.themeSystem,
              ThemeMode.light => l10n.themeLight,
              ThemeMode.dark => l10n.themeDark,
            }, style: secondary),
            onTap: () => _pickTheme(context, ref),
          ),
          const Divider(),
          ListTile(
            key: const ValueKey('settings-pro'),
            title: Text(l10n.proTitle),
            subtitle: Text(proLabel, style: secondary),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.pro()),
          ),
          ListTile(
            key: const ValueKey('settings-restore'),
            title: Text(l10n.proRestore),
            trailing: pro.busy == ProBusy.restoring
                ? SizedBox.square(
                    dimension: KalanSpace.md,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: context.colors.textMuted,
                    ),
                  )
                : null,
            onTap: pro.busy == ProBusy.none
                ? () => restoreProPurchase(context, ref)
                : null,
          ),
          const Divider(),
          ListTile(
            title: Text(l10n.settingsSources),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.sources),
          ),
          if (kDebugMode)
            SwitchListTile.adaptive(
              key: const ValueKey('debug-pro'),
              title: Text(l10n.settingsDebugPro),
              value: s.debugPro,
              onChanged: (v) =>
                  _update(ref, AppSettingsCompanion(debugPro: Value(v))),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              KalanSpace.md,
              KalanSpace.lg,
              KalanSpace.md,
              0,
            ),
            child: Text(l10n.settingsPrivacy, style: secondary),
          ),
        ],
      ),
    );
  }
}

/// Wraps a dialog result so "cleared" (null value) differs from "cancelled".
class _AmountDialog extends StatefulWidget {
  const _AmountDialog({
    required this.title,
    required this.help,
    required this.initialMinor,
    required this.currency,
  });

  final String title;
  final String help;
  final int? initialMinor;
  final Currency currency;

  @override
  State<_AmountDialog> createState() => _AmountDialogState();
}

class _AmountDialogState extends State<_AmountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.text.isEmpty && widget.initialMinor != null) {
      _controller.text = formatMinorForInput(
        widget.initialMinor!,
        widget.currency,
        localeName: context.localeName,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return KalanAlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: OptionalAmountField(
          fieldKey: const ValueKey('settings-amount'),
          controller: _controller,
          label: widget.title,
          helperText: widget.help,
        ),
      ),
      actions: [
        KalanDialogAction(
          label: l10n.actionCancel,
          onPressed: () => Navigator.pop(context),
        ),
        KalanDialogAction(
          label: l10n.actionSave,
          primary: true,
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            final text = _controller.text;
            Navigator.pop(
              context,
              Choice(
                text.trim().isEmpty
                    ? null
                    : parseAmount(
                        text,
                        widget.currency,
                        localeName: context.localeName,
                      ),
              ),
            );
          },
        ),
      ],
    );
  }
}
