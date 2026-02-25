import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LevelUpOverlay extends StatelessWidget {
  final int newLevel;
  final String levelTitle;
  final VoidCallback onDismiss;

  const LevelUpOverlay({
    super.key,
    required this.newLevel,
    required this.levelTitle,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: GestureDetector(
        onTap: onDismiss,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF1A535C),
                        const Color(0xFF2A9D8F),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2A9D8F).withOpacity(0.5),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'LEVEL UP!',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: const Color(0xFFFFD700),
                              letterSpacing: 4,
                              fontWeight: FontWeight.bold,
                            ),
                      )
                          .animate()
                          .fadeIn()
                          .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1), curve: Curves.elasticOut),
                      const SizedBox(height: 12),
                      Text(
                        '$newLevel',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              height: 1,
                            ),
                      )
                          .animate()
                          .fadeIn(delay: 150.ms)
                          .scale(begin: const Offset(0, 0), end: const Offset(1, 1), curve: Curves.easeOutBack),
                      const SizedBox(height: 4),
                      Text(
                        levelTitle,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                      ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3, end: 0),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to continue',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white54),
                      ).animate().fadeIn(delay: 600.ms),
                    ],
                  ),
                ),
              ],
            )
                .animate()
                .fadeIn(duration: 200.ms)
                .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), curve: Curves.easeOutCubic),
          ],
        ),
      ),
    );
  }
}
