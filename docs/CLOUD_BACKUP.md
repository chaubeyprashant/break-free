# Cloud backup

Signed-in users can upload local progress to Firebase so uninstall / new device does not wipe recovery data.

## Path

`users/{uid}/backup/snapshot`

## Payload

- `schemaVersion` — currently `1`
- `updatedAt` — server timestamp
- `keyCount` — number of SharedPreferences keys stored
- `keys` — map of `{ key: { t: type, v: value } }` for keys listed in `SettingsRepository.localProgressKeys`

Types: `s` string, `b` bool, `i` int, `d` double, `ls` string list.

## Not included

- Google Play entitlement / payment data
- Notification bodies
- FCM tokens (live on the user doc separately)

## App entry points

- Profile → **Cloud backup**
- Auto-backup when the app backgrounds (toggleable)

## Security

Deploy `firestore.rules` so only `request.auth.uid` can read/write their own `backup` docs.
