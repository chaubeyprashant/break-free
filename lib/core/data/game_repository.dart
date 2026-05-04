import 'package:shared_preferences/shared_preferences.dart';
import 'package:break_free/core/models/user_progress.dart';

class GameRepository {
  static const String _progressKey = 'user_progress';

  Future<void> saveProgress(UserProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_progressKey, progress.toJson());
  }

  Future<UserProgress> getProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encoded = prefs.getString(_progressKey);
    if (encoded == null) {
      return UserProgress(); // Return default starting state
    }
    return UserProgress.fromJson(encoded);
  }
}
