import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:break_free/core/data/recovery_plan_repository.dart';
import 'package:break_free/core/models/recovery_action.dart';
import 'package:break_free/core/providers/recovery_plan_provider.dart';

Future<RecoveryPlanProvider> loadedProvider() async {
  final provider = RecoveryPlanProvider(RecoveryPlanRepository());
  await Future<void>.delayed(Duration.zero);
  return provider;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('RecoveryAction', () {
    test('round-trips through its map form', () {
      const action = RecoveryAction(id: 'x', title: 'Call a friend', kind: RecoveryActionKind.contactCompanion, enabled: false, isCustom: true);
      final restored = RecoveryAction.fromMap(action.toMap())!;
      expect(restored.id, 'x');
      expect(restored.title, 'Call a friend');
      expect(restored.kind, RecoveryActionKind.contactCompanion);
      expect(restored.enabled, isFalse);
      expect(restored.isCustom, isTrue);
    });

    test('rejects records without an id or title', () {
      expect(RecoveryAction.fromMap({'title': 'no id'}), isNull);
      expect(RecoveryAction.fromMap({'id': 'a', 'title': '   '}), isNull);
      expect(RecoveryAction.fromMap({'id': 'a', 'title': 'ok', 'kind': 'bogus'})!.kind, RecoveryActionKind.checklist);
    });

    test('defaults cover the example actions', () {
      final titles = RecoveryPlanDefaults.actions().map((a) => a.title.toLowerCase()).join(' | ');
      expect(titles, contains('phone away'));
      expect(titles, contains('walk'));
      expect(titles, contains('water'));
      expect(titles, contains('breathing'));
      expect(titles, contains('urge surfing'));
      expect(titles, contains('companion'));
      expect(RecoveryPlanDefaults.actions().map((a) => a.id).toSet().length, RecoveryPlanDefaults.actions().length);
    });
  });

  group('RecoveryPlanRepository', () {
    test('returns defaults until something is saved', () async {
      final plan = await RecoveryPlanRepository().getPlan();
      expect(plan.map((a) => a.id), RecoveryPlanDefaults.actions().map((a) => a.id));
    });

    test('persists a saved plan across instances', () async {
      await RecoveryPlanRepository().savePlan([const RecoveryAction(id: 'only', title: 'Only step', isCustom: true)]);
      final plan = await RecoveryPlanRepository().getPlan();
      expect(plan.length, 1);
      expect(plan.single.title, 'Only step');
    });
  });

  group('RecoveryPlanProvider', () {
    test('adds custom actions and persists them', () async {
      final provider = await loadedProvider();
      final added = await provider.addCustomAction('  Text my sponsor ');
      expect(added!.title, 'Text my sponsor');
      expect(added.isCustom, isTrue);
      expect(await provider.addCustomAction('   '), isNull);

      final stored = await RecoveryPlanRepository().getPlan();
      expect(stored.last.title, 'Text my sponsor');
    });

    test('disabled actions leave the active list but stay in the plan', () async {
      final provider = await loadedProvider();
      await provider.setEnabled('walk', false);
      expect(provider.activeActions.any((a) => a.id == 'walk'), isFalse);
      expect(provider.plan.any((a) => a.id == 'walk'), isTrue);
      expect((await RecoveryPlanRepository().getPlan()).firstWhere((a) => a.id == 'walk').enabled, isFalse);
    });

    test('reorder moves items like ReorderableListView.onReorderItem reports them', () async {
      final provider = await loadedProvider();
      final ids = provider.plan.map((a) => a.id).toList();

      // onReorderItem already adjusts newIndex after removal (insert at 2, not 3).
      await provider.reorder(0, 2);
      expect(provider.plan.map((a) => a.id).toList(), [ids[1], ids[2], ids[0], ...ids.sublist(3)]);

      await provider.reorder(ids.length - 1, 0); // move last item to the top
      expect(provider.plan.first.id, ids.last);
    });

    test('only custom actions can be removed', () async {
      final provider = await loadedProvider();
      final custom = (await provider.addCustomAction('Custom'))!;
      await provider.remove('walk');
      await provider.remove(custom.id);
      expect(provider.plan.any((a) => a.id == 'walk'), isTrue);
      expect(provider.plan.any((a) => a.id == custom.id), isFalse);
    });

    test('reset restores the defaults', () async {
      final provider = await loadedProvider();
      await provider.addCustomAction('Custom');
      await provider.setEnabled('water', false);
      await provider.resetToDefaults();
      expect(provider.plan.map((a) => a.id), RecoveryPlanDefaults.actions().map((a) => a.id));
      expect(provider.plan.every((a) => a.enabled), isTrue);
    });
  });
}
