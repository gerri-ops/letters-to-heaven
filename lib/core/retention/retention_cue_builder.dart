import '../../data/models/models.dart';
import 'retention_copy.dart';

/// Soft, optional cues for Home — never streaks or warning badges.
class RetentionCue {
  const RetentionCue({
    required this.id,
    required this.title,
    required this.kind,
    this.entryId,
    this.subtitle,
  });

  final String id;
  final String title;
  final RetentionCueKind kind;
  final String? entryId;
  final String? subtitle;
}

enum RetentionCueKind {
  draft,
  memoryQuestion,
  saveBeforeForget,
  importPhoto,
  monthlyKeepsake,
  resurface,
  remembrance,
  familyContribution,
}

/// Builds calm return options from local state (no pressure scoring).
abstract final class RetentionCueBuilder {
  static List<RetentionCue> build({
    required List<Entry> entries,
    required MemoryQuestionCadence questionCadence,
    required bool monthlyKeepsakeEnabled,
    required MemoryResurfacingMode resurfacingMode,
    required bool hasRemembranceDates,
    required bool hasFamilyContributionWaiting,
    required DateTime now,
    String? lastKeepsakePreviewYearMonth,
    String? lastQuestionYearWeekOrMonth,
  }) {
    final cues = <RetentionCue>[];

    final draft = _newestDraft(entries);
    if (draft != null) {
      cues.add(
        RetentionCue(
          id: 'draft-${draft.id}',
          title: RetentionCopy.continueDraft,
          kind: RetentionCueKind.draft,
          entryId: draft.id,
          subtitle: draft.title.trim().isEmpty
              ? entryTypeSoftLabel(draft.type)
              : draft.title.trim(),
        ),
      );
    }

    if (questionCadence != MemoryQuestionCadence.off) {
      final key = questionCadence == MemoryQuestionCadence.weekly
          ? _yearWeek(now)
          : _yearMonth(now);
      if (lastQuestionYearWeekOrMonth != key) {
        cues.add(
          RetentionCue(
            id: 'question-$key',
            title: questionCadence == MemoryQuestionCadence.weekly
                ? RetentionCopy.memoryQuestionWeekly
                : RetentionCopy.memoryQuestionMonthly,
            kind: RetentionCueKind.memoryQuestion,
            subtitle: 'One optional question. Not today is always fine.',
          ),
        );
      }
    }

    cues.add(
      const RetentionCue(
        id: 'save-before-forget',
        title: RetentionCopy.saveBeforeForget,
        kind: RetentionCueKind.saveBeforeForget,
        subtitle: 'A quick private note—no schedule.',
      ),
    );

    cues.add(
      const RetentionCue(
        id: 'import-photo',
        title: RetentionCopy.importPhoto,
        kind: RetentionCueKind.importPhoto,
        subtitle: 'Only when you choose to look.',
      ),
    );

    if (monthlyKeepsakeEnabled) {
      final ym = _yearMonth(now);
      if (lastKeepsakePreviewYearMonth != ym) {
        cues.add(
          const RetentionCue(
            id: 'monthly-keepsake',
            title: RetentionCopy.monthlyKeepsake,
            kind: RetentionCueKind.monthlyKeepsake,
            subtitle: 'A gentle look at what you have already saved.',
          ),
        );
      }
    }

    if (resurfacingMode != MemoryResurfacingMode.off) {
      final candidate = _resurfaceCandidate(entries, resurfacingMode);
      if (candidate != null) {
        cues.add(
          RetentionCue(
            id: 'resurface-${candidate.id}',
            title: RetentionCopy.resurfaceMemory,
            kind: RetentionCueKind.resurface,
            entryId: candidate.id,
            subtitle: 'You choose whether to open it.',
          ),
        );
      }
    }

    if (hasRemembranceDates) {
      cues.add(
        const RetentionCue(
          id: 'remembrance',
          title: RetentionCopy.remembranceDates,
          kind: RetentionCueKind.remembrance,
          subtitle: 'Optional. Pause anytime.',
        ),
      );
    }

    if (hasFamilyContributionWaiting) {
      cues.add(
        const RetentionCue(
          id: 'family',
          title: RetentionCopy.familyContribution,
          kind: RetentionCueKind.familyContribution,
          subtitle: 'Waiting quietly until you are ready.',
        ),
      );
    }

    return cues;
  }

  static Entry? _newestDraft(List<Entry> entries) {
    final drafts = entries
        .where((e) => e.status == EntryStatus.draft && !e.isDeleted)
        .toList()
      ..sort((a, b) {
        final ad = a.updatedAt ?? a.createdAt ?? DateTime(1970);
        final bd = b.updatedAt ?? b.createdAt ?? DateTime(1970);
        return bd.compareTo(ad);
      });
    return drafts.isEmpty ? null : drafts.first;
  }

  /// Never auto-picks letters (may be painful). Prefer favorites / memories.
  static Entry? _resurfaceCandidate(
    List<Entry> entries,
    MemoryResurfacingMode mode,
  ) {
    var pool = entries.where(
      (e) =>
          !e.isDeleted &&
          e.status == EntryStatus.saved &&
          e.isVisibleOnHome &&
          e.type != EntryType.letter &&
          e.body.trim().isNotEmpty,
    );
    if (mode == MemoryResurfacingMode.favoritesWhenAsked) {
      pool = pool.where((e) => e.isFavorite);
    }
    final list = pool.toList()
      ..sort((a, b) {
        if (a.isFavorite != b.isFavorite) {
          return a.isFavorite ? -1 : 1;
        }
        final ad = a.updatedAt ?? a.createdAt ?? DateTime(1970);
        final bd = b.updatedAt ?? b.createdAt ?? DateTime(1970);
        return ad.compareTo(bd); // quieter / older first
      });
    return list.isEmpty ? null : list.first;
  }

  static String _yearMonth(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}';

  static String _yearWeek(DateTime d) {
    final start = DateTime(d.year);
    final dayOfYear = d.difference(start).inDays;
    final week = 1 + dayOfYear ~/ 7;
    return '${d.year}-W${week.toString().padLeft(2, '0')}';
  }

  static String entryTypeSoftLabel(EntryType type) {
    switch (type) {
      case EntryType.letter:
        return 'Letter draft';
      case EntryType.memory:
        return 'Memory draft';
      case EntryType.meaningfulMoment:
        return 'Moment draft';
      case EntryType.keepsake:
        return 'Keepsake draft';
    }
  }
}
