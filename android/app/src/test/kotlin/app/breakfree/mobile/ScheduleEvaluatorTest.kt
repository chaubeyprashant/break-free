package app.breakfree.mobile

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.util.Calendar

class ScheduleEvaluatorTest {

    private fun cal(year: Int, month: Int, day: Int, hour: Int, minute: Int = 0): Calendar {
        return Calendar.getInstance().apply {
            set(Calendar.YEAR, year)
            set(Calendar.MONTH, month - 1)
            set(Calendar.DAY_OF_MONTH, day)
            set(Calendar.HOUR_OF_DAY, hour)
            set(Calendar.MINUTE, minute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
    }

    @Test
    fun `overnight schedule crosses midnight`() {
        val s = ProtectionScheduleNative(
            id = "1",
            name = "Night",
            startMinutes = 22 * 60,
            endMinutes = 7 * 60,
            daysOfWeek = setOf(1, 2, 3, 4, 5, 6, 7),
            appPackages = emptySet(),
            webCategories = setOf("adult"),
            enabled = true,
        )
        // 2026-10-05 is Monday
        assertTrue(s.isActiveAt(cal(2026, 10, 5, 23)))
        assertTrue(s.isActiveAt(cal(2026, 10, 6, 6)))
        assertFalse(s.isActiveAt(cal(2026, 10, 6, 8)))
    }

    @Test
    fun `work schedule respects weekdays`() {
        val s = ProtectionScheduleNative(
            id = "2",
            name = "Work",
            startMinutes = 9 * 60,
            endMinutes = 17 * 60,
            daysOfWeek = setOf(1, 2, 3, 4, 5),
            appPackages = emptySet(),
            webCategories = emptySet(),
            enabled = true,
        )
        assertTrue(s.isActiveAt(cal(2026, 10, 5, 10))) // Mon
        assertFalse(s.isActiveAt(cal(2026, 10, 4, 10))) // Sun
    }
}
