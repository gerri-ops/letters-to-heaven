/// Letters to Heaven does not compete through AI grief counseling.
///
/// Technology protects and organizes the memory. It does not tell the user
/// what the memory means.
abstract final class AiProductStance {
  static const positionHeadline =
      'Technology protects and organizes the memory. '
      'It does not tell you what the memory means.';

  static const positionSupporting =
      'Some apps offer AI reflections, emotional support, grief exercises, '
      'and healing tools. Letters to Heaven takes a cleaner path: keep what '
      'matters private and findable—without counseling you about your grief.';

  static const settingsSectionTitle = 'How we use technology';

  /// Safe, optional helpers — organize and protect only.
  static const safeFunctions = <String>[
    'Private audio transcription',
    'Spelling correction chosen by the user',
    'Sorting entries by date',
    'Detecting duplicate uploads',
    'Building an export index',
    'Suggesting titles from the user’s own text',
    'Helping locate an entry',
  ];

  /// Never ship — counseling, impersonation, or unrequested interpretation.
  static const forbiddenFunctions = <String>[
    'Replies from the deceased',
    'Generated voice replicas',
    'Interpretations of signs',
    'Grief diagnoses',
    'Emotional scores',
    'Treatment claims',
    'Unrequested summaries of private letters',
    'AI-generated advice presented as counseling',
  ];

  static const neverCounseling =
      'Letters to Heaven is not grief counseling, therapy, or a clinical tool.';

  static const neverImpersonate =
      'Letters to Heaven will never pretend to speak as the person you lost.';

  static const neverCloneVoice =
      'Letters to Heaven never generates new speech in a loved one’s voice.';
}
