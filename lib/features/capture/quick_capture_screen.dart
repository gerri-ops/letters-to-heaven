import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:uuid/uuid.dart';

import '../../core/analytics/analytics.dart';
import '../../core/billing/plan_entitlements.dart';
import '../../core/billing/premium_upgrade_sheet.dart';
import '../../core/billing/trust_paywall_copy.dart';
import '../../core/media/local_media_store.dart';
import '../../core/media/local_only_media_banner.dart';
import '../../core/state/app_scope.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/artwork_assets.dart';
import '../../core/theme/artwork_image.dart';
import '../../core/theme/letters_app_bar.dart';
import '../../data/models/models.dart';
import '../../data/repositories/app_repository.dart';
import '../entries/emotional_exit_door.dart';

enum QuickCaptureMode { type, speak, photo, audio }

enum QuickCaptureKind { note, cardinalVisit }

class QuickCaptureScreen extends StatefulWidget {
  const QuickCaptureScreen({
    super.key,
    this.initialMode = QuickCaptureMode.type,
  });

  final QuickCaptureMode initialMode;

  @override
  State<QuickCaptureScreen> createState() => _QuickCaptureScreenState();
}

class _QuickCaptureScreenState extends State<QuickCaptureScreen> {
  final _bodyController = TextEditingController();
  final _bodyFocus = FocusNode();
  final _mediaStore = LocalMediaStore();
  final _speech = stt.SpeechToText();
  static const _uuid = Uuid();

  QuickCaptureMode _mode = QuickCaptureMode.type;
  QuickCaptureKind _kind = QuickCaptureKind.note;
  bool _saving = false;
  bool _speechReady = false;
  bool _listening = false;
  String? _speechStatus;
  final List<_PendingMedia> _attachments = [];

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    switch (_mode) {
      case QuickCaptureMode.type:
        _bodyFocus.requestFocus();
        return;
      case QuickCaptureMode.speak:
        await _startSpeaking();
        return;
      case QuickCaptureMode.photo:
        await _addPhoto();
        return;
      case QuickCaptureMode.audio:
        await _addAudio();
        return;
    }
  }

  Future<void> _ensureSpeech() async {
    if (_speechReady) {
      return;
    }
    try {
      _speechReady = await _speech.initialize(
        onError: (e) {
          if (!mounted) {
            return;
          }
          setState(() {
            _listening = false;
            _speechStatus = 'Could not hear that. Try again or type.';
          });
        },
        onStatus: (status) {
          if (!mounted) {
            return;
          }
          if (status == 'done' || status == 'notListening') {
            setState(() => _listening = false);
          }
        },
      );
    } catch (_) {
      _speechReady = false;
    }
  }

  Future<void> _setMode(QuickCaptureMode mode) async {
    if (_listening) {
      await _speech.stop();
      if (mounted) {
        setState(() => _listening = false);
      }
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _mode = mode;
      _speechStatus = null;
    });
    switch (mode) {
      case QuickCaptureMode.type:
        _bodyFocus.requestFocus();
        return;
      case QuickCaptureMode.speak:
        await _startSpeaking();
        return;
      case QuickCaptureMode.photo:
        await _addPhoto();
        return;
      case QuickCaptureMode.audio:
        await _addAudio();
        return;
    }
  }

  Future<void> _startSpeaking() async {
    final app = AppScope.of(context);
    if (!app.premium) {
      await showPremiumUpgradeSheet(
        context,
        title: 'Voice & audio',
        body: '',
        trigger: PaywallTrigger.voiceRecording,
      );
      if (mounted) {
        setState(() {
          _mode = QuickCaptureMode.type;
          _speechStatus = null;
        });
        _bodyFocus.requestFocus();
      }
      return;
    }
    await _ensureSpeech();
    if (!_speechReady) {
      if (mounted) {
        setState(() {
          _speechStatus =
              'Speak is Premium, and voice dictation is not available in this '
              'browser. Type here, or use Add audio on a phone or tablet.';
          _mode = QuickCaptureMode.type;
          _listening = false;
        });
        _bodyFocus.requestFocus();
      }
      return;
    }
    setState(() {
      _listening = true;
      _mode = QuickCaptureMode.speak;
      _speechStatus = 'Listening… say what you want to keep.';
    });
    final prefix = _bodyController.text;
    await _speech.listen(
      onResult: (result) {
        if (!mounted) {
          return;
        }
        final spoken = result.recognizedWords.trim();
        if (spoken.isEmpty) {
          return;
        }
        final separator = prefix.trim().isEmpty ? '' : ' ';
        _bodyController.text = '$prefix$separator$spoken';
        _bodyController.selection = TextSelection.collapsed(
          offset: _bodyController.text.length,
        );
      },
      listenOptions: stt.SpeechListenOptions(
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.dictation,
      ),
    );
  }

  Future<void> _stopSpeaking() async {
    await _speech.stop();
    if (mounted) {
      setState(() => _listening = false);
    }
  }

  Future<void> _addPhoto() async {
    final app = AppScope.of(context);
    final photoCount =
        _attachments.where((a) => a.mimeType.startsWith('image/')).length;
    if (!PlanEntitlements.canAddPhoto(
      premium: app.premium,
      currentPhotoCount: photoCount,
    )) {
      await showPremiumUpgradeSheet(
        context,
        title: 'Unlimited photos',
        body: '',
        trigger: PaywallTrigger.browsePlans,
      );
      return;
    }
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      imageQuality: 85,
    );
    if (file == null || !mounted) {
      return;
    }
    final path = await _mediaStore.persistImage(
      sourcePath: file.path,
      ownerUid: app.uid,
    );
    setState(() {
      _attachments.add(
        _PendingMedia(
          id: _uuid.v4(),
          localPath: path,
          mimeType: 'image/jpeg',
          label: 'Photo',
        ),
      );
      _mode = QuickCaptureMode.photo;
    });
    _bodyFocus.requestFocus();
  }

  Future<void> _addAudio() async {
    final app = AppScope.of(context);
    if (!app.premium) {
      await showPremiumUpgradeSheet(
        context,
        title: 'Voice & audio',
        body: '',
        trigger: PaywallTrigger.voiceRecording,
      );
      return;
    }
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty || !mounted) {
        return;
      }
      final file = result.files.first;
      final sourcePath = file.path;
      if (sourcePath == null || sourcePath.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not read that audio file. Try another.'),
            ),
          );
        }
        return;
      }
      final path = await _mediaStore.persistFile(
        sourcePath: sourcePath,
        ownerUid: app.uid,
        defaultExtension: '.m4a',
      );
      final name = file.name.isEmpty ? 'Voice note' : file.name;
      setState(() {
        _attachments.add(
          _PendingMedia(
            id: _uuid.v4(),
            localPath: path,
            mimeType: file.extension == null
                ? 'audio/*'
                : 'audio/${file.extension}',
            label: name,
          ),
        );
        _mode = QuickCaptureMode.audio;
      });
      _bodyFocus.requestFocus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not add audio: $e')),
        );
      }
    }
  }

  Future<void> _save({bool stepAway = false}) async {
    if (_saving) {
      return;
    }
    final body = _bodyController.text.trim();
    if (body.isEmpty && _attachments.isEmpty) {
      if (stepAway && mounted) {
        context.go('/shell/home');
      }
      return;
    }
    final app = AppScope.of(context);
    final memorial = app.currentMemorial;
    final uid = app.uid;
    if (memorial == null || uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Set up a memorial first.')),
      );
      return;
    }

    setState(() => _saving = true);
    if (_listening) {
      await _stopSpeaking();
    }

    final entryId = _uuid.v4();
    final mediaIds = <String>[];
    try {
      for (final item in _attachments) {
        await app.repository.upsertMedia(
          MediaAttachment(
            id: item.id,
            entryId: entryId,
            ownerUid: uid,
            localPath: item.localPath,
            mimeType: item.mimeType,
            fileName: item.label,
            syncState: SyncState.localOnly,
            createdAt: DateTime.now(),
          ),
        );
        mediaIds.add(item.id);
      }

      final placements = [
        for (var i = 0; i < _attachments.length; i++)
          if (_attachments[i].mimeType.startsWith('image/'))
            {
              'id': _uuid.v4(),
              'mediaId': _attachments[i].id,
              'localPath': _attachments[i].localPath,
              'x': 0.12 + (i % 3) * 0.08,
              'y': 0.14 + (i % 2) * 0.1,
              'scale': 0.34,
            },
      ];

      final isCardinal = _kind == QuickCaptureKind.cardinalVisit;
      final entry = Entry(
        id: entryId,
        memorialId: memorial.id,
        ownerUid: uid,
        type: isCardinal ? EntryType.meaningfulMoment : EntryType.keepsake,
        title: '',
        body: _bodyController.text,
        status: EntryStatus.saved,
        mediaIds: mediaIds,
        extensionJson: {
          if (placements.isNotEmpty) 'placements': placements,
          if (isCardinal) 'template': 'cardinal',
        },
        entryDate: DateTime.now(),
        createdAt: DateTime.now(),
      );

      await app.repository.upsertEntry(entry);
      app.notifyContentChanged();
      // ignore: unawaited_futures
      app.syncService.syncNow(displayName: app.displayName, email: app.email);
      PrivacySafeAnalytics.instance.logEntrySaved(
        type: isCardinal
            ? EntryType.meaningfulMoment.name
            : EntryType.keepsake.name,
      );

      if (!mounted) {
        return;
      }
      if (stepAway) {
        await showEmotionalExitDoor(context, entryId: entryId);
        return;
      }
      if (app.shouldShowFirstSaveSuccess(isDraft: false)) {
        PrivacySafeAnalytics.instance.log('first_entry_saved');
        await app.markFirstSaveSuccessSeen();
        if (!mounted) {
          return;
        }
        if (!app.hasCloudAccount) {
          context.go('/protect-memories');
        } else {
          if (!app.onboardingComplete) {
            await app.completeOnboarding();
          }
          if (mounted) {
            context.go('/first-save-success?entryId=$entryId');
          }
        }
        return;
      }
      if (!app.onboardingComplete) {
        await app.completeOnboarding();
        if (mounted) {
          context.go('/shell/home');
        }
      } else {
        context.pop();
      }
    } on EntryLimitExceeded catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _bodyController.dispose();
    _bodyFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: LettersAppBar(
        title: const Text('Remember something?'),
        intro: 'No title needed. Capture it, then keep going.',
        actions: [
          TextButton(
            onPressed: _saving ? null : () => _save(stepAway: true),
            child: const Text('Step away'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const LocalOnlyMediaBanner(),
              Expanded(
                child: TextField(
                  controller: _bodyController,
                  focusNode: _bodyFocus,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
                  decoration: const InputDecoration(
                    hintText: 'Start typing, speaking, or attach something…',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                  ),
                ),
              ),
              if (_speechStatus != null) ...[
                const SizedBox(height: 4),
                Text(
                  _speechStatus!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _listening
                        ? AppColors.cardinalRed
                        : AppColors.mutedOlive,
                  ),
                ),
              ],
              if (_attachments.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final item in _attachments)
                      InputChip(
                        avatar: Icon(
                          item.mimeType.startsWith('audio/')
                              ? Icons.graphic_eq
                              : Icons.image_outlined,
                          size: 18,
                        ),
                        label: Text(item.label),
                        onDeleted: () {
                          setState(() => _attachments.remove(item));
                        },
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _KindChip(
                    label: 'Quick note',
                    selected: _kind == QuickCaptureKind.note,
                    icon: Icons.edit_note,
                    onTap: () {
                      setState(() => _kind = QuickCaptureKind.note);
                      _bodyFocus.requestFocus();
                    },
                  ),
                  _KindChip(
                    label: 'Cardinal visit',
                    selected: _kind == QuickCaptureKind.cardinalVisit,
                    artwork: ArtworkAssets.cardinal,
                    onTap: () {
                      setState(() => _kind = QuickCaptureKind.cardinalVisit);
                      _bodyFocus.requestFocus();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ModeChip(
                    label: 'Type',
                    icon: Icons.edit_outlined,
                    selected: _mode == QuickCaptureMode.type && !_listening,
                    onTap: () => _setMode(QuickCaptureMode.type),
                  ),
                  _ModeChip(
                    label: _listening ? 'Listening…' : 'Speak',
                    icon: _listening ? Icons.mic : Icons.mic_none,
                    selected: _mode == QuickCaptureMode.speak || _listening,
                    onTap: () {
                      if (_listening) {
                        _stopSpeaking();
                      } else {
                        _setMode(QuickCaptureMode.speak);
                      }
                    },
                  ),
                  _ModeChip(
                    label: 'Add photo',
                    icon: Icons.add_photo_alternate_outlined,
                    selected: _mode == QuickCaptureMode.photo,
                    onTap: () => _setMode(QuickCaptureMode.photo),
                  ),
                  _ModeChip(
                    label: 'Add audio',
                    icon: Icons.audiotrack_outlined,
                    selected: _mode == QuickCaptureMode.audio,
                    onTap: () => _setMode(QuickCaptureMode.audio),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _saving ? null : () => _save(stepAway: true),
                child: const Text(EmotionalExitCopy.buttonLabel),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _saving ? null : () => _save(),
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingMedia {
  const _PendingMedia({
    required this.id,
    required this.localPath,
    required this.mimeType,
    required this.label,
  });

  final String id;
  final String localPath;
  final String mimeType;
  final String label;
}

class _KindChip extends StatelessWidget {
  const _KindChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.artwork,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final String? artwork;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.softBlush : AppColors.parchment,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? AppColors.cardinalRed : AppColors.softBlush,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (artwork != null)
                ArtworkImage(
                  asset: artwork!,
                  height: 18,
                  width: 18,
                  fit: BoxFit.contain,
                )
              else
                Icon(
                  icon ?? Icons.circle_outlined,
                  size: 18,
                  color: AppColors.burgundy,
                ),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.burgundy,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.softBlush : AppColors.parchment,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? AppColors.cardinalRed : AppColors.softBlush,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: AppColors.burgundy),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.burgundy,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
