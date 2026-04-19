import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../core/constants/strings_tamil.dart';
import '../../providers/stt_providers.dart';

/// Progress screen shown while whisper.cpp transcribes the recorded audio.
///
/// Kicks off the transcription in [initState] and auto-navigates to the
/// review screen on success. Shows a Tamil error + retry on failure.
class TranscribingScreen extends ConsumerStatefulWidget {
  const TranscribingScreen({required this.audioPath, super.key});

  final String audioPath;

  @override
  ConsumerState<TranscribingScreen> createState() => _TranscribingScreenState();
}

class _TranscribingScreenState extends ConsumerState<TranscribingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  void _start() {
    ref.read(sttNotifierProvider.notifier).transcribe(widget.audioPath);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<SttState>(sttNotifierProvider, (_, next) {
      if (next is SttComplete) {
        final uri = Uri(
          path: '/review',
          queryParameters: {
            'audioPath': next.audioPath,
            'text': next.text,
          },
        );
        context.go(uri.toString());
      }
    });

    final state = ref.watch(sttNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(TamilStrings.sttTranscribing)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(child: _buildBody(state)),
        ),
      ),
    );
  }

  Widget _buildBody(SttState state) {
    return switch (state) {
      SttIdle() || SttLoadingModel() => const _Loading(
          label: TamilStrings.sttModelLoading,
        ),
      SttTranscribing() => const _Loading(
          label: TamilStrings.sttTranscribing,
        ),
      SttComplete() => const _Loading(
          label: TamilStrings.sttTranscribing,
        ),
      SttError(:final code, :final message) =>
        _Error(code: code, message: message, onRetry: _start),
    };
  }
}

class _Loading extends StatelessWidget {
  const _Loading({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 64,
          height: 64,
          child: CircularProgressIndicator(
            strokeWidth: 4,
            color: NilamTheme.primaryGreen,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          label,
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({
    required this.code,
    required this.message,
    required this.onRetry,
  });

  final String code;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final friendly = _friendlyMessage(code);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline,
            size: 64, color: NilamTheme.redPrimary),
        const SizedBox(height: 16),
        Text(
          friendly,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: NilamTheme.redPrimary,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          '[$code] $message',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: NilamTheme.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: () => context.go('/record'),
              icon: const Icon(Icons.arrow_back),
              label: const Text(TamilStrings.retake),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text(TamilStrings.retry),
            ),
          ],
        ),
      ],
    );
  }

  static String _friendlyMessage(String code) {
    return switch (code) {
      'E006' => TamilStrings.errorSttModelMissing,
      'E007' => TamilStrings.errorSttFailed,
      'E008' => TamilStrings.errorSttLowConfidence,
      _ => TamilStrings.errorSttFailed,
    };
  }
}
