import 'package:material_ui/material_ui.dart';

import 'theme.dart';

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
  const LetterBadge(this.name, {super.key, this.size = 40});

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
    final palette = context.palette;
    final locale = Localizations.maybeLocaleOf(context)?.languageCode ?? 'en';
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: palette.badgeBackground,
          shape: BoxShape.circle,
        ),
        child: Text(
          letterOf(name, localeName: locale),
          textScaler: TextScaler.noScaling,
          style: TextStyle(
            color: palette.badgeForeground,
            fontWeight: FontWeight.w600,
            fontSize: size * 0.42,
          ),
        ),
      ),
    );
  }
}

/// One bar per period: spoken for in ink, left in green. When spoken for
/// exceeds income, the excess is coral.
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
    final palette = context.palette;
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
                      color: palette.spokenForBar,
                    ),
                  ),
                if (left > 0)
                  Expanded(
                    flex: left,
                    child: ColoredBox(
                      key: const ValueKey('bar-left'),
                      color: palette.leftBar,
                    ),
                  ),
                if (excess > 0)
                  Expanded(
                    flex: excess,
                    child: ColoredBox(
                      key: const ValueKey('bar-excess'),
                      color: palette.negative,
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
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(child: Icon(icon, color: color, size: 20)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
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
            color: context.palette.secondaryText,
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
                ?.copyWith(color: context.palette.secondaryText),
          ),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}
