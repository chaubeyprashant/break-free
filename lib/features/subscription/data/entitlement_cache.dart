import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Short-lived local cache of the last store-verified Premium status.
/// Never permanently unlocks Premium by itself — only used for offline grace.
class EntitlementCache {
  static const String _key = 'entitlement_cache_v1';

  /// After this duration offline, Premium falls back to free until re-verified.
  static const Duration offlineGrace = Duration(days: 3);

  Future<CachedEntitlement?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      return CachedEntitlement.fromMap(json.decode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> write(CachedEntitlement value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, json.encode(value.toMap()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

class CachedEntitlement {
  const CachedEntitlement({
    required this.isPremium,
    required this.verifiedAt,
    this.productId,
  });

  final bool isPremium;
  final DateTime verifiedAt;
  final String? productId;

  bool get isWithinGrace =>
      DateTime.now().difference(verifiedAt) <= EntitlementCache.offlineGrace;

  Map<String, dynamic> toMap() => {
        'isPremium': isPremium,
        'verifiedAt': verifiedAt.toIso8601String(),
        if (productId != null) 'productId': productId,
      };

  factory CachedEntitlement.fromMap(Map<String, dynamic> map) => CachedEntitlement(
        isPremium: map['isPremium'] == true,
        verifiedAt: DateTime.tryParse(map['verifiedAt'] as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
        productId: map['productId'] as String?,
      );
}
