package app.breakfree.mobile

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class DomainNormalizerTest {

    @Test
    fun `normalize strips noise`() {
        assertEquals("example.com", DomainNormalizer.normalize("HTTPS://WWW.Example.COM/path?x=1"))
        assertNull(DomainNormalizer.normalize("not a domain"))
    }

    @Test
    fun `hostMatches avoids lookalikes`() {
        assertTrue(DomainNormalizer.hostMatches("sub.example.com", "example.com"))
        assertFalse(DomainNormalizer.hostMatches("notexample.com", "example.com"))
        assertFalse(DomainNormalizer.hostMatches("example.com.evil.test", "example.com"))
    }
}
