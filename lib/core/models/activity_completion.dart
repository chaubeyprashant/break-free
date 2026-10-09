import 'dart:convert';
import 'package:break_free/core/models/replacement_activity.dart';

/// A finished replacement activity.
class ActivityCompletion {
  const ActivityCompletion({
    required this.id,
    required this.activityId,
    required this.completedAt,
    required this.tierMinutes,
    required this.xpAwarded,
  });

  final String id;
  final String activityId;
  final DateTime completedAt;
  final int tierMinutes;
  final int xpAwarded;

  ReplacementActivity? get activity => ActivityCatalog.byId(activityId);

  Map<String, dynamic> toMap() => {
        'id': id,
        'activityId': activityId,
        'completedAt': completedAt.toIso8601String(),
        'tierMinutes': tierMinutes,
        'xpAwarded': xpAwarded,
      };

  static ActivityCompletion? fromMap(Map<String, dynamic> map) {
    final id = map['id'];
    final activityId = map['activityId'];
    final completedAt = DateTime.tryParse(map['completedAt'] as String? ?? '');
    final tierMinutes = map['tierMinutes'];
    final xp = map['xpAwarded'];
    if (id is! String || activityId is! String || completedAt == null || tierMinutes is! int || xp is! int) return null;
    return ActivityCompletion(id: id, activityId: activityId, completedAt: completedAt, tierMinutes: tierMinutes, xpAwarded: xp);
  }

  String toJson() => json.encode(toMap());
}
