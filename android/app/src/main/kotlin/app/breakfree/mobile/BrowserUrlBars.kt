package app.breakfree.mobile

/**
 * Browsers whose address bar the web filter can read, keyed by package name.
 *
 * The filter only works in these apps: it looks up the address bar by its view id, which is
 * browser specific and can change when a browser ships a redesign. The list shown to users in
 * the disclosure and in settings is derived from this table through [displayNames], so the app
 * never claims support for a browser that is not actually handled here.
 */
object BrowserUrlBars {

    data class Browser(
        val packageName: String,
        val displayName: String,
        val addressBarViewId: String,
    )

    val supported: List<Browser> = listOf(
        Browser("com.android.chrome", "Chrome", "com.android.chrome:id/url_bar"),
        Browser("com.brave.browser", "Brave", "com.brave.browser:id/url_bar"),
        Browser("com.microsoft.emmx", "Edge", "com.microsoft.emmx:id/url_bar"),
        Browser("com.vivaldi.browser", "Vivaldi", "com.vivaldi.browser:id/url_bar"),
        Browser("com.kiwibrowser.browser", "Kiwi", "com.kiwibrowser.browser:id/url_bar"),
        Browser("com.sec.android.app.sbrowser", "Samsung Internet", "com.sec.android.app.sbrowser:id/location_bar_edit_text"),
        Browser("org.mozilla.firefox", "Firefox", "org.mozilla.firefox:id/mozac_browser_toolbar_url_view"),
        Browser("org.mozilla.focus", "Firefox Focus", "org.mozilla.focus:id/mozac_browser_toolbar_url_view"),
        Browser("com.opera.browser", "Opera", "com.opera.browser:id/url_field"),
        Browser("com.opera.mini.native", "Opera Mini", "com.opera.mini.native:id/url_field"),
        Browser("com.duckduckgo.mobile.android", "DuckDuckGo", "com.duckduckgo.mobile.android:id/omnibarTextInput"),
    )

    private val byPackage: Map<String, Browser> = supported.associateBy { it.packageName }

    /** Resource id of the address bar for [packageName], or null when the browser is not supported. */
    fun addressBarViewId(packageName: String?): String? =
        packageName?.let { byPackage[it]?.addressBarViewId }

    fun isSupported(packageName: String?): Boolean = addressBarViewId(packageName) != null

    /** Names to show in the UI, in table order, without duplicates. */
    fun displayNames(): List<String> = supported.map { it.displayName }.distinct()
}
