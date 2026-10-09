package app.breakfree.mobile

/**
 * Category-aware notification keyword matching with word-boundary-ish checks
 * to reduce false positives (e.g. "bar" inside "Barbara").
 */
object NotificationKeywordMatcher {

    data class Match(val category: String, val keyword: String)

    private val categories: Map<String, List<String>> = mapOf(
        "smoking" to listOf("smoke", "tobacco", "vape", "cigarette", "cigar", "nicotine"),
        "alcohol" to listOf("liquor", "alcohol", "beer", "wine", "vodka", "whiskey", "whisky"),
        "junk_food" to listOf(
            "mcdonalds", "mcdonald's", "burger king", "kfc", "wendys", "wendy's",
            "dominos", "domino's", "taco bell", "krispy", "fast food",
        ),
        "gambling" to listOf(
            "draftkings", "betmgm", "fanduel", "casino", "sportsbook", "betting odds",
        ),
        "shopping" to listOf("amazon order", "temu", "shein", "aliexpress", "your order from"),
    )

    fun findMatch(title: String, text: String, enabledCategories: Set<String>): Match? {
        val full = "$title $text".lowercase()
        // Skip empty / pure OTP-style noise.
        if (full.trim().length < 4) return null
        // Ignore common banking OTP phrasing without purchase intent.
        if (full.contains("otp") || full.contains("one-time") || full.contains("verification code")) {
            return null
        }

        for (category in enabledCategories) {
            val keywords = categories[category] ?: continue
            for (keyword in keywords) {
                if (containsPhrase(full, keyword)) {
                    return Match(category, keyword)
                }
            }
        }
        return null
    }

    /** Phrase match that avoids matching short tokens inside longer words. */
    internal fun containsPhrase(haystack: String, phrase: String): Boolean {
        val p = phrase.lowercase()
        if (p.contains(' ')) return haystack.contains(p)
        val idx = haystack.indexOf(p)
        if (idx < 0) return false
        val before = if (idx == 0) ' ' else haystack[idx - 1]
        val afterIdx = idx + p.length
        val after = if (afterIdx >= haystack.length) ' ' else haystack[afterIdx]
        return !before.isLetterOrDigit() && !after.isLetterOrDigit()
    }
}
