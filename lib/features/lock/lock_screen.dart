import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/format.dart';
import '../../core/theme/kalan_theme.dart';
import 'app_lock_controller.dart';

/// The Kalan mark as the launch screen shows it (128 logical px), in the
/// theme's light or dark colors. A brand image: its colors are the
/// logo's own, not screen tokens.
class KalanMark extends StatelessWidget {
  const KalanMark({super.key});

  static const double size = 128;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Image.asset(
      dark
          ? 'assets/brand/mark/kalan_mark_dark.png'
          : 'assets/brand/mark/kalan_mark.png',
      width: size,
      height: size,
      gaplessPlayback: true,
      semanticLabel: context.l10n.appTitle,
    );
  }
}

/// Sits over the whole app (MaterialApp.builder). With the lock off it
/// only passes [child] through, in the same place in the tree, so nothing
/// is rebuilt when the lock is turned on or off. Locked: [child] is kept
/// but not painted, read aloud, focused or animated; the lock screen is
/// all there is. Covered: the ground and the mark, nothing else.
class AppLockGate extends ConsumerWidget {
  const AppLockGate({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lock = ref.watch(appLockProvider);
    return Stack(
      fit: StackFit.expand,
      children: [
        Offstage(
          offstage: lock.locked,
          child: ExcludeFocus(
            excluding: lock.locked,
            child: TickerMode(enabled: !lock.locked, child: child),
          ),
        ),
        if (lock.locked)
          const LockScreen()
        else if (lock.covered)
          const AppSwitcherCover(),
      ],
    );
  }
}

/// The lock screen: ground, the mark in the middle, one calm line and
/// "Unlock". No amount, name or date.
class LockScreen extends ConsumerWidget {
  const LockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final bottom = SafeArea(
      minimum: const EdgeInsets.all(KalanSpace.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.appLockReason,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: colors.textMuted),
          ),
          const SizedBox(height: KalanSpace.md),
          FilledButton(
            key: const ValueKey('lock-unlock'),
            onPressed: () => ref.read(appLockProvider.notifier).unlock(),
            child: Text(l10n.appLockUnlock),
          ),
        ],
      ),
    );
    return Material(
      key: const ValueKey('lock-screen'),
      color: colors.bg,
      child: CustomMultiChildLayout(
        delegate: _LockLayout(),
        children: [
          LayoutId(
            id: _LockPart.mark,
            child: const FittedBox(fit: BoxFit.scaleDown, child: KalanMark()),
          ),
          LayoutId(id: _LockPart.bottom, child: bottom),
        ],
      ),
    );
  }
}

enum _LockPart { mark, bottom }

/// The text and the button at the bottom; the mark exactly where the
/// launch screen and the cover have it (the middle) when there is room,
/// otherwise in the middle of the space above them, smaller if need be
/// (landscape, small phones, large text). Never under the button.
class _LockLayout extends MultiChildLayoutDelegate {
  _LockLayout();

  @override
  void performLayout(Size size) {
    final bottom = layoutChild(
      _LockPart.bottom,
      BoxConstraints.tightFor(width: size.width)
          .loosen()
          .copyWith(minWidth: size.width, maxHeight: size.height),
    );
    final top = size.height - bottom.height;
    positionChild(_LockPart.bottom, Offset(0, top));
    const mark = KalanMark.size;
    final centred = size.height / 2 + mark / 2 <= top;
    final side = centred ? mark : top.clamp(0.0, mark);
    layoutChild(_LockPart.mark, BoxConstraints.tight(Size.square(side)));
    final centreY = centred ? size.height / 2 : top / 2;
    positionChild(
      _LockPart.mark,
      Offset((size.width - side) / 2, centreY - side / 2),
    );
  }

  @override
  bool shouldRelayout(_LockLayout oldDelegate) => false;
}

/// While Kalan is not in front and the lock is on: the ground and the
/// mark, no text, no blur.
class AppSwitcherCover extends StatelessWidget {
  const AppSwitcherCover({super.key});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: ColoredBox(
      key: const ValueKey('app-switcher-cover'),
      color: context.colors.bg,
      child: const Center(child: KalanMark()),
    ),
  );
}
