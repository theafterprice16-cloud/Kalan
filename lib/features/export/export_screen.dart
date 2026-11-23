import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/format.dart';
import '../../core/theme/kalan_theme.dart';
import '../privacy/amounts_hidden.dart';
import 'backup_prefs.dart';
import 'export_service.dart';

/// "Export" (Roadmap 29): a spreadsheet (CSV) or a full backup with an
/// optional password, saved or shared through the system share sheet.
/// Free for everyone; Kalan sends the file nowhere itself.
class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key, this.initial = ExportKind.spreadsheet});

  final ExportKind initial;

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  final _form = GlobalKey<FormState>();
  final _button = GlobalKey();
  // Kept only while the screen is open; never stored or logged.
  final _password = TextEditingController();
  final _again = TextEditingController();
  ExportKind _kind = ExportKind.spreadsheet;
  bool _obscured = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _kind = widget.initial;
  }

  @override
  void dispose() {
    _password.dispose();
    _again.dispose();
    super.dispose();
  }

  Rect? _origin() {
    final box = _button.currentContext?.findRenderObject() as RenderBox?;
    return box == null ? null : box.localToGlobal(Offset.zero) & box.size;
  }

  Future<void> _export() async {
    if (_kind == ExportKind.backup && !_form.currentState!.validate()) return;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _busy = true);
    try {
      final outcome = await ref
          .read(exportServiceProvider)
          .export(
            kind: _kind,
            l10n: l10n,
            password: _kind == ExportKind.backup ? _password.text : null,
            origin: _origin(),
          );
      if (outcome != ShareOutcome.dismissed && mounted) {
        _password.clear();
        _again.clear();
        if (navigator.canPop()) navigator.pop();
      }
    } on Object {
      messenger.showSnackBar(SnackBar(content: Text(l10n.exportFailed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final muted = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: colors.textMuted);
    final last = ref.watch(backupPrefsProvider).lastFullBackup;
    final backup = _kind == ExportKind.backup;
    const gap = SizedBox(height: KalanSpace.md);

    Widget option(ExportKind kind, String title, String hint) => Semantics(
      selected: _kind == kind,
      inMutuallyExclusiveGroup: true,
      child: ListTile(
        key: ValueKey('export-${kind.name}'),
        minTileHeight: 48,
        title: Text(title),
        subtitle: Text(hint, style: muted),
        trailing: _kind == kind
            ? Icon(Icons.check, color: colors.text)
            : null,
        onTap: _busy ? null : () => setState(() => _kind = kind),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.exportTitle)),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.only(bottom: KalanSpace.xl),
            children: [
              option(
                ExportKind.spreadsheet,
                l10n.exportSpreadsheet,
                l10n.exportSpreadsheetHint,
              ),
              option(ExportKind.backup, l10n.exportBackup, l10n.exportBackupHint),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  KalanSpace.md,
                  KalanSpace.xs,
                  KalanSpace.md,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (backup) ...[
                      Text(
                        last == null
                            ? l10n.lastBackupNone
                            : l10n.lastBackupOn(context.longDate(last)),
                        key: const ValueKey('export-last-backup'),
                        style: muted,
                      ),
                      gap,
                      TextFormField(
                        key: const ValueKey('export-password'),
                        controller: _password,
                        enabled: !_busy,
                        obscureText: _obscured,
                        autocorrect: false,
                        enableSuggestions: false,
                        keyboardType: TextInputType.visiblePassword,
                        decoration: InputDecoration(
                          labelText: l10n.exportPassword,
                          suffixIcon: IconButton(
                            key: const ValueKey('export-password-show'),
                            tooltip: _obscured
                                ? l10n.exportShowPassword
                                : l10n.exportHidePassword,
                            icon: Icon(
                              _obscured
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: colors.textMuted,
                            ),
                            onPressed: () =>
                                setState(() => _obscured = !_obscured),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: KalanSpace.sm),
                      TextFormField(
                        key: const ValueKey('export-password-again'),
                        controller: _again,
                        enabled: !_busy,
                        obscureText: _obscured,
                        autocorrect: false,
                        enableSuggestions: false,
                        keyboardType: TextInputType.visiblePassword,
                        decoration: InputDecoration(
                          labelText: l10n.exportPasswordAgain,
                        ),
                        // Any password is fine; only the two must match.
                        validator: (value) => (value ?? '') == _password.text
                            ? null
                            : l10n.exportPasswordMismatch,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: KalanSpace.xs),
                      Text(
                        l10n.exportPasswordNote,
                        key: const ValueKey('export-password-note'),
                        style: muted,
                      ),
                    ],
                    if (ref.watch(amountsHiddenProvider)) ...[
                      gap,
                      Text(
                        l10n.exportAmountsShown,
                        key: const ValueKey('export-amounts-shown'),
                        style: muted,
                      ),
                    ],
                    const SizedBox(height: KalanSpace.lg),
                    if (backup && _password.text.isEmpty) ...[
                      Text(
                        l10n.exportNoPassword,
                        key: const ValueKey('export-no-password'),
                        style: muted,
                      ),
                      const SizedBox(height: KalanSpace.xs),
                    ],
                    FilledButton(
                      key: _button,
                      onPressed: _busy ? null : () => unawaited(_export()),
                      child: Text(l10n.exportSave),
                    ),
                    if (_busy) ...[
                      const SizedBox(height: KalanSpace.sm),
                      Row(
                        key: const ValueKey('export-busy'),
                        children: [
                          SizedBox.square(
                            dimension: KalanSpace.md,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.textMuted,
                            ),
                          ),
                          const SizedBox(width: KalanSpace.xs),
                          Expanded(
                            child: Text(l10n.exportPreparing, style: muted),
                          ),
                        ],
                      ),
                    ],
                    gap,
                    Text(l10n.exportWhere, style: muted),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
