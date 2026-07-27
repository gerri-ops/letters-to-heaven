# Retention without streaks

Grief journaling is episodic. Writing several times in one week and then disappearing for two months does **not** mean the app failed.

## Healthy return triggers

| Trigger | Implementation |
|---------|----------------|
| Optional birthday / anniversary reminders | Settings → Reminders / remembrance dates (opt-in) |
| Unfinished draft | Home → *Whenever you are ready* → Continue draft |
| Weekly or monthly memory question | Settings → Returning at your pace (user-selected cadence) |
| “Save this before I forget” widget | Soft Home cue + deep link `/capture?from=widget`; phone widget gallery when shipped |
| Private photo import (user-initiated) | Home cue → quick capture photo mode |
| Monthly keepsake preview | Opt-in; Home cue once per month |
| Family contribution notification | Quiet Home cue when Family Circle sets the waiting flag |
| User-controlled memory resurfacing | Opt-in; never auto-opens letters; asks before opening |

## Never use

- Daily streaks
- Missed-day counts
- Progress percentages
- “You are falling behind”
- Empty monthly calendars
- Red warning badges
- Grief scores
- Healing scores
- Pressure to reread painful entries

Copy and banned phrases: `lib/core/retention/retention_copy.dart`.

## Surfaces

- Home section: `lib/features/home/home_retention_section.dart`
- Settings: `/retention` — `RetentionSettingsScreen`
- Pace promise onboarding reinforces no-streak language
