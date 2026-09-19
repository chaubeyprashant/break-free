import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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
        ChangeNotifierProvider(
          create: (context) => StreakPolicyProvider(context.read<StreakPolicyRepository>()),
        ),
        ChangeNotifierProvider(create: (_) => HabitProvider(HabitRepository())),
        ChangeNotifierProvider(create: (_) => GameProvider(GameRepository())),
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
