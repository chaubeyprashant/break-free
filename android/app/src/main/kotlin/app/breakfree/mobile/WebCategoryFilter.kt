package app.breakfree.mobile

/**
 * Category-aware website filter for supported-browser address bars.
 * Adult list reuses [AdultContentFilter]; gambling and custom domains are additive.
 */
object WebCategoryFilter {

    data class Match(val category: String, val keyword: String)

    val gamblingKeywords: List<String> = listOf(
        "draftkings",
        "fanduel",
        "betmgm",
        "bet365",
        "williamhill",
        "pokerstars",
        "casino.com",
        "stake.com",
        "roulette",
        "sportsbook",
    )

    fun findMatch(
        addressBarText: String?,
        adultEnabled: Boolean,
        gamblingEnabled: Boolean,
        customEnabled: Boolean,
        customDomains: Collection<String>,
        allowlist: Collection<String>,
    ): Match? {
        val text = AdultContentFilter.normalize(addressBarText) ?: return null
        val host = DomainNormalizer.hostOf(text)

        for (allowed in allowlist) {
            if (DomainNormalizer.hostMatches(host, allowed)) return null
        }

        if (customEnabled) {
            for (domain in customDomains) {
                if (DomainNormalizer.hostMatches(host, domain)) {
                    return Match("custom", domain)
                }
            }
        }

        if (adultEnabled) {
            AdultContentFilter.findMatch(text)?.let { return Match("adult", it) }
        }

        if (gamblingEnabled) {
            gamblingKeywords.firstOrNull { text.contains(it) }?.let {
                return Match("gambling", it)
            }
        }

        return null
    }
}
