import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/analytics/analytics.dart';
import '../../core/state/app_scope.dart';
import '../../core/theme/letters_app_bar.dart';
import '../../core/utils/entry_helpers.dart';
import '../../data/models/models.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  List<Entry> _results = [];
  bool _searched = false;

  Future<void> _runSearch() async {
    final query = _controller.text.trim();
    if (query.isEmpty) {
      return;
    }
    PrivacySafeAnalytics.instance.log('search_performed');
    final memorial = AppScope.of(context).currentMemorial;
    final results = await AppScope.of(context).repository.searchEntries(
          query: query,
          memorialId: memorial?.id,
        );
    setState(() {
      _results = results;
      _searched = true;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const LettersAppBar(
        title: Text('Search'),
        intro: 'Find words across your journal and memories.',
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Search titles and entries',
                    ),
                    onSubmitted: (_) => _runSearch(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _runSearch,
                ),
              ],
            ),
          ),
          Expanded(
            child: !_searched
                ? const Center(child: Text('Search your journal'))
                : _results.isEmpty
                    ? const Center(child: Text('No matches'))
                    : ListView.builder(
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final e = _results[index];
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
        ],
      ),
    );
  }
}
