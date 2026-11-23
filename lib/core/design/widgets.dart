import 'package:material_ui/material_ui.dart';

import '../theme/kalan_theme.dart';

/// Large amount with tabular figures. Scales down instead of overflowing.
class AmountText extends StatelessWidget {
  const AmountText(
    this.text, {
    super.key,
    this.size = AmountSize.large,
    this.color,
    this.semanticsLabel,
  });

  final String text;
  final AmountSize size;
  final Color? color;
  final String? semanticsLabel;

  static const tabular = [FontFeature.tabularFigures()];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final base = switch (size) {
      AmountSize.large => theme.displayMedium,
      AmountSize.medium => theme.headlineSmall,
      AmountSize.small => theme.titleMedium,
    };
    final style = base?.copyWith(
      fontWeight: size == AmountSize.small ? FontWeight.w600 : FontWeight.w700,
      fontFeatures: tabular,
      color: color,
    );
    final label = Text(
      text,
      style: style,
      maxLines: 1,
      semanticsLabel: semanticsLabel,
    );
    if (size == AmountSize.small) return label;
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: label,
    );
  }
}

enum AmountSize { large, medium, small }

/// Neutral letter badge in place of provider or bank logos.
class LetterBadge extends StatelessWidget {
  const LetterBadge(this.name, {super.key, this.size = defaultSize});

  static const double defaultSize = 40;

  final String name;
  final double size;

  /// First letter, uppercased with Turkish dotted/dotless i in mind.
  static String letterOf(String name, {String localeName = 'en'}) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final first = String.fromCharCode(trimmed.runes.first);
    if (localeName.startsWith('tr')) {
      if (first == 'i') return 'İ';
      if (first == 'ı') return 'I';
    }
    return first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final locale = Localizations.maybeLocaleOf(context)?.languageCode ?? 'en';
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.surfaceRaised,
          shape: BoxShape.circle,
        ),
        child: Text(
          letterOf(name, localeName: locale),
          // One decorative letter in a fixed circle, hidden from screen
          // readers; the name beside it is real text and scales.
          textScaler: TextScaler.noScaling,
          style: TextStyle(
            color: colors.textMuted,
            fontWeight: FontWeight.w600,
            fontSize: size * 0.42,
          ),
        ),
      ),
    );
  }
}

/// One bar per period: spoken for in chartCommitted, left in accent. When
/// spoken for exceeds income, the excess is negative.
class PeriodBar extends StatelessWidget {
  const PeriodBar({
    required this.spokenForMinor,
    required this.incomeMinor,
    required this.semanticsLabel,
    super.key,
    this.height = 12,
  });

  final int spokenForMinor;
  final int incomeMinor;
  final String semanticsLabel;
  final double height;

  /// Segment weights in thousandths: (spokenFor, left, excess).
  static (int, int, int) weights(int spokenFor, int income) {
    final whole = spokenFor > income ? spokenFor : income;
    if (whole <= 0) return (0, 0, 0);
    int part(int v) => v <= 0 ? 0 : ((v * 1000) ~/ whole).clamp(1, 1000);
    if (spokenFor > income) {
      final inside = part(income);
      return (inside, 0, 1000 - inside);
    }
    final spent = part(spokenFor);
    return (spent, income - spokenFor > 0 ? 1000 - spent : 0, 0);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (spent, left, excess) = weights(spokenForMinor, incomeMinor);
    return Semantics(
      label: semanticsLabel,
      container: true,
      child: ExcludeSemantics(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: SizedBox(
            height: height,
            child: Row(
              // Stretch so the colored segments take the bar's height.
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (spent > 0)
                  Expanded(
                    flex: spent,
                    child: ColoredBox(
                      key: const ValueKey('bar-spoken-for'),
                      color: colors.chartCommitted,
                    ),
                  ),
                if (left > 0)
                  Expanded(
                    flex: left,
                    child: ColoredBox(
                      key: const ValueKey('bar-left'),
                      color: colors.accent,
                    ),
                  ),
                if (excess > 0)
                  Expanded(
                    flex: excess,
                    child: ColoredBox(
                      key: const ValueKey('bar-excess'),
                      color: colors.negative,
                    ),
                  ),
                if (spent + left + excess == 0)
                  Expanded(
                    child: ColoredBox(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A calm note with an icon, so status never relies on color alone.
class StatusNote extends StatelessWidget {
  const StatusNote({
    required this.icon,
    required this.text,
    required this.color,
    super.key,
    this.textColor,
    this.semanticsLabel,
  });

  final IconData icon;
  final String text;

  /// What a screen reader says in place of [text] (a hidden amount).
  final String? semanticsLabel;

  /// Icon color.
  final Color color;

  /// Defaults to the body text color.
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(child: Icon(icon, color: color, size: 20)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: textColor),
            semanticsLabel: semanticsLabel,
          ),
        ),
      ],
    );
  }
}

/// Section title used across screens.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: context.colors.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Centered single-sentence empty state.
class EmptyState extends StatelessWidget {
  const EmptyState(this.text, {super.key, this.action});

  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: context.colors.textMuted),
          ),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}

/// "Overdue" badge in late: icon and text, never color alone.
class OverdueBadge extends StatelessWidget {
  const OverdueBadge({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final late = context.colors.late;
    return Row(
      key: const ValueKey('overdue-badge'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.schedule, size: 16, color: late),
        const SizedBox(width: 4),
        // Wraps in a narrow column (longer languages, large text).
        Flexible(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: late, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
