# Phase coverage map

Maps plan phases to implementation. **Priorities:** [RELEASE_PRIORITIES.md](RELEASE_PRIORITIES.md).

## Must launch — core

| Capability | Location |
|------------|----------|
| Quick text capture | `features/capture/` |
| Letters / memories / moments / photo keepsakes | `EntryType.*`, editors |
| Voice record / upload | `features/voice/` |
| One memorial (Basic) | `PlanEntitlements.basicMemorialLimit` |
| Local-first + autosave | `app_database`, entry editor |
| Search | `features/keepsake/search_screen.dart` |
| Biometric lock | Settings + `BiometricLockService` |
| Private cloud backup | Media policy + sync (Premium) |
| Simple keepsake PDF | `keepsake_pdf_builder`, export |
| Data export / deletion | `data_rights_screen` |
| Gentle prompts | `optional_prompt_sheet`, prompts library |
| Notification controls | `reminders_screen`, ReminderCopy |

## Shortly after / early

| Capability | Location / note |
|------------|-----------------|
| Multiple memorials | `features/memorials/` (Premium) |
| Gift Premium (non-renewing) | `features/gifts/` — store wiring post-launch |
| Keepsake builder (complete) | `features/keepsake/` — deepen after simple PDF |
| Home quick-memory cue | Retention section; native widget later |

## Foundation

| Item | Location |
|------|----------|
| Flutter scaffold | `lib/`, `android/`, `ios/`, `web/` |
| Theme tokens | `lib/core/theme/app_theme.dart` |
| Routing | `lib/core/routing/app_router.dart` |
| Local DB | `lib/data/local/app_database.dart` |
| Firebase stubs / REST | `lib/firebase_options.dart`, `lib/core/firebase/` |
| Prompts | `assets/prompts/launch_prompts.json` |
| Privacy trust | `core/privacy/`, `/privacy-trust` |
| AI stance | `core/ai/`, [AI_STANCE.md](AI_STANCE.md) |
| Retention without streaks | `core/retention/` |

## Delayed / out

Public community, AI emotional advice, grief tracking, complex decoration, large sticker editor, in-app print ordering, extensive daily content, social feed — see [DEFERRED_SCOPE.md](DEFERRED_SCOPE.md).
