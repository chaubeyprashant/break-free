import 'package:shared_preferences/shared_preferences.dart';
import 'package:break_free/core/models/achievement.dart';

class AchievementRepository {
  static const String unlockedKey = 'achievements_unlocked';

  Future<List<UnlockedAchievement>> getUnlocked() async {
    final prefs = await SharedPreferences.getInstance();
    return UnlockedAchievement.decodeList(prefs.getString(unlockedKey));
  }

  Future<void> saveUnlocked(List<UnlockedAchievement> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(unlockedKey, UnlockedAchievement.encodeList(list));
  }
}
