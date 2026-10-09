package app.breakfree.mobile

/**
 * Architecture boundary for optional network-level filtering.
 *
 * Current shipping backend: [AccessibilityBrowserFilterBackend] (supported browsers only).
 * [LocalVpnFilterBackend] is intentionally unimplemented — see docs/PROTECTION_VPN_FEASIBILITY.md.
 */
interface NetworkFilterBackend {
    val id: String
    val displayName: String
    fun isAvailable(): Boolean
    fun start()
    fun stop()
}

/** Address-bar filtering via AccessibilityService — what Break Free ships today. */
class AccessibilityBrowserFilterBackend : NetworkFilterBackend {
    override val id: String = "accessibility_browser"
    override val displayName: String = "Supported browser filter"
    override fun isAvailable(): Boolean = true
    override fun start() { /* owned by AppBlockerService lifecycle */ }
    override fun stop() { /* owned by AppBlockerService lifecycle */ }
}

/**
 * Placeholder for a future on-device VpnService filter.
 * Must not be registered or started until Play policy review and battery testing pass.
 */
class LocalVpnFilterBackend : NetworkFilterBackend {
    override val id: String = "local_vpn"
    override val displayName: String = "Local VPN filter (not available)"
    override fun isAvailable(): Boolean = false
    override fun start() {
        throw UnsupportedOperationException(
            "Local VPN filtering is not implemented. Use supported-browser accessibility filtering.",
        )
    }
    override fun stop() {}
}
