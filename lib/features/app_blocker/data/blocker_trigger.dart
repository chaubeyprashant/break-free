/// Trigger events sent by the native side (MainActivity) when one of the
/// on-device detectors fires.
enum BlockerTriggerType {
  /// The accessibility service saw the user open an app they chose to block.
  blockedApp,

  /// The accessibility service read an adult website in a supported browser.
  adultContent,

  /// Category/custom website blocked in a supported browser.
  websiteBlocked,

  /// The notification scanner matched a keyword in a notification.
  suspiciousTransaction,
}

class BlockerTrigger {
  const BlockerTrigger({
    required this.id,
    required this.type,
    this.packageName,
    this.appName,
    this.url,
    this.text,
    this.category,
    this.keyword,
  });

  /// Assigned natively per event so the same trigger can be recognised when it
  /// arrives twice (once pushed, once pulled on a cold start).
  final int id;
  final BlockerTriggerType type;
  final String? packageName;
  final String? appName;
  final String? url;
  final String? text;
  final String? category;
  final String? keyword;

  /// Parses the map built by MainActivity.parseTrigger. Returns null for
  /// anything that is not a well-formed trigger.
  static BlockerTrigger? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final type = switch (raw['type']) {
      'blocked_app' => BlockerTriggerType.blockedApp,
      'adult_content' => BlockerTriggerType.adultContent,
      'website_blocked' => BlockerTriggerType.websiteBlocked,
      'suspicious_transaction' => BlockerTriggerType.suspiciousTransaction,
      _ => null,
    };
    final id = raw['id'];
    if (type == null || id is! int) return null;
    return BlockerTrigger(
      id: id,
      type: type,
      packageName: raw['packageName'] as String?,
      appName: raw['appName'] as String?,
      url: raw['url'] as String?,
      text: raw['text'] as String?,
      category: raw['category'] as String?,
      keyword: raw['keyword'] as String?,
    );
  }
}

/// Remembers the last handled trigger so an event is not acted on twice when
/// it is both pushed over the channel and pulled with `getPendingTrigger`.
class BlockerTriggerDeduplicator {
  int? _lastHandledId;

  /// Returns true the first time a trigger id is seen and false afterwards.
  bool shouldHandle(BlockerTrigger trigger) {
    if (trigger.id == _lastHandledId) return false;
    _lastHandledId = trigger.id;
    return true;
  }
}
