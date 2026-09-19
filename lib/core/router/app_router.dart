import 'package:go_router/go_router.dart';
import 'package:break_free/features/dashboard/presentation/dashboard_screen.dart';
import 'package:break_free/features/panic_mode/presentation/panic_mode_screen.dart';
import 'package:break_free/features/subscription/presentation/subscription_screen.dart';
import 'package:break_free/features/onboarding/presentation/onboarding_screen.dart';
import 'package:break_free/features/onboarding/presentation/habit_selection_screen.dart';
import 'package:break_free/features/auth/presentation/auth_screen.dart';

import 'package:break_free/features/gamification/presentation/mind_city_screen.dart';
import 'package:break_free/features/gamification/presentation/bubble_popper_game.dart';
import 'package:break_free/features/recovery/presentation/relapse_screen.dart';
import 'package:break_free/features/journal/presentation/reflection_screen.dart';
import 'package:break_free/features/settings/presentation/settings_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:break_free/features/app_blocker/presentation/app_selection_screen.dart';
import 'package:break_free/features/app_blocker/presentation/intervention_screen.dart';
import 'package:break_free/features/app_blocker/presentation/adult_intervention_screen.dart';
import 'package:break_free/features/scanner/presentation/scanner_settings_screen.dart';
import 'package:break_free/features/scanner/presentation/transaction_intervention_screen.dart';
import 'package:break_free/features/settings/presentation/accountability_settings_screen.dart';
import 'package:break_free/features/companion/presentation/companion_dashboard_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final bool loggedIn = FirebaseAuth.instance.currentUser != null;
    final bool isAuthRoute = state.uri.path == '/auth' || state.uri.path == '/onboarding';

    if (!loggedIn && !isAuthRoute) {
      return '/onboarding';
    }
    
    if (loggedIn && isAuthRoute) {
      return '/';
    }

    return null;
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
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthScreen(),
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
    GoRoute(
      path: '/app-blocker',
      builder: (context, state) => const AppSelectionScreen(),
    ),
    GoRoute(
      path: '/intervention',
      builder: (context, state) {
        final packageName = state.extra as String? ?? 'Unknown App';
        return InterventionScreen(packageName: packageName);
      },
    ),
    GoRoute(
      path: '/scanner-settings',
      builder: (context, state) => const ScannerSettingsScreen(),
    ),
    GoRoute(
      path: '/transaction-intervention',
      builder: (context, state) {
        final text = state.extra as String? ?? 'Suspicious transaction detected.';
        return TransactionInterventionScreen(notificationText: text);
      },
    ),
    GoRoute(
      path: '/adult-intervention',
      builder: (context, state) {
        final url = state.extra as String? ?? 'Adult content detected.';
        return AdultInterventionScreen(url: url);
      },
    ),
    GoRoute(
      path: '/accountability-settings',
      builder: (context, state) => const AccountabilitySettingsScreen(),
    ),
    GoRoute(
      path: '/companion',
      builder: (context, state) => const CompanionDashboardScreen(),
    ),
  ],
);
