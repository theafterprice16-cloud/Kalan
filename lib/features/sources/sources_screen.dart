import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/format.dart';
import '../../app/providers.dart';
import '../../core/design/widgets.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/kalan_theme.dart';
import '../../data/db/app_database.dart';

class SourcesScreen extends ConsumerWidget {
  const SourcesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final sources = ref.watch(sourcesProvider).value;
    final secondary = Theme.of(context).textTheme.bodyMedium
        ?.copyWith(color: context.colors.textMuted);
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
          : sources.isEmpty
          ? Center(child: EmptyState(l10n.sourcesEmpty))
          : ListView(
              padding: const EdgeInsets.only(bottom: 96, top: 8),
              children: [
                for (final s in sources)
                  ListTile(
                    minTileHeight: 64,
                    leading: LetterBadge(s.name),
                    title: Text(s.name),
                    subtitle: Text(
                      s.kind == SourceKind.card &&
                              s.statementDay != null &&
                              s.dueDay != null
                          ? '${l10n.sourceKindCard} · '
                                '${l10n.cardSummary(s.statementDay!, s.dueDay!)}'
                          : l10n.sourceKindProvider,
                      style: secondary,
                    ),
                    onTap: () => context.push(Routes.source(s.id)),
                  ),
              ],
            ),
    );
  }
}
