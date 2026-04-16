import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';

import '../core/constants/strings_tamil.dart';
import '../core/logging/logger.dart';
import '../services/audio/audio_constants.dart';
import '../services/audio/audio_recording_service.dart';

// -----------------------------------------------------------------------------
// Sealed recording state
// -----------------------------------------------------------------------------

sealed class RecordingState {
  const RecordingState();
}

class RecordingIdle extends RecordingState {
  const RecordingIdle();
}

class RecordingActive extends RecordingState {
  const RecordingActive({
    required this.elapsed,
    required this.amplitudes,
  });

  final Duration elapsed;
  final List<double> amplitudes;
}

class RecordingComplete extends RecordingState {
  const RecordingComplete({
    required this.filePath,
    required this.duration,
    this.qualityWarning,
  });

  final String filePath;
  final Duration duration;
  final String? qualityWarning;
}

class RecordingError extends RecordingState {
  const RecordingError({required this.message});

  final String message;
}

// -----------------------------------------------------------------------------
// Providers
// -----------------------------------------------------------------------------

final audioRecordingServiceProvider = Provider<AudioRecordingService>((ref) {
  final service = AudioRecordingService(AudioRecorder());
  ref.onDispose(() => service.dispose());
  return service;
});

final recordingNotifierProvider =
    NotifierProvider<RecordingNotifier, RecordingState>(
  RecordingNotifier.new,
);

// -----------------------------------------------------------------------------
// Notifier
// -----------------------------------------------------------------------------

class RecordingNotifier extends Notifier<RecordingState> {
  static const _tag = 'RecordingNotifier';

  Timer? _elapsedTimer;
  StreamSubscription<Amplitude>? _amplitudeSub;
  final List<double> _amplitudes = [];

  @override
  RecordingState build() => const RecordingIdle();

  AudioRecordingService get _service =>
      ref.read(audioRecordingServiceProvider);

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> startRecording() async {
    try {
      final granted = await _service.checkPermission();
      if (!granted) {
        state = const RecordingError(message: TamilStrings.micPermissionNeeded);
        return;
      }

      await _service.startRecording();

      _service.onAutoStop = _handleAutoStop;

      _amplitudes.clear();
      _amplitudeSub = _service.amplitudeStream.listen(_onAmplitude);

      _elapsedTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => _updateElapsed(),
      );

      state = RecordingActive(
        elapsed: Duration.zero,
        amplitudes: List.unmodifiable(_amplitudes),
      );

      AppLogger.info('Recording started', _tag);
    } catch (e, st) {
      AppLogger.error('Start recording failed', _tag, e, st);
      state = RecordingError(message: TamilStrings.errorRecordingFailed);
    }
  }

  Future<void> stopRecording() async {
    try {
      _cancelTimers();
      final elapsed = _service.elapsed;
      final filePath = await _service.stopRecording();
      final warning = _resolveQualityWarning(_service.qualityWarning);

      state = RecordingComplete(
        filePath: filePath,
        duration: elapsed,
        qualityWarning: warning,
      );

      AppLogger.info('Recording complete: $filePath (${elapsed.inSeconds}s)', _tag);
    } catch (e, st) {
      AppLogger.error('Stop recording failed', _tag, e, st);
      state = RecordingError(message: TamilStrings.errorRecordingFailed);
    }
  }

  Future<void> cancelRecording() async {
    _cancelTimers();
    await _service.cancelRecording();
    state = const RecordingIdle();
    AppLogger.info('Recording cancelled by user', _tag);
  }

  void reset() {
    _cancelTimers();
    state = const RecordingIdle();
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  void _onAmplitude(Amplitude amplitude) {
    final normalized =
        AudioRecordingService.normalizeAmplitude(amplitude.current);

    _amplitudes.add(normalized);
    if (_amplitudes.length > AudioConstants.maxAmplitudeSamples) {
      _amplitudes.removeAt(0);
    }

    _service.addAmplitudeSample(amplitude.current);

    state = RecordingActive(
      elapsed: _service.elapsed,
      amplitudes: List.unmodifiable(_amplitudes),
    );
  }

  void _updateElapsed() {
    final current = state;
    if (current is RecordingActive) {
      state = RecordingActive(
        elapsed: _service.elapsed,
        amplitudes: current.amplitudes,
      );
    }
  }

  void _handleAutoStop() {
    AppLogger.info('Auto-stop triggered at max duration', _tag);
    stopRecording();
  }

  void _cancelTimers() {
    _elapsedTimer?.cancel();
    _elapsedTimer = null;
    _amplitudeSub?.cancel();
    _amplitudeSub = null;
  }

  String? _resolveQualityWarning(String? quality) {
    if (quality == null) return null;
    return switch (quality) {
      'too_quiet' => TamilStrings.warningTooQuiet,
      'clipping' => TamilStrings.warningClipping,
      _ => null,
    };
  }
}
