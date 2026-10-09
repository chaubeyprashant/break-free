package app.breakfree.mobile

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class AdultContentFilterTest {

    @Test
    fun `matches well known adult domains anywhere in the address`() {
        assertEquals("porn", AdultContentFilter.findMatch("pornhub.com"))
        assertEquals("xvideos", AdultContentFilter.findMatch("https://www.xvideos.com/video123/title"))
        assertEquals("xhamster", AdultContentFilter.findMatch("m.xhamster.com"))
        assertEquals("onlyfans", AdultContentFilter.findMatch("onlyfans.com/someone"))
    }

    @Test
    fun `matching ignores case and surrounding whitespace`() {
        assertEquals("porn", AdultContentFilter.findMatch("  PornHub.COM  "))
        assertEquals("hentai", AdultContentFilter.findMatch("NHENTAI.NET/g/1"))
    }

    @Test
    fun `matches a keyword typed into the address bar before navigating`() {
        assertEquals("xnxx", AdultContentFilter.findMatch("xnxx"))
    }

    @Test
    fun `host only keywords match in the host but not in paths or queries`() {
        assertEquals("xxx", AdultContentFilter.findMatch("xxx.com/videos"))
        assertEquals("beeg", AdultContentFilter.findMatch("https://beeg.com"))
        assertNull(AdultContentFilter.findMatch("example.com/release/v1.xxx"))
        assertNull(AdultContentFilter.findMatch("example.com/search?q=xxx"))
        assertNull(AdultContentFilter.findMatch("news.example.com/motherless-children-charity"))
    }

    @Test
    fun `everyday addresses and browser placeholder text are not flagged`() {
        assertNull(AdultContentFilter.findMatch("Search or type URL"))
        assertNull(AdultContentFilter.findMatch("https://www.sussex.ac.uk"))
        assertNull(AdultContentFilter.findMatch("essex.gov.uk/services"))
        assertNull(AdultContentFilter.findMatch("github.com/flutter/flutter"))
        assertNull(AdultContentFilter.findMatch("https://en.wikipedia.org/wiki/Unisex"))
    }

    @Test
    fun `blank input is never flagged`() {
        assertNull(AdultContentFilter.findMatch(null))
        assertNull(AdultContentFilter.findMatch(""))
        assertNull(AdultContentFilter.findMatch("   "))
    }

    @Test
    fun `hostOf strips scheme path query and fragment`() {
        assertEquals("m.example.com", AdultContentFilter.hostOf("https://m.example.com/a?b=c#d"))
        assertEquals("example.com", AdultContentFilter.hostOf("example.com"))
        assertEquals("example.com", AdultContentFilter.hostOf("example.com?x=1"))
        assertEquals("example.com", AdultContentFilter.hostOf("http://example.com/"))
    }
}
