import 'package:shared_preferences/shared_preferences.dart';
import 'package:mukti/core/models/streak_policy.dart';

class StreakPolicyRepository {
  static const String _key = 'streak_policy';

  Future<void> save(StreakPolicy policy) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, policy.toJson());
  }

  Future<StreakPolicy> get() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_key);
    if (s == null) return StreakPolicy();
    return StreakPolicy.fromJson(s);
  }
}
