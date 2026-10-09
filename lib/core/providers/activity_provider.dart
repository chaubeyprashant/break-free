import 'package:flutter/material.dart';
import 'package:break_free/core/data/activity_repository.dart';
import 'package:break_free/core/models/activity_completion.dart';
import 'package:break_free/core/models/replacement_activity.dart';

/// Records completed replacement activities. XP is awarded by the caller via
/// GameProvider so there is one reward path; the amount is stored here for
/// the record.
class ActivityProvider extends ChangeNotifier {
  ActivityProvider(this._repository) {
    _load();
  }

  final ActivityRepository _repository;
  List<ActivityCompletion> _completions = [];

  List<ActivityCompletion> get completions => List.unmodifiable(_completions);

  int get completionsToday {
    final now = DateTime.now();
    return _completions
        .where((c) => c.completedAt.year == now.year && c.completedAt.month == now.month && c.completedAt.day == now.day)
        .length;
  }

  int get totalMinutes => _completions.fold(0, (sum, c) => sum + c.tierMinutes);

  Future<void> reloadFromDisk() => _load();

  Future<void> _load() async {
    _completions = await _repository.getCompletions();
    notifyListeners();
  }

  Future<ActivityCompletion> recordCompletion(ReplacementActivity activity, {required int xpAwarded}) async {
    final completion = ActivityCompletion(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      activityId: activity.id,
      completedAt: DateTime.now(),
      tierMinutes: activity.tier.minutes,
      xpAwarded: xpAwarded,
    );
    await _repository.addCompletion(completion);
    _completions = [..._completions, completion];
    notifyListeners();
    return completion;
  }
}
