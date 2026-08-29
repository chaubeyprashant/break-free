import 'package:break_free/core/data/activity_log_repository.dart';
import 'package:break_free/core/data/check_in_repository.dart';
import 'package:break_free/core/data/game_repository.dart';
import 'package:break_free/core/data/streak_policy_repository.dart';
import 'package:break_free/core/models/streak_policy.dart';
import 'package:break_free/features/dashboard/data/streak_repository.dart';

// We use entities as models
import '../../domain/entities/dashboard_stats_entity.dart';
import '../../domain/entities/activity_entity.dart';

abstract class DashboardDataSource {
  Future<DashboardStatsEntity> fetchDashboardStats();
  Future<List<ActivityEntity>> fetchRecentActivities();
}

/// Reads the dashboard from on-device storage. The app has no backend, so
/// every number here comes from what the user has actually done.
class DashboardLocalDataSource implements DashboardDataSource {
  final CheckInRepository _checkIns;
  final GameRepository _game;
  final StreakRepository _streak;
  final StreakPolicyRepository _policy;
  final ActivityLogRepository _activityLog;

  DashboardLocalDataSource({
    CheckInRepository? checkIns,
    GameRepository? game,
    StreakRepository? streak,
    StreakPolicyRepository? policy,
    ActivityLogRepository? activityLog,
  }) : _checkIns = checkIns ?? CheckInRepository(),
       _game = game ?? GameRepository(),
       _streak = streak ?? StreakRepository(),
       _policy = policy ?? StreakPolicyRepository(),
       _activityLog = activityLog ?? ActivityLogRepository();

  @override
  Future<DashboardStatsEntity> fetchDashboardStats() async {
    final now = DateTime.now();
    final progress = await _game.getProgress();
    // Idempotent: starts the clock the first time the user reaches the
    // dashboard, so the streak isn't stuck at zero waiting for some other
    // screen to construct StreakProvider.
    await _streak.startStreak();
    final startDate = await _streak.getStreakStartDate();
    final policy = await _policy.get();

    final elapsed = startDate == null ? Duration.zero : now.difference(startDate);

    return DashboardStatsEntity(
      currentStreak: elapsed.inDays,
      currentStreakHours: elapsed.inHours,
      totalCheckIns: await _checkIns.getTotalCheckIns(),
      shieldsAvailable: StreakPolicy.shieldsPerWeek - policy.shieldsUsedThisWeek,
      totalCoins: progress.coins,
      weeklyProgressXP: await _checkIns.xpForWeekOf(now),
      hasCheckedInToday: await _checkIns.hasCheckedInOn(now),
    );
  }

  @override
  Future<List<ActivityEntity>> fetchRecentActivities() async {
    final events = await _activityLog.getEvents();
    return events
        .map(
          (event) => ActivityEntity(
            id: event.id,
            title: event.title,
            description: event.description,
            timestamp: event.timestamp,
            iconType: event.type,
          ),
        )
        .toList();
  }
}
