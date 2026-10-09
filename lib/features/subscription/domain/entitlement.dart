/// Authoritative premium status for the signed-in device.
///
/// [isPremium] is true only when store-backed evidence says so, or when a
/// short offline grace cache still applies after a recent successful verify.
enum EntitlementSource {
  /// Verified from Google Play (or future App Store) in this session.
  store,

  /// Temporary cache used only while offline after a recent store verify.
  offlineCache,

  /// No active entitlement.
  none,
}

enum PurchaseFlowStatus {
  idle,
  loadingProducts,
  ready,
  purchasing,
  processing,
  restoring,
  success,
  cancelled,
  pending,
  failed,
  offline,
  storeUnavailable,
}

class Entitlement {
  const Entitlement({
    required this.isPremium,
    required this.source,
    this.activeProductId,
    this.verifiedAt,
    this.message,
  });

  final bool isPremium;
  final EntitlementSource source;
  final String? activeProductId;
  final DateTime? verifiedAt;
  final String? message;

  static const free = Entitlement(
    isPremium: false,
    source: EntitlementSource.none,
  );

  Entitlement copyWith({
    bool? isPremium,
    EntitlementSource? source,
    String? activeProductId,
    DateTime? verifiedAt,
    String? message,
    bool clearProduct = false,
    bool clearMessage = false,
  }) {
    return Entitlement(
      isPremium: isPremium ?? this.isPremium,
      source: source ?? this.source,
      activeProductId: clearProduct ? null : (activeProductId ?? this.activeProductId),
      verifiedAt: verifiedAt ?? this.verifiedAt,
      message: clearMessage ? null : (message ?? this.message),
    );
  }
}
