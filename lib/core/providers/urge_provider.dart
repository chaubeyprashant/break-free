import 'package:flutter/material.dart';
import 'package:break_free/core/data/urge_repository.dart';
import 'package:break_free/core/models/urge_event.dart';
import 'package:break_free/core/models/urge_intervention.dart';

class UrgeProvider extends ChangeNotifier {
  final UrgeRepository _repository;
  List<UrgeEvent> _urges = [];

  UrgeProvider(this._repository) {
    _load();
  }

  /// Oldest first.
  List<UrgeEvent> get urges => List.unmodifiable(_urges);

  int get urgesToday {
    final now = DateTime.now();
    return _urges.where((u) =>
        u.timestamp.year == now.year && u.timestamp.month == now.month && u.timestamp.day == now.day).length;
  }

  Future<void> reloadFromDisk() => _load();

  Future<void> _load() async {
    _urges = await _repository.getUrges();
    notifyListeners();
  }

  /// Records a completed urge flow and returns the stored event.
  Future<UrgeEvent> logUrge({required int intensity, required UrgeTrigger trigger}) async {
    final event = UrgeEvent(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      intensity: intensity,
      trigger: trigger,
    );
    await _repository.addUrge(event);
    _urges = [..._urges, event];
    notifyListeners();
    return event;
  }

  UrgeEvent? byId(String id) {
    for (final u in _urges) {
      if (u.id == id) return u;
    }
    return null;
  }

  /// Records which intervention the user completed for [urgeId] and marks the
  /// urge handled. Returns null if the urge is unknown. XP is awarded by the
  /// caller through GameProvider so there is a single reward path.
  Future<UrgeEvent?> markHandled(String urgeId, UrgeIntervention intervention) async {
    final index = _urges.indexWhere((u) => u.id == urgeId);
    if (index == -1) return null;
    final updated = _urges[index].copyWith(
      intervention: intervention,
      handledAt: DateTime.now(),
      outcome: UrgeOutcome.rodeItOut,
    );
    await _repository.updateUrge(updated);
    _urges = [..._urges]..[index] = updated;
    notifyListeners();
    return updated;
  }

  /// Records that [intervention] was started for [urgeId] but abandoned.
  /// Never downgrades an urge that was already handled.
  Future<UrgeEvent?> markStoppedEarly(String urgeId, UrgeIntervention intervention) async {
    final index = _urges.indexWhere((u) => u.id == urgeId);
    if (index == -1) return null;
    final current = _urges[index];
    if (current.isHandled) return current;
    final updated = current.copyWith(intervention: intervention, outcome: UrgeOutcome.stoppedEarly);
    await _repository.updateUrge(updated);
    _urges = [..._urges]..[index] = updated;
    notifyListeners();
    return updated;
  }
}
