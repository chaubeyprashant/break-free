package app.breakfree.mobile

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class NotificationKeywordMatcherTest {

    @Test
    fun `matches whole word smoke but not Barbara for bar`() {
        assertTrue(NotificationKeywordMatcher.containsPhrase("buy a cigarette today", "cigarette"))
        assertFalse(NotificationKeywordMatcher.containsPhrase("hello barbara", "bar"))
    }

    @Test
    fun `skips otp noise`() {
        assertNull(
            NotificationKeywordMatcher.findMatch(
                "OTP",
                "Your one-time verification code is 1234",
                setOf("shopping", "alcohol"),
            ),
        )
    }

    @Test
    fun `matches category keyword`() {
        val match = NotificationKeywordMatcher.findMatch(
            "DraftKings",
            "Your parlays are ready",
            setOf("gambling"),
        )
        assertNotNull(match)
        assertEquals("gambling", match!!.category)
    }
}
