import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../core/exceptions/app_exception.dart';
import '../../core/logging/logger.dart';
import 'audio_constants.dart';

/// Core audio recording service wrapping the `record` package.
///
/// Captures PCM 16-bit, 16 kHz, mono WAV for Whisper STT ingestion.
class AudioRecordingService {
  AudioRecordingService(this._recorder);

  static const _tag = 'AudioRecordingService';

  final AudioRecorder _recorder;
  Timer? _maxDurationTimer;
  DateTime? _startTime;
  String? _currentFilePath;

  final List<double> _rawAmplitudes = [];

  /// Callback invoked when max duration auto-stop triggers.
  void Function()? onAutoStop;

  // ---------------------------------------------------------------------------
  // Permission
  // ---------------------------------------------------------------------------

  Future<bool> checkPermission() async {
    try {
      final granted = await _recorder.hasPermission();
      AppLogger.debug(
        'Microphone permission ${granted ? "granted" : "denied"}',
        _tag,
      );
      return granted;
    } catch (e, st) {
      AppLogger.error('Permission check failed', _tag, e, st);
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Recording lifecycle
  // ---------------------------------------------------------------------------

  Future<void> startRecording() async {
    try {
      final supported =
          await _recorder.isEncoderSupported(AudioEncoder.wav);
      if (!supported) {
        throw const AudioException(
          message: 'WAV encoder not supported on this device',
        );
      }

      final dir = await _audioDirectory();
      _currentFilePath = generateFilePath(dir, DateTime.now());

      const config = RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: AudioConstants.sampleRate,
        numChannels: AudioConstants.numChannels,
        bitRate: AudioConstants.bitRate,
        autoGain: true,
        noiseSuppress: true,
      );

      await _recorder.start(config, path: _currentFilePath!);
      _startTime = DateTime.now();
      _rawAmplitudes.clear();

      _maxDurationTimer = Timer(
        const Duration(seconds: AudioConstants.maxDurationSeconds),
        _onMaxDuration,
      );

      AppLogger.info('Recording started: $_currentFilePath', _tag);
    } catch (e, st) {
      _cleanup();
      if (e is AudioException) rethrow;
      AppLogger.error('Start recording failed', _tag, e, st);
      throw AudioException(message: 'Recording failed to start', originalError: e);
    }
  }

  Future<String> stopRecording() async {
    try {
      _maxDurationTimer?.cancel();
      _maxDurationTimer = null;

      final path = await _recorder.stop();
      final filePath = path ?? _currentFilePath;

      if (filePath == null || !File(filePath).existsSync()) {
        throw const AudioException(message: 'Recording file not found');
      }

      AppLogger.info('Recording stopped: $filePath', _tag);
      _currentFilePath = null;
      return filePath;
    } catch (e, st) {
      if (e is AudioException) rethrow;
      AppLogger.error('Stop recording failed', _tag, e, st);
      throw AudioException(message: 'Failed to stop recording', originalError: e);
    }
  }

  Future<void> cancelRecording() async {
    try {
      _cleanup();
      await _recorder.cancel();
      AppLogger.info('Recording cancelled', _tag);
    } catch (e, st) {
      AppLogger.error('Cancel recording failed', _tag, e, st);
    }
  }

  // ---------------------------------------------------------------------------
  // Streams
  // ---------------------------------------------------------------------------

  Stream<Amplitude> get amplitudeStream => _recorder.onAmplitudeChanged(
        const Duration(milliseconds: AudioConstants.amplitudeIntervalMs),
      );

  Stream<RecordState> get recordStateStream => _recorder.onStateChanged();

  // ---------------------------------------------------------------------------
  // Duration tracking
  // ---------------------------------------------------------------------------

  Duration get elapsed {
    if (_startTime == null) return Duration.zero;
    return DateTime.now().difference(_startTime!);
  }

  // ---------------------------------------------------------------------------
  // Amplitude collection for quality analysis
  // ---------------------------------------------------------------------------

  void addAmplitudeSample(double dbFS) {
    _rawAmplitudes.add(dbFS);
  }

  String? get qualityWarning => analyzeQuality(_rawAmplitudes);

  // ---------------------------------------------------------------------------
  // Cleanup
  // ---------------------------------------------------------------------------

  Future<void> dispose() async {
    _cleanup();
    await _recorder.dispose();
    AppLogger.debug('AudioRecordingService disposed', _tag);
  }

  void _cleanup() {
    _maxDurationTimer?.cancel();
    _maxDurationTimer = null;
    _startTime = null;
    _currentFilePath = null;
  }

  void _onMaxDuration() {
    AppLogger.info('Max recording duration reached (${AudioConstants.maxDurationSeconds}s)', _tag);
    onAutoStop?.call();
  }

  Future<String> _audioDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${appDir.path}/${AudioConstants.audioSubDir}');
    if (!audioDir.existsSync()) {
      audioDir.createSync(recursive: true);
    }
    return audioDir.path;
  }

  // ---------------------------------------------------------------------------
  // Pure static functions (testable without platform)
  // ---------------------------------------------------------------------------

  /// Normalizes a dBFS value (-60..0) to a 0.0..1.0 range for waveform display.
  static double normalizeAmplitude(double dbFS) {
    return ((dbFS - AudioConstants.minDb) /
            (AudioConstants.maxDb - AudioConstants.minDb))
        .clamp(0.0, 1.0);
  }

  /// Analyzes collected amplitude samples for quality issues.
  ///
  /// Returns `'too_quiet'`, `'clipping'`, or `null` if quality is acceptable.
  static String? analyzeQuality(List<double> amplitudes) {
    if (amplitudes.isEmpty) return null;

    final average =
        amplitudes.reduce((a, b) => a + b) / amplitudes.length;

    if (average < AudioConstants.silenceThresholdDb) {
      return 'too_quiet';
    }

    final hasClipping =
        amplitudes.any((a) => a > AudioConstants.clippingThresholdDb);
    if (hasClipping) {
      return 'clipping';
    }

    return null;
  }

  /// Generates a WAV file path from a directory and timestamp.
  static String generateFilePath(String dir, DateTime now) {
    final timestamp = now.millisecondsSinceEpoch;
    return '$dir/${AudioConstants.filePrefix}$timestamp${AudioConstants.fileExtension}';
  }
}
