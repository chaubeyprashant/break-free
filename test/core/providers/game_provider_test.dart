import 'package:break_free/core/data/game_repository.dart';
import 'package:break_free/core/providers/game_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('addXp applies the award to the held progress and persists it', () async {
    final repository = GameRepository();
    final provider = GameProvider(repository);
    // Let the constructor's initial load finish.
    await Future<void>.delayed(Duration.zero);

    final levelledUp = await provider.addXp(120);

    expect(levelledUp, isTrue);
    expect(provider.progress.level, 2);
    expect(provider.progress.xp, 20);
    expect(provider.progress.coins, 10);

    final persisted = await repository.getProgress();
    expect(persisted.level, 2);
    expect(persisted.xp, 20);
  });

  test('addXp reports no level up when the threshold is not reached', () async {
    final provider = GameProvider(GameRepository());
    await Future<void>.delayed(Duration.zero);

    final levelledUp = await provider.addXp(10, coinBonus: 5);

    expect(levelledUp, isFalse);
    expect(provider.progress.xp, 10);
    expect(provider.progress.coins, 5);
  });
}
