import 'package:freezed_annotation/freezed_annotation.dart';

part 'dashboard_stats_entity.freezed.dart';
part 'dashboard_stats_entity.g.dart';

@freezed
abstract class DashboardStatsEntity with _$DashboardStatsEntity {
  const factory DashboardStatsEntity({
    required int currentStreak,
    /// Streak length in hours, so day one can show progress instead of a zero.
    required int currentStreakHours,
    required int totalCheckIns,
    required int shieldsAvailable,
    required int totalCoins,
    required List<double> weeklyProgressXP, // XP gained per day, Monday to Sunday
    required bool hasCheckedInToday,
  }) = _DashboardStatsEntity;

  factory DashboardStatsEntity.fromJson(Map<String, dynamic> json) => _$DashboardStatsEntityFromJson(json);
}
