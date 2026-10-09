package app.breakfree.mobile

import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar

data class ProtectionScheduleNative(
    val id: String,
    val name: String,
    val startMinutes: Int,
    val endMinutes: Int,
    val daysOfWeek: Set<Int>,
    val appPackages: Set<String>,
    val webCategories: Set<String>,
    val enabled: Boolean,
) {
    val crossesMidnight: Boolean get() = endMinutes <= startMinutes

    fun isActiveAt(cal: Calendar): Boolean {
        if (!enabled || daysOfWeek.isEmpty()) return false
        val minutes = cal.get(Calendar.HOUR_OF_DAY) * 60 + cal.get(Calendar.MINUTE)
        // Calendar.DAY_OF_WEEK: 1=Sun … 7=Sat. Dart uses 1=Mon … 7=Sun.
        val dartWeekday = when (cal.get(Calendar.DAY_OF_WEEK)) {
            Calendar.SUNDAY -> 7
            else -> cal.get(Calendar.DAY_OF_WEEK) - 1
        }
        if (!crossesMidnight) {
            if (!daysOfWeek.contains(dartWeekday)) return false
            return minutes >= startMinutes && minutes < endMinutes
        }
        if (minutes >= startMinutes) return daysOfWeek.contains(dartWeekday)
        if (minutes < endMinutes) {
            val prev = if (dartWeekday == 1) 7 else dartWeekday - 1
            return daysOfWeek.contains(prev)
        }
        return false
    }
}

object ScheduleEvaluator {

    fun parseSchedules(json: String?): List<ProtectionScheduleNative> {
        if (json.isNullOrBlank()) return emptyList()
        return try {
            val arr = JSONArray(json)
            buildList {
                for (i in 0 until arr.length()) {
                    val o = arr.getJSONObject(i)
                    add(
                        ProtectionScheduleNative(
                            id = o.optString("id"),
                            name = o.optString("name", "Schedule"),
                            startMinutes = o.optInt("startMinutes"),
                            endMinutes = o.optInt("endMinutes"),
                            daysOfWeek = intSet(o.optJSONArray("daysOfWeek")),
                            appPackages = stringSet(o.optJSONArray("appPackages")),
                            webCategories = stringSet(o.optJSONArray("webCategories")),
                            enabled = o.optBoolean("enabled", true),
                        ),
                    )
                }
            }
        } catch (_: Exception) {
            emptyList()
        }
    }

    fun activeSchedules(schedules: List<ProtectionScheduleNative>, now: Calendar = Calendar.getInstance()) =
        schedules.filter { it.isActiveAt(now) }

    private fun intSet(arr: JSONArray?): Set<Int> {
        if (arr == null) return emptySet()
        return buildSet {
            for (i in 0 until arr.length()) add(arr.getInt(i))
        }
    }

    private fun stringSet(arr: JSONArray?): Set<String> {
        if (arr == null) return emptySet()
        return buildSet {
            for (i in 0 until arr.length()) add(arr.getString(i))
        }
    }

    fun toJsonArray(schedules: List<ProtectionScheduleNative>): String {
        val arr = JSONArray()
        for (s in schedules) {
            arr.put(
                JSONObject()
                    .put("id", s.id)
                    .put("name", s.name)
                    .put("startMinutes", s.startMinutes)
                    .put("endMinutes", s.endMinutes)
                    .put("daysOfWeek", JSONArray(s.daysOfWeek.toList()))
                    .put("appPackages", JSONArray(s.appPackages.toList()))
                    .put("webCategories", JSONArray(s.webCategories.toList()))
                    .put("enabled", s.enabled),
            )
        }
        return arr.toString()
    }
}
