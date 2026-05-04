# Branding assets

| File | Purpose |
|------|---------|
| `app_icon.png` | Master launcher art (square, high resolution). Used by `flutter_launcher_icons` to generate Android adaptive icons and iOS icons. |

## Change the store / launcher icon

1. Replace `app_icon.png` with your own square image (at least **1024×1024** PNG recommended; keep important content in the center ~66% for Android adaptive masks).
2. From the project root run:
   ```bash
   dart run flutter_launcher_icons
   ```
3. Rebuild: `flutter build appbundle`

For the **Google Play high-res icon** (512×512), export a square crop from the same artwork and upload it in Play Console → Store listing.
