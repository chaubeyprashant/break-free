import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'package:break_free/features/auth/data/auth_repository.dart';
import 'package:break_free/features/auth/presentation/auth_provider.dart';
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
import 'package:break_free/features/app_blocker/data/app_blocker_repository.dart';
import 'package:break_free/core/data/urge_repository.dart';
import 'package:break_free/core/providers/urge_provider.dart';
import 'package:break_free/core/data/danger_window_repository.dart';
import 'package:break_free/core/providers/danger_window_provider.dart';
import 'package:break_free/core/services/protection_reminder_service.dart';
import 'package:break_free/core/data/recovery_plan_repository.dart';
import 'package:break_free/core/providers/recovery_plan_provider.dart';
import 'package:break_free/core/data/activity_repository.dart';
import 'package:break_free/core/providers/activity_provider.dart';
import 'package:break_free/core/data/daily_quest_repository.dart';
import 'package:break_free/core/providers/daily_quest_provider.dart';
import 'package:break_free/core/data/achievement_repository.dart';
import 'package:break_free/core/models/achievement.dart';
import 'package:break_free/core/providers/achievement_provider.dart';
import 'package:break_free/core/data/journal_repository.dart';
import 'package:break_free/core/providers/journal_provider.dart';
import 'package:break_free/core/data/check_in_repository.dart';
import 'package:break_free/core/providers/check_in_provider.dart';
import 'package:break_free/core/data/settings_repository.dart';
import 'package:break_free/core/providers/settings_provider.dart';
import 'package:break_free/core/providers/entitlement_provider.dart';
import 'package:break_free/core/providers/protection_provider.dart';
import 'package:break_free/core/providers/cloud_backup_provider.dart';
import 'package:break_free/core/data/protection_repository.dart';
import 'package:break_free/core/data/protection_event_repository.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
}


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase initialization error (Did you run flutterfire configure?): $e");
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Request notification permissions
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  // Listen for foreground messages (optional if we just want basic system tray notifications, but good to have)
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('Got a message whilst in the foreground!');
    if (message.notification != null) {
      debugPrint('Message also contained a notification: ${message.notification}');
    }
  });
  
  await appBlockerRepository.initialize();
  
  runApp(const BreakFreeApp());
}

class BreakFreeApp extends StatelessWidget {
  const BreakFreeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => AuthRepository()),
        ChangeNotifierProvider(
          create: (context) => AuthProvider(context.read<AuthRepository>()),
        ),
        Provider(create: (_) => StreakRepository()),
        ChangeNotifierProvider(
          create: (context) => StreakProvider(context.read<StreakRepository>()),
        ),
        Provider(create: (_) => StreakPolicyRepository()),
        ChangeNotifierProvider(create: (_) => HabitProvider(HabitRepository())),
        ChangeNotifierProvider(create: (_) => GameProvider(GameRepository())),
        ChangeNotifierProvider(create: (_) => UrgeProvider(UrgeRepository())),
        ChangeNotifierProvider(create: (_) => JournalProvider(JournalRepository())),
        ChangeNotifierProvider(create: (_) => CheckInProvider(CheckInRepository())),
        ChangeNotifierProvider(create: (_) => SettingsProvider(SettingsRepository())),
        ChangeNotifierProvider(create: (_) => EntitlementProvider()),
        ChangeNotifierProvider(create: (_) => CloudBackupProvider()),
        ChangeNotifierProvider(
          create: (_) => ProtectionProvider(
            repository: ProtectionRepository(),
            events: ProtectionEventRepository(),
          ),
        ),
        ChangeNotifierProxyProvider<EntitlementProvider, StreakPolicyProvider>(
          create: (context) => StreakPolicyProvider(context.read<StreakPolicyRepository>()),
          update: (_, entitlement, policy) {
            policy!.applyCaps(
              freezesPerWeek: entitlement.freezesPerWeek,
              shieldsPerWeek: entitlement.shieldsPerWeek,
            );
            return policy;
          },
        ),
        ChangeNotifierProvider(create: (_) => RecoveryPlanProvider(RecoveryPlanRepository())),
        ChangeNotifierProvider(create: (_) => ActivityProvider(ActivityRepository())),
        ChangeNotifierProxyProvider3<UrgeProvider, ActivityProvider, HabitProvider, DailyQuestProvider>(
          create: (context) => DailyQuestProvider(
            DailyQuestRepository(),
            awardReward: (xp, coins) => context.read<GameProvider>().addXp(xp, coinBonus: coins),
          ),
          update: (_, urges, activities, habits, quests) => quests!
            ..update(
              urges: urges.urges,
              activities: activities.completions,
              hasHabits: habits.habits.isNotEmpty,
              hasBlockedApps: appBlockerRepository.blockedApps.isNotEmpty,
            ),
        ),
        ChangeNotifierProxyProvider6<UrgeProvider, ActivityProvider, HabitProvider, GameProvider, StreakPolicyProvider, DailyQuestProvider, AchievementProvider>(
          create: (context) => AchievementProvider(
            AchievementRepository(),
            awardXp: (xp) => context.read<GameProvider>().addXp(xp),
          ),
          update: (_, urges, activities, habits, game, policy, quests, achievements) => achievements!
            ..evaluate(AchievementInputs(
              urges: urges.urges,
              activities: activities.completions,
              habits: habits.habits,
              level: game.progress.level,
              policy: policy.policy,
              quests: quests.quests,
            )),
        ),
        ChangeNotifierProxyProvider<UrgeProvider, DangerWindowProvider>(
          create: (_) => DangerWindowProvider(DangerWindowRepository(), LocalProtectionReminderService()),
          update: (_, urgeProvider, dangerWindowProvider) => dangerWindowProvider!..updateUrges(urgeProvider.urges),
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return _CloudBackupLifecycle(
            child: MaterialApp.router(
              title: 'Break Free',
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: settings.themeMode,
              routerConfig: router,
              debugShowCheckedModeBanner: false,
            ),
          );
        },
      ),
    );
  }
}

/// Keeps cloud backup auth state in sync and auto-backs up on background.
class _CloudBackupLifecycle extends StatefulWidget {
  const _CloudBackupLifecycle({required this.child});

  final Widget child;

  @override
  State<_CloudBackupLifecycle> createState() => _CloudBackupLifecycleState();
}

class _CloudBackupLifecycleState extends State<_CloudBackupLifecycle> with WidgetsBindingObserver {
  bool? _lastSignedIn;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncAuth());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _syncAuth() {
    if (!mounted) return;
    final signedIn = context.read<AuthProvider>().user != null;
    if (_lastSignedIn == signedIn) return;
    _lastSignedIn = signedIn;
    context.read<CloudBackupProvider>().onAuthChanged(signedIn: signedIn);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      context.read<CloudBackupProvider>().maybeAutoBackup();
    }
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = context.watch<AuthProvider>().user != null;
    if (_lastSignedIn != signedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncAuth());
    }
    return widget.child;
  }
}
