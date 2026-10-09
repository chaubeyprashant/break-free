# VPN / DNS protection — feasibility (Phase 3)

## Decision

**Do not ship a local VPN/DNS filter in this release.**

Keep supported-browser Accessibility filtering as the only network-adjacent protection.
Code boundary: `NetworkFilterBackend` / `LocalVpnFilterBackend` (unavailable stub).

## Technical viability

A `VpnService` that captures DNS (or limited TCP) and matches domains on-device is
technically possible on Android. Challenges for Break Free:

- Always-on VPN UX and user education
- Conflicts with user/enterprise VPNs
- Battery and always-running foreground service expectations
- Interaction with existing AccessibilityService (dual sensitive capabilities)
- Split-tunnel / fail-open vs fail-closed product choices

## Google Play policy

VPN apps require prominent disclosure, a privacy policy that matches behavior, and
often a declaration that traffic is not sold/misused. Even a “local only” VPN is
reviewed as a VPN. Shipping a stub that claims VPN protection would be misleading.

## Compatibility with current architecture

Accessibility browser filtering already covers the stated product claim:
“Website protection currently works with supported browsers.”

Adding VPN before that claim is solid would increase review risk without closing
the largest gap (unsupported browsers / in-app WebViews).

## Future path (when appropriate)

1. Play policy counsel + Data safety form update  
2. On-device DNS matcher using existing category/custom domain lists  
3. Explicit opt-in setup, battery disclosure, safe failure (fail-open with local event)  
4. Keep Accessibility app blocking; VPN only for DNS domain blocks  
5. Never send browsing traffic to an external server for filtering  

Until then, `getProtectionHealth()` reports `vpnLayer: not_implemented`.
