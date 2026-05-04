# Google Play submission checklist — Break Free

Use this with your **AAB** from `flutter build appbundle` (release-signed; see `RELEASE_SIGNING.md`).

## Store listing (copy from `play_store/`)

| Field | File / notes |
|--------|----------------|
| **App name** | Break Free (or your final title; max 30 characters) |
| **Short description** | `short_description.txt` (max **80** characters — trim if needed) |
| **Full description** | `full_description.txt` (max 4000 characters) |
| **Release notes** | `what_s_new_1.0.0.txt` — paste per locale (e.g. en-US) under “Release notes” |

## Graphics (create in Figma / Canva / screenshots)

| Asset | Spec | Tips |
|--------|------|------|
| **App icon** (launcher) | Generated in the app from `assets/branding/app_icon.png` via `dart run flutter_launcher_icons` | Already wired; rebuild AAB after icon changes. |
| **Store listing — App icon** | **512 × 512** px, 32-bit PNG, max 1 MB | Export from the same branding; Play Console → Main store listing. |
| **Feature graphic** | **1024 × 500** px | Optional for some flows; often required for featured placement. Brand + tagline, no tiny text. |
| **Phone screenshots** | Min **2**, max **8**; JPEG or 24-bit PNG; min short side **320 px**, max long side **3840 px** | Capture: Home, habits, level header, Mind City, Journal, Settings. |
| **7-inch / 10-inch tablet** | Optional if you mark tablet support | Add if you support tablets. |

## Policy & technical

- [ ] **Privacy policy URL** (HTTPS, publicly reachable). Host a page that states what data you collect. For local-only apps, describe “data stored on device only” if accurate. Template ideas: `PRIVACY_POLICY_TEMPLATE.md`.
- [ ] **Data safety form** (Play Console) — Declare location, contacts, financial info, health, etc. Match your app: e.g. **no** collection if everything is on-device.
- [ ] **Content rating** questionnaire — Complete honestly (likely “Everyone” or low maturity for self-help).
- [ ] **Target audience** & **News apps** (if applicable) — Answer as required.
- [ ] **Advertising ID** — Declare if you use ads (this project has no ad SDK by default).
- [ ] **App access** — If login is required, provide test credentials or mark “no restricted access.”
- [ ] **Release signing** — `android/key.properties` + keystore; not debug-signed (see `RELEASE_SIGNING.md`).

## Build commands

```bash
dart run flutter_launcher_icons   # after changing app_icon.png
flutter build appbundle           # output: build/app/outputs/bundle/release/app-release.aab
```

## Version bumps

In `pubspec.yaml`, increment for each Play upload, e.g. `1.0.1+2` (name + build number).

---

Official references: [Play Console help](https://support.google.com/googleplay/android-developer/), [Launch checklist](https://developer.android.com/distribute/best-practices/launch).
