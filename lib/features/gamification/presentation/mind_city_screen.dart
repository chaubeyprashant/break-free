import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mukti/core/providers/game_provider.dart';

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
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Base ground
                    Container(
                      width: 300,
                      height: 10,
                      color: Colors.green,
                    ).animate().fadeIn(),
                    // Buildings unlocked by level
                    if (level >= 1)
                      const Positioned(
                        bottom: 10,
                        left: 50,
                        child: Icon(Icons.house, size: 64, color: Colors.brown),
                      ).animate().slideY(begin: 1, end: 0),
                    if (level >= 2)
                      const Positioned(
                        bottom: 10,
                        right: 50,
                        child: Icon(
                          Icons.apartment,
                          size: 80,
                          color: Colors.blueGrey,
                        ),
                      ).animate().slideY(begin: 1, end: 0, delay: 200.ms),
                    if (level >= 3)
                      const Positioned(
                        bottom: 10,
                        child: Icon(
                          Icons.domain,
                          size: 100,
                          color: Colors.indigo,
                        ),
                      ).animate().slideY(begin: 1, end: 0, delay: 400.ms),
                    if (level >= 5)
                      const Positioned(
                        bottom: 80,
                        right: 20,
                        child: Text('☀️', style: TextStyle(fontSize: 40)),
                      ).animate().fadeIn(delay: 600.ms).rotate(),
                  ],
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
