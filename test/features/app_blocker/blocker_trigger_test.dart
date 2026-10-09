import 'package:flutter_test/flutter_test.dart';
import 'package:break_free/features/app_blocker/data/blocker_trigger.dart';

void main() {
  group('BlockerTrigger.fromMap', () {
    test('parses a blocked-app trigger as sent by MainActivity', () {
      final trigger = BlockerTrigger.fromMap(<Object?, Object?>{
        'id': 1700000000000,
        'type': 'blocked_app',
        'packageName': 'com.instagram.android',
        'appName': 'Instagram',
      });

      expect(trigger, isNotNull);
      expect(trigger!.id, 1700000000000);
      expect(trigger.type, BlockerTriggerType.blockedApp);
      expect(trigger.packageName, 'com.instagram.android');
      expect(trigger.appName, 'Instagram');
      expect(trigger.url, isNull);
    });

    test('parses an adult-content trigger with the address bar text', () {
      final trigger = BlockerTrigger.fromMap(<Object?, Object?>{
        'id': 42,
        'type': 'adult_content',
        'url': 'example.com/xvideos-test',
      });

      expect(trigger!.type, BlockerTriggerType.adultContent);
      expect(trigger.url, 'example.com/xvideos-test');
    });

    test('parses a website_blocked trigger with category', () {
      final trigger = BlockerTrigger.fromMap(<Object?, Object?>{
        'id': 99,
        'type': 'website_blocked',
        'url': 'https://draftkings.com',
        'category': 'gambling',
        'keyword': 'draftkings',
      });

      expect(trigger!.type, BlockerTriggerType.websiteBlocked);
      expect(trigger.category, 'gambling');
      expect(trigger.keyword, 'draftkings');
    });

    test('parses a suspicious-transaction trigger', () {
      final trigger = BlockerTrigger.fromMap(<Object?, Object?>{
        'id': 7,
        'type': 'suspicious_transaction',
        'text': "Detected 'vape' in notification.",
      });

      expect(trigger!.type, BlockerTriggerType.suspiciousTransaction);
      expect(trigger.text, "Detected 'vape' in notification.");
    });

    test('rejects malformed input instead of throwing', () {
      expect(BlockerTrigger.fromMap(null), isNull);
      expect(BlockerTrigger.fromMap('blocked_app'), isNull);
      expect(BlockerTrigger.fromMap(<Object?, Object?>{'type': 'unknown', 'id': 1}), isNull);
      expect(BlockerTrigger.fromMap(<Object?, Object?>{'type': 'blocked_app'}), isNull);
      expect(BlockerTrigger.fromMap(<Object?, Object?>{'type': 'blocked_app', 'id': 'x'}), isNull);
    });
  });

  group('BlockerTriggerDeduplicator', () {
    test('handles a trigger once even when it is pushed and pulled', () {
      final dedup = BlockerTriggerDeduplicator();
      const trigger = BlockerTrigger(id: 10, type: BlockerTriggerType.blockedApp);

      expect(dedup.shouldHandle(trigger), isTrue);
      expect(dedup.shouldHandle(trigger), isFalse);
    });

    test('still handles a new trigger with a different id', () {
      final dedup = BlockerTriggerDeduplicator();

      expect(dedup.shouldHandle(const BlockerTrigger(id: 1, type: BlockerTriggerType.adultContent)), isTrue);
      expect(dedup.shouldHandle(const BlockerTrigger(id: 2, type: BlockerTriggerType.adultContent)), isTrue);
      expect(dedup.shouldHandle(const BlockerTrigger(id: 2, type: BlockerTriggerType.adultContent)), isFalse);
    });
  });
}
