import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/strings_tamil.dart';
import '../../core/utils/relative_time.dart';
import '../../providers/database_providers.dart';
import '../../providers/user_providers.dart';
import '../../services/database/models/query_history.dart';

/// App entry screen — large CTA to ask a new question and a list of the
/// 5 most recent past queries.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final asyncUserId = ref.watch(currentUserIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(TamilStrings.homeTitle),
        actions: [
          IconButton(
            tooltip: TamilStrings.history,
            onPressed: () => context.push('/history'),
            icon: const Icon(Icons.history),
          ),
          IconButton(
            tooltip: TamilStrings.settings,
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                TamilStrings.appTagline,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 72,
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/record'),
                  icon: const Icon(Icons.mic, size: 28),
                  label: const Text(
                    TamilStrings.askQuestionCta,
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                TamilStrings.recentQuestions,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: asyncUserId.when(
                  data: (userId) => _RecentList(userId: userId),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) =>
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

class _RecentList extends ConsumerWidget {
  const _RecentList({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncRecent = ref.watch(recentQueriesProvider(userId));
    return asyncRecent.when(
      data: (queries) {
        if (queries.isEmpty) return const _EmptyRecent();
        return ListView.separated(
          itemCount: queries.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (_, i) => _QueryTile(query: queries[i]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(TamilStrings.errorDatabase)),
    );
  }
}

class _EmptyRecent extends StatelessWidget {
  const _EmptyRecent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.agriculture,
            size: 56,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            TamilStrings.noRecentQuestions,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _QueryTile extends StatelessWidget {
  const _QueryTile({required this.query});

  final QueryHistory query;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        query.transcription,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(formatRelativeTamil(query.timestamp)),
      trailing: _ratingIcon(query.userRating),
      onTap: () => context.push('/response/${query.id}'),
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
