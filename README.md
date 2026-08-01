# Letters to Heaven

Private memorial journal and memory keeper by **Cardinal Memorials**.

**App name:** Letters to Heaven  
**Subtitle:** Grief Journal & Memory Keeper  
**Market as:** The private place that catches a memory before it disappears.

**Headline:** Save the little things before time carries them away.

**Supporting:** Write what you still wish you could say. Preserve the stories, photos, voices, recipes, signs, and ordinary details you never want to lose.

**Subscription:** For $4.99 a month, your memories are privately backed up, easy to find, rich with photos and voices, and ready to become a keepsake whenever you choose.

Do not market as a prompt library, a cheaper therapist, or a digital 213-page journal. See [docs/COMMERCIAL_POSITION.md](docs/COMMERCIAL_POSITION.md).

**Privacy (product feature):** Your journal is private by default. We do not sell personal memories. No ads beside your entries. Your writing is not used to train an AI model. You control exports and invitations. Delete anytime. Memories remain after cancellation. We never pretend to speak as the person you lost. See [docs/PRIVACY_TRUST.md](docs/PRIVACY_TRUST.md).

**AI stance:** Technology protects and organizes the memory. It does not tell you what the memory means—and we do not compete through AI grief counseling. See [docs/AI_STANCE.md](docs/AI_STANCE.md).

Full store copy: [docs/APP_STORE_LISTING.md](docs/APP_STORE_LISTING.md).

## Quick start

```bash
# Flutter stable on PATH (or use C:\Users\<you>\flutter\bin)
flutter pub get
flutter run
```

Configure Firebase when ready:

```bash
flutterfire configure
# replaces placeholder values in lib/firebase_options.dart
```

Copy `.env.example` for local notes — never commit production secrets.

## Architecture

| Layer | Choice |
|-------|--------|
| Client | Flutter (iOS, Android; web scaffolded) |
| Local | SQLite (`sqflite`); production should use SQLCipher |
| Cloud | Firebase Auth, Firestore, Storage, Functions (stubs in `firebase/`) |
| Billing | Basic + Premium $4.99/mo or $39.99/yr via **Stripe Checkout**; non-renewing gift year $39.99; 14-day local trial + Stripe trial; store IAP later |

## App structure

```
lib/core/       theme, routing, security, sync, analytics
lib/data/       models, local DB, repository
lib/features/   auth, onboarding, home, journal, memories, signs, keepsake, settings
assets/prompts/ 60 launch prompts
docs/           phase coverage, launch readiness, deferred scope, beta runbook
```

Navigation: **Home · Journal · Memories · Signs · Keepsake** (+ Settings).

## Privacy & safety

- Private by default; no ads; no sale of journal content
- Analytics never include entry bodies, loved-one names, or private media
- Never generates messages as if from a deceased person; never clones their voice
- Technology protects and organizes memory — it does not interpret grief or offer AI counseling ([AI_STANCE.md](docs/AI_STANCE.md))
- Signs copy uses user-led “felt meaningful” language
- Not therapy — support resources linked in Settings

## Docs

- [Release priorities](docs/RELEASE_PRIORITIES.md) — Must / shortly after / delay
- [Commercial position](docs/COMMERCIAL_POSITION.md)
- [Phase coverage](docs/PHASE_COVERAGE.md)
- [Launch readiness](docs/LAUNCH_READINESS.md)
- [Deferred / delayed](docs/DEFERRED_SCOPE.md)
- [Privacy trust](docs/PRIVACY_TRUST.md)
- [AI stance](docs/AI_STANCE.md)
- [Stripe subscriptions](docs/STRIPE_SETUP.md)
- [Beta & store runbook](docs/BETA_STORE_RUNBOOK.md)

## License

Proprietary — Cardinal Memorials. All rights reserved.
