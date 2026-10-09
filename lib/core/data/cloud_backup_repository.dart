import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:break_free/core/data/settings_repository.dart';

/// Metadata for the latest cloud snapshot (no payload).
class CloudBackupMeta {
  const CloudBackupMeta({
    required this.updatedAt,
    required this.keyCount,
    required this.schemaVersion,
  });

  final DateTime updatedAt;
  final int keyCount;
  final int schemaVersion;
}

/// Firebase backup of on-device SharedPreferences progress.
///
/// Path: `users/{uid}/backup/snapshot`
/// Only the signed-in user can read/write their own doc (enforce in Firestore rules).
class CloudBackupRepository {
  CloudBackupRepository({
    FirebaseFirestore? db,
    FirebaseAuth? auth,
  })  : _dbOverride = db,
        _authOverride = auth;

  static const int schemaVersion = 1;
  static const String _docId = 'snapshot';
  static const String autoBackupKey = 'cloud_backup_auto_enabled';

  final FirebaseFirestore? _dbOverride;
  final FirebaseAuth? _authOverride;

  FirebaseFirestore get _db => _dbOverride ?? FirebaseFirestore.instance;
  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;

  String? get currentUserId {
    try {
      return _auth.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  DocumentReference<Map<String, dynamic>>? _snapshotRef() {
    final uid = currentUserId;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).collection('backup').doc(_docId);
  }

  /// Keys eligible for cloud backup (same set as local progress wipe).
  static List<String> get backupKeys => SettingsRepository.localProgressKeys;

  Future<bool> getAutoBackupEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(autoBackupKey) ?? true;
  }

  Future<void> setAutoBackupEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(autoBackupKey, value);
  }

  Future<CloudBackupMeta?> fetchMeta() async {
    final ref = _snapshotRef();
    if (ref == null) return null;
    final snap = await ref.get();
    if (!snap.exists) return null;
    final data = snap.data();
    if (data == null) return null;
    final ts = data['updatedAt'];
    DateTime updated;
    if (ts is Timestamp) {
      updated = ts.toDate();
    } else {
      updated = DateTime.tryParse('$ts') ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    final keys = data['keys'];
    final count = keys is Map ? keys.length : (data['keyCount'] as num?)?.toInt() ?? 0;
    return CloudBackupMeta(
      updatedAt: updated,
      keyCount: count,
      schemaVersion: (data['schemaVersion'] as num?)?.toInt() ?? 1,
    );
  }

  /// Collect local prefs into a Firestore-friendly map.
  Future<Map<String, dynamic>> collectLocalPayload() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = <String, dynamic>{};
    for (final key in backupKeys) {
      if (!prefs.containsKey(key)) continue;
      final value = prefs.get(key);
      if (value is String) {
        keys[key] = {'t': 's', 'v': value};
      } else if (value is bool) {
        keys[key] = {'t': 'b', 'v': value};
      } else if (value is int) {
        keys[key] = {'t': 'i', 'v': value};
      } else if (value is double) {
        keys[key] = {'t': 'd', 'v': value};
      } else if (value is List<String>) {
        keys[key] = {'t': 'ls', 'v': value};
      }
    }
    return keys;
  }

  Future<void> uploadBackup(Map<String, dynamic> keys) async {
    final ref = _snapshotRef();
    if (ref == null) {
      throw StateError('Sign in to back up your progress.');
    }
    await ref.set({
      'schemaVersion': schemaVersion,
      'updatedAt': FieldValue.serverTimestamp(),
      'keyCount': keys.length,
      'keys': keys,
      'platform': 'android',
    });
  }

  Future<Map<String, dynamic>?> downloadBackup() async {
    final ref = _snapshotRef();
    if (ref == null) {
      throw StateError('Sign in to restore your progress.');
    }
    final snap = await ref.get();
    if (!snap.exists) return null;
    final data = snap.data();
    final keys = data?['keys'];
    if (keys is Map<String, dynamic>) return keys;
    if (keys is Map) {
      return keys.map((k, v) => MapEntry(k.toString(), v));
    }
    return null;
  }

  /// Apply a downloaded payload to SharedPreferences (overwrites matching keys).
  Future<int> applyPayload(Map<String, dynamic> keys) async {
    final prefs = await SharedPreferences.getInstance();
    var applied = 0;
    for (final entry in keys.entries) {
      final key = entry.key;
      if (!backupKeys.contains(key)) continue;
      final raw = entry.value;
      if (raw is! Map) continue;
      final type = raw['t']?.toString();
      final value = raw['v'];
      switch (type) {
        case 's':
          if (value is String) {
            await prefs.setString(key, value);
            applied++;
          }
        case 'b':
          if (value is bool) {
            await prefs.setBool(key, value);
            applied++;
          }
        case 'i':
          if (value is num) {
            await prefs.setInt(key, value.toInt());
            applied++;
          }
        case 'd':
          if (value is num) {
            await prefs.setDouble(key, value.toDouble());
            applied++;
          }
        case 'ls':
          if (value is List) {
            await prefs.setStringList(key, value.map((e) => e.toString()).toList());
            applied++;
          }
      }
    }
    return applied;
  }
}
