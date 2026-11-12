import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../app/shell.dart';
import '../../features/home/home_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/plans/add_plan_screen.dart';
import '../../features/plans/plan_detail_screen.dart';
import '../../features/plans/plans_screen.dart';
import '../../features/recurring/recurring_edit_screen.dart';
import '../../features/roadmap/roadmap_screen.dart';
import '../../features/settings/pay_settings_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/sources/source_edit_screen.dart';
import '../../features/sources/sources_screen.dart';
import 'routes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(settingsProvider, (_, _) => refresh.value++);

  final router = GoRouter(
    initialLocation: Routes.home,
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
              GoRoute(path: Routes.home, builder: (_, _) => const HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.plans,
                builder: (_, _) => const PlansScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.settings,
                builder: (_, _) => const SettingsScreen(),
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
    ],
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});
