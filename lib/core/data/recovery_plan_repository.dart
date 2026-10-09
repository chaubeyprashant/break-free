import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:break_free/core/models/recovery_action.dart';

/// Local-only storage for the recovery plan. Independent of the blocker and
/// of any permission: it is plain SharedPreferences.
class RecoveryPlanRepository {
  static const String planKey = 'recovery_plan';

  /// Returns the stored plan, or the defaults when nothing was saved yet.
  Future<List<RecoveryAction>> getPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(planKey);
    if (encoded == null) return RecoveryPlanDefaults.actions();

    final decoded = json.decode(encoded);
    if (decoded is! List) return RecoveryPlanDefaults.actions();
    final actions = decoded
        .whereType<Map>()
        .map((e) => RecoveryAction.fromMap(Map<String, dynamic>.from(e)))
        .whereType<RecoveryAction>()
        .toList();
    return actions;
  }

  Future<void> savePlan(List<RecoveryAction> plan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(planKey, json.encode(plan.map((a) => a.toMap()).toList()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(planKey);
  }
}
