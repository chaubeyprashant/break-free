package app.breakfree.mobile

import android.app.Notification
import android.content.Intent
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log

class NotificationScannerService : NotificationListenerService() {
    private val TAG = "NotificationScanner"
    
    private val keywords = listOf(
        // Smoking
        "smoke", "tobacco", "vape", "cigarette", "cigar",
        // Alcohol
        "liquor", "alcohol", "beer", "wine", "vodka", "whiskey", "pub ", "bar ",
        // Junk Food
        "mcdonalds", "burger", "kfc", "wendys", "dominos", "pizza", "donut", "candy", "fast food", "taco bell", "krispy",
        // Gambling
        "draftkings", "betmgm", "casino", "stake", "betting", "fanduel",
        // Shopping
        "amazon", "temu", "shein", "zara", "aliexpress"
    )

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        super.onNotificationPosted(sbn)
        sbn?.let {
            val packageName = it.packageName
            val extras = it.notification.extras
            val title = extras.getString(Notification.EXTRA_TITLE) ?: ""
            val text = extras.getString(Notification.EXTRA_TEXT) ?: ""
            
            val fullText = "$title $text".lowercase()
            
            Log.d(TAG, "Notification received from $packageName: $fullText")

            // Simple keyword search
            val foundKeyword = keywords.find { keyword -> fullText.contains(keyword) }
            
            if (foundKeyword != null) {
                Log.d(TAG, "Suspicious transaction detected! Keyword: $foundKeyword")
                
                // Wake up MainActivity
                val launchIntent = Intent(this, MainActivity::class.java).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                    putExtra("BLOCKED_PACKAGE", "notification_scanner")
                    putExtra("TRIGGER_REASON", "suspicious_transaction")
                    putExtra("NOTIFICATION_TEXT", "Detected '$foundKeyword' in notification.")
                }
                startActivity(launchIntent)
            }
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        super.onNotificationRemoved(sbn)
    }
}
