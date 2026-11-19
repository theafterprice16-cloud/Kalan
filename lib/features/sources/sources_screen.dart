import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/format.dart';
import '../../app/providers.dart';
import '../../core/design/widgets.dart';
import '../../core/engine/card_statement.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/kalan_theme.dart';
import '../../data/db/app_database.dart';
import 'card_statements.dart';
import 'charge_forecast_view.dart';
import 'charge_section.dart';

/// Sources and cards, each in its own card. A card with installments on
/// its coming statements shows them under its name (16). A source that
/// automatic payments are taken from (and every bank account) shows what
/// comes out of it by which day (18); automatic plans without a source get
/// their own card at the end.
class SourcesScreen extends ConsumerStatefulWidget {
  const SourcesScreen({super.key, this.focusCardId});

  /// Opens scrolled to this card's statements ([Routes.cardStatements]).
  final int? focusCardId;

  @override
  ConsumerState<SourcesScreen> createState() => _SourcesScreenState();
}

class _SourcesScreenState extends ConsumerState<SourcesScreen> {
  final _focusKey = GlobalKey();
  bool _focused = false;

  void _scrollToFocusOnce() {
    if (_focused || widget.focusCardId == null) return;
    _focused = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final target = _focusKey.currentContext;
      if (target == null || !target.mounted) return;
      Scrollable.ensureVisible(
        target,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sources = ref.watch(sourcesProvider).value;
    // The statements follow the plans; wait for both before scrolling.
    final plansReady = ref.watch(plansProvider).hasValue;
    if (sources != null && plansReady) _scrollToFocusOnce();
    final unassigned =
        ref.watch(chargeForecastProvider)?.forecast.unassigned ?? const [];
    final unassignedCard = unassigned.isEmpty
        ? null
        : UnassignedChargesCard(items: unassigned);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.sourcesTitle)),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => context.push(Routes.newSource()),
        icon: const Icon(Icons.add),
        label: Text(l10n.addSource),
      ),
      body: sources == null
          ? const Center(child: CircularProgressIndicator())
          : sources.isEmpty && unassignedCard == null
          ? Center(child: EmptyState(l10n.sourcesEmpty))
          : SingleChildScrollView(
              key: const ValueKey('sources-list'),
              padding: const EdgeInsets.fromLTRB(
                KalanSpace.md,
                KalanSpace.xs,
                KalanSpace.md,
                KalanSpace.fabClearance,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final s in sources)
                    Padding(
                      padding: const EdgeInsets.only(bottom: KalanSpace.sm),
                      child: _SourceCard(
                        key: s.id == widget.focusCardId ? _focusKey : null,
                        source: s,
                      ),
                    ),
                  if (sources.isEmpty) EmptyState(l10n.sourcesEmpty),
                  ?unassignedCard,
                ],
              ),
            ),
    );
  }
}

class _SourceCard extends ConsumerWidget {
  const _SourceCard({required this.source, super.key});

  final SourceRow source;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final s = source;
    final secondary = Theme.of(context).textTheme.bodyMedium
        ?.copyWith(color: context.colors.textMuted);
    final view = s.kind == SourceKind.card
        ? ref.watch(cardStatementsProvider(s.id))
        : null;
    final forecast = ref.watch(chargeForecastProvider);
    // Every bank account, and any other source automatic payments are
    // taken from.
    final charges =
        forecast != null &&
            (s.kind == SourceKind.account ||
                forecast.forecast.bySource.containsKey(s.id))
        ? forecast.of(s.id)
        : null;
    return Card(
      key: ValueKey('source-card-${s.id}'),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            minTileHeight: 64,
            leading: LetterBadge(s.name),
            title: Text(s.name),
            subtitle: Text(switch (s.kind) {
              SourceKind.card when s.statementDay != null && s.dueDay != null =>
                '${l10n.sourceKindCard} · '
                    '${l10n.cardSummary(s.statementDay!, s.dueDay!)}',
              SourceKind.card => l10n.sourceKindCard,
              SourceKind.account => l10n.sourceKindAccount,
              SourceKind.provider => l10n.sourceKindProvider,
            }, style: secondary),
            onTap: () => context.push(Routes.source(s.id)),
          ),
          if (charges != null) ChargeSection(source: s, charges: charges),
          if (view != null) CardStatementsSection(view: view),
        ],
      ),
    );
  }
}

/// A card's six coming statements and the note that they hold only the
/// installments added to Kalan (decisions 7 and 9).
class CardStatementsSection extends ConsumerWidget {
  const CardStatementsSection({required this.view, super.key});

  final CardStatementsView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final theme = Theme.of(context);
    return Column(
      key: ValueKey('card-statements-${view.card.id}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            KalanSpace.md,
            KalanSpace.sm,
            KalanSpace.md,
            KalanSpace.xxs,
          ),
          child: Semantics(
            header: true,
            child: Text(
              l10n.cardStatementsTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                color: colors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        for (final (i, statement) in view.statements.indexed)
          _StatementRow(
            key: ValueKey('card-statement-${view.card.id}-$i'),
            cardId: view.card.id,
            statement: statement,
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            KalanSpace.md,
            KalanSpace.xxs,
            KalanSpace.md,
            KalanSpace.md,
          ),
          child: Text(
            l10n.cardStatementsNote,
            style: theme.textTheme.bodySmall?.copyWith(color: colors.textMuted),
          ),
        ),
      ],
    );
  }
}

class _StatementRow extends ConsumerWidget {
  const _StatementRow({
    required this.cardId,
    required this.statement,
    super.key,
  });

  final int cardId;
  final CardStatement statement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: colors.textMuted);
    final due = context.shortDate(statement.dueDate);
    return MergeSemantics(
      child: InkWell(
        onTap: () => context.push(
          Routes.cardStatement(cardId, statement.statementDate.epochDay),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: kMinInteractiveDimension,
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              KalanSpace.md,
              KalanSpace.xs,
              KalanSpace.xs,
              KalanSpace.xs,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) => Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: KalanSpace.xs,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              l10n.cardStatementTitle(
                                context.shortDate(statement.statementDate),
                              ),
                              style: theme.textTheme.bodyLarge,
                            ),
                            if (statement.isClosed)
                              StatementClosedNote(style: muted),
                          ],
                        ),
                        Text(
                          statement.isEmpty
                              ? l10n.cardStatementEmptyDue(due)
                              : l10n.cardStatementCountDue(
                                  statement.count,
                                  due,
                                ),
                          style: muted,
                        ),
                      ],
                    ),
                  ),
                  if (!statement.isEmpty) ...[
                    const SizedBox(width: KalanSpace.xs),
                    FittedAmount(
                      ref.money(context, statement.totalMinor),
                      maxWidth: constraints.maxWidth / 2,
                    ),
                  ],
                  ExcludeSemantics(
                    child: Icon(Icons.chevron_right, color: colors.textMuted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Closed": the statement is cut and not due yet. A small icon and the
/// word, in textMuted: a fact, not a warning.
class StatementClosedNote extends StatelessWidget {
  const StatementClosedNote({required this.style, super.key});

  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const ValueKey('statement-closed'),
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: Icon(
            Icons.lock_outline,
            size: 16,
            color: context.colors.textMuted,
          ),
        ),
        const SizedBox(width: KalanSpace.xxs),
        Flexible(child: Text(context.l10n.cardStatementClosed, style: style)),
      ],
    );
  }
}

/// A total that keeps to [maxWidth], shrinking only when it would not fit
/// (very large text on a narrow phone).
class FittedAmount extends StatelessWidget {
  const FittedAmount(
    this.text, {
    required this.maxWidth,
    super.key,
    this.color,
  });

  final String text;
  final double maxWidth;
  final Color? color;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(maxWidth: maxWidth),
    child: FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerEnd,
      child: AmountText(text, size: AmountSize.small, color: color),
    ),
  );
}
