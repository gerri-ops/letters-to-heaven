import 'package:flutter_test/flutter_test.dart';
import 'package:letters_to_heaven/core/ai/ai_product_stance.dart';

void main() {
  test('AI stance rejects counseling competition', () {
    expect(
      AiProductStance.positionHeadline,
      contains('does not tell you what the memory means'),
    );
    expect(AiProductStance.safeFunctions, hasLength(7));
    expect(AiProductStance.forbiddenFunctions, hasLength(8));
    expect(
      AiProductStance.forbiddenFunctions,
      contains('Replies from the deceased'),
    );
    expect(
      AiProductStance.forbiddenFunctions,
      contains('AI-generated advice presented as counseling'),
    );
  });

  test('safe helper list never includes counseling-adjacent promises', () {
    final surface = AiProductStance.safeFunctions.join(' ').toLowerCase();

    for (final banned in [
      'counseling',
      'emotional support',
      'healing',
      'diagnos',
      'score',
      'deceased',
      'replica',
      'advice',
      'interpret',
      'treatment',
      'summary',
      'summaries',
    ]) {
      expect(
        surface.contains(banned),
        isFalse,
        reason: 'Safe helpers must not include: $banned',
      );
    }
  });
}
