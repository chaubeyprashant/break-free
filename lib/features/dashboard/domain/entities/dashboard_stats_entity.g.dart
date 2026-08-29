// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_stats_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DashboardStatsEntity _$DashboardStatsEntityFromJson(
  Map<String, dynamic> json,
) => _DashboardStatsEntity(
  currentStreak: (json['currentStreak'] as num).toInt(),
  currentStreakHours: (json['currentStreakHours'] as num).toInt(),
  totalCheckIns: (json['totalCheckIns'] as num).toInt(),
  shieldsAvailable: (json['shieldsAvailable'] as num).toInt(),
  totalCoins: (json['totalCoins'] as num).toInt(),
  weeklyProgressXP: (json['weeklyProgressXP'] as List<dynamic>)
      .map((e) => (e as num).toDouble())
      .toList(),
  hasCheckedInToday: json['hasCheckedInToday'] as bool,
);

Map<String, dynamic> _$DashboardStatsEntityToJson(
  _DashboardStatsEntity instance,
) => <String, dynamic>{
  'currentStreak': instance.currentStreak,
  'currentStreakHours': instance.currentStreakHours,
  'totalCheckIns': instance.totalCheckIns,
  'shieldsAvailable': instance.shieldsAvailable,
  'totalCoins': instance.totalCoins,
  'weeklyProgressXP': instance.weeklyProgressXP,
  'hasCheckedInToday': instance.hasCheckedInToday,
};
