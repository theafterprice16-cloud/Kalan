import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../app/shell.dart';
import '../../features/home/home_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/periods/coming_periods_screen.dart';
import '../../features/plans/add_plan_screen.dart';
import '../../features/plans/plan_detail_screen.dart';
import '../../features/plans/plan_edit_screen.dart';
import '../../features/plans/plans_screen.dart';
import '../../features/pro/pro_screen.dart';
import '../../features/recurring/recurring_edit_screen.dart';
import '../../features/reminders/reminders_help_screen.dart';
import '../../features/roadmap/roadmap_screen.dart';
import '../../features/settings/pay_settings_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/sources/source_edit_screen.dart';
import '../../features/sources/sources_screen.dart';
import 'routes.dart';
import 'tab_messengers.dart';

/// Where the app starts (home); tests start elsewhere.
final initialRouteProvider = Provider<String>((ref) => Routes.home);

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(settingsProvider, (_, _) => refresh.value++);

  final router = GoRouter(
    initialLocation: ref.read(initialRouteProvider),
    refreshListenable: refresh,
    redirect: (context, state) {
      final settings = ref.read(settingsProvider);
      if (!settings.hasValue) return null;
      final onboarded = settings.value != null;
      final atOnboarding = state.matchedLocation == Routes.onboarding;
      if (!onboarded && !atOnboarding) return Routes.onboarding;
      if (onboarded && atOnboarding) return Routes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.onboarding,
        builder: (_, _) => const OnboardingScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.home,
                builder: (_, _) => const _Tab(Routes.home, HomeScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.plans,
                builder: (_, _) => const _Tab(Routes.plans, PlansScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.settings,
                builder: (_, _) =>
                    const _Tab(Routes.settings, SettingsScreen()),
              ),
            ],
          ),
        ],
      ),
      GoRoute(path: Routes.addPlan, builder: (_, _) => const AddPlanScreen()),
      GoRoute(
        path: '/plan/:id',
        builder: (_, state) =>
            PlanDetailScreen(planId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/plan/:id/edit',
        builder: (_, state) =>
            PlanEditScreen(planId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(path: Routes.sources, builder: (_, _) => const SourcesScreen()),
      GoRoute(
        path: '/source/new',
        builder: (_, state) => SourceEditScreen(
          startAsCard: state.uri.queryParameters['kind'] == 'card',
        ),
      ),
      GoRoute(
        path: '/source/:id',
        builder: (_, state) =>
            SourceEditScreen(sourceId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: Routes.newRecurring,
        builder: (_, _) => const RecurringEditScreen(),
      ),
      GoRoute(
        path: '/recurring/:id',
        builder: (_, state) => RecurringEditScreen(
          recurringId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(path: Routes.pay, builder: (_, _) => const PaySettingsScreen()),
      GoRoute(path: Routes.roadmap, builder: (_, _) => const RoadmapScreen()),
      GoRoute(
        path: '/pro',
        builder: (_, state) => ProScreen(
          returnOnUnlock: state.uri.queryParameters['then'] == 'back',
        ),
      ),
      GoRoute(
        path: Routes.comingPeriodsPath,
        builder: (_, state) => ComingPeriodsScreen(
          initialSelected:
              int.tryParse(state.uri.queryParameters['selected'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        path: Routes.remindersHelp,
        builder: (_, _) => const RemindersHelpScreen(),
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});

/// Each tab has its own messenger (see [TabMessengers]).
class _Tab extends ConsumerWidget {
  const _Tab(this.path, this.child);

  final String path;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ScaffoldMessenger(
    key: ref.watch(tabMessengersProvider).keyFor(path),
    child: child,
  );
}
