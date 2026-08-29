import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/onboarding_provider.dart';

import 'package:break_free/features/dashboard/presentation/dashboard_screen.dart';
import 'package:break_free/features/panic_mode/presentation/panic_mode_screen.dart';
import 'package:break_free/features/subscription/presentation/subscription_screen.dart';
import 'package:break_free/features/onboarding/presentation/onboarding_screen.dart';
import 'package:break_free/features/onboarding/presentation/habit_selection_screen.dart';

import 'package:break_free/features/gamification/presentation/mind_city_screen.dart';
import 'package:break_free/features/gamification/presentation/bubble_popper_game.dart';
import 'package:break_free/features/recovery/presentation/relapse_screen.dart';
import 'package:break_free/features/journal/presentation/reflection_screen.dart';
import 'package:break_free/features/settings/presentation/settings_screen.dart';

/// Onboarding lives here so a new user picks the habits they want to break
/// before anything else. Both screens count as "in onboarding".
const _onboardingRoutes = {'/onboarding', '/habit-selection'};

final goRouterProvider = Provider<GoRouter>((ref) {
  final onboardingState = ref.watch(onboardingProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      // Sign-in is anonymous and happens in the background, so nothing here
      // waits on it — the app is usable offline.
      if (onboardingState.isLoading) return null;

      final hasOnboarded = onboardingState.value ?? false;
      final inOnboarding = _onboardingRoutes.contains(state.matchedLocation);

      // A user who has never chosen a habit has nothing to track yet.
      if (!hasOnboarded && !inOnboarding) {
        return '/onboarding';
      }

      return null; // No redirect needed
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const DashboardScreen()),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/habit-selection',
        builder: (context, state) => const HabitSelectionScreen(),
      ),
      GoRoute(path: '/city', builder: (context, state) => const MindCityScreen()),
      GoRoute(
        path: '/bubble-game',
        builder: (context, state) => const BubblePopperGame(),
      ),
      GoRoute(
        path: '/relapse',
        builder: (context, state) {
          final habitId = state.extra as String?;
          return RelapseScreen(habitId: habitId);
        },
      ),
      GoRoute(
        path: '/reflection',
        builder: (context, state) => const ReflectionScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/panic',
        builder: (context, state) => const PanicModeScreen(),
      ),
      GoRoute(
        path: '/subscription',
        builder: (context, state) => const SubscriptionScreen(),
      ),
    ],
  );
});
