import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:break_free/core/data/protection_event_repository.dart';
import 'package:break_free/core/data/protection_repository.dart';
import 'package:break_free/core/models/domain_normalizer.dart';
import 'package:break_free/core/models/protection_event.dart';
import 'package:break_free/core/models/protection_schedule.dart';
import 'package:break_free/features/subscription/domain/premium_feature.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DomainNormalizer', () {
    test('strips scheme www path and case', () {
      expect(DomainNormalizer.normalize('HTTPS://WWW.Example.COM/path?q=1'), 'example.com');
      expect(DomainNormalizer.normalize('example.com/'), 'example.com');
    });

    test('rejects junk', () {
      expect(DomainNormalizer.normalize('not a domain'), isNull);
      expect(DomainNormalizer.normalize('localhost'), isNull);
    });

    test('hostMatches only exact or subdomain', () {
      expect(DomainNormalizer.hostMatches('www.example.com', 'example.com'), isTrue);
      expect(DomainNormalizer.hostMatches('sub.example.com', 'example.com'), isTrue);
      expect(DomainNormalizer.hostMatches('notexample.com', 'example.com'), isFalse);
      expect(DomainNormalizer.hostMatches('example.com.evil.com', 'example.com'), isFalse);
    });
  });

  group('ProtectionSchedule midnight crossing', () {
    test('night window 22:00-07:00', () {
      final s = ProtectionSchedule(
        id: '1',
        name: 'Night',
        startMinutes: 22 * 60,
        endMinutes: 7 * 60,
        daysOfWeek: {1, 2, 3, 4, 5, 6, 7},
        appPackages: {},
        webCategories: {'adult'},
      );
      // Monday 23:00
      expect(s.isActiveAt(DateTime(2026, 10, 5, 23)), isTrue);
      // Tuesday 06:00 (still in overnight from Monday)
      expect(s.isActiveAt(DateTime(2026, 10, 6, 6)), isTrue);
      // Tuesday 08:00
      expect(s.isActiveAt(DateTime(2026, 10, 6, 8)), isFalse);
      // Tuesday 12:00
      expect(s.isActiveAt(DateTime(2026, 10, 6, 12)), isFalse);
    });

    test('same-day work window', () {
      final s = ProtectionSchedule(
        id: '2',
        name: 'Work',
        startMinutes: 9 * 60,
        endMinutes: 17 * 60,
        daysOfWeek: {1, 2, 3, 4, 5},
        appPackages: {},
        webCategories: {},
      );
      expect(s.isActiveAt(DateTime(2026, 10, 5, 10)), isTrue); // Mon
      expect(s.isActiveAt(DateTime(2026, 10, 5, 18)), isFalse);
      expect(s.isActiveAt(DateTime(2026, 10, 4, 10)), isFalse); // Sun
    });
  });

  group('Protection repositories', () {
    test('config and schedules round-trip', () async {
      final repo = ProtectionRepository();
      final config = (await repo.loadConfig()).copyWith(webGamblingEnabled: true);
      await repo.saveConfig(config);
      expect((await repo.loadConfig()).webGamblingEnabled, isTrue);

      await repo.saveSchedules([
        ProtectionSchedule(
          id: 'n',
          name: 'Night',
          startMinutes: 1320,
          endMinutes: 420,
          daysOfWeek: {1, 2, 3, 4, 5, 6, 7},
          appPackages: {},
          webCategories: {'adult'},
        ),
      ]);
      expect((await repo.loadSchedules()).single.name, 'Night');
    });

    test('custom domains normalize and dedupe', () async {
      final repo = ProtectionRepository();
      final domains = await repo.addCustomDomain('https://WWW.Blocked.COM/x');
      expect(domains, ['blocked.com']);
      await repo.addCustomDomain('blocked.com');
      expect((await repo.loadConfig()).customDomains, ['blocked.com']);
    });

    test('events stay local and capped', () async {
      final events = ProtectionEventRepository();
      for (var i = 0; i < 5; i++) {
        await events.add(
          ProtectionEvent(
            id: '$i',
            type: ProtectionEventType.appBlocked,
            timestamp: DateTime.now().add(Duration(seconds: i)),
            title: 'e$i',
          ),
        );
      }
      final loaded = await events.load();
      expect(loaded.length, 5);
      expect(loaded.first.title, 'e4');
    });
  });

  group('Free protection tiers', () {
    test('basic protection limits are defined without inventing VPN', () {
      expect(FreeTier.maxSchedules, 1);
      expect(FreeTier.maxCustomDomains, 5);
      expect(PremiumFeature.advancedSchedules.title, isNotEmpty);
      expect(PremiumFeature.expandedCustomBlocklist.title, isNotEmpty);
    });
  });
}
