import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'routes.dart';

/// One snackbar messenger per tab. A tab's snackbars sit above its "Add"
/// button instead of covering it, and only that tab draws them.
class TabMessengers {
  final Map<String, GlobalKey<ScaffoldMessengerState>> _keys = {
    for (final path in [Routes.home, Routes.plans, Routes.settings])
      path: GlobalKey<ScaffoldMessengerState>(debugLabel: 'tab $path'),
  };

  GlobalKey<ScaffoldMessengerState> keyFor(String tabPath) => _keys[tabPath]!;

  /// The messenger of the tab [router] shows, when a tab is on top.
  ScaffoldMessengerState? visible(GoRouter router) {
    var match = router.routerDelegate.currentConfiguration.matches.last;
    if (match is! ShellRouteMatch) return null;
    while (match is ShellRouteMatch) {
      match = match.matches.last;
    }
    final route = match.route;
    return route is GoRoute ? _keys[route.path]?.currentState : null;
  }
}

final tabMessengersProvider = Provider<TabMessengers>((_) => TabMessengers());

extension PopWithMessage on GoRouter {
  /// Goes back, then shows [snackBar] where the user lands: on a tab, in
  /// that tab's messenger (above its "Add" button); elsewhere in
  /// [fallback], the messenger of the screen being left.
  void popWithMessage(
    SnackBar snackBar, {
    required ScaffoldMessengerState fallback,
    required TabMessengers tabs,
    Object? result,
  }) {
    pop(result);
    (tabs.visible(this) ?? fallback).showSnackBar(snackBar);
  }
}
