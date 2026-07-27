import 'package:flutter_test/flutter_test.dart';
import 'package:letters_to_heaven/core/retention/retention_copy.dart';
import 'package:letters_to_heaven/core/retention/retention_cue_builder.dart';
import 'package:letters_to_heaven/data/models/models.dart';

void main() {
  test('retention copy lists healthy triggers and avoid patterns', () {
    expect(RetentionCopy.healthyTriggers, hasLength(8));
    expect(RetentionCopy.avoidPatterns, hasLength(9));
    expect(RetentionCopy.principle, contains('episodic'));
  });

  test('retention surfaces never use banned pressure phrases', () {
    final surface = [
      RetentionCopy.principle,
      RetentionCopy.homeSectionTitle,
      RetentionCopy.homeSectionSupporting,
      RetentionCopy.continueDraft,
      RetentionCopy.memoryQuestionWeekly,
      RetentionCopy.saveBeforeForget,
      RetentionCopy.importPhoto,
      RetentionCopy.monthlyKeepsake,
      RetentionCopy.resurfaceMemory,
      RetentionCopy.widgetLabel,
      RetentionCopy.widgetDescription,
      RetentionCopy.settingsIntro,
      ...RetentionCopy.healthyTriggers,
    ].join(' ');

    for (final banned in RetentionCopy.bannedPhrases) {
      expect(
        surface.toLowerCase().contains(banned.toLowerCase()),
        isFalse,
        reason: 'Banned retention phrase: $banned',
      );
    }
  });

  test('cue builder offers draft and never forces letter resurfacing', () {
    final entries = [
      Entry(
        id: 'd1',
        memorialId: 'm1',
        ownerUid: 'u1',
        type: EntryType.letter,
        title: 'Hard letter',
        body: 'Painful words',
        status: EntryStatus.draft,
      ),
      Entry(
        id: 'l1',
        memorialId: 'm1',
        ownerUid: 'u1',
        type: EntryType.letter,
        title: 'Saved letter',
        body: 'Should not resurface automatically',
        status: EntryStatus.saved,
        isFavorite: true,
      ),
      Entry(
        id: 'mem1',
        memorialId: 'm1',
        ownerUid: 'u1',
        type: EntryType.memory,
        title: 'Sunday gravy',
        body: 'Extra garlic',
        status: EntryStatus.saved,
        isFavorite: true,
      ),
    ];

    final cues = RetentionCueBuilder.build(
      entries: entries,
      questionCadence: MemoryQuestionCadence.off,
      monthlyKeepsakeEnabled: false,
      resurfacingMode: MemoryResurfacingMode.favoritesWhenAsked,
      hasRemembranceDates: false,
      hasFamilyContributionWaiting: false,
      now: DateTime(2026, 7, 27),
    );

    expect(cues.any((c) => c.kind == RetentionCueKind.draft), isTrue);
    expect(cues.any((c) => c.kind == RetentionCueKind.saveBeforeForget), isTrue);
    expect(cues.any((c) => c.kind == RetentionCueKind.importPhoto), isTrue);
    final resurface = cues.where((c) => c.kind == RetentionCueKind.resurface);
    expect(resurface, isNotEmpty);
    expect(resurface.first.entryId, 'mem1');
  });
}
