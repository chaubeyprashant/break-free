import 'package:flutter/material.dart';
import 'package:break_free/core/data/danger_window_repository.dart';
import 'package:break_free/core/models/danger_window.dart';
import 'package:break_free/core/models/urge_event.dart';
import 'package:break_free/core/services/protection_reminder_service.dart';

/// Derives the danger window from the urge list it is given and owns the
/// opt-in protection reminder. Nothing is scheduled unless the user enables
/// it; the reminder is dropped again if the pattern disappears.
class DangerWindowProvider extends ChangeNotifier {
  DangerWindowProvider(this._repository, this._scheduler) {
    _load();
  }

  final DangerWindowRepository _repository;
  final ProtectionReminderScheduler _scheduler;

  DangerWindow? _window;
  bool _reminderEnabled = false;
  bool _loaded = false;

  DangerWindow? get window => _window;
  bool get reminderEnabled => _reminderEnabled;

  Future<void> _load() async {
    _reminderEnabled = await _repository.isReminderEnabled();
    _loaded = true;
    await _syncSchedule();
    notifyListeners();
  }

  /// Called whenever the urge list changes (ChangeNotifierProxyProvider).
  Future<void> updateUrges(List<UrgeEvent> urges) async {
    final next = DangerWindowAnalyzer.analyze(urges);
    final changed = next?.startHour != _window?.startHour || next?.count != _window?.count || next?.total != _window?.total;
    _window = next;
    if (changed) {
      await _syncSchedule();
      notifyListeners();
    }
  }

  Future<void> setReminderEnabled(bool enabled) async {
    _reminderEnabled = enabled;
    await _repository.setReminderEnabled(enabled);
    await _syncSchedule();
    notifyListeners();
  }

  Future<void> _syncSchedule() async {
    if (!_loaded) return;
    final window = _window;
    if (_reminderEnabled && window != null) {
      await _scheduler.scheduleFor(window);
    } else {
      await _scheduler.cancel();
    }
  }
}
