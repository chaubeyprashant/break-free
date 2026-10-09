import 'package:flutter/material.dart';
import 'package:break_free/core/theme/bf_colors.dart';
import 'package:break_free/core/theme/bf_spacing.dart';

/// Quiet level acknowledgment — no gold gradients or celebration chrome.
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
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: BfSpacing.xxl),
            padding: const EdgeInsets.all(BfSpacing.xl),
            decoration: BoxDecoration(
              color: BfColors.inkElevated,
              borderRadius: BorderRadius.circular(BfRadius.md),
              border: Border.all(color: BfColors.borderDark),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'LEVEL $newLevel',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        letterSpacing: 2,
                        color: BfColors.textSecondaryDark,
                      ),
                ),
                const SizedBox(height: BfSpacing.sm),
                Text(
                  levelTitle,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: BfColors.textPrimaryDark,
                        fontWeight: FontWeight.w500,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: BfSpacing.md),
                Text(
                  'Keep going.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: BfColors.textSecondaryDark,
                      ),
                ),
                const SizedBox(height: BfSpacing.lg),
                TextButton(
                  onPressed: onDismiss,
                  child: const Text('Continue'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
