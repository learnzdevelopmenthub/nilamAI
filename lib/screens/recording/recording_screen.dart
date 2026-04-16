import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme.dart';
import '../../core/constants/strings_tamil.dart';
import '../../providers/audio_providers.dart';
import 'widgets/recording_controls.dart';
import 'widgets/recording_timer.dart';
import 'widgets/waveform_painter.dart';

/// Main recording screen with waveform, timer, and controls.
///
/// Auto-stops recording if app goes to background.
class RecordingScreen extends ConsumerStatefulWidget {
  const RecordingScreen({super.key});

  @override
  ConsumerState<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends ConsumerState<RecordingScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      final recordingState = ref.read(recordingNotifierProvider);
      if (recordingState is RecordingActive) {
        ref.read(recordingNotifierProvider.notifier).stopRecording();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final recordingState = ref.watch(recordingNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(TamilStrings.recordingTitle),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              _buildWaveform(recordingState),
              const SizedBox(height: 16),
              _buildTimer(recordingState),
              const SizedBox(height: 16),
              _buildStatusText(recordingState),
              _buildQualityWarning(recordingState),
              const Spacer(flex: 3),
              const RecordingControls(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWaveform(RecordingState recordingState) {
    final amplitudes = switch (recordingState) {
      RecordingActive(:final amplitudes) => amplitudes,
      _ => const <double>[],
    };

    return RepaintBoundary(
      child: SizedBox(
        height: 200,
        width: double.infinity,
        child: CustomPaint(
          painter: WaveformPainter(
            amplitudes: amplitudes,
            barColor: NilamTheme.primaryGreen,
          ),
        ),
      ),
    );
  }

  Widget _buildTimer(RecordingState recordingState) {
    final elapsed = switch (recordingState) {
      RecordingActive(:final elapsed) => elapsed,
      RecordingComplete(:final duration) => duration,
      _ => Duration.zero,
    };

    return RecordingTimer(elapsed: elapsed);
  }

  Widget _buildStatusText(RecordingState recordingState) {
    final (text, color) = switch (recordingState) {
      RecordingIdle() => (TamilStrings.tapToRecord, NilamTheme.onSurfaceVariant),
      RecordingActive() => (TamilStrings.recordingActive, NilamTheme.primaryGreen),
      RecordingComplete() => (TamilStrings.recordingComplete, NilamTheme.primaryGreen),
      RecordingError(:final message) => (message, NilamTheme.redPrimary),
    };

    return Text(
      text,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: color),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildQualityWarning(RecordingState recordingState) {
    if (recordingState is! RecordingComplete ||
        recordingState.qualityWarning == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.warning_amber, color: NilamTheme.warmAmber, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              recordingState.qualityWarning!,
              style: const TextStyle(
                color: NilamTheme.warmAmber,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
