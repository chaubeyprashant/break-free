package app.breakfree.mobile

/**
 * Normalizes domains for custom blocking. Host equality / subdomain only —
 * never loose substring matches against unrelated hosts.
 */
object DomainNormalizer {

    fun normalize(raw: String?): String? {
        var text = raw?.trim()?.lowercase() ?: return null
        if (text.isEmpty()) return null
        text = text.removePrefix("https://").removePrefix("http://")
        text = text.substringBefore('/').substringBefore('?').substringBefore('#')
        if (text.contains('@')) text = text.substringAfterLast('@')
        if (text.contains(':') && !text.contains(']')) {
            text = text.substringBefore(':')
        }
        while (text.startsWith('.')) text = text.drop(1)
        while (text.endsWith('.')) text = text.dropLast(1)
        if (text.startsWith("www.")) text = text.removePrefix("www.")
        if (text.isEmpty() || !text.contains('.') || text.contains(' ')) return null
        return text
    }

    fun hostMatches(host: String, blocked: String): Boolean {
        val h = normalize(host) ?: host.lowercase()
        val b = normalize(blocked) ?: blocked.lowercase()
        return h == b || h.endsWith(".$b")
    }

    fun hostOf(addressBarText: String): String {
        val text = addressBarText.trim().lowercase()
        return text.substringAfter("://", text)
            .substringBefore('/')
            .substringBefore('?')
            .substringBefore('#')
            .removePrefix("www.")
    }
}
