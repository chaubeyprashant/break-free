package app.breakfree.mobile

import android.accessibilityservice.AccessibilityService
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.SystemClock
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import androidx.core.app.NotificationCompat

/**
 * Powers the App & Web Blocker. Two detections run here, both entirely on the device:
 *
 *  1. App blocking: on every window change the foreground package is compared with the list the
 *     user picked (and any active schedule overrides).
 *  2. Web filter: for supported browsers only (see [BrowserUrlBars]) the address bar text is read
 *     and checked against [WebCategoryFilter] (adult / gambling / custom domains).
 *
 * Schedules and blocklists live in [ProtectionStore] SharedPreferences so rules keep working
 * when the Flutter process is not alive. This is not a VPN/DNS filter.
 */
class AppBlockerService : AccessibilityService() {

    companion object {
        private const val TAG = "AppBlockerService"

        const val PREFS_NAME = "AppBlockerPrefs"
        const val KEY_BLOCKED_APPS = "blocked_apps"

        const val EXTRA_TRIGGER_REASON = "TRIGGER_REASON"
        const val EXTRA_BLOCKED_PACKAGE = "BLOCKED_PACKAGE"
        const val EXTRA_BLOCKED_APP_NAME = "BLOCKED_APP_NAME"
        const val EXTRA_ADULT_URL = "ADULT_URL"
        const val EXTRA_MATCH_CATEGORY = "MATCH_CATEGORY"
        const val EXTRA_MATCH_KEYWORD = "MATCH_KEYWORD"
        const val REASON_ADULT_CONTENT = "adult_content"
        const val REASON_WEBSITE_BLOCKED = "website_blocked"

        private const val URL_CHECK_INTERVAL_MS = 400L
        private const val INTERVENTION_COOLDOWN_MS = 4_000L
        private const val TAMPER_CHANNEL = "protection_accountability"
    }

    private var lastUrlCheckAt = 0L
    private var lastInterventionAt = 0L
    private var lastInterventionKey: String? = null

    override fun onServiceConnected() {
        super.onServiceConnected()
        val info = serviceInfo
        ProtectionStore.prefs(this).edit()
            .putBoolean(ProtectionStore.KEY_WAS_A11Y_ENABLED, true)
            .apply()
        Log.i(
            TAG,
            "Connected: canRetrieveWindowContent=${info?.canRetrieveWindowContent} " +
                "eventTypes=${info?.eventTypes} flags=${info?.flags}",
        )
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        val packageName = event?.packageName?.toString() ?: return
        if (packageName == this.packageName) return
        if (ProtectedPackages.isCriticalSystem(packageName)) return

        val prefs = ProtectionStore.prefs(this)
        if (!ProtectionStore.isProtectionEnabled(prefs)) return

        when (event.eventType) {
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED -> {
                if (!checkIfAppIsBlocked(packageName)) {
                    checkBrowserAddressBar(packageName, throttle = false)
                }
            }
            AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED -> {
                checkBrowserAddressBar(packageName, throttle = true)
            }
        }
    }

    override fun onInterrupt() {
        // Required by the API; there is no feedback to interrupt.
    }

    override fun onUnbind(intent: Intent?): Boolean {
        // Accountability signal only — never tries to re-enable itself or trap the user.
        notifyTamper("Protection permission may have been turned off")
        return super.onUnbind(intent)
    }

    private fun checkIfAppIsBlocked(packageName: String): Boolean {
        if (ProtectedPackages.isNeverBlock(packageName, this.packageName)) return false

        val prefs = ProtectionStore.prefs(this)
        if (ProtectionStore.isBypassActive(prefs, packageName, null)) return false

        val active = ScheduleEvaluator.activeSchedules(ProtectionStore.schedules(prefs))
        val alwaysOn = ProtectionStore.alwaysOnApps(prefs)
        val globalBlocked = ProtectionStore.blockedApps(prefs)

        val shouldBlock = when {
            active.isNotEmpty() -> {
                active.any { schedule ->
                    val apps = if (schedule.appPackages.isEmpty()) globalBlocked else schedule.appPackages
                    apps.contains(packageName)
                }
            }
            alwaysOn -> globalBlocked.contains(packageName)
            else -> false
        }
        if (!shouldBlock) return false

        val appName = try {
            val appInfo = packageManager.getApplicationInfo(packageName, 0)
            packageManager.getApplicationLabel(appInfo).toString()
        } catch (e: Exception) {
            packageName
        }
        Log.d(TAG, "Blocked app launched: $appName ($packageName)")

        return launchIntervention(key = "app:$packageName") {
            putExtra(EXTRA_BLOCKED_PACKAGE, packageName)
            putExtra(EXTRA_BLOCKED_APP_NAME, appName)
        }
    }

    private fun checkBrowserAddressBar(packageName: String, throttle: Boolean) {
        val viewId = BrowserUrlBars.addressBarViewId(packageName) ?: return

        val now = SystemClock.elapsedRealtime()
        if (throttle && now - lastUrlCheckAt < URL_CHECK_INTERVAL_MS) return
        lastUrlCheckAt = now

        val prefs = ProtectionStore.prefs(this)
        val active = ScheduleEvaluator.activeSchedules(ProtectionStore.schedules(prefs))

        // Web categories: schedule can narrow; otherwise use global toggles.
        val adultEnabled: Boolean
        val gamblingEnabled: Boolean
        val customEnabled: Boolean
        if (active.isNotEmpty()) {
            val cats = active.flatMap { it.webCategories }.toSet()
            // Empty schedule categories → inherit global toggles.
            if (cats.isEmpty()) {
                adultEnabled = prefs.getBoolean(ProtectionStore.KEY_WEB_ADULT, true)
                gamblingEnabled = prefs.getBoolean(ProtectionStore.KEY_WEB_GAMBLING, false)
                customEnabled = prefs.getBoolean(ProtectionStore.KEY_CUSTOM_DOMAINS_ENABLED, true)
            } else {
                adultEnabled = cats.contains("adult")
                gamblingEnabled = cats.contains("gambling")
                customEnabled = cats.contains("custom")
            }
        } else {
            adultEnabled = prefs.getBoolean(ProtectionStore.KEY_WEB_ADULT, true)
            gamblingEnabled = prefs.getBoolean(ProtectionStore.KEY_WEB_GAMBLING, false)
            customEnabled = prefs.getBoolean(ProtectionStore.KEY_CUSTOM_DOMAINS_ENABLED, true)
        }

        val root = rootInActiveWindow ?: return
        try {
            if (root.packageName?.toString() != packageName) return
            val nodes = root.findAccessibilityNodeInfosByViewId(viewId) ?: return
            for (node in nodes) {
                val text = node.text?.toString() ?: continue
                val host = DomainNormalizer.hostOf(text)
                if (ProtectionStore.isBypassActive(prefs, packageName, host)) continue

                val match = WebCategoryFilter.findMatch(
                    addressBarText = text,
                    adultEnabled = adultEnabled,
                    gamblingEnabled = gamblingEnabled,
                    customEnabled = customEnabled,
                    customDomains = ProtectionStore.customDomains(prefs),
                    allowlist = ProtectionStore.allowlist(prefs),
                ) ?: continue

                Log.d(TAG, "Website blocked in $packageName (category=${match.category}, matched='${match.keyword}')")
                launchIntervention(key = "url:${match.category}:${match.keyword}") {
                    putExtra(EXTRA_TRIGGER_REASON, REASON_WEBSITE_BLOCKED)
                    putExtra(EXTRA_ADULT_URL, text)
                    putExtra(EXTRA_MATCH_CATEGORY, match.category)
                    putExtra(EXTRA_MATCH_KEYWORD, match.keyword)
                    // Keep legacy reason for older Flutter handlers when adult.
                    if (match.category == "adult") {
                        putExtra(EXTRA_TRIGGER_REASON, REASON_ADULT_CONTENT)
                    }
                }
                return
            }
        } catch (e: Exception) {
            Log.w(TAG, "Address bar check failed for $packageName", e)
        }
    }

    private fun launchIntervention(key: String, extras: Intent.() -> Unit): Boolean {
        val now = SystemClock.elapsedRealtime()
        if (key == lastInterventionKey && now - lastInterventionAt < INTERVENTION_COOLDOWN_MS) {
            return false
        }
        lastInterventionKey = key
        lastInterventionAt = now

        val launchIntent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            extras()
        }
        startActivity(launchIntent)
        return true
    }

    private fun notifyTamper(message: String) {
        try {
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                nm.createNotificationChannel(
                    NotificationChannel(
                        TAMPER_CHANNEL,
                        "Protection accountability",
                        NotificationManager.IMPORTANCE_DEFAULT,
                    ),
                )
            }
            val open = PendingIntent.getActivity(
                this,
                0,
                Intent(this, MainActivity::class.java),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            val notification = NotificationCompat.Builder(this, TAMPER_CHANNEL)
                .setSmallIcon(android.R.drawable.ic_dialog_alert)
                .setContentTitle("Break Free protection")
                .setContentText(message)
                .setContentIntent(open)
                .setAutoCancel(true)
                .build()
            nm.notify(7101, notification)
        } catch (e: Exception) {
            Log.w(TAG, "Tamper notify failed", e)
        }
    }
}
