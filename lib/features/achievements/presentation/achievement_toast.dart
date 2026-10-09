import 'package:flutter/material.dart';
import 'package:break_free/core/models/achievement.dart';
import 'package:break_free/core/theme/bf_colors.dart';
import 'package:break_free/core/theme/bf_spacing.dart';

/// Quiet unlock snackbar — no bouncing emoji, no amber celebration chrome.
class AchievementToast {
  static void show(BuildContext context, AchievementId id) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.fromLTRB(BfSpacing.md, 0, BfSpacing.md, 88),
        content: Row(
          children: [
            const Icon(Icons.emoji_events_outlined, size: 20, color: BfColors.accent),
            const SizedBox(width: BfSpacing.sm),
            Expanded(
              child: Text(
                '${id.title}  ·  +${id.xp} XP',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
