import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../core/constants/strings_tamil.dart';
import '../../core/logging/logger.dart';
import '../../providers/database_providers.dart';
import '../../services/database/models/query_history.dart';

const String _ratingThumbsUp = 'thumbs_up';
const String _ratingThumbsDown = 'thumbs_down';

/// Displays the saved query, the (eventual) AI response, and rating controls.
///
/// Audio playback is stubbed (Phase 7, see #16). Gemma response field stays
/// null until Phase 6 wires the LLM (#15) — placeholder in the meantime.
class ResponseScreen extends ConsumerWidget {
  const ResponseScreen({required this.queryId, super.key});

  final String queryId;

  static const _tag = 'ResponseScreen';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncQuery = ref.watch(queryByIdProvider(queryId));
    return Scaffold(
      appBar: AppBar(title: const Text(TamilStrings.responseTitle)),
      body: SafeArea(
        child: asyncQuery.when(
          data: (query) {
            if (query == null) {
              return const Center(child: Text(TamilStrings.queryNotFound));
            }
            return _ResponseBody(query: query);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) {
            AppLogger.error('Failed to load query $queryId', _tag, e, st);
            return Center(child: Text(TamilStrings.errorDatabase));
          },
        ),
      ),
    );
  }
}

class _ResponseBody extends ConsumerStatefulWidget {
  const _ResponseBody({required this.query});

  final QueryHistory query;

  @override
  ConsumerState<_ResponseBody> createState() => _ResponseBodyState();
}

class _ResponseBodyState extends ConsumerState<_ResponseBody> {
  static const _tag = 'ResponseScreen';
  bool _saving = false;

  Future<void> _setRating(String tappedRating) async {
    if (_saving) return;
    final current = widget.query.userRating;
    final newRating = current == tappedRating ? null : tappedRating;

    setState(() => _saving = true);
    try {
      final dao = ref.read(queryHistoryDaoProvider);
      final q = widget.query;
      await dao.update(
        QueryHistory(
          id: q.id,
          userId: q.userId,
          timestamp: q.timestamp,
          audioFilePath: q.audioFilePath,
          transcription: q.transcription,
          transcriptionConfidence: q.transcriptionConfidence,
          gemmaPrompt: q.gemmaPrompt,
          gemmaResponse: q.gemmaResponse,
          gemmaLatencyMs: q.gemmaLatencyMs,
          userRating: newRating,
          createdAt: q.createdAt,
          updatedAt: DateTime.now(),
        ),
      );
      ref.invalidate(queryByIdProvider(widget.query.id));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(TamilStrings.ratingSaved)),
      );
    } catch (e, st) {
      AppLogger.error('Failed to save rating', _tag, e, st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(TamilStrings.errorDatabase)),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = widget.query;
    final response = query.gemmaResponse;
    final hasResponse = response != null && response.isNotEmpty;
    final rating = query.userRating;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    TamilStrings.yourQuestion,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    query.transcription,
                    style: theme.textTheme.headlineSmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    TamilStrings.aiResponse,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // TODO(#15): once Phase 6 (#6) wires Gemma, the placeholder
                  // branch goes away — `hasResponse` should always be true.
                  Text(
                    hasResponse ? response : TamilStrings.responsePlaceholder,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontStyle:
                          hasResponse ? FontStyle.normal : FontStyle.italic,
                      color: hasResponse
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _AudioControls(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _RatingButton(
                  label: TamilStrings.helpful,
                  selected: rating == _ratingThumbsUp,
                  onPressed: _saving
                      ? null
                      : () => _setRating(_ratingThumbsUp),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _RatingButton(
                  label: TamilStrings.notHelpful,
                  selected: rating == _ratingThumbsDown,
                  onPressed: _saving
                      ? null
                      : () => _setRating(_ratingThumbsDown),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => context.go('/'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              side: const BorderSide(color: NilamTheme.outline),
            ),
            child: const Text(TamilStrings.goHome),
          ),
        ],
      ),
    );
  }
}

// TODO(#16): Phase 7 (#7) wires real TTS — replace `onPressed: null` with
// play/pause handlers, swap the static "1.0x" label for a Dropdown bound to
// `settingsProvider.ttsSpeed`, and drop the `audioComingSoon` caption.
class _AudioControls extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: TamilStrings.play,
                  onPressed: null,
                  iconSize: 36,
                  icon: const Icon(Icons.play_arrow),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: TamilStrings.stop,
                  onPressed: null,
                  iconSize: 36,
                  icon: const Icon(Icons.pause),
                ),
                const SizedBox(width: 16),
                Text(
                  '${TamilStrings.playSpeed}: 1.0x',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              TamilStrings.audioComingSoon,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingButton extends StatelessWidget {
  const _RatingButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final style = ButtonStyle(
      minimumSize: WidgetStateProperty.all(const Size(double.infinity, 56)),
    );
    return selected
        ? FilledButton(onPressed: onPressed, style: style, child: Text(label))
        : FilledButton.tonal(
            onPressed: onPressed,
            style: style,
            child: Text(label),
          );
  }
}
