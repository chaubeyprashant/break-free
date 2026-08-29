// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_progress.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserProgress _$UserProgressFromJson(Map<String, dynamic> json) =>
    _UserProgress(
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      level: (json['level'] as num?)?.toInt() ?? 1,
      coins: (json['coins'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$UserProgressToJson(_UserProgress instance) =>
    <String, dynamic>{
      'xp': instance.xp,
      'level': instance.level,
      'coins': instance.coins,
    };
