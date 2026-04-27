import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../core/constants/strings_tamil.dart';
import '../../core/logging/logger.dart';
import '../../providers/database_providers.dart';
import '../../providers/feature_providers.dart';
import '../../providers/llm_providers.dart';
import '../../providers/settings_providers.dart';
import '../../services/database/models/query_history.dart';
import '../../services/llm/gemma_service.dart';

const String _ratingThumbsUp = 'thumbs_up';
const String _ratingThumbsDown = 'thumbs_down';

/// Displays the saved query, the AI response, and rating controls.
///
/// Audio playback is stubbed (Phase 7, see #16). The AI response area watches
/// [gemmaNotifierProvider] for loading/complete/error states and persists the
/// result to [QueryHistory] via [queryHistoryDaoProvider] on completion.
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Clear any stale terminal state left behind by a prior query. An
      // in-progress LoadingModel/Generating is preserved so a fresh kickoff
      // from TranscriptionReview still drives the UI.
      final state = ref.read(gemmaNotifierProvider);
      if (state is GemmaComplete || state is GemmaError) {
        ref.read(gemmaNotifierProvider.notifier).reset();
      }
    });
  }

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

  Future<void> _persistGemma(GemmaResponse response) async {
    try {
      final dao = ref.read(queryHistoryDaoProvider);
      await dao.update(
        widget.query.copyWith(
          gemmaPrompt: response.prompt,
          gemmaResponse: response.text,
          gemmaLatencyMs: response.latencyMs,
          updatedAt: DateTime.now(),
        ),
      );
      ref.invalidate(queryByIdProvider(widget.query.id));
    } catch (e, st) {
      AppLogger.error('Failed to persist Gemma response', _tag, e, st);
    }
  }

  void _regenerate() {
    final notifier = ref.read(gemmaNotifierProvider.notifier);
    notifier.reset();
    unawaited(() async {
      final profile = await ref.read(userProfileDaoProvider).getCurrent();
      await notifier.generate(
        query: widget.query.transcription,
        cropType: profile?.primaryCrop,
      );
    }());
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<GemmaState>(gemmaNotifierProvider, (_, next) async {
      if (next is! GemmaComplete) return;
      if (widget.query.gemmaResponse != null &&
          widget.query.gemmaResponse!.isNotEmpty) {
        return;
      }
      await _persistGemma(next.response);
      if (!mounted) return;
      ref.read(gemmaNotifierProvider.notifier).reset();
    });

    final theme = Theme.of(context);
    final query = widget.query;
    final stored = query.gemmaResponse;
    final hasStored = stored != null && stored.isNotEmpty;
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
                  if (hasStored)
                    Text(
                      stored,
                      style: theme.textTheme.bodyLarge,
                    )
                  else
                    _GemmaStateView(onRetry: _regenerate),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _AudioControls(textToSpeak: hasStored ? stored : null),
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

/// Renders the current Gemma pipeline state inside the AI-response card.
///
/// Only used when [QueryHistory.gemmaResponse] is null/empty — stored DB
/// responses take precedence over the notifier state (see
/// [_ResponseBodyState.build]).
class _GemmaStateView extends ConsumerWidget {
  const _GemmaStateView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gemmaNotifierProvider);
    final theme = Theme.of(context);
    return switch (state) {
      GemmaIdle() => _GemmaIdle(onGenerate: onRetry),
      GemmaLoadingModel() =>
        const _GemmaLoading(label: TamilStrings.gemmaLoadingModel),
      GemmaGenerating() =>
        const _GemmaLoading(label: TamilStrings.gemmaGenerating),
      GemmaComplete(:final response) => Text(
          response.text,
          style: theme.textTheme.bodyLarge,
        ),
      GemmaError(:final code, :final message) =>
        _GemmaError(code: code, message: message, onRetry: onRetry),
    };
  }
}

/// Idle view for rows without a stored response. Used for history entries
/// created before Gemma was wired up — the user taps the button to trigger
/// generation on-demand rather than auto-running it on open.
class _GemmaIdle extends StatelessWidget {
  const _GemmaIdle({required this.onGenerate});
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          TamilStrings.responsePlaceholder,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontStyle: FontStyle.italic,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.tonalIcon(
            onPressed: onGenerate,
            icon: const Icon(Icons.auto_awesome),
            label: const Text(TamilStrings.gemmaGenerateAnswer),
          ),
        ),
      ],
    );
  }
}

class _GemmaLoading extends StatelessWidget {
  const _GemmaLoading({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: NilamTheme.primaryGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      ],
    );
  }
}

class _GemmaError extends StatelessWidget {
  const _GemmaError({
    required this.code,
    required this.message,
    required this.onRetry,
  });

  final String code;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.error_outline, color: NilamTheme.redPrimary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                TamilStrings.gemmaError,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: NilamTheme.redPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '[$code] $message',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text(TamilStrings.retry),
          ),
        ),
      ],
    );
  }
}

/// TTS controls bound to [ttsServiceProvider] and [settingsProvider]. Play
/// is disabled until [textToSpeak] is non-empty (i.e. a stored response is
/// available). Stop disposes the in-flight utterance.
class _AudioControls extends ConsumerStatefulWidget {
  const _AudioControls({required this.textToSpeak});

  final String? textToSpeak;

  @override
  ConsumerState<_AudioControls> createState() => _AudioControlsState();
}

class _AudioControlsState extends ConsumerState<_AudioControls> {
  bool _speaking = false;

  Future<void> _speak() async {
    final text = widget.textToSpeak;
    if (text == null || text.trim().isEmpty || _speaking) return;
    final tts = ref.read(ttsServiceProvider);
    final speed = ref.read(settingsProvider).ttsSpeed;
    setState(() => _speaking = true);
    try {
      await tts.speak(text, speed: speed);
    } finally {
      if (mounted) setState(() => _speaking = false);
    }
  }

  Future<void> _stop() async {
    final tts = ref.read(ttsServiceProvider);
    await tts.stop();
    if (mounted) setState(() => _speaking = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final speed = ref.watch(settingsProvider).ttsSpeed;
    final canPlay =
        (widget.textToSpeak ?? '').trim().isNotEmpty && !_speaking;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: TamilStrings.play,
              onPressed: canPlay ? _speak : null,
              iconSize: 36,
              icon: const Icon(Icons.play_arrow),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: TamilStrings.stop,
              onPressed: _speaking ? _stop : null,
              iconSize: 36,
              icon: const Icon(Icons.stop),
            ),
            const SizedBox(width: 16),
            Text(
              '${TamilStrings.playSpeed}: ${speed.toStringAsFixed(1)}x',
              style: theme.textTheme.bodyMedium?.copyWith(
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
