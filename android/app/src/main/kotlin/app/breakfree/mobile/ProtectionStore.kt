package app.breakfree.mobile

import android.content.Context
import android.content.SharedPreferences
import android.os.SystemClock
import org.json.JSONArray
import org.json.JSONObject

/**
 * Native mirror of Flutter protection config. AccessibilityService reads this
 * even when the Flutter process is dead.
 */
object ProtectionStore {
    const val PREFS_NAME = AppBlockerService.PREFS_NAME

    const val KEY_BLOCKED_APPS = AppBlockerService.KEY_BLOCKED_APPS
    const val KEY_PROTECTION_ENABLED = "protection_enabled"
    const val KEY_ALWAYS_ON_APPS = "always_on_apps"
    const val KEY_WEB_ADULT = "web_adult_enabled"
    const val KEY_WEB_GAMBLING = "web_gambling_enabled"
    const val KEY_CUSTOM_DOMAINS_ENABLED = "custom_domains_enabled"
    const val KEY_CUSTOM_DOMAINS = "custom_domains_json"
    const val KEY_ALLOWLIST = "allowlist_domains_json"
    const val KEY_SCHEDULES = "schedules_json"
    const val KEY_ALLOW_CONTINUE = "allow_continue_anyway"
    const val KEY_CONTINUE_MINUTES = "continue_anyway_minutes"
    const val KEY_BYPASS_UNTIL = "bypass_until_elapsed"
    const val KEY_BYPASS_PACKAGE = "bypass_package"
    const val KEY_BYPASS_DOMAIN = "bypass_domain"
    const val KEY_SCANNER_ENABLED = "scanner_enabled"
    const val KEY_SCANNER_CATEGORIES = "scanner_categories_json"
    const val KEY_SCANNER_COOLDOWN = "scanner_cooldown_seconds"
    const val KEY_LAST_SCANNER_AT = "last_scanner_intervention_elapsed"
    const val KEY_WAS_A11Y_ENABLED = "was_accessibility_enabled"

    fun prefs(context: Context): SharedPreferences =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    fun isProtectionEnabled(p: SharedPreferences): Boolean =
        p.getBoolean(KEY_PROTECTION_ENABLED, true)

    fun alwaysOnApps(p: SharedPreferences): Boolean =
        p.getBoolean(KEY_ALWAYS_ON_APPS, true)

    fun blockedApps(p: SharedPreferences): Set<String> =
        p.getStringSet(KEY_BLOCKED_APPS, emptySet()) ?: emptySet()

    fun customDomains(p: SharedPreferences): List<String> =
        parseStringList(p.getString(KEY_CUSTOM_DOMAINS, "[]"))

    fun allowlist(p: SharedPreferences): List<String> =
        parseStringList(p.getString(KEY_ALLOWLIST, "[]"))

    fun schedules(p: SharedPreferences): List<ProtectionScheduleNative> =
        ScheduleEvaluator.parseSchedules(p.getString(KEY_SCHEDULES, "[]"))

    fun scannerCategories(p: SharedPreferences): Set<String> =
        parseStringList(p.getString(KEY_SCANNER_CATEGORIES, null)).toSet().ifEmpty {
            setOf("smoking", "alcohol", "junk_food", "gambling", "shopping")
        }

    fun isBypassActive(p: SharedPreferences, packageName: String?, domain: String?): Boolean {
        val until = p.getLong(KEY_BYPASS_UNTIL, 0L)
        if (until <= SystemClock.elapsedRealtime()) return false
        val bypassPkg = p.getString(KEY_BYPASS_PACKAGE, null)
        val bypassDomain = p.getString(KEY_BYPASS_DOMAIN, null)
        if (!bypassPkg.isNullOrBlank() && bypassPkg == packageName) return true
        if (!bypassDomain.isNullOrBlank() && !domain.isNullOrBlank()) {
            if (DomainNormalizer.hostMatches(domain, bypassDomain)) return true
        }
        // Global short bypass when neither key set specifically.
        return bypassPkg.isNullOrBlank() && bypassDomain.isNullOrBlank()
    }

    fun grantContinueAnyway(p: SharedPreferences, packageName: String?, domain: String?) {
        val minutes = p.getInt(KEY_CONTINUE_MINUTES, 5).coerceIn(1, 60)
        p.edit()
            .putLong(KEY_BYPASS_UNTIL, SystemClock.elapsedRealtime() + minutes * 60_000L)
            .putString(KEY_BYPASS_PACKAGE, packageName)
            .putString(KEY_BYPASS_DOMAIN, DomainNormalizer.normalize(domain))
            .apply()
    }

    fun applyFlutterConfig(p: SharedPreferences, config: Map<*, *>, schedulesJson: String) {
        val custom = (config["customDomains"] as? List<*>)?.mapNotNull { it as? String } ?: emptyList()
        val allow = (config["allowlistDomains"] as? List<*>)?.mapNotNull { it as? String } ?: emptyList()
        val cats = (config["scannerCategories"] as? List<*>)?.mapNotNull { it as? String } ?: emptyList()
        p.edit()
            .putBoolean(KEY_PROTECTION_ENABLED, config["protectionEnabled"] as? Boolean ?: true)
            .putBoolean(KEY_ALWAYS_ON_APPS, config["alwaysOnApps"] as? Boolean ?: true)
            .putBoolean(KEY_WEB_ADULT, config["webAdultEnabled"] as? Boolean ?: true)
            .putBoolean(KEY_WEB_GAMBLING, config["webGamblingEnabled"] as? Boolean ?: false)
            .putBoolean(KEY_CUSTOM_DOMAINS_ENABLED, config["customDomainsEnabled"] as? Boolean ?: true)
            .putBoolean(KEY_ALLOW_CONTINUE, config["allowContinueAnyway"] as? Boolean ?: true)
            .putInt(KEY_CONTINUE_MINUTES, (config["continueAnywayMinutes"] as? Number)?.toInt() ?: 5)
            .putBoolean(KEY_SCANNER_ENABLED, config["scannerEnabled"] as? Boolean ?: true)
            .putInt(KEY_SCANNER_COOLDOWN, (config["scannerCooldownSeconds"] as? Number)?.toInt() ?: 120)
            .putString(KEY_CUSTOM_DOMAINS, JSONArray(custom).toString())
            .putString(KEY_ALLOWLIST, JSONArray(allow).toString())
            .putString(KEY_SCANNER_CATEGORIES, JSONArray(cats).toString())
            .putString(KEY_SCHEDULES, schedulesJson)
            .apply()
    }

    fun healthMap(context: Context, a11yEnabled: Boolean, notificationEnabled: Boolean): HashMap<String, Any?> {
        val p = prefs(context)
        val active = ScheduleEvaluator.activeSchedules(schedules(p))
        return hashMapOf(
            "protectionEnabled" to isProtectionEnabled(p),
            "accessibilityEnabled" to a11yEnabled,
            "notificationAccessEnabled" to notificationEnabled,
            "blockedAppCount" to blockedApps(p).size,
            "customDomainCount" to customDomains(p).size,
            "activeScheduleCount" to active.size,
            "activeScheduleNames" to active.map { it.name },
            "webAdultEnabled" to p.getBoolean(KEY_WEB_ADULT, true),
            "webGamblingEnabled" to p.getBoolean(KEY_WEB_GAMBLING, false),
            "vpnLayer" to "not_implemented",
            "supportedBrowserFilter" to true,
        )
    }

    private fun parseStringList(raw: String?): List<String> {
        if (raw.isNullOrBlank()) return emptyList()
        return try {
            val arr = JSONArray(raw)
            buildList {
                for (i in 0 until arr.length()) add(arr.getString(i))
            }
        } catch (_: Exception) {
            emptyList()
        }
    }

    fun schedulesToFlutterJson(list: List<*>): String {
        val arr = JSONArray()
        for (item in list) {
            if (item !is Map<*, *>) continue
            val o = JSONObject()
            for ((k, v) in item) {
                when (v) {
                    null -> Unit
                    is List<*> -> o.put(k.toString(), JSONArray(v))
                    is Boolean, is Number, is String -> o.put(k.toString(), v)
                    else -> o.put(k.toString(), v.toString())
                }
            }
            arr.put(o)
        }
        return arr.toString()
    }
}
