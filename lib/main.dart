import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as legacy_provider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:break_free/core/theme/app_theme.dart';
import 'package:break_free/core/router/app_router.dart';
import 'package:break_free/features/dashboard/data/streak_repository.dart';
import 'package:break_free/features/dashboard/presentation/streak_provider.dart';
import 'package:break_free/core/providers/habit_provider.dart';
import 'package:break_free/core/data/habit_repository.dart';
import 'package:break_free/core/providers/game_provider.dart';
import 'package:break_free/core/data/game_repository.dart';
import 'package:break_free/core/data/streak_policy_repository.dart';
import 'package:break_free/core/providers/streak_policy_provider.dart';
import 'package:break_free/core/data/activity_log_repository.dart';
import 'package:break_free/core/data/check_in_repository.dart';
import 'package:break_free/core/data/relapse_log_repository.dart';
import 'package:break_free/core/data/reminder_settings_repository.dart';
import 'package:break_free/core/notifications/notification_service.dart';
import 'package:break_free/core/storage/hive_setup.dart';
import 'package:break_free/features/auth/presentation/providers/auth_provider.dart';
import 'package:break_free/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await HiveSetup.init();
  
  runApp(
    const ProviderScope(
      child: BreakFreeApp(),
    ),
  );

  // Off the startup path: scheduled alarms don't survive app updates or a
  // reboot, so re-arm whatever the user asked for.
  unawaited(_rearmDailyReminder());
}

Future<void> _rearmDailyReminder() async {
  try {
    final reminder = await ReminderSettingsRepository().load();
    if (!reminder.enabled) return;
    await NotificationService().scheduleDailyReminder(
      hour: reminder.hour,
      minute: reminder.minute,
    );
  } catch (error) {
    debugPrint('Could not re-arm the daily reminder: $error');
  }
}

class BreakFreeApp extends ConsumerWidget {
  const BreakFreeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    // Kicks off anonymous sign-in. Nothing is gated on the result; we just
    // want the Firebase identity established as early as possible.
    ref.watch(authProvider);

    // We keep MultiProvider for legacy providers until they are fully migrated to Riverpod
    return legacy_provider.MultiProvider(
      providers: [
        legacy_provider.Provider(create: (_) => StreakRepository()),
        legacy_provider.Provider(create: (_) => CheckInRepository()),
        legacy_provider.Provider(create: (_) => ActivityLogRepository()),
        legacy_provider.Provider(create: (_) => RelapseLogRepository()),
        legacy_provider.Provider(create: (_) => ReminderSettingsRepository()),
        legacy_provider.Provider(create: (_) => NotificationService()),
        legacy_provider.ChangeNotifierProvider(
          create: (context) => StreakProvider(context.read<StreakRepository>()),
        ),
        legacy_provider.Provider(create: (_) => StreakPolicyRepository()),
        legacy_provider.ChangeNotifierProvider(
          create: (context) => StreakPolicyProvider(context.read<StreakPolicyRepository>()),
        ),
        legacy_provider.ChangeNotifierProvider(create: (_) => HabitProvider(HabitRepository())),
        legacy_provider.ChangeNotifierProvider(create: (_) => GameProvider(GameRepository())),
      ],
      child: MaterialApp.router(
        title: 'Break Free',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
