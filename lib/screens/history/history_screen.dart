import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/strings_tamil.dart';
import '../../core/utils/relative_time.dart';
import '../../providers/database_providers.dart';
import '../../providers/user_providers.dart';
import '../../services/database/models/query_history.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String? _keyword;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _keyword = value.trim().isEmpty ? null : value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final asyncUserId = ref.watch(currentUserIdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(TamilStrings.historyTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: TamilStrings.searchHint,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: TamilStrings.cancel,
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: asyncUserId.when(
                  data: (userId) =>
                      _HistoryList(userId: userId, keyword: _keyword),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) =>
                      Center(child: Text(TamilStrings.errorDatabase)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryList extends ConsumerWidget {
  const _HistoryList({required this.userId, required this.keyword});

  final String userId;
  final String? keyword;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = HistoryQuery(userId: userId, keyword: keyword);
    final asyncQueries = ref.watch(historyQueriesProvider(query));

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(historyQueriesProvider(query)),
      child: asyncQueries.when(
        data: (queries) {
          if (queries.isEmpty) return const _EmptyHistory();
          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: queries.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, i) => _HistoryTile(
              query: queries[i],
              onDeleted: () =>
                  ref.invalidate(historyQueriesProvider(query)),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(TamilStrings.errorDatabase)),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: Center(
            child: Text(
              TamilStrings.historyEmpty,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HistoryTile extends ConsumerWidget {
  const _HistoryTile({required this.query, required this.onDeleted});

  final QueryHistory query;
  final VoidCallback onDeleted;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(TamilStrings.deleteConfirmTitle),
        content: const Text(TamilStrings.deleteConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(TamilStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(TamilStrings.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(queryHistoryDaoProvider).delete(query.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(TamilStrings.deleted)),
    );
    onDeleted();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      onLongPressHint: TamilStrings.delete,
      child: ListTile(
        title: Text(
          query.transcription,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(formatRelativeTamil(query.timestamp)),
        trailing: _ratingIcon(query.userRating),
        onTap: () => context.push('/response/${query.id}'),
        onLongPress: () => _confirmDelete(context, ref),
      ),
    );
  }

  Widget? _ratingIcon(String? rating) {
    if (rating == 'thumbs_up') {
      return const Icon(Icons.thumb_up, size: 20);
    }
    if (rating == 'thumbs_down') {
      return const Icon(Icons.thumb_down, size: 20);
    }
    return null;
  }
}
