import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_scope.dart';
import '../../core/theme/artwork_assets.dart';
import '../../core/theme/artwork_image.dart';
import '../../core/theme/letters_app_bar.dart';
import '../../core/utils/entry_helpers.dart';
import '../../data/models/models.dart';

/// @deprecated Prefer [LibraryScreen] with Meaningful Moment filter.
class SignsScreen extends StatefulWidget {
  const SignsScreen({super.key});

  @override
  State<SignsScreen> createState() => _SignsScreenState();
}

class _SignsScreenState extends State<SignsScreen> {
  static const _types = {EntryType.meaningfulMoment};
  List<Entry> _entries = [];
  bool _loading = true;
  AppState? _app;
  int _lastEpoch = -1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = AppScope.of(context);
    if (!identical(_app, app)) {
      _app?.removeListener(_onAppChanged);
      _app = app;
      _app!.addListener(_onAppChanged);
    }
    _refresh();
  }

  @override
  void dispose() {
    _app?.removeListener(_onAppChanged);
    super.dispose();
  }

  void _onAppChanged() {
    if (!mounted || _app == null) {
      return;
    }
    if (_app!.contentEpoch != _lastEpoch) {
      _refresh();
    }
  }

  Future<void> _refresh() async {
    final app = _app ?? AppScope.of(context);
    _lastEpoch = app.contentEpoch;
    final memorial = app.currentMemorial;
    if (memorial == null) {
      if (mounted) {
        setState(() {
          _entries = [];
          _loading = false;
        });
      }
      return;
    }
    final all = await app.repository.listEntries(memorialId: memorial.id);
    if (!mounted) {
      return;
    }
    setState(() {
      _entries = all.where((e) => _types.contains(e.type)).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const LettersAppBar(
        title: Text('Meaningful Moments'),
        intro: 'Dreams, cardinals, songs, and moments that felt meaningful.',
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: _entries.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 48),
                        Center(
                          child: ArtworkImage(
                            asset: ArtworkAssets.dogwood,
                            height: 140,
                            fit: BoxFit.contain,
                          ),
                        ),
                        SizedBox(height: 16),
                        Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              'Nothing Here Yet. Add Something When You\'re Ready.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      itemCount: _entries.length,
                      itemBuilder: (context, index) {
                        final e = _entries[index];
                        return ListTile(
                          title: Text(
                            e.title.isEmpty
                                ? entryTypeLabel(e.type)
                                : e.title,
                          ),
                          subtitle: Text(entryTypeLabel(e.type)),
                          onTap: () => context.push('/entry/${e.id}'),
                        );
                      },
                    ),
            ),
    );
  }
}
