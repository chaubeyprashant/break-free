import 'package:freezed_annotation/freezed_annotation.dart';

part 'activity_entity.freezed.dart';
part 'activity_entity.g.dart';

@freezed
abstract class ActivityEntity with _$ActivityEntity {
  const factory ActivityEntity({
    required String id,
    required String title,
    required String description,
    required DateTime timestamp,
    required String iconType, // e.g., 'check_in', 'relapse', 'achievement'
  }) = _ActivityEntity;

  factory ActivityEntity.fromJson(Map<String, dynamic> json) => _$ActivityEntityFromJson(json);
}
