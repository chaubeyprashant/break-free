import 'package:flutter/material.dart';
import 'package:break_free/core/data/recovery_plan_repository.dart';
import 'package:break_free/core/models/recovery_action.dart';

class RecoveryPlanProvider extends ChangeNotifier {
  RecoveryPlanProvider(this._repository) {
    _load();
  }

  final RecoveryPlanRepository _repository;
  List<RecoveryAction> _plan = RecoveryPlanDefaults.actions();
  bool _loaded = false;

  /// Full plan in the user's order, including disabled actions.
  List<RecoveryAction> get plan => List.unmodifiable(_plan);

  /// What the help screen shows.
  List<RecoveryAction> get activeActions => _plan.where((a) => a.enabled).toList();

  bool get isLoaded => _loaded;

  Future<void> reloadFromDisk() => _load();

  Future<void> _load() async {
    _plan = await _repository.getPlan();
    _loaded = true;
    notifyListeners();
  }

  Future<void> _commit(List<RecoveryAction> next) async {
    _plan = next;
    await _repository.savePlan(next);
    notifyListeners();
  }

  Future<RecoveryAction?> addCustomAction(String title) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return null;
    final action = RecoveryAction(
      id: 'custom_${DateTime.now().microsecondsSinceEpoch}',
      title: trimmed,
      isCustom: true,
    );
    await _commit([..._plan, action]);
    return action;
  }

  Future<void> setEnabled(String id, bool enabled) async {
    await _commit([for (final a in _plan) a.id == id ? a.copyWith(enabled: enabled) : a]);
  }

  Future<void> rename(String id, String title) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;
    await _commit([for (final a in _plan) a.id == id ? a.copyWith(title: trimmed) : a]);
  }

  /// Removes a custom action. Built-in actions are kept (disable them instead).
  Future<void> remove(String id) async {
    await _commit(_plan.where((a) => a.id != id || !a.isCustom).toList());
  }

  /// Expects indexes from [ReorderableListView.onReorderItem] (already adjusted).
  Future<void> reorder(int oldIndex, int newIndex) async {
    if (oldIndex < 0 || oldIndex >= _plan.length) return;
    final next = [..._plan];
    final item = next.removeAt(oldIndex);
    next.insert(newIndex.clamp(0, next.length), item);
    await _commit(next);
  }

  Future<void> resetToDefaults() async {
    await _repository.clear();
    await _commit(RecoveryPlanDefaults.actions());
  }
}
