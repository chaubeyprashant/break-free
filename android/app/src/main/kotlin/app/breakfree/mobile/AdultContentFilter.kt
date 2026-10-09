package app.breakfree.mobile

/**
 * Decides whether the text shown in a browser's address bar points at an adult website.
 *
 * Pure Kotlin with no Android imports so it is covered by JVM unit tests
 * (android/app/src/test). The lists are a starting blocklist of widely known adult sites and
 * terms, not an exhaustive filter, and matching is a plain substring check on the address text.
 */
object AdultContentFilter {

    /**
     * Matched anywhere in the address text (host, path or query). Deliberately excludes short
     * words such as "sex" that appear inside ordinary names (Essex, Sussex, unisex).
     */
    val keywords: List<String> = listOf(
        "porn",
        "hentai",
        "nsfw",
        "onlyfans",
        "fansly",
        "rule34",
        "xvideos",
        "xnxx",
        "xhamster",
        "redtube",
        "spankbang",
        "chaturbate",
        "stripchat",
        "livejasmin",
        "bongacams",
        "brazzers",
        "myfreecams",
        "camsoda",
        "tnaflix",
        "fapello",
        "erome",
        "tube8",
        "sxyprn",
        "thisvid",
    )

    /**
     * Matched only inside the host name. These are too ambiguous to match in paths or search
     * queries ("xxx" shows up in version strings and artist names, for example).
     */
    val hostOnlyKeywords: List<String> = listOf(
        "xxx",
        "cam4",
        "beeg",
        "motherless",
    )

    /** Returns the matched keyword, or null when [addressBarText] looks safe. */
    fun findMatch(addressBarText: String?): String? {
        val text = normalize(addressBarText) ?: return null
        keywords.firstOrNull { text.contains(it) }?.let { return it }
        val host = hostOf(text)
        return hostOnlyKeywords.firstOrNull { host.contains(it) }
    }

    internal fun normalize(text: String?): String? =
        text?.trim()?.lowercase()?.takeIf { it.isNotEmpty() }

    /**
     * Host portion of an address as browsers display it:
     * "https://m.example.com/a?b=c" -> "m.example.com", "example.com?x=1" -> "example.com".
     */
    internal fun hostOf(text: String): String =
        text.substringAfter("://", text)
            .substringBefore('/')
            .substringBefore('?')
            .substringBefore('#')
}
