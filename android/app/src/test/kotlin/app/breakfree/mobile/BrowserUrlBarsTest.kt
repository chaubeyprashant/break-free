package app.breakfree.mobile

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class BrowserUrlBarsTest {

    @Test
    fun `chrome and samsung internet are supported`() {
        assertEquals("com.android.chrome:id/url_bar", BrowserUrlBars.addressBarViewId("com.android.chrome"))
        assertEquals(
            "com.sec.android.app.sbrowser:id/location_bar_edit_text",
            BrowserUrlBars.addressBarViewId("com.sec.android.app.sbrowser"),
        )
        assertTrue(BrowserUrlBars.isSupported("org.mozilla.firefox"))
    }

    @Test
    fun `unknown packages are not supported`() {
        assertNull(BrowserUrlBars.addressBarViewId("com.example.notabrowser"))
        assertFalse(BrowserUrlBars.isSupported(null))
        assertFalse(BrowserUrlBars.isSupported("app.breakfree.mobile"))
    }

    @Test
    fun `every address bar id belongs to its own package`() {
        for (browser in BrowserUrlBars.supported) {
            assertTrue(
                "${browser.displayName}: ${browser.addressBarViewId}",
                browser.addressBarViewId.startsWith("${browser.packageName}:id/"),
            )
        }
    }

    @Test
    fun `display names are unique and match the table`() {
        val names = BrowserUrlBars.displayNames()
        assertEquals(names.size, names.toSet().size)
        assertEquals(BrowserUrlBars.supported.size, names.size)
        assertTrue(names.contains("Chrome"))
    }

    @Test
    fun `package names are unique`() {
        val packages = BrowserUrlBars.supported.map { it.packageName }
        assertEquals(packages.size, packages.toSet().size)
    }
}
