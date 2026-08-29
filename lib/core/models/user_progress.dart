import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'user_progress.freezed.dart';
part 'user_progress.g.dart';

@freezed
abstract class UserProgress with _$UserProgress {
  const UserProgress._();

  @HiveType(typeId: 1, adapterName: 'UserProgressAdapter')
  const factory UserProgress({
    @HiveField(0) @Default(0) int xp,
    @HiveField(1) @Default(1) int level,
    @HiveField(2) @Default(0) int coins,
  }) = _UserProgress;

  factory UserProgress.fromJson(Map<String, dynamic> json) =>
      _$UserProgressFromJson(json);

  int get xpToNextLevel => level * 100;

  static const List<String> levelTitles = [
    'Beginner',
    'Rookie',
    'Warrior',
    'Survivor',
    'Champion',
    'Legend',
    'Master',
    'Grandmaster',
    'Phoenix',
    'Hero of Break Free',
  ];

  String get levelTitle =>
      level <= levelTitles.length ? levelTitles[level - 1] : levelTitles.last;

  // With Freezed, we return a new instance instead of mutating
  UserProgress addXp(int amount) {
    int newXp = xp + amount;
    int newLevel = level;
    int newCoins = coins;
    
    int xpRequired = newLevel * 100;
    while (newXp >= xpRequired) {
      newXp -= xpRequired;
      newLevel++;
      newCoins += 10;
      xpRequired = newLevel * 100; // update required xp for next iteration
    }
    
    return copyWith(xp: newXp, level: newLevel, coins: newCoins);
  }

  UserProgress addCoins(int amount) {
    return copyWith(coins: coins + amount);
  }
}
