import '../../data/models/models.dart';

/// Soft template id for Voice Keepsakes (stored on keepsake entries).
const voiceKeepsakeTemplateId = 'voice';

bool isVoiceKeepsake(Entry entry) {
  if (entry.type != EntryType.keepsake) {
    return false;
  }
  return entry.extensionJson['template']?.toString() == voiceKeepsakeTemplateId;
}

String? voiceSpeaker(Entry entry) =>
    entry.extensionJson['speaker']?.toString();

String? voiceTimePeriod(Entry entry) =>
    entry.extensionJson['timePeriod']?.toString();

String? voiceTranscript(Entry entry) =>
    entry.extensionJson['transcript']?.toString();

String? voiceSourceKind(Entry entry) =>
    entry.extensionJson['sourceKind']?.toString();

/// Private listen URL for QR codes — only when a durable remote path exists.
String? voicePrivateListenUrl(MediaAttachment? media) {
  final remote = media?.remotePath?.trim();
  if (remote == null || remote.isEmpty) {
    return null;
  }
  if (remote.startsWith('http://') || remote.startsWith('https://')) {
    return remote;
  }
  return null;
}

const voicePremiumHero =
    'Preserve not only what happened, but how they sounded.';

const voiceNoCloneDisclaimer =
    'Letters to Heaven never generates new speech in a loved one’s voice. '
    'Technology protects the memory—it does not tell you what it means.';
