package app.breakfree.mobile

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import java.util.Calendar

/**
 * Schedules inexact alarms at schedule boundaries for local accountability events.
 * Blocking itself does not depend on these alarms — [AppBlockerService] evaluates
 * schedules on every accessibility event.
 */
object ProtectionAlarmScheduler {
    private const val TAG = "ProtectionAlarms"
    private const val ACTION = "app.breakfree.mobile.PROTECTION_SCHEDULE_TICK"
    private const val REQ = 8201

    fun reschedule(context: Context) {
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val schedules = ProtectionStore.schedules(ProtectionStore.prefs(context))
            .filter { it.enabled }
        cancel(context, am)
        if (schedules.isEmpty()) return

        val next = nextBoundaryMillis(schedules) ?: return
        val pi = pendingIntent(context)
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, next, pi)
            } else {
                am.set(AlarmManager.RTC_WAKEUP, next, pi)
            }
            Log.d(TAG, "Next schedule boundary at $next")
        } catch (e: Exception) {
            Log.w(TAG, "Could not schedule boundary alarm", e)
        }
    }

    fun cancel(context: Context, am: AlarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager) {
        am.cancel(pendingIntent(context))
    }

    private fun pendingIntent(context: Context): PendingIntent {
        val intent = Intent(context, ProtectionScheduleReceiver::class.java).setAction(ACTION)
        return PendingIntent.getBroadcast(
            context,
            REQ,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    /** Next start or end boundary among enabled schedules within ~3 days. */
    internal fun nextBoundaryMillis(
        schedules: List<ProtectionScheduleNative>,
        now: Calendar = Calendar.getInstance(),
    ): Long? {
        var best: Long? = null
        val nowMs = now.timeInMillis
        for (dayOffset in 0..2) {
            for (s in schedules) {
                for (boundary in listOf(s.startMinutes, s.endMinutes)) {
                    val cal = now.clone() as Calendar
                    cal.add(Calendar.DAY_OF_YEAR, dayOffset)
                    cal.set(Calendar.HOUR_OF_DAY, boundary / 60)
                    cal.set(Calendar.MINUTE, boundary % 60)
                    cal.set(Calendar.SECOND, 0)
                    cal.set(Calendar.MILLISECOND, 0)
                    val t = cal.timeInMillis
                    if (t > nowMs + 1_000L && (best == null || t < best)) {
                        best = t
                    }
                }
            }
        }
        return best
    }
}

class ProtectionScheduleReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        // Boundary tick — Flutter may record SCHEDULE_STARTED/ENDED on next open.
        // Persist a lightweight flag for Protection Center health.
        val prefs = ProtectionStore.prefs(context)
        val active = ScheduleEvaluator.activeSchedules(ProtectionStore.schedules(prefs))
        prefs.edit()
            .putString("last_active_schedules", active.joinToString(",") { it.name })
            .putLong("last_schedule_tick_at", System.currentTimeMillis())
            .apply()
        ProtectionAlarmScheduler.reschedule(context)
    }
}

class ProtectionBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action != Intent.ACTION_BOOT_COMPLETED &&
            intent?.action != Intent.ACTION_LOCKED_BOOT_COMPLETED
        ) {
            return
        }
        ProtectionAlarmScheduler.reschedule(context)
    }
}
