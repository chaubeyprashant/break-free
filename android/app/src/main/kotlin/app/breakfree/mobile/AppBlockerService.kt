package app.breakfree.mobile

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.view.accessibility.AccessibilityEvent
import android.content.Context
import android.util.Log

class AppBlockerService : AccessibilityService() {

    private val adultKeywords = listOf("pornhub", "xvideos", "onlyfans", "xnxx", "xhamster", "brazzers", "redtube", "nhentai")

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        
        if (event.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            val packageName = event.packageName?.toString()
            if (packageName != null) {
                checkIfAppIsBlocked(packageName)
            }
        }

        if (event.eventType == AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED || event.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            checkIfAdultContent(event)
        }
    }

    private fun checkIfAdultContent(event: AccessibilityEvent) {
        val rootNode = rootInActiveWindow ?: return
        
        // Find the URL bar in common browsers
        val urlNodeList = rootNode.findAccessibilityNodeInfosByViewId("com.android.chrome:id/url_bar")
            .plus(rootNode.findAccessibilityNodeInfosByViewId("com.brave.browser:id/url_bar"))

        for (node in urlNodeList) {
            val urlText = node.text?.toString()?.lowercase() ?: continue
            
            for (keyword in adultKeywords) {
                if (urlText.contains(keyword)) {
                    Log.d("AppBlockerService", "Adult content detected: $urlText")
                    val launchIntent = Intent(this, MainActivity::class.java)
                    launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                    launchIntent.putExtra("TRIGGER_REASON", "adult_content")
                    launchIntent.putExtra("ADULT_URL", urlText)
                    startActivity(launchIntent)
                    return
                }
            }
        }
    }

    private fun checkIfAppIsBlocked(packageName: String) {
        // Read blocked apps from SharedPreferences
        val prefs = getSharedPreferences("AppBlockerPrefs", Context.MODE_PRIVATE)
        val blockedApps = prefs.getStringSet("blocked_apps", emptySet()) ?: emptySet()

        if (blockedApps.contains(packageName) && packageName != "app.breakfree.mobile") {
            // Resolve human-readable app name
            val appName = try {
                val appInfo = packageManager.getApplicationInfo(packageName, 0)
                packageManager.getApplicationLabel(appInfo).toString()
            } catch (e: Exception) {
                packageName
            }
            Log.d("AppBlockerService", "Blocked app launched: $appName ($packageName)")
            
            // Launch the Break Free app Intervention screen
            val launchIntent = Intent(this, MainActivity::class.java)
            launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            launchIntent.putExtra("BLOCKED_PACKAGE", packageName)
            launchIntent.putExtra("BLOCKED_APP_NAME", appName)
            startActivity(launchIntent)
        }
    }

    override fun onInterrupt() {
        // Required, but no action needed
    }
}
