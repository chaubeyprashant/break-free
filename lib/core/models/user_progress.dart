import 'dart:convert';

class UserProgress {
  int xp;
  int level;
  int coins;
  // TODO: Add avatar customization fields later

  UserProgress({this.xp = 0, this.level = 1, this.coins = 0});

  // Simple leveling logic: Level * 100 XP required for next level
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

  String get levelTitle => level <= levelTitles.length ? levelTitles[level - 1] : levelTitles.last;

  void addXp(int amount) {
    xp += amount;
    while (xp >= xpToNextLevel) {
      xp -= xpToNextLevel;
      level++;
      coins += 10;
    }
  }

  void addCoins(int amount) {
    coins += amount;
  }

  Map<String, dynamic> toMap() {
    return {'xp': xp, 'level': level, 'coins': coins};
  }

  factory UserProgress.fromMap(Map<String, dynamic> map) {
    return UserProgress(
      xp: map['xp'] ?? 0,
      level: map['level'] ?? 1,
      coins: map['coins'] ?? 0,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserProgress.fromJson(String source) =>
      UserProgress.fromMap(json.decode(source));
}
