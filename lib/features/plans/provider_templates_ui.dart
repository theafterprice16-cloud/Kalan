import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/format.dart';
import '../../app/providers.dart';
import '../../core/design/widgets.dart';
import '../../core/engine/engine.dart';
import '../../core/templates/provider_templates.dart';
import '../../core/theme/kalan_theme.dart';
import '../../data/db/app_database.dart';
import '../../l10n/generated/app_localizations.dart';

/// The templates file shipped with the app (Roadmap 25). Never fetched:
/// it changes only with an app update. Overridden in tests.
final providerTemplatesSourceProvider = FutureProvider<String>(
  (ref) => rootBundle.loadString(providerTemplatesAsset, cache: false),
);

/// Every template in the file; empty when the file cannot be read, so the
/// add plan screen stays exactly as it was.
final providerTemplatesProvider = Provider<List<ProviderTemplate>>((ref) {
  final json = ref.watch(providerTemplatesSourceProvider).value;
  if (json == null) return const [];
  try {
    return parseProviderTemplates(json);
  } on ProviderTemplateFormatException {
    return const [];
  }
});

/// The templates for the device region (not the app language,
/// DECISIONS 30); empty where none are verified.
final regionTemplatesProvider = Provider<List<ProviderTemplate>>(
  (ref) => templatesForRegion(
    ref.watch(providerTemplatesProvider),
    ref.watch(deviceRegionProvider),
  ),
);

/// A template and the pattern the user picked from it.
typedef TemplateChoice = ({ProviderTemplate template, TemplateVariant variant});

/// The provider source a template's plan uses: an existing provider
/// source with the same name (case and accents ignored), or null when one
/// has to be created at save. Cards and bank accounts never match.
SourceRow? matchProviderSource(List<SourceRow> sources, String name) {
  final key = foldName(name);
  if (key.isEmpty) return null;
  for (final s in sources) {
    if (s.kind == SourceKind.provider && foldName(s.name) == key) return s;
  }
  return null;
}

/// "3 payments · monthly", "4 payments · every 2 weeks", "One payment ·
/// 30 days later": built from the ARB files, never stored in the data.
String variantLabel(AppLocalizations l10n, TemplateVariant v) {
  if (v.kind == PlanKind.payLater) {
    final rule = v.payLaterRule!;
    return rule.kind == PayLaterRuleKind.nextMonthDay
        ? l10n.providerVariantPayLaterNextMonth(rule.value!)
        : l10n.providerVariantPayLaterDays(rule.value!);
  }
  return switch (v.interval!.days) {
    null => l10n.providerVariantSameDay(v.count),
    14 => l10n.providerVariantBiweekly(v.count),
    final days => l10n.providerVariantEveryDays(v.count, days),
  };
}

/// "Start from a provider": up to five plain-text rows under the plan
/// types, sorted by name. Nothing is suggested or ranked; the plan types
/// above stay the way to go on without a template.
class ProviderStartSection extends StatelessWidget {
  const ProviderStartSection({
    required this.templates,
    required this.selected,
    required this.onChosen,
    super.key,
  });

  final List<ProviderTemplate> templates;

  /// The template the form was filled from, if any.
  final TemplateChoice? selected;
  final ValueChanged<TemplateChoice> onChosen;

  Future<void> _tap(BuildContext context, ProviderTemplate t) async {
    if (t.variants.length == 1) {
      onChosen((template: t, variant: t.variants.single));
      return;
    }
    final current = selected;
    final variant = await showModalBottomSheet<TemplateVariant>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => TemplateVariantSheet(
        template: t,
        selected: current != null && current.template == t
            ? current.variant
            : null,
      ),
    );
    if (variant != null) onChosen((template: t, variant: variant));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final theme = Theme.of(context);
    return Column(
      key: const ValueKey('provider-start'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.providerStartTitle,
            style: theme.textTheme.titleSmall,
          ),
        ),
        const SizedBox(height: KalanSpace.xxs),
        Text(
          l10n.providerStartHint,
          style: theme.textTheme.bodyMedium?.copyWith(color: colors.textMuted),
        ),
        const SizedBox(height: KalanSpace.xs),
        for (final t in templates)
          _ProviderRow(
            template: t,
            isSelected: selected?.template == t,
            onTap: () => _tap(context, t),
          ),
      ],
    );
  }
}

class _ProviderRow extends StatelessWidget {
  const _ProviderRow({
    required this.template,
    required this.isSelected,
    required this.onTap,
  });

  final ProviderTemplate template;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final variants = template.variants;
    final several = variants.length > 1;
    return Semantics(
      selected: isSelected,
      button: true,
      child: ListTile(
        key: ValueKey('provider-${template.id}'),
        minTileHeight: 56,
        contentPadding: EdgeInsets.zero,
        leading: LetterBadge(template.name, size: 32),
        title: Text(template.name, style: TextStyle(color: colors.text)),
        subtitle: Text(
          several
              ? l10n.providerVariantOptions(variants.length)
              : variantLabel(l10n, variants.single),
          style: TextStyle(color: colors.textMuted),
        ),
        // The same selection sign as the plan types: a check in ink.
        trailing: isSelected
            ? Icon(Icons.check, color: colors.text)
            : several
            ? Icon(Icons.chevron_right, color: colors.textMuted)
            : null,
        onTap: onTap,
      ),
    );
  }
}

/// A provider with several patterns: a short sheet, the main pattern
/// first. The chosen one (or, before a choice, the first) carries the
/// check.
class TemplateVariantSheet extends StatelessWidget {
  const TemplateVariantSheet({
    required this.template,
    this.selected,
    super.key,
  });

  final ProviderTemplate template;
  final TemplateVariant? selected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final marked = selected ?? template.variants.first;
    return SafeArea(
      child: SingleChildScrollView(
        key: const ValueKey('template-variant-sheet'),
        padding: const EdgeInsets.only(bottom: KalanSpace.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                KalanSpace.lg,
                0,
                KalanSpace.lg,
                KalanSpace.xs,
              ),
              child: Semantics(
                header: true,
                child: Text(
                  template.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            for (final (i, v) in template.variants.indexed)
              Semantics(
                selected: v == marked,
                button: true,
                child: ListTile(
                  key: ValueKey('template-variant-$i'),
                  minTileHeight: 56,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: KalanSpace.lg,
                  ),
                  title: Text(variantLabel(l10n, v)),
                  trailing: v == marked
                      ? Icon(Icons.check, color: colors.text)
                      : null,
                  onTap: () => Navigator.pop(context, v),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Under the form while it holds a template's values: "Starting values
/// for Scalapay · Last checked: Nov 2026. Change them if your terms
/// differ." Muted, no warning color.
class TemplateNote extends StatelessWidget {
  const TemplateNote({required this.template, super.key});

  final ProviderTemplate template;

  @override
  Widget build(BuildContext context) => Text(
    context.l10n.providerTemplateNote(
      template.name,
      context.shortMonthYear(template.checked),
    ),
    key: const ValueKey('template-note'),
    style: Theme.of(context).textTheme.bodyMedium
        ?.copyWith(color: context.colors.textMuted),
  );
}
