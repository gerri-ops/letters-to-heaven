import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

import '../../core/analytics/analytics.dart';
import '../../core/billing/premium_upgrade_sheet.dart';
import '../../core/billing/trust_paywall_copy.dart';
import '../../core/media/local_media_store.dart';
import '../../core/media/local_only_media_banner.dart';
import '../../core/state/app_scope.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/letters_app_bar.dart';
import '../../data/models/models.dart';
import '../../data/repositories/app_repository.dart';
import '../entries/emotional_exit_door.dart';
import '../shell/letters_back_or_home_button.dart';
import 'voice_keepsake_models.dart';

class VoiceKeepsakeEditorScreen extends StatefulWidget {
  const VoiceKeepsakeEditorScreen({super.key, this.entryId});

  final String? entryId;

  @override
  State<VoiceKeepsakeEditorScreen> createState() =>
      _VoiceKeepsakeEditorScreenState();
}

class _VoiceKeepsakeEditorScreenState extends State<VoiceKeepsakeEditorScreen> {
  final _titleController = TextEditingController();
  final _contextController = TextEditingController();
  final _speakerController = TextEditingController();
  final _periodController = TextEditingController();
  final _transcriptController = TextEditingController();
  final _mediaStore = LocalMediaStore();
  final _recorder = AudioRecorder();
  static const _uuid = Uuid();

  bool _loading = true;
  bool _saving = false;
  bool _recording = false;
  String? _existingId;
  DateTime? _createdAt;
  DateTime? _clipDate;
  String? _sourceKind;
  String? _mediaPath;
  String? _mediaId;
  String? _mimeType;
  String? _fileLabel;
  bool _hiddenFromHome = false;
  DateTime? _privateReturnDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final app = AppScope.of(context);
    if (!app.premium) {
      if (mounted) {
        await showPremiumUpgradeSheet(
          context,
          title: '',
          body: '',
          trigger: PaywallTrigger.voiceRecording,
        );
        if (mounted) {
          context.go('/voice-keepsakes');
        }
      }
      return;
    }
    if (widget.entryId != null) {
      final entry = await app.repository.getEntryById(widget.entryId!);
      if (entry != null && mounted) {
        _existingId = entry.id;
        _createdAt = entry.createdAt;
        _titleController.text = entry.title;
        _contextController.text = entry.body;
        _speakerController.text = voiceSpeaker(entry) ?? '';
        _periodController.text = voiceTimePeriod(entry) ?? '';
        _transcriptController.text = voiceTranscript(entry) ?? '';
        _sourceKind = voiceSourceKind(entry);
        _clipDate = entry.entryDate;
        _hiddenFromHome = entry.hiddenFromHome;
        _privateReturnDate = entry.privateReturnDate;
        final media = await app.repository.listMediaForEntry(entry.id);
        if (media.isNotEmpty) {
          _mediaId = media.first.id;
          _mediaPath = media.first.localPath;
          _mimeType = media.first.mimeType;
          _fileLabel = media.first.fileName ?? 'Attached clip';
        }
      }
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _startRecording() async {
    try {
      if (!await _recorder.hasPermission()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Microphone permission is needed to record.'),
            ),
          );
        }
        return;
      }
      String path;
      if (kIsWeb) {
        path = '';
      } else {
        final dir = await getTemporaryDirectory();
        path = p.join(dir.path, 'voice_${_uuid.v4()}.m4a');
      }
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );
      setState(() {
        _recording = true;
        _sourceKind = 'record';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Recording is not available here. Upload a voice memo instead. ($e)',
            ),
          ),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _recorder.stop();
      if (path == null || path.isEmpty) {
        if (mounted) setState(() => _recording = false);
        return;
      }
      if (!mounted) return;
      final app = AppScope.of(context);
      final persisted = await _mediaStore.persistFile(
        sourcePath: path,
        ownerUid: app.uid,
        defaultExtension: '.m4a',
      );
      if (!mounted) return;
      setState(() {
        _recording = false;
        _mediaPath = persisted;
        _mediaId = _uuid.v4();
        _mimeType = 'audio/mp4';
        _fileLabel = 'Recording';
        _sourceKind = 'record';
      });
    } catch (e) {
      if (mounted) {
        setState(() => _recording = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save recording: $e')),
        );
      }
    }
  }

  Future<void> _pickAudio() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty || !mounted) {
        return;
      }
      final file = result.files.first;
      final source = file.path;
      if (source == null || source.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read that audio file.')),
        );
        return;
      }
      final app = AppScope.of(context);
      final persisted = await _mediaStore.persistFile(
        sourcePath: source,
        ownerUid: app.uid,
        defaultExtension: '.m4a',
      );
      setState(() {
        _mediaPath = persisted;
        _mediaId = _uuid.v4();
        _mimeType = file.extension == null ? 'audio/*' : 'audio/${file.extension}';
        _fileLabel = file.name.isEmpty ? 'Audio clip' : file.name;
        _sourceKind = 'upload';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not add audio: $e')),
        );
      }
    }
  }

  Future<void> _pickVideo() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty || !mounted) {
        return;
      }
      final file = result.files.first;
      final source = file.path;
      if (source == null || source.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read that video file.')),
        );
        return;
      }
      final app = AppScope.of(context);
      final persisted = await _mediaStore.persistFile(
        sourcePath: source,
        ownerUid: app.uid,
        defaultExtension: '.mp4',
      );
      setState(() {
        _mediaPath = persisted;
        _mediaId = _uuid.v4();
        _mimeType = file.extension == null ? 'video/*' : 'video/${file.extension}';
        _fileLabel = file.name.isEmpty ? 'Video with voice' : file.name;
        _sourceKind = 'video';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not add video: $e')),
        );
      }
    }
  }

  Future<void> _pickClipDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _clipDate ?? now,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null && mounted) {
      setState(() => _clipDate = picked);
    }
  }

  Future<void> _save({bool stepAway = false}) async {
    if (_saving) {
      return;
    }
    final app = AppScope.of(context);
    if (!app.premium) {
      await showPremiumUpgradeSheet(
        context,
        title: '',
        body: '',
        trigger: PaywallTrigger.voiceRecording,
      );
      return;
    }
    final memorial = app.currentMemorial;
    final uid = app.uid;
    if (memorial == null || uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Set up who you are remembering first.')),
      );
      return;
    }
    if (_mediaPath == null &&
        _contextController.text.trim().isEmpty &&
        _transcriptController.text.trim().isEmpty) {
      if (stepAway && mounted) {
        context.go('/shell/home');
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a clip, a short note, or a transcript to save.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    final entryId = _existingId ?? _uuid.v4();
    final mediaIds = <String>[];
    try {
      if (_mediaPath != null) {
        final id = _mediaId ?? _uuid.v4();
        await app.repository.upsertMedia(
          MediaAttachment(
            id: id,
            entryId: entryId,
            ownerUid: uid,
            localPath: _mediaPath!,
            mimeType: _mimeType ?? 'audio/*',
            fileName: _fileLabel,
            syncState: SyncState.localOnly,
            createdAt: DateTime.now(),
          ),
        );
        mediaIds.add(id);
        _mediaId = id;
      }

      final entry = Entry(
        id: entryId,
        memorialId: memorial.id,
        ownerUid: uid,
        type: EntryType.keepsake,
        title: _titleController.text.trim(),
        body: _contextController.text,
        status: EntryStatus.saved,
        mediaIds: mediaIds,
        extensionJson: {
          'template': voiceKeepsakeTemplateId,
          if (_speakerController.text.trim().isNotEmpty)
            'speaker': _speakerController.text.trim(),
          if (_periodController.text.trim().isNotEmpty)
            'timePeriod': _periodController.text.trim(),
          if (_transcriptController.text.trim().isNotEmpty)
            'transcript': _transcriptController.text.trim(),
          if (_sourceKind != null) 'sourceKind': _sourceKind,
          'includeAudioQr': true,
        },
        entryDate: _clipDate ?? DateTime.now(),
        createdAt: _createdAt ?? DateTime.now(),
        hiddenFromHome: _hiddenFromHome,
        privateReturnDate: _privateReturnDate,
      );
      await app.repository.upsertEntry(entry);
      app.notifyContentChanged();
      // ignore: unawaited_futures
      app.syncService.syncNow(displayName: app.displayName, email: app.email);
      PrivacySafeAnalytics.instance.logEntrySaved(type: 'voice_keepsake');
      if (mounted) {
        if (stepAway) {
          await showEmotionalExitDoor(context, entryId: entryId);
        } else {
          context.go('/voice-keepsakes');
        }
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
    unawaited(_recorder.dispose());
    _titleController.dispose();
    _contextController.dispose();
    _speakerController.dispose();
    _periodController.dispose();
    _transcriptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        appBar: LettersAppBar(
          title: Text('Voice Keepsakes'),
          leading: LettersBackOrHomeButton(
            fallbackLocation: '/voice-keepsakes',
          ),
          automaticallyImplyLeading: false,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final theme = Theme.of(context);
    return Scaffold(
      appBar: LettersAppBar(
        title: Text(widget.entryId == null ? 'New voice keepsake' : 'Edit voice keepsake'),
        intro: voicePremiumHero,
        leading: const LettersBackOrHomeButton(
          fallbackLocation: '/voice-keepsakes',
        ),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: _saving ? null : () => _save(stepAway: true),
            child: const Text('Step away'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const LocalOnlyMediaBanner(),
          Text(
            voiceNoCloneDisclaimer,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.mutedOlive,
            ),
          ),
          const SizedBox(height: 16),
          Text('Capture', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: _recording ? _stopRecording : _startRecording,
                icon: Icon(_recording ? Icons.stop : Icons.mic),
                label: Text(_recording ? 'Stop recording' : 'Record myself'),
              ),
              OutlinedButton.icon(
                onPressed: _pickAudio,
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload audio'),
              ),
              OutlinedButton.icon(
                onPressed: _pickVideo,
                icon: const Icon(Icons.videocam_outlined),
                label: const Text('Import short video'),
              ),
            ],
          ),
          if (_fileLabel != null) ...[
            const SizedBox(height: 12),
            InputChip(
              avatar: Icon(
                (_mimeType ?? '').startsWith('video/')
                    ? Icons.videocam_outlined
                    : Icons.graphic_eq,
                size: 18,
              ),
              label: Text(_fileLabel!),
              onDeleted: () {
                setState(() {
                  _fileLabel = null;
                  _mediaPath = null;
                  _mediaId = null;
                  _mimeType = null;
                });
              },
            ),
          ],
          const SizedBox(height: 20),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title (optional)',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contextController,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Context about this clip',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _speakerController,
            decoration: const InputDecoration(
              labelText: 'Who is speaking',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _periodController,
            decoration: const InputDecoration(
              labelText: 'Date or estimated time period',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _transcriptController,
            minLines: 3,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: 'Written transcript',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              _clipDate == null
                  ? 'Add a date for this clip'
                  : MaterialLocalizations.of(context)
                      .formatMediumDate(_clipDate!),
            ),
            trailing: const Icon(Icons.calendar_today),
            onTap: _pickClipDate,
          ),
          const SizedBox(height: 8),
          Text(
            'In a private PDF export, a QR code can link to the audio when '
            'durable private access is available.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.mutedOlive,
            ),
          ),
          const SizedBox(height: 20),
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
    );
  }
}
