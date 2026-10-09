import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:break_free/core/data/cloud_backup_repository.dart';
import 'package:break_free/core/data/settings_repository.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('collectLocalPayload captures string and bool progress keys', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('habits_data', '[{"id":"1"}]');
    await prefs.setBool('danger_window_reminder_enabled', true);
    await prefs.setString('unrelated_key', 'skip');

    final repo = CloudBackupRepository();
    final payload = await repo.collectLocalPayload();

    expect(payload['habits_data'], {'t': 's', 'v': '[{"id":"1"}]'});
    expect(payload['danger_window_reminder_enabled'], {'t': 'b', 'v': true});
    expect(payload.containsKey('unrelated_key'), isFalse);
    expect(CloudBackupRepository.backupKeys, SettingsRepository.localProgressKeys);
  });

  test('applyPayload restores typed keys', () async {
    final repo = CloudBackupRepository();
    final applied = await repo.applyPayload({
      'habits_data': {'t': 's', 'v': '[{"id":"x"}]'},
      'danger_window_reminder_enabled': {'t': 'b', 'v': false},
      'blocked_apps_list': {'t': 'ls', 'v': ['com.example.app']},
      'not_a_backup_key': {'t': 's', 'v': 'nope'},
    });

    expect(applied, 3);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('habits_data'), '[{"id":"x"}]');
    expect(prefs.getBool('danger_window_reminder_enabled'), isFalse);
    expect(prefs.getStringList('blocked_apps_list'), ['com.example.app']);
    expect(prefs.getString('not_a_backup_key'), isNull);
  });
}
