# Launch readiness & acceptance gates

Checklist for **Must launch** items in [RELEASE_PRIORITIES.md](RELEASE_PRIORITIES.md). Mark during alpha → closed beta → store release.

## Must launch — product

- [ ] Quick text capture
- [ ] Voice recording and upload
- [ ] Photo memories
- [ ] Letters
- [ ] One memorial profile
- [ ] Local-first writing
- [ ] Autosave (≤10 seconds of text lost after force-close)
- [ ] Search
- [ ] Biometric lock
- [ ] Private cloud backup (Premium; owner-only rules)
- [ ] Simple keepsake PDF (respects `hiddenFromExport`)
- [ ] Subscription **and restore purchase** (store IAP live)
- [ ] Data export and account deletion
- [ ] Gentle prompt option (optional; never forced)
- [ ] Notification controls (opt-in; pause; silence; gentle copy)

## Must launch — trust & safety

- [ ] Privacy as product feature ([PRIVACY_TRUST.md](PRIVACY_TRUST.md)); analytics never includes entry text, loved-one names, exact locations, private media, or search queries
- [ ] No ads SDK; no deceased-person impersonation; no AI grief counseling ([AI_STANCE.md](AI_STANCE.md))
- [ ] Paywall copy approved; Start 14-Day Free Trial / Continue With Basic; no pressure phrases
- [ ] Not-therapy disclaimer; support resources reachable
- [ ] Privacy policy, terms, subscription terms linked

## Must launch — quality & store

- [ ] Offline create/edit/search of local entries
- [ ] Screen reader + large text: onboarding, letter, export
- [ ] Crash-free sessions ≥99.5% in beta
- [ ] App Store / Play screenshots ([APP_STORE_SCREENSHOTS.md](APP_STORE_SCREENSHOTS.md)); listing ([APP_STORE_LISTING.md](APP_STORE_LISTING.md))
- [ ] IAP: monthly $4.99 + annual $39.99 configured; restore works
- [ ] Closed beta 30–50; staged rollout after crash/sync gates

## Already strong / keep verifying (not blockers if green)

- Emotional exit door; retention without streaks; review asks only after safe success
- Four entry types; Basic useful plan; Premium protection/media positioning

## Shortly after launch (do not block store)

Track in [RELEASE_PRIORITIES.md](RELEASE_PRIORITIES.md): multiple memorials polish, voice transcription, complete keepsake builder, Family Circle, gift store products, relationship prompt packs, PDF journal import, native home widget.

## Critical acceptance scripts (smoke)

1. **Onboarding language:** Welcome → first capture or home. Account offered only after a local save.
2. **Offline write:** Airplane mode → letter or memory → save → reopen offline → reconnect → no duplicate loss.
3. **Private export:** Mix of entry types including one hidden from export → PDF omits hidden → share file.
4. **Subscription + restore:** Purchase or trial → kill app → restore purchase → Premium features return; cancel → existing memories still readable/exportable.
5. **Delete:** Export → delete account/data → confirm wipe.

## Pre-build inputs still needed from product owner

- App icon / separated artwork assets (subtitle locked in [APP_STORE_LISTING.md](APP_STORE_LISTING.md))
- Legal privacy policy & terms URLs
- Support-resource plan by market
- Export theme visual comps
- Beta invite list
- Store product IDs for monthly, annual, and (post-launch) gift year
