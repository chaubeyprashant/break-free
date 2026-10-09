# Break Free

Gamified self-control coach (Flutter). Dart package name: `break_free`.

## Run

```bash
flutter pub get
flutter run
```

## App & Web Blocker (Android only)

Implemented as an `AccessibilityService` in `android/app/src/main/kotlin/app/breakfree/mobile/AppBlockerService.kt`.

- **App blocking** compares every foreground window change with the packages the user picked in the app. A match brings up the intervention screen.
- **Web filter** reads the address bar of the browsers listed in `BrowserUrlBars.kt` and checks it against `AdultContentFilter.kt` (a substring blocklist of well-known adult sites and terms). Other browsers, in-app WebViews and DNS are not covered, so an unlisted browser bypasses it. The browser list shown in the app comes from that table over the method channel, so add browsers there, not in Dart.
- Both detections run on the device. Blocker events are mirrored to Firestore only when the user has linked a companion (`app_blocker_repository.dart`).
- `res/xml/accessibility_service_config.xml` must keep `canRetrieveWindowContent="true"`, `flagReportViewIds` and `typeWindowContentChanged`. Without them the web filter silently does nothing.
- On a cold start the trigger intent arrives before Dart is ready, so `MainActivity` parks it and Flutter pulls it with `getPendingTrigger`.

Manual test on a device: enable the service (Settings → Accessibility → Break Free; on a sideloaded build Android may first ask you to allow restricted settings from App info), block an app and open it, then open Chrome and type `example.com/xvideos-test` (a harmless address containing a blocklisted keyword). Each should bring up an intervention screen within about a second. Unit tests for the matching logic:

```bash
cd android && ./gradlew :app:testDebugUnitTest
```

Play Console: complete the Accessibility API declaration describing both uses, the package visibility declaration for `QUERY_ALL_PACKAGES` (needed to list installed apps), and declare location and app-activity sharing in Data safety because linked companions receive blocker events.

## Android package ID

`app.breakfree.mobile` — update Play Console if you previously used `app.mukti.breakfree` (treated as a different app).
