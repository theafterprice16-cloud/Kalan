import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/format.dart';
import '../../core/design/widgets.dart';
import '../../core/theme/kalan_theme.dart';
import 'roadmap.dart';

class RoadmapScreen extends ConsumerWidget {
  const RoadmapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final roadmap = ref.watch(roadmapProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsRoadmap)),
      body: switch (roadmap) {
        AsyncData(:final value) when value.isEmpty => Center(
          child: EmptyState(l10n.roadmapEmpty),
        ),
        AsyncData(:final value) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: value.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, i) => _RoadmapCard(item: value[i]),
        ),
        AsyncError() => Center(child: EmptyState(l10n.roadmapError)),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _RoadmapCard extends StatelessWidget {
  const _RoadmapCard({required this.item});

  final RoadmapItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = context.localeName;
    final (icon, label) = switch (item.status) {
      RoadmapStatus.planned => (Icons.schedule, l10n.roadmapPlanned),
      RoadmapStatus.inProgress => (Icons.autorenew, l10n.roadmapInProgress),
      RoadmapStatus.shipped => (
        Icons.check_circle_outline,
        l10n.roadmapShipped,
      ),
    };
    final secondary = theme.textTheme.bodyMedium?.copyWith(
      color: context.colors.textMuted,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                item.title(locale),
                style: theme.textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 4),
            Text(item.summary(locale), style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 18, color: context.colors.textMuted),
                    const SizedBox(width: 4),
                    Text(label, style: secondary),
                  ],
                ),
                if (item.targetVersion != null)
                  Text(
                    l10n.roadmapTarget(item.targetVersion!),
                    style: secondary,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
