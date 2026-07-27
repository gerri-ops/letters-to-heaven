# Revised release priorities

Source of truth for what must ship, what follows shortly, and what stays delayed.
Implementation status notes what already exists in this repo vs still open.

## Must launch

| Capability | Status (repo) |
|------------|---------------|
| Quick text capture | Present — `/capture`, Home actions |
| Voice recording and upload | Present — Voice Keepsakes |
| Photo memories | Present — capture + keepsake/photo on entries |
| Letters | Present — `EntryType.letter` |
| One memorial profile | Present — Basic limit = 1 |
| Local-first writing | Present — SQLite offline |
| Autosave | Present — draft autosave on editor |
| Search | Present — `/search` |
| Biometric lock | Present — Settings |
| Private cloud backup | Present — Premium encrypted backup (store IAP hardening still open) |
| Simple keepsake PDF | Present — export / preview PDF |
| Subscription and restore purchase | Partial — local trial + Premium flags; **store IAP + restore required for launch** |
| Data export and account deletion | Present — Data rights |
| Gentle prompt option | Present — optional prompt sheet / library |
| Notification controls | Present — Reminders opt-in, pause, silence |

Launch gates and smoke scripts: [LAUNCH_READINESS.md](LAUNCH_READINESS.md).

## Release shortly after launch

| Capability | Status (repo) |
|------------|---------------|
| Multiple memorials | Early — Premium multi-memorial UI already in app; polish/store packaging for post-launch train |
| Voice transcription | Open — Premium line item; private transcription only ([AI_STANCE.md](AI_STANCE.md)) |
| Complete keepsake builder | Partial — book types/themes exist; deepen to “complete” builder |
| Family Circle | Open — see deferred Family Circle scope |
| Gift subscriptions | Early — non-renewing gift year flow present; **store product + redeem backend for launch train** |
| Relationship-based prompt packs | Open |
| Import from existing PDF journal | Open |
| Home-screen quick-memory widget | Partial — in-app “Save this before I forget” cue; **native home-screen widget post-launch** |

## Delay (do not prioritize)

- Public community
- AI emotional advice ([AI_STANCE.md](AI_STANCE.md))
- Grief tracking
- Complex page decoration
- Large sticker editor
- Printed-book ordering inside the app
- Extensive daily content
- Social sharing feed

These align with forever-out or far-horizon items in [DEFERRED_SCOPE.md](DEFERRED_SCOPE.md).

## Product rules that apply at every release

- No streaks / missed-day pressure ([RETENTION.md](RETENTION.md))
- Privacy as a product feature ([PRIVACY_TRUST.md](PRIVACY_TRUST.md))
- No AI grief counseling; technology organizes memory, it does not interpret it ([AI_STANCE.md](AI_STANCE.md))
- No deceased-voice cloning or impersonation
