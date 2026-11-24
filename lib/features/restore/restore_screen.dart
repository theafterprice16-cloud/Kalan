import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/format.dart';
import '../../app/providers.dart';
import '../../core/backup/backup_file.dart';
import '../../core/backup/backup_summary.dart';
import '../../core/date/local_date.dart';
import '../../core/design/haptics.dart';
import '../../core/design/kalan_dialog.dart';
import '../../core/design/widgets.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/kalan_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import 'restore_notice.dart';
import 'restore_service.dart';

/// Where the restore screen is in its flow (decision 6). While a file is
/// read the screen stays where it is, with a progress line.
enum RestoreStep { start, password, summary, restoring }

/// The calm sentence for a failure; null for none (a password is asked).
String? restoreFailureText(AppLocalizations l10n, RestoreFailure? failure) =>
    switch (failure) {
      RestoreFailure.notABackup => l10n.restoreErrorNotBackup,
      RestoreFailure.newerVersion => l10n.restoreErrorNewer,
      RestoreFailure.wrongPassword => l10n.restoreErrorPassword,
      RestoreFailure.unreadable => l10n.restoreErrorUnreadable,
      RestoreFailure.copyFailed => l10n.restoreErrorCopy,
      RestoreFailure.passwordNeeded || null => null,
    };

/// "Restore from backup" (Roadmap 30): pick a file, read it (with its
/// password), see what is in it, confirm, restore, go home. Nothing on
/// the phone changes before the confirmed restore, and then all at once.
class RestoreScreen extends ConsumerStatefulWidget {
  const RestoreScreen({super.key});

  @override
  ConsumerState<RestoreScreen> createState() => _RestoreScreenState();
}

class _RestoreScreenState extends ConsumerState<RestoreScreen> {
  final _password = TextEditingController();
  RestoreStep _step = RestoreStep.start;
  Uint8List? _bytes;
  BackupContents? _contents;
  BackupSummary? _summary;
  bool _hasData = false;
  bool _obscured = true;

  /// Reading and checking the picked file (with its password).
  bool _reading = false;

  /// Shown on the start step, or under the password field.
  RestoreFailure? _failure;

  RestoreService get _service => ref.read(restoreServiceProvider);

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  /// Back to the start with [failure] shown; the picked file is let go.
  void _fail(RestoreFailure failure) => setState(() {
    _step = RestoreStep.start;
    _reading = false;
    _failure = failure;
    _bytes = null;
    _contents = null;
    _password.clear();
  });

  Future<void> _pick() async {
    setState(() => _failure = null);
    final Uint8List? bytes;
    try {
      bytes = await _service.pick();
    } on RestoreException catch (e) {
      if (mounted) _fail(e.failure);
      return;
    }
    if (bytes == null || !mounted) return;
    _bytes = bytes;
    _password.clear();
    // A new file: back to the start, where its reading shows.
    setState(() {
      _step = RestoreStep.start;
      _contents = null;
      _summary = null;
    });
    await _read();
  }

  Future<void> _read() async {
    final bytes = _bytes;
    if (bytes == null || _reading) return;
    final password = _password.text;
    setState(() {
      _reading = true;
      _failure = null;
    });
    try {
      final contents = await _service.read(
        bytes,
        password: password.isEmpty ? null : password,
      );
      final hasData = await _service.hasData();
      if (!mounted) return;
      _password.clear();
      setState(() {
        _contents = contents;
        _summary = BackupSummary.of(contents.data);
        _hasData = hasData;
        _reading = false;
        _step = RestoreStep.summary;
      });
    } on RestoreException catch (e) {
      if (!mounted) return;
      switch (e.failure) {
        case RestoreFailure.passwordNeeded:
          setState(() {
            _reading = false;
            _step = RestoreStep.password;
          });
        case RestoreFailure.wrongPassword when password.isNotEmpty:
          // The field stays open; no limit on tries.
          setState(() {
            _reading = false;
            _step = RestoreStep.password;
            _failure = RestoreFailure.wrongPassword;
          });
        default:
          _fail(e.failure);
      }
    } on Object {
      if (mounted) _fail(RestoreFailure.unreadable);
    }
  }

  Future<void> _confirmAndRestore() async {
    final contents = _contents;
    // A second tap while it runs does nothing.
    if (contents == null || _step == RestoreStep.restoring) return;
    if (_hasData) {
      final l10n = context.l10n;
      final date = context.longDate(_backupDay(contents));
      final ok = await showKalanDialog<bool>(
        context: context,
        builder: (context) => KalanAlertDialog(
          title: Text(l10n.restoreConfirmTitle),
          content: Text(l10n.restoreConfirmBody(date)),
          actions: [
            KalanDialogAction(
              label: l10n.actionCancel,
              onPressed: () => Navigator.pop(context, false),
            ),
            KalanDialogAction(
              key: const ValueKey('restore-confirm'),
              label: l10n.restoreButton,
              primary: true,
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      );
      if (ok != true || !mounted || _step == RestoreStep.restoring) return;
    }
    setState(() => _step = RestoreStep.restoring);
    try {
      final summary = await _service.restore(contents);
      if (!mounted) return;
      KalanHaptics.success();
      ref.read(restoreNoticeProvider.notifier).restored(summary);
      // From setup too: the rest of setup is skipped.
      context.go(Routes.home);
    } on RestoreException catch (e) {
      if (mounted) _fail(e.failure);
    } on Object {
      if (mounted) _fail(RestoreFailure.unreadable);
    }
  }

  static LocalDate _backupDay(BackupContents contents) =>
      LocalDate.fromDateTime(contents.header.createdAt.toLocal());

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(color: colors.textMuted);
    final busy = _reading || _step == RestoreStep.restoring;
    const gap = SizedBox(height: KalanSpace.md);

    Widget progress(String text) => Row(
      key: const ValueKey('restore-busy'),
      children: [
        SizedBox.square(
          dimension: KalanSpace.md,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: colors.textMuted,
          ),
        ),
        const SizedBox(width: KalanSpace.xs),
        Expanded(child: Text(text, style: muted)),
      ],
    );

    final failureText = _step == RestoreStep.start
        ? restoreFailureText(l10n, _failure)
        : null;

    final children = <Widget>[
      if (_step == RestoreStep.start) ...[
        Text(l10n.restoreIntro, style: theme.textTheme.bodyLarge),
        if (failureText != null) ...[
          gap,
          StatusNote(
            key: const ValueKey('restore-error'),
            icon: Icons.info_outline,
            color: colors.textMuted,
            text: failureText,
          ),
        ],
        const SizedBox(height: KalanSpace.lg),
        FilledButton(
          key: const ValueKey('restore-pick'),
          onPressed: busy ? null : () => unawaited(_pick()),
          child: Text(l10n.restoreChooseFile),
        ),
        if (_reading) ...[
          const SizedBox(height: KalanSpace.sm),
          progress(l10n.restoreReading),
        ],
      ],
      if (_step == RestoreStep.password) ...[
        Text(l10n.restorePasswordIntro, style: theme.textTheme.bodyLarge),
        gap,
        TextField(
          key: const ValueKey('restore-password'),
          controller: _password,
          enabled: !_reading,
          obscureText: _obscured,
          autofocus: true,
          autocorrect: false,
          enableSuggestions: false,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            if (_password.text.isNotEmpty) unawaited(_read());
          },
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: l10n.restorePassword,
            errorText: restoreFailureText(l10n, _failure),
            suffixIcon: IconButton(
              key: const ValueKey('restore-password-show'),
              tooltip: _obscured
                  ? l10n.exportShowPassword
                  : l10n.exportHidePassword,
              icon: Icon(
                _obscured
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: colors.textMuted,
              ),
              onPressed: () => setState(() => _obscured = !_obscured),
            ),
          ),
        ),
        const SizedBox(height: KalanSpace.lg),
        FilledButton(
          key: const ValueKey('restore-open'),
          onPressed: _password.text.isEmpty || _reading
              ? null
              : () => unawaited(_read()),
          child: Text(l10n.restoreOpen),
        ),
        if (_reading) ...[
          const SizedBox(height: KalanSpace.sm),
          progress(l10n.restoreReading),
        ] else ...[
          const SizedBox(height: KalanSpace.xs),
          TextButton(
            onPressed: () => unawaited(_pick()),
            child: Text(l10n.restoreChooseOther),
          ),
        ],
      ],
      if ((_step == RestoreStep.summary || _step == RestoreStep.restoring) &&
          _contents != null &&
          _summary != null) ...[
        _SummaryCard(
          contents: _contents!,
          summary: _summary!,
          hasData: _hasData,
        ),
        if (_hasData) ...[
          gap,
          Text(
            l10n.restoreReplaceNote,
            key: const ValueKey('restore-replace-note'),
            style: theme.textTheme.bodyMedium?.copyWith(color: colors.text),
          ),
        ],
        const SizedBox(height: KalanSpace.lg),
        FilledButton(
          key: const ValueKey('restore-button'),
          onPressed: busy ? null : () => unawaited(_confirmAndRestore()),
          child: Text(l10n.restoreButton),
        ),
        if (_step == RestoreStep.restoring) ...[
          const SizedBox(height: KalanSpace.sm),
          progress(l10n.restoreWorking),
        ] else ...[
          const SizedBox(height: KalanSpace.xs),
          TextButton(
            key: const ValueKey('restore-other'),
            onPressed: () => unawaited(_pick()),
            child: Text(l10n.restoreChooseOther),
          ),
        ],
      ],
    ];

    // Going back never stops a restore halfway: it runs to its end in one
    // transaction, whether the screen stays or not (no PopScope; the back
    // gesture is kept, flutter-cross-ui 2.2).
    return Scaffold(
      appBar: AppBar(title: Text(l10n.restoreFromBackup)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(KalanSpace.md),
          children: children,
        ),
      ),
    );
  }
}

/// What the backup holds (decision 6): its date, plans by state,
/// recurring payments, sources and cards, and its currency. Surface;
/// figures in text, the label muted.
class _SummaryCard extends ConsumerWidget {
  const _SummaryCard({
    required this.contents,
    required this.summary,
    required this.hasData,
  });

  final BackupContents contents;
  final BackupSummary summary;
  final bool hasData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final code = contents.header.currency;
    // Only a phone with data has a currency of its own to compare with.
    final current = hasData ? ref.watch(currencyProvider).code : code;
    final line = text.bodyLarge?.copyWith(color: colors.text);
    Widget row(String value, {Key? key}) => Padding(
      padding: const EdgeInsets.only(top: KalanSpace.xs),
      child: Text(value, key: key, style: line),
    );
    return Card(
      key: const ValueKey('restore-summary'),
      child: Padding(
        padding: const EdgeInsets.all(KalanSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.restoreSummaryDate(
                context.longDate(
                  LocalDate.fromDateTime(contents.header.createdAt.toLocal()),
                ),
              ),
              key: const ValueKey('restore-summary-date'),
              style: text.titleMedium?.copyWith(
                color: colors.text,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: KalanSpace.sm),
            Text(
              l10n.restoreSummaryLabel,
              style: text.bodyMedium?.copyWith(color: colors.textMuted),
            ),
            row(
              l10n.restoreSummaryPlans(
                summary.plans,
                summary.open,
                summary.onHold,
                summary.archived,
              ),
            ),
            row(l10n.restoreSummaryRecurring(summary.recurring)),
            row(l10n.restoreSummarySources(summary.sources, summary.cards)),
            row(
              current == code
                  ? l10n.restoreSummaryCurrency(code)
                  : l10n.restoreSummaryCurrencyChange(code, current),
              key: const ValueKey('restore-summary-currency'),
            ),
          ],
        ),
      ),
    );
  }
}
