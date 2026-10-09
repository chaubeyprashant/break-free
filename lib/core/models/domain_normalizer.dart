/// Normalizes user-entered domains for custom website blocking.
///
/// Strips scheme, www, path, query, fragment, trailing dots/slashes, and lowercases.
/// Matching uses registrable-host equality or subdomain-of-blocked-host — never
/// substring matches that would catch unrelated domains (e.g. "notexample.com").
class DomainNormalizer {
  DomainNormalizer._();

  static String? normalize(String? raw) {
    if (raw == null) return null;
    var text = raw.trim().toLowerCase();
    if (text.isEmpty) return null;

    text = text.replaceFirst(RegExp(r'^https?://'), '');
    text = text.split('/').first;
    text = text.split('?').first;
    text = text.split('#').first;
    if (text.contains('@')) {
      text = text.split('@').last;
    }
    if (text.contains(':') && !text.contains(']')) {
      // host:port
      text = text.split(':').first;
    }
    while (text.startsWith('.')) {
      text = text.substring(1);
    }
    while (text.endsWith('.')) {
      text = text.substring(0, text.length - 1);
    }
    if (text.startsWith('www.')) {
      text = text.substring(4);
    }
    if (text.isEmpty || !text.contains('.') || text.contains(' ')) {
      return null;
    }
    return text;
  }

  /// True when [host] is exactly [blocked] or a subdomain of it.
  static bool hostMatches(String host, String blocked) {
    final h = normalize(host) ?? host.toLowerCase();
    final b = normalize(blocked) ?? blocked.toLowerCase();
    if (h == b) return true;
    return h.endsWith('.$b');
  }
}
