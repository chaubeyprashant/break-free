package app.breakfree.mobile

/**
 * Packages that must never be blocked — Break Free itself, system UI, phone/emergency,
 * accessibility settings, and other apps that would strand the user.
 */
object ProtectedPackages {

    private val exact: Set<String> = setOf(
        "com.android.settings",
        "com.android.phone",
        "com.android.server.telecom",
        "com.android.systemui",
        "com.android.emergency",
        "com.google.android.dialer",
        "com.samsung.android.dialer",
        "com.android.dialer",
        "com.google.android.permissioncontroller",
        "com.android.permissioncontroller",
        "com.google.android.packageinstaller",
        "com.android.packageinstaller",
        "com.google.android.apps.accessibility.voiceaccess",
    )

    fun isNeverBlock(packageName: String?, selfPackage: String): Boolean {
        if (packageName.isNullOrBlank()) return true
        if (packageName == selfPackage) return true
        if (exact.contains(packageName)) return true
        // Allowlist common launcher packages so home stays reachable.
        if (packageName.contains("launcher", ignoreCase = true)) return true
        // Do not blanket-block all com.android.* (Chrome is com.android.chrome and may be listed).
        // Only blocklist the critical exact set above; skip permission/a11y controllers via exact.
        return false
    }

    /** Prefer never blocking system shared UI even if user somehow added it. */
    fun isCriticalSystem(packageName: String?): Boolean {
        if (packageName.isNullOrBlank()) return true
        return exact.contains(packageName) ||
            packageName.startsWith("com.android.systemui") ||
            packageName.contains("launcher", ignoreCase = true)
    }
}
