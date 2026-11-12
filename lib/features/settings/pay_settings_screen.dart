import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/format.dart';
import '../../app/providers.dart';
import '../onboarding/pay_form.dart';

/// Pay frequency and payday, shared with onboarding.
class PaySettingsScreen extends ConsumerStatefulWidget {
  const PaySettingsScreen({super.key});

  @override
  ConsumerState<PaySettingsScreen> createState() => _PaySettingsScreenState();
}

class _PaySettingsScreenState extends ConsumerState<PaySettingsScreen> {
  PayFormValue? _pay;

  Future<void> _save() async {
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    await ref.read(settingsRepositoryProvider).update(_pay!.toCompanion());
    messenger.showSnackBar(SnackBar(content: Text(l10n.settingsSaved)));
    router.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings = ref.watch(settingsProvider).value;
    if (settings != null) {
      _pay ??= PayFormValue.fromSettings(settings, ref.read(todayProvider));
    }
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsPay)),
      body: _pay == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                PayFields(value: _pay!, onChanged: () => setState(() {})),
                const SizedBox(height: 24),
                FilledButton(
                  key: const ValueKey('save-pay'),
                  onPressed: _save,
                  child: Text(l10n.actionSave),
                ),
              ],
            ),
    );
  }
}
