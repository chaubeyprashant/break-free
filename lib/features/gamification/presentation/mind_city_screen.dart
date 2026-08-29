import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:break_free/core/providers/game_provider.dart';

class MindCityScreen extends StatelessWidget {
  const MindCityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mind City')),
      body: Consumer<GameProvider>(
        builder: (context, gameProvider, child) {
          final level = gameProvider.progress.level;
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Your City (Level $level)',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 32),
                // The stack needs its own size: its children are all
                // positioned, so it would otherwise collapse to the ground bar
                // and clip every building out of view.
                SizedBox(
                  width: 300,
                  height: 160,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      // Base ground
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          height: 10,
                          color: Colors.green,
                        ).animate().fadeIn(),
                      ),
                      // Buildings unlocked by level. Animate the child, not the
                      // Positioned itself — a Positioned has to sit directly
                      // under the Stack to take effect.
                      if (level >= 1)
                        Positioned(
                          bottom: 10,
                          left: 20,
                          child: const Icon(
                            Icons.house,
                            size: 64,
                            color: Colors.brown,
                          ).animate().slideY(begin: 1, end: 0),
                        ),
                      if (level >= 2)
                        Positioned(
                          bottom: 10,
                          right: 20,
                          child: const Icon(
                            Icons.apartment,
                            size: 80,
                            color: Colors.blueGrey,
                          ).animate().slideY(begin: 1, end: 0, delay: 200.ms),
                        ),
                      if (level >= 3)
                        Positioned(
                          bottom: 10,
                          child: const Icon(
                            Icons.domain,
                            size: 100,
                            color: Colors.indigo,
                          ).animate().slideY(begin: 1, end: 0, delay: 400.ms),
                        ),
                      if (level >= 5)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: const Text(
                            '☀️',
                            style: TextStyle(fontSize: 40),
                          ).animate().fadeIn(delay: 600.ms).rotate(),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                const Text('Keep streaks to grow your city!'),
              ],
            ),
          );
        },
      ),
    );
  }
}
