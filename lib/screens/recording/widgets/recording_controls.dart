import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme.dart';
import '../../../core/constants/strings_tamil.dart';
import '../../../providers/audio_providers.dart';

/// Recording control buttons that change based on [RecordingState].
class RecordingControls extends ConsumerWidget {
  const RecordingControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordingState = ref.watch(recordingNotifierProvider);
    final notifier = ref.read(recordingNotifierProvider.notifier);

    return switch (recordingState) {
      RecordingIdle() => _buildRecordButton(notifier),
      RecordingActive() => _buildActiveControls(notifier),
      RecordingComplete() => _buildCompleteControls(notifier),
      RecordingError(:final message) => _buildErrorControls(notifier, message),
    };
  }

  Widget _buildRecordButton(RecordingNotifier notifier) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: FloatingActionButton(
            heroTag: 'record_btn',
            onPressed: notifier.startRecording,
            backgroundColor: NilamTheme.warmAmber,
            child: const Icon(Icons.mic, size: 36, color: NilamTheme.onSurface),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          TamilStrings.tapToRecord,
          style: TextStyle(
            color: NilamTheme.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildActiveControls(RecordingNotifier notifier) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed: notifier.cancelRecording,
          icon: const Icon(Icons.close),
          label: const Text(TamilStrings.cancel),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(120, 48),
            side: const BorderSide(color: NilamTheme.outline),
          ),
        ),
        const SizedBox(width: 24),
        SizedBox(
          width: 72,
          height: 72,
          child: FloatingActionButton(
            heroTag: 'stop_btn',
            onPressed: notifier.stopRecording,
            backgroundColor: NilamTheme.redPrimary,
            child:
                const Icon(Icons.stop, size: 32, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildCompleteControls(RecordingNotifier notifier) {
    return ElevatedButton.icon(
      onPressed: notifier.reset,
      icon: const Icon(Icons.mic),
      label: const Text(TamilStrings.record),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(160, 48),
      ),
    );
  }

  Widget _buildErrorControls(RecordingNotifier notifier, String message) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message,
          style: const TextStyle(color: NilamTheme.redPrimary, fontSize: 14),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: notifier.reset,
          icon: const Icon(Icons.refresh),
          label: const Text(TamilStrings.retry),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(160, 48),
          ),
        ),
      ],
    );
  }
}
