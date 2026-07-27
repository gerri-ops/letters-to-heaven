# Media storage

Firebase Storage bucket: `gs://letters-to-heaven-64491.firebasestorage.app`

## Behavior

- Photos always copy into app documents via `LocalMediaStore` first
- **Cloud photo backup** (Settings) gates uploads
- When backup is on and you are signed in, media is queued as `pendingUpload` and uploaded to:

  `users/{uid}/entries/{entryId}/{mediaId}_{fileName}`

- Auth + Storage use Firebase **REST** (works on Windows desktop preview too)
- Rules: `firebase/storage.rules` (owner-only under `users/{uid}/**`)

## Enable checklist

1. Firebase project on Blaze with Storage created
2. Deploy rules: `firebase deploy --only storage` (done for current project)
3. Enable **Email/Password** in Firebase Authentication console
4. Create/sign in with email in the app
5. Settings → **Cloud photo backup** → Enable

## Not related to Storage

Cardinal/floral **artwork** ships in `assets/artwork/` and never uses Firebase Storage.
