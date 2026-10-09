package app.breakfree.mobile

import android.app.Notification
import android.content.Intent
import android.os.SystemClock
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log

/**
 * Optional notification keyword scanner. Content is matched on-device and is not stored.
 * Categories and cooldown come from [ProtectionStore].
 */
class NotificationScannerService : NotificationListenerService() {
    private val tag = "NotificationScanner"

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        super.onNotificationPosted(sbn)
        val notification = sbn ?: return
        if (notification.packageName == packageName) return

        val prefs = ProtectionStore.prefs(this)
        if (!ProtectionStore.isProtectionEnabled(prefs)) return
        if (!prefs.getBoolean(ProtectionStore.KEY_SCANNER_ENABLED, true)) return

        val cooldownSec = prefs.getInt(ProtectionStore.KEY_SCANNER_COOLDOWN, 120).coerceIn(30, 3600)
        val last = prefs.getLong(ProtectionStore.KEY_LAST_SCANNER_AT, 0L)
        val now = SystemClock.elapsedRealtime()
        if (now - last < cooldownSec * 1000L) return

        val extras = notification.notification.extras
        val title = extras.getString(Notification.EXTRA_TITLE) ?: ""
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""

        val match = NotificationKeywordMatcher.findMatch(
            title = title,
            text = text,
            enabledCategories = ProtectionStore.scannerCategories(prefs),
        ) ?: return

        // Do not log full notification bodies — keyword + category only.
        Log.d(tag, "Intervention keyword=${match.keyword} category=${match.category}")
        prefs.edit().putLong(ProtectionStore.KEY_LAST_SCANNER_AT, now).apply()

        val launchIntent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            putExtra(AppBlockerService.EXTRA_BLOCKED_PACKAGE, "notification_scanner")
            putExtra(AppBlockerService.EXTRA_TRIGGER_REASON, "suspicious_transaction")
            putExtra("NOTIFICATION_TEXT", "Matched “${match.keyword}” (${match.category.replace('_', ' ')})")
            putExtra(AppBlockerService.EXTRA_MATCH_CATEGORY, match.category)
            putExtra(AppBlockerService.EXTRA_MATCH_KEYWORD, match.keyword)
        }
        startActivity(launchIntent)
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        super.onNotificationRemoved(sbn)
    }
}
