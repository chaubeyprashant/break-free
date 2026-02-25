import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mukti/core/theme/app_theme.dart';
import 'package:mukti/core/router/app_router.dart';
import 'package:mukti/features/dashboard/data/streak_repository.dart';
import 'package:mukti/features/dashboard/presentation/streak_provider.dart';
import 'package:mukti/core/providers/habit_provider.dart';
import 'package:mukti/core/data/habit_repository.dart';
import 'package:mukti/core/providers/game_provider.dart';
import 'package:mukti/core/data/game_repository.dart';
import 'package:mukti/core/data/streak_policy_repository.dart';
import 'package:mukti/core/providers/streak_policy_provider.dart';

void main() {
  runApp(const MuktiApp());
}

class MuktiApp extends StatelessWidget {
  const MuktiApp({super.key});

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
