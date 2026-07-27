# Audio attachments (Phase 2)

Phase 1 ships **photos** only. Phase 2 media path:

1. Record or pick audio in the entry editor (`extensionJson['audioPath']` or `media` table).
2. Compress / store locally; queue upload when Firebase Storage is configured.
3. Enforce plan storage limits via `Entitlement` + settings UI.
4. Playback controls must support screen readers (Semantics labels).
5. Transcription is **deferred** (privacy/cost); keep original audio when added later.

UI hook: use `Entry.mediaIds` and `MediaAttachment` in `models.dart`. Expand `entry_editor_screen.dart` with an audio section when ready for store builds.
