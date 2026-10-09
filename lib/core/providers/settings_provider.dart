import 'package:flutter/material.dart';
import 'package:break_free/core/data/settings_repository.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._repository) {
    _load();
  }

  final SettingsRepository _repository;

  ThemeMode _themeMode = ThemeMode.system;
  bool _dailyReminders = true;
  bool _protectionReminders = true;
  bool _shareLocation = true;
  bool _loaded = false;
  String? _error;

  ThemeMode get themeMode => _themeMode;
  bool get dailyRemindersEnabled => _dailyReminders;
  bool get protectionRemindersEnabled => _protectionReminders;
  bool get shareLocationWithCompanion => _shareLocation;
  bool get isLoaded => _loaded;
  String? get error => _error;

  Future<void> _load() async {
    try {
      _themeMode = await _repository.getThemeMode();
      _dailyReminders = await _repository.getDailyRemindersEnabled();
      _protectionReminders = await _repository.getProtectionRemindersEnabled();
      _shareLocation = await _repository.getShareLocationWithCompanion();
      _error = null;
    } catch (_) {
      _error = 'Could not load settings.';
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> reload() => _load();

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _repository.setThemeMode(mode);
  }

  Future<void> setDailyRemindersEnabled(bool value) async {
    _dailyReminders = value;
    notifyListeners();
    await _repository.setDailyRemindersEnabled(value);
  }

  Future<void> setProtectionRemindersEnabled(bool value) async {
    _protectionReminders = value;
    notifyListeners();
    await _repository.setProtectionRemindersEnabled(value);
  }

  Future<void> setShareLocationWithCompanion(bool value) async {
    _shareLocation = value;
    notifyListeners();
    await _repository.setShareLocationWithCompanion(value);
  }

  Future<void> clearLocalProgress() => _repository.clearLocalProgress();
}
