/// Trust-first Premium paywall copy.
///
/// Never auto-show on first launch. Only after a value moment, or when the
/// user opens Subscribe on purpose.
///
/// Commercial position: private rescue net for memories; keepsake creation is
/// the premium reason to subscribe — not prompts or therapy.
abstract final class TrustPaywallCopy {
  static const headline =
      'Save the little things before time carries them away.';

  static const supporting =
      'For \$4.99 a month, your memories are privately backed up, easy to find, '
      'rich with photos and voices, and ready to become a keepsake whenever '
      'you choose.';

  static const benefits = <String>[
    'Private cloud backup across your devices',
    'Unlimited photos, voice, and short video',
    'Printable keepsakes when you are ready',
    'A separate place for more than one loved one',
    'Search that stays private and easy to return to',
    'Export anytime — your memories remain after cancellation',
  ];

  static const trustStatement =
      'Your existing memories remain available after cancellation. '
      'Your journal is private by default.';

  static const startTrialLabel = 'Start 14-Day Free Trial';
  static const continueBasicLabel = 'Continue With Basic';

  /// Soft upgrade when someone needs a second memorial (or more).
  static const secondMemorialHeadline =
      'Make a separate private place for each person or pet you want to remember.';

  static const secondMemorialSupporting =
      'Basic includes one memorial. Premium lets you keep separate spaces—'
      'for both parents, a spouse and a pet, a child and a grandparent, '
      'several family members, or a friend alongside a relative—'
      'so you never have to choose whose memory receives a place.';

  /// Phrases we must never use in paywall or upgrade surfaces.
  static const bannedPhrases = <String>[
    'Unlock healing',
    'Invest in yourself',
    'Start your journey',
    'Do not lose your progress',
    'Your memories are waiting',
    'Limited time',
    'Only today',
    'Continue grieving with Premium',
    'cheaper than therapy',
    'grief program',
    '213-page',
  ];
}

/// Why the paywall appeared — value moments only (plus intentional browse).
enum PaywallTrigger {
  /// After the first memory has been saved.
  firstMemorySaved,

  /// User tries to add a voice recording.
  voiceRecording,

  /// User previews a keepsake / PDF builder.
  keepsakePreview,

  /// User turns on private backup.
  privateBackup,

  /// User adds a second memorial.
  secondMemorial,

  /// User tries to sync another device.
  syncAnotherDevice,

  /// User opened Subscribe or a related Premium feature on purpose.
  browsePlans,
}

extension PaywallTriggerX on PaywallTrigger {
  String get queryValue => name;

  static PaywallTrigger fromQuery(String? raw) {
    for (final value in PaywallTrigger.values) {
      if (value.name == raw) {
        return value;
      }
    }
    return PaywallTrigger.browsePlans;
  }
}
