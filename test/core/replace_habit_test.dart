import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:break_free/core/data/activity_repository.dart';
import 'package:break_free/core/models/activity_completion.dart';
import 'package:break_free/core/models/replacement_activity.dart';
import 'package:break_free/core/providers/activity_provider.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('ActivityCatalog', () {
    test('offers the four duration tiers with at least three activities each', () {
      expect(ActivityTier.values.map((t) => t.minutes), [2, 5, 10, 30]);
      for (final tier in ActivityTier.values) {
        expect(ActivityCatalog.forTier(tier).length, greaterThanOrEqualTo(3), reason: tier.label);
      }
    });

    test('covers the example activity types', () {
      final text = ActivityCatalog.all.map((a) => '${a.id} ${a.title}'.toLowerCase()).join(' | ');
      for (final word in ['breath', 'walk', 'stretch', 'read', 'music', 'journal']) {
        expect(text, contains(word), reason: word);
      }
      expect(ActivityCatalog.all.any((a) => a.kind == ActivityKind.miniGame), isTrue, reason: 'mini-game');
    });

    test('ids are unique and resolvable', () {
      final ids = ActivityCatalog.all.map((a) => a.id).toList();
      expect(ids.toSet().length, ids.length);
      expect(ActivityCatalog.byId('walk_5')!.tier, ActivityTier.five);
      expect(ActivityCatalog.byId('nope'), isNull);
    });

    test('xp grows with duration', () {
      final xp = ActivityTier.values.map((t) => t.xpReward).toList();
      for (var i = 1; i < xp.length; i++) {
        expect(xp[i], greaterThan(xp[i - 1]));
      }
    });

    test('prompts spread evenly across the duration', () {
      final walk = ActivityCatalog.byId('walk_5')!; // 5 prompts over 300s -> 60s each
      expect(walk.promptAt(Duration.zero), walk.prompts[0]);
      expect(walk.promptAt(const Duration(seconds: 59)), walk.prompts[0]);
      expect(walk.promptAt(const Duration(seconds: 60)), walk.prompts[1]);
      expect(walk.promptAt(const Duration(seconds: 299)), walk.prompts[4]);
      expect(walk.promptAt(const Duration(seconds: 400)), walk.prompts[4]);
      expect(ActivityCatalog.byId('bubbles_2')!.promptAt(Duration.zero), isNull);
    });
  });

  group('ActivityCompletion persistence', () {
    test('round-trips and rejects broken records', () {
      final c = ActivityCompletion(id: '1', activityId: 'read_10', completedAt: DateTime(2026, 9, 28, 21), tierMinutes: 10, xpAwarded: 15);
      final restored = ActivityCompletion.fromMap(c.toMap())!;
      expect(restored.activityId, 'read_10');
      expect(restored.activity!.title, 'Read ten pages');
      expect(restored.tierMinutes, 10);
      expect(restored.xpAwarded, 15);
      expect(ActivityCompletion.fromMap({'id': 'x'}), isNull);
    });

    test('provider records completions and persists them', () async {
      final provider = ActivityProvider(ActivityRepository());
      await Future<void>.delayed(Duration.zero);

      await provider.recordCompletion(ActivityCatalog.byId('stretch_2')!, xpAwarded: 5);
      await provider.recordCompletion(ActivityCatalog.byId('walk_30')!, xpAwarded: 30);

      expect(provider.completions.length, 2);
      expect(provider.completionsToday, 2);
      expect(provider.totalMinutes, 32);

      final stored = await ActivityRepository().getCompletions();
      expect(stored.map((c) => c.activityId), ['stretch_2', 'walk_30']);
      expect(stored.last.xpAwarded, 30);
    });
  });
}
