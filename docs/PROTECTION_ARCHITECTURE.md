# Break Free protection architecture (Phase 3)

## Layers

1. **App blocking** — `AppBlockerService` (Accessibility) compares foreground package
   to user list + active schedules. Critical system packages never blocked.
2. **Supported-browser website filter** — address-bar view IDs in `BrowserUrlBars`,
   categories in `WebCategoryFilter` + custom domains via `DomainNormalizer`.
3. **Notification scanner** — optional `NotificationListenerService` with category
   matching and cooldown (`NotificationKeywordMatcher`).
4. **Schedules** — stored in SharedPreferences (`ProtectionStore`); evaluated natively
   on each event. Boundary alarms + boot receiver for accountability ticks.
5. **Flutter Protection Center** — status, setup guidance, schedules, domains, history.
6. **Companion alerts** — optional short summaries only (no browsing content).
7. **VPN/DNS** — not implemented; see `PROTECTION_VPN_FEASIBILITY.md`.

## Storage

| Data | Where | Sync |
|------|--------|------|
| Blocked apps | Flutter prefs + `AppBlockerPrefs` | Native mirror |
| Schedules / config | Flutter prefs + native JSON | Native mirror |
| Protection events | Local SharedPreferences | Companion summaries only if enabled |
| Address bar / notification text | Not retained | — |

## What Android cannot guarantee

- Every browser or in-app WebView
- Blocking when Accessibility is off or OEM-killed
- Instant schedule ticks under Doze (blocking still evaluates on next event)
- Preventing uninstall or permission revocation
