import 'package:break_free/core/data/reminder_settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('defaults to off at the 8:00 PM the settings screen advertises', () async {
    final settings = await ReminderSettingsRepository().load();

    expect(settings.enabled, isFalse);
    expect(settings.hour, 20);
    expect(settings.minute, 0);
    expect(settings.label, '8:00 PM');
  });

  test('round-trips the user choice', () async {
    final repository = ReminderSettingsRepository();

    await repository.save(
      const ReminderSettings(enabled: true, hour: 7, minute: 5),
    );

    final loaded = await ReminderSettingsRepository().load();
    expect(loaded.enabled, isTrue);
    expect(loaded.hour, 7);
    expect(loaded.minute, 5);
    expect(loaded.label, '7:05 AM');
  });

  group('label formatting', () {
    test('renders midnight and noon as 12, not 0', () {
      expect(
        const ReminderSettings(enabled: true, hour: 0, minute: 0).label,
        '12:00 AM',
      );
      expect(
        const ReminderSettings(enabled: true, hour: 12, minute: 30).label,
        '12:30 PM',
      );
    });

    test('pads the minutes', () {
      expect(
        const ReminderSettings(enabled: true, hour: 21, minute: 5).label,
        '9:05 PM',
      );
    });
  });
}
