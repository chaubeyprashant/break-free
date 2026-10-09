import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:break_free/core/data/cloud_backup_repository.dart';
import 'package:break_free/features/app_blocker/data/app_blocker_repository.dart';
import 'package:break_free/core/providers/check_in_provider.dart';
import 'package:break_free/core/providers/game_provider.dart';
import 'package:break_free/core/providers/habit_provider.dart';
import 'package:break_free/core/providers/journal_provider.dart';
import 'package:break_free/core/providers/protection_provider.dart';
import 'package:break_free/core/providers/recovery_plan_provider.dart';
import 'package:break_free/core/providers/settings_provider.dart';
import 'package:break_free/core/providers/streak_policy_provider.dart';
import 'package:break_free/core/providers/urge_provider.dart';
import 'package:break_free/core/providers/activity_provider.dart';
import 'package:break_free/core/providers/achievement_provider.dart';
import 'package:break_free/core/providers/daily_quest_provider.dart';

enum CloudBackupStatus { idle, loading, backingUp, restoring, success, error }

/// Backs up local progress to Firestore so reinstall / new device can restore it.
class CloudBackupProvider extends ChangeNotifier {
  CloudBackupProvider({CloudBackupRepository? repository})
      : _repository = repository ?? CloudBackupRepository() {
    _bootstrap();
  }

  final CloudBackupRepository _repository;

  CloudBackupStatus _status = CloudBackupStatus.idle;
  String? _message;
  CloudBackupMeta? _meta;
  bool _autoBackup = true;
  bool _signedIn = false;

  CloudBackupStatus get status => _status;
  String? get message => _message;
  CloudBackupMeta? get meta => _meta;
  bool get autoBackupEnabled => _autoBackup;
  bool get isSignedIn => _signedIn;
  bool get hasCloudBackup => _meta != null;

  Future<void> _bootstrap() async {
    _autoBackup = await _repository.getAutoBackupEnabled();
    _signedIn = _repository.currentUserId != null;
    if (_signedIn) {
      await refreshMeta();
    }
    notifyListeners();
  }

  /// Call after auth state changes.
  Future<void> onAuthChanged({required bool signedIn}) async {
    _signedIn = signedIn;
    if (!signedIn) {
      _meta = null;
      _status = CloudBackupStatus.idle;
      _message = null;
      notifyListeners();
      return;
    }
    await refreshMeta();
  }

  Future<void> refreshMeta() async {
    if (_repository.currentUserId == null) {
      _signedIn = false;
      _meta = null;
      notifyListeners();
      return;
    }
    _signedIn = true;
    _status = CloudBackupStatus.loading;
    notifyListeners();
    try {
      _meta = await _repository.fetchMeta();
      _status = CloudBackupStatus.idle;
      _message = null;
    } catch (e) {
      debugPrint('Cloud backup meta failed: $e');
      _status = CloudBackupStatus.error;
      _message = 'Could not reach cloud backup.';
    }
    notifyListeners();
  }

  Future<void> setAutoBackupEnabled(bool value) async {
    _autoBackup = value;
    await _repository.setAutoBackupEnabled(value);
    notifyListeners();
  }

  Future<bool> backupNow({bool silent = false}) async {
    if (_repository.currentUserId == null) {
      _status = CloudBackupStatus.error;
      _message = 'Sign in to back up your progress.';
      notifyListeners();
      return false;
    }
    if (!silent) {
      _status = CloudBackupStatus.backingUp;
      _message = 'Uploading progress…';
      notifyListeners();
    }
    try {
      final keys = await _repository.collectLocalPayload();
      await _repository.uploadBackup(keys);
      _meta = await _repository.fetchMeta();
      _status = CloudBackupStatus.success;
      _message = silent ? null : 'Backup saved to your account.';
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Cloud backup failed: $e');
      _status = CloudBackupStatus.error;
      _message = 'Backup failed. Check your connection and try again.';
      notifyListeners();
      return false;
    }
  }

  /// Quiet backup used when the app backgrounds (if auto-backup is on).
  Future<void> maybeAutoBackup() async {
    if (!_autoBackup || _repository.currentUserId == null) return;
    if (_status == CloudBackupStatus.backingUp || _status == CloudBackupStatus.restoring) {
      return;
    }
    await backupNow(silent: true);
  }

  Future<bool> restoreNow({
    required HabitProvider habits,
    required GameProvider game,
    required UrgeProvider urges,
    required JournalProvider journal,
    required CheckInProvider checkIns,
    required SettingsProvider settings,
    required ProtectionProvider protection,
    required RecoveryPlanProvider recoveryPlan,
    required StreakPolicyProvider streakPolicy,
    required ActivityProvider activities,
    required AchievementProvider achievements,
    required DailyQuestProvider quests,
  }) async {
    if (_repository.currentUserId == null) {
      _status = CloudBackupStatus.error;
      _message = 'Sign in to restore your progress.';
      notifyListeners();
      return false;
    }
    _status = CloudBackupStatus.restoring;
    _message = 'Restoring from cloud…';
    notifyListeners();
    try {
      final keys = await _repository.downloadBackup();
      if (keys == null || keys.isEmpty) {
        _status = CloudBackupStatus.error;
        _message = 'No cloud backup found for this account.';
        notifyListeners();
        return false;
      }
      final applied = await _repository.applyPayload(keys);
      await Future.wait([
        habits.reloadFromDisk(),
        game.reloadFromDisk(),
        urges.reloadFromDisk(),
        journal.reload(),
        checkIns.reloadFromDisk(),
        settings.reload(),
        protection.reload(),
        recoveryPlan.reloadFromDisk(),
        streakPolicy.refresh(),
        activities.reloadFromDisk(),
        achievements.reloadFromDisk(),
        quests.reloadFromDisk(),
        appBlockerRepository.reloadFromDisk(),
      ]);
      _meta = await _repository.fetchMeta();
      _status = CloudBackupStatus.success;
      _message = 'Restored $applied items from cloud.';
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Cloud restore failed: $e');
      _status = CloudBackupStatus.error;
      _message = 'Restore failed. Check your connection and try again.';
      notifyListeners();
      return false;
    }
  }

  void acknowledge() {
    if (_status == CloudBackupStatus.success || _status == CloudBackupStatus.error) {
      _status = CloudBackupStatus.idle;
      _message = null;
      notifyListeners();
    }
  }
}
