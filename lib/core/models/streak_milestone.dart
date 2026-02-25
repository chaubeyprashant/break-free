/// Streak milestones for gamification badges and rewards.
class StreakMilestone {
  final int days;
  final String label;
  final String emoji;

  const StreakMilestone({required this.days, required this.label, required this.emoji});

  static const List<StreakMilestone> milestones = [
    StreakMilestone(days: 3, label: '3 Day Streak', emoji: '🔥'),
    StreakMilestone(days: 7, label: '1 Week', emoji: '⭐'),
    StreakMilestone(days: 14, label: '2 Weeks', emoji: '💪'),
    StreakMilestone(days: 30, label: '1 Month', emoji: '🏆'),
    StreakMilestone(days: 60, label: '2 Months', emoji: '👑'),
    StreakMilestone(days: 100, label: '100 Days', emoji: '🌟'),
  ];

  /// Highest milestone reached for given streak days.
  static StreakMilestone? reached(int streakDays) {
    StreakMilestone? last;
    for (final m in milestones) {
      if (streakDays >= m.days) last = m;
    }
    return last;
  }

  /// Next milestone to aim for.
  static StreakMilestone? next(int streakDays) {
    for (final m in milestones) {
      if (streakDays < m.days) return m;
    }
    return null;
  }
}
