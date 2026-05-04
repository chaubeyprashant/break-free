import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

void main() {
  runApp(const BreakFreeApp());
}

class BreakFreeApp extends StatelessWidget {
  const BreakFreeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
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
