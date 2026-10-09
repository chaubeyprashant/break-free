package app.breakfree.mobile

import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Context
import android.content.Intent
import android.provider.Settings
import android.view.accessibility.AccessibilityManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "com.breakfree/app_blocker"

        private const val REASON_SUSPICIOUS_TRANSACTION = "suspicious_transaction"
        private const val EXTRA_NOTIFICATION_TEXT = "NOTIFICATION_TEXT"

        private const val TYPE_BLOCKED_APP = "blocked_app"
        private const val TYPE_ADULT_CONTENT = "adult_content"
        private const val TYPE_WEBSITE_BLOCKED = "website_blocked"
        private const val TYPE_SUSPICIOUS_TRANSACTION = "suspicious_transaction"
    }

    private var methodChannel: MethodChannel? = null

    /**
     * The most recent trigger that Flutter has not confirmed handling. On a cold start the trigger
     * intent is processed before Dart has registered its handler, so it is parked here and Flutter
     * pulls it with "getPendingTrigger" once it is ready.
     */
    private var pendingTrigger: HashMap<String, Any?>? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "isAccessibilityServiceEnabled" -> {
                    result.success(isAccessibilityServiceEnabled())
                }
                "openAccessibilitySettings" -> {
                    val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                    startActivity(intent)
                    result.success(true)
                }
                "setBlockedApps" -> {
                    val blockedApps = call.argument<List<String>>("blockedApps") ?: emptyList()
                    val prefs = ProtectionStore.prefs(this)
                    prefs.edit().putStringSet(ProtectionStore.KEY_BLOCKED_APPS, blockedApps.toSet()).apply()
                    result.success(true)
                }
                "getPendingTrigger" -> {
                    val trigger = pendingTrigger
                    pendingTrigger = null
                    result.success(trigger)
                }
                "getSupportedBrowsers" -> {
                    result.success(BrowserUrlBars.displayNames())
                }
                "isNotificationServiceEnabled" -> {
                    result.success(isNotificationServiceEnabled())
                }
                "openNotificationSettings" -> {
                    val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                    startActivity(intent)
                    result.success(true)
                }
                "syncProtectionConfig" -> {
                    @Suppress("UNCHECKED_CAST")
                    val config = (call.argument<Map<*, *>>("config") ?: emptyMap<Any, Any>()) as Map<*, *>
                    val schedules = call.argument<List<*>>("schedules") ?: emptyList<Any>()
                    val schedulesJson = ProtectionStore.schedulesToFlutterJson(schedules)
                    ProtectionStore.applyFlutterConfig(ProtectionStore.prefs(this), config, schedulesJson)
                    ProtectionAlarmScheduler.reschedule(this)
                    result.success(true)
                }
                "grantContinueAnyway" -> {
                    val packageName = call.argument<String>("packageName")
                    val domain = call.argument<String>("domain")
                    ProtectionStore.grantContinueAnyway(ProtectionStore.prefs(this), packageName, domain)
                    result.success(true)
                }
                "getProtectionHealth" -> {
                    result.success(
                        ProtectionStore.healthMap(
                            this,
                            isAccessibilityServiceEnabled(),
                            isNotificationServiceEnabled(),
                        ),
                    )
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onResume() {
        super.onResume()
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null) return
        val trigger = parseTrigger(intent) ?: return

        intent.removeExtra(AppBlockerService.EXTRA_TRIGGER_REASON)
        intent.removeExtra(AppBlockerService.EXTRA_BLOCKED_PACKAGE)
        intent.removeExtra(AppBlockerService.EXTRA_BLOCKED_APP_NAME)
        intent.removeExtra(AppBlockerService.EXTRA_ADULT_URL)
        intent.removeExtra(AppBlockerService.EXTRA_MATCH_CATEGORY)
        intent.removeExtra(AppBlockerService.EXTRA_MATCH_KEYWORD)
        intent.removeExtra(EXTRA_NOTIFICATION_TEXT)

        deliverTrigger(trigger)
    }

    private fun parseTrigger(intent: Intent): HashMap<String, Any?>? {
        val reason = intent.getStringExtra(AppBlockerService.EXTRA_TRIGGER_REASON)
        val blockedPackage = intent.getStringExtra(AppBlockerService.EXTRA_BLOCKED_PACKAGE)
        val trigger = HashMap<String, Any?>()

        when {
            reason == REASON_SUSPICIOUS_TRANSACTION -> {
                trigger["type"] = TYPE_SUSPICIOUS_TRANSACTION
                trigger["text"] = intent.getStringExtra(EXTRA_NOTIFICATION_TEXT) ?: ""
                trigger["category"] = intent.getStringExtra(AppBlockerService.EXTRA_MATCH_CATEGORY)
                trigger["keyword"] = intent.getStringExtra(AppBlockerService.EXTRA_MATCH_KEYWORD)
            }
            reason == AppBlockerService.REASON_ADULT_CONTENT ||
                reason == AppBlockerService.REASON_WEBSITE_BLOCKED -> {
                trigger["type"] =
                    if (reason == AppBlockerService.REASON_ADULT_CONTENT) TYPE_ADULT_CONTENT
                    else TYPE_WEBSITE_BLOCKED
                trigger["url"] = intent.getStringExtra(AppBlockerService.EXTRA_ADULT_URL) ?: ""
                trigger["category"] = intent.getStringExtra(AppBlockerService.EXTRA_MATCH_CATEGORY)
                trigger["keyword"] = intent.getStringExtra(AppBlockerService.EXTRA_MATCH_KEYWORD)
            }
            blockedPackage != null -> {
                trigger["type"] = TYPE_BLOCKED_APP
                trigger["packageName"] = blockedPackage
                trigger["appName"] = intent.getStringExtra(AppBlockerService.EXTRA_BLOCKED_APP_NAME) ?: blockedPackage
            }
            else -> return null
        }

        trigger["id"] = System.currentTimeMillis()
        return trigger
    }

    private fun deliverTrigger(trigger: HashMap<String, Any?>) {
        pendingTrigger = trigger
        val channel = methodChannel ?: return
        channel.invokeMethod("onBlockerTrigger", trigger, object : MethodChannel.Result {
            override fun success(result: Any?) {
                if (pendingTrigger === trigger) pendingTrigger = null
            }

            override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                // Keep the trigger parked; Flutter will pull it.
            }

            override fun notImplemented() {
                // Dart handler not registered yet; Flutter will pull it.
            }
        })
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val am = getSystemService(Context.ACCESSIBILITY_SERVICE) as AccessibilityManager
        val enabledServices = am.getEnabledAccessibilityServiceList(AccessibilityServiceInfo.FEEDBACK_ALL_MASK)
        for (service in enabledServices) {
            val serviceInfo = service.resolveInfo.serviceInfo
            if (serviceInfo.packageName == packageName && serviceInfo.name == AppBlockerService::class.java.name) {
                return true
            }
        }
        return false
    }

    private fun isNotificationServiceEnabled(): Boolean {
        val pkgName = packageName
        val flat = Settings.Secure.getString(contentResolver, "enabled_notification_listeners")
        if (!flat.isNullOrEmpty()) {
            val names = flat.split(":")
            for (i in names.indices) {
                val cn = android.content.ComponentName.unflattenFromString(names[i])
                if (cn != null && cn.packageName == pkgName) {
                    return true
                }
            }
        }
        return false
    }
}
