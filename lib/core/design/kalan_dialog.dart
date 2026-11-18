import 'package:material_ui/material_ui.dart';

import '../theme/kalan_theme.dart';

/// Whether the phone follows Apple's habits (layout and behaviour only; the
/// look stays Kalan's). The one place screens learn the platform from.
bool followsApple(BuildContext context) => switch (Theme.of(context).platform) {
  TargetPlatform.iOS || TargetPlatform.macOS => true,
  _ => false,
};

/// Opens a Kalan dialog on both platforms. Flat raised surface with a thin
/// border and no dimming or blur (no glass, product decision 18 Nov 2026);
/// tapping outside closes it on both phones.
Future<T?> showKalanDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) => showDialog<T>(
  context: context,
  barrierDismissible: barrierDismissible,
  builder: builder,
);

/// An alert in the phone's own arrangement: Material's on Android; on iPhone
/// a centred title and message with full-width actions along the bottom
/// edge, split by hairlines. Both on Kalan's flat surface.
class KalanAlertDialog extends StatelessWidget {
  const KalanAlertDialog({
    required this.actions,
    super.key,
    this.title,
    this.content,
  });

  final Widget? title;
  final Widget? content;

  /// Usually [KalanDialogAction]s.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    if (!followsApple(context)) {
      return AlertDialog(title: title, content: content, actions: actions);
    }
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final divider = Divider(height: 1, thickness: 1, color: colors.border);
    final Widget actionArea;
    if (actions.length <= 2) {
      actionArea = IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, action) in actions.indexed) ...[
              if (i > 0)
                VerticalDivider(width: 1, thickness: 1, color: colors.border),
              Expanded(child: action),
            ],
          ],
        ),
      );
    } else {
      actionArea = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, action) in actions.indexed) ...[
            if (i > 0) divider,
            action,
          ],
        ],
      );
    }
    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  KalanSpace.md,
                  KalanSpace.lg,
                  KalanSpace.md,
                  KalanSpace.md,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (title != null)
                      DefaultTextStyle.merge(
                        style: text.titleMedium?.copyWith(color: colors.text),
                        textAlign: TextAlign.center,
                        child: title!,
                      ),
                    if (title != null && content != null)
                      const SizedBox(height: KalanSpace.xs),
                    if (content != null)
                      DefaultTextStyle.merge(
                        style: text.bodyMedium?.copyWith(color: colors.text),
                        textAlign: TextAlign.center,
                        child: content!,
                      ),
                  ],
                ),
              ),
            ),
            divider,
            actionArea,
          ],
        ),
      ),
    );
  }
}

/// One dialog button. Android: a text button. iPhone: a full-width cell of
/// the action row. [destructive] uses `late` (deleting only); [primary]
/// marks the expected answer in bold on iPhone.
class KalanDialogAction extends StatelessWidget {
  const KalanDialogAction({
    required this.label,
    required this.onPressed,
    super.key,
    this.destructive = false,
    this.primary = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool destructive;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = destructive ? colors.late : colors.accentText;
    if (!followsApple(context)) {
      return TextButton(
        style: destructive
            ? TextButton.styleFrom(foregroundColor: color)
            : null,
        onPressed: onPressed,
        child: Text(label),
      );
    }
    final text = Theme.of(context).textTheme;
    return TextButton(
      style: TextButton.styleFrom(
        foregroundColor: color,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(
          horizontal: KalanSpace.xs,
          vertical: KalanSpace.sm,
        ),
        shape: const RoundedRectangleBorder(),
        textStyle: text.bodyLarge?.copyWith(
          fontWeight: primary ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      onPressed: onPressed,
      child: Text(label, textAlign: TextAlign.center),
    );
  }
}
