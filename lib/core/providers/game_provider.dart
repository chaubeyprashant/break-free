import 'package:flutter/material.dart';
import 'package:break_free/core/data/game_repository.dart';
import 'package:break_free/core/models/user_progress.dart';

class GameProvider extends ChangeNotifier {
  final GameRepository _repository;
  UserProgress _progress = UserProgress();

  GameProvider(this._repository) {
    _loadProgress();
  }

  UserProgress get progress => _progress;

  Future<void> _loadProgress() async {
    _progress = await _repository.getProgress();
    notifyListeners();
  }

  /// Returns true if user leveled up. Optionally add coins (e.g. for check-in).
  Future<bool> addXp(int amount, {int coinBonus = 0}) async {
    final levelBefore = _progress.level;
    _progress.addXp(amount);
    if (coinBonus > 0) _progress.addCoins(coinBonus);
    await _repository.saveProgress(_progress);
    notifyListeners();
    return _progress.level > levelBefore;
  }
}
