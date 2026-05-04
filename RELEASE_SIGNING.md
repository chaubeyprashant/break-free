# Release signing (Play Store / AAB)

Your app must be signed in **release** mode for Play Store. Do this once, then every release build will be signed.

## 1. Create a keystore (one-time)

From the project root:

```bash
cd android
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

- Use a strong **store password** and **key password** (you’ll need them for every release).
- Fill in name/organization or use placeholders; you can change them later with keytool.
- This creates `android/upload-keystore.jks`. **Back it up somewhere safe** (e.g. encrypted backup). If you lose it, you can’t update the same app on Play Store.

## 2. Create `key.properties`

In the **android** folder, copy the example and edit with your values:

```bash
cd android
cp key.properties.example key.properties
```

Edit `android/key.properties`:

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=../upload-keystore.jks
```

(`storeFile` is relative to `android/app`, so `../upload-keystore.jks` means the file in `android/`.)

**Do not commit `key.properties` or `upload-keystore.jks`.** They are already in `.gitignore`.

## 3. Build release AAB

From the project root:

```bash
flutter build appbundle
```

Output: `build/app/outputs/bundle/release/app-release.aab`. Upload this file in Play Console.

If `key.properties` is missing, the release build falls back to debug signing (so local `flutter run --release` still works), but **don’t upload that AAB to Play Store**. Once `key.properties` and the keystore are set up, release builds will be signed for release automatically.

## References

- [Flutter: Android release signing](https://docs.flutter.dev/deployment/android#signing-the-app)
- [Play Console: App signing](https://support.google.com/googleplay/android-developer/answer/9842756)
