package app.breakfree.mobile

import android.content.Context
import android.content.Intent
import android.provider.Settings
import android.accessibilityservice.AccessibilityServiceInfo
import android.view.accessibility.AccessibilityManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.breakfree/app_blocker"
    private var methodChannel: MethodChannel? = null

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
                    val prefs = getSharedPreferences("AppBlockerPrefs", Context.MODE_PRIVATE)
                    prefs.edit().putStringSet("blocked_apps", blockedApps.toSet()).apply()
                    result.success(true)
                }
                "isNotificationServiceEnabled" -> {
                    result.success(isNotificationServiceEnabled())
                }
                "openNotificationSettings" -> {
                    val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                    startActivity(intent)
                    result.success(true)
                }
                "sendSms" -> {
                    val phoneNumber = call.argument<String>("phoneNumber")
                    val message = call.argument<String>("message")
                    if (phoneNumber != null && message != null) {
                        try {
                            val smsManager = android.telephony.SmsManager.getDefault()
                            smsManager.sendTextMessage(phoneNumber, null, message, null, null)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("SMS_FAILED", e.message, null)
                        }
                    } else {
                        result.error("INVALID_ARGS", "Phone number or message is null", null)
                    }
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
        intent?.let {
            val triggerReason = it.getStringExtra("TRIGGER_REASON")
            if (triggerReason == "suspicious_transaction") {
                val text = it.getStringExtra("NOTIFICATION_TEXT") ?: ""
                methodChannel?.invokeMethod("onSuspiciousTransaction", text)
                it.removeExtra("TRIGGER_REASON")
                return
            } else if (triggerReason == "adult_content") {
                val url = it.getStringExtra("ADULT_URL") ?: ""
                methodChannel?.invokeMethod("onAdultContentDetected", url)
                it.removeExtra("TRIGGER_REASON")
                return
            }

            val blockedPackage = it.getStringExtra("BLOCKED_PACKAGE")
            if (blockedPackage != null) {
                val blockedAppName = it.getStringExtra("BLOCKED_APP_NAME") ?: blockedPackage
                val args = hashMapOf("packageName" to blockedPackage, "appName" to blockedAppName)
                methodChannel?.invokeMethod("onBlockedAppOpened", args)
                it.removeExtra("BLOCKED_PACKAGE") // Processed
                it.removeExtra("BLOCKED_APP_NAME")
            }
        }
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
