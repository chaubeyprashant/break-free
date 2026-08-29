import 'package:break_free/core/models/user_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserProgress.addXp', () {
    test('accumulates xp without levelling up below the threshold', () {
      const progress = UserProgress();

      final result = progress.addXp(50);

      expect(result.xp, 50);
      expect(result.level, 1);
      expect(result.coins, 0);
    });

    test('levels up and carries the remainder over', () {
      const progress = UserProgress();

      final result = progress.addXp(120);

      expect(result.level, 2);
      expect(result.xp, 20);
      expect(result.coins, 10);
    });

    test('can cross several levels in a single award', () {
      const progress = UserProgress();

      // 100 for level 2, then 200 for level 3, leaving 50 over.
      final result = progress.addXp(350);

      expect(result.level, 3);
      expect(result.xp, 50);
      expect(result.coins, 20);
    });

    test('leaves the original instance untouched', () {
      const progress = UserProgress();

      progress.addXp(500);

      expect(progress.xp, 0);
      expect(progress.level, 1);
    });
  });

  test('levelTitle clamps to the last title beyond the defined levels', () {
    expect(const UserProgress(level: 1).levelTitle, 'Beginner');
    expect(const UserProgress(level: 3).levelTitle, 'Warrior');
    expect(const UserProgress(level: 99).levelTitle, 'Hero of Break Free');
  });
}
