package app.breakfree.mobile

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class WebCategoryFilterTest {

    @Test
    fun `custom domain wins before adult`() {
        val match = WebCategoryFilter.findMatch(
            addressBarText = "https://www.blocked.com/x",
            adultEnabled = true,
            gamblingEnabled = false,
            customEnabled = true,
            customDomains = listOf("blocked.com"),
            allowlist = emptyList(),
        )
        assertEquals("custom", match!!.category)
    }

    @Test
    fun `allowlist overrides`() {
        assertNull(
            WebCategoryFilter.findMatch(
                addressBarText = "https://pornhub.com",
                adultEnabled = true,
                gamblingEnabled = false,
                customEnabled = false,
                customDomains = emptyList(),
                allowlist = listOf("pornhub.com"),
            ),
        )
    }

    @Test
    fun `gambling category`() {
        val match = WebCategoryFilter.findMatch(
            addressBarText = "https://draftkings.com",
            adultEnabled = false,
            gamblingEnabled = true,
            customEnabled = false,
            customDomains = emptyList(),
            allowlist = emptyList(),
        )
        assertEquals("gambling", match!!.category)
    }
}
