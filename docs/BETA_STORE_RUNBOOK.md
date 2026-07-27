# Beta & store submission runbook

## Closed beta (30–50)

1. Configure Firebase **dev** project; run `flutterfire configure`.
2. Internal alpha: account, memorial, letters, prompts, local storage, sync stubs.
3. Invite Cardinal Memorials / Etsy / trusted contacts privately — do not ask public loss stories.
4. Collect PRD beta questions (safety, clarity, first entry, trust, PDF value, willingness to pay).
5. Watch Crashlytics (when enabled), sync failures, export failures — no journal text in logs.

## Store release

1. Complete [LAUNCH_READINESS.md](LAUNCH_READINESS.md) **Must launch** checkboxes ([RELEASE_PRIORITIES.md](RELEASE_PRIORITIES.md)).
2. Privacy policy + terms live URLs in app and store listings. Use [APP_STORE_LISTING.md](APP_STORE_LISTING.md) for Connect fields.
3. IAP: monthly, annual, and **non-renewing gift year** product IDs mapped in `validateReceipt` Cloud Function. Gift must never auto-renew.
4. Screenshots: follow [APP_STORE_SCREENSHOTS.md](APP_STORE_SCREENSHOTS.md) (letter → memory cards → capture → home → voice/interview → PDF → privacy). Real UI only; captions must stay legible at phone preview size.
5. Staged rollout; pause if crash-free < 99.5% or cross-account access issues.

## Analytics (approved only)

`account_created`, `memorial_created`, `first_entry_saved`, `entry_saved` (type only), `prompt_opened` (id only), `media_upload_succeeded` (type/size band), `export_started` / `export_completed`, `reminder_opted_in`, `subscription_started`, `gift_purchased`, `gift_redeemed`, `review_prompt_shown`, `review_leave_tapped`, `review_not_now`, `review_do_not_ask`, `sync_failed` (code), `account_deletion_started`.
