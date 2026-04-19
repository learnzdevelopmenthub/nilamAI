import 'dart:async';
import 'dart:io';

import 'package:whisper_ggml/whisper_ggml.dart';

import '../../core/exceptions/app_exception.dart';
import '../../core/logging/logger.dart';
import 'stt_constants.dart';
import 'whisper_model_loader.dart';

/// Minimal abstraction over the whisper.cpp backend so tests can substitute
/// a fake without pulling in the native library.
abstract class WhisperTranscriber {
  Future<String> transcribe({
    required String modelPath,
    required String audioPath,
    required String language,
  });
}

/// Production transcriber delegating to the [Whisper] class from
/// `whisper_ggml`. Uses [WhisperModel.base] as the enum tag — the actual
/// weights are determined by [modelPath], not this field.
class WhisperGgmlTranscriber implements WhisperTranscriber {
  const WhisperGgmlTranscriber();

  @override
  Future<String> transcribe({
    required String modelPath,
    required String audioPath,
    required String language,
  }) async {
    final whisper = Whisper(model: WhisperModel.base);
    final response = await whisper.transcribe(
      transcribeRequest: TranscribeRequest(
        audio: audioPath,
        language: language,
        isTranslate: false,
        isNoTimestamps: true,
      ),
      modelPath: modelPath,
    );
    return response.text;
  }
}

/// Outcome of a successful transcription.
class TranscriptionResult {
  const TranscriptionResult({required this.text, required this.rawText});

  /// Cleaned text (trimmed, whitespace collapsed) ready for the review UI.
  final String text;

  /// Raw output from whisper.cpp before normalization.
  final String rawText;
}

/// High-level service that transcribes a Tamil WAV file to text using
/// the locally bundled whisper.cpp model.
class WhisperSttService {
  WhisperSttService({
    required WhisperModelLoader loader,
    required WhisperTranscriber transcriber,
  })  : _loader = loader,
        _transcriber = transcriber;

  static const _tag = 'WhisperSttService';

  final WhisperModelLoader _loader;
  final WhisperTranscriber _transcriber;

  Future<TranscriptionResult> transcribe(String audioPath) async {
    validateAudioFile(audioPath);

    final String modelPath;
    try {
      modelPath = await _loader.ensureModelAvailable();
    } on SttException {
      rethrow;
    } catch (e) {
      throw SttException.modelNotLoaded(originalError: e);
    }

    final stopwatch = Stopwatch()..start();
    try {
      final raw = await _transcriber
          .transcribe(
            modelPath: modelPath,
            audioPath: audioPath,
            language: SttConstants.language,
          )
          .timeout(
            const Duration(seconds: SttConstants.maxTranscribeSeconds),
          );
      stopwatch.stop();
      AppLogger.info(
        'Transcription complete in ${stopwatch.elapsedMilliseconds} ms',
        _tag,
      );
      return TranscriptionResult(
        text: normalizeTranscription(raw),
        rawText: raw,
      );
    } on TimeoutException catch (e) {
      throw SttException.transcriptionFailed(
        'timeout after ${SttConstants.maxTranscribeSeconds}s',
        originalError: e,
      );
    } on SttException {
      rethrow;
    } catch (e, s) {
      AppLogger.error('Whisper transcription failed', _tag, e, s);
      throw SttException.transcriptionFailed(
        e.toString(),
        originalError: e,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Pure static helpers (unit-testable without the native layer)
  // ---------------------------------------------------------------------------

  /// Throws [SttException.transcriptionFailed] if the path is not a usable
  /// WAV file (missing, wrong extension, empty, or too small).
  static void validateAudioFile(String audioPath) {
    if (audioPath.isEmpty) {
      throw SttException.transcriptionFailed('audio path is empty');
    }
    if (!audioPath.toLowerCase().endsWith(SttConstants.wavExtension)) {
      throw SttException.transcriptionFailed(
        'unsupported audio format: $audioPath',
      );
    }
    final file = File(audioPath);
    if (!file.existsSync()) {
      throw SttException.transcriptionFailed('audio file not found: $audioPath');
    }
    final size = file.lengthSync();
    if (size < SttConstants.minAudioFileBytes) {
      throw SttException.transcriptionFailed(
        'audio file too small ($size bytes)',
      );
    }
  }

  /// Trims whitespace and collapses internal whitespace runs. Strips any
  /// leading punctuation / whitespace-only output from whisper.
  static String normalizeTranscription(String raw) {
    if (raw.isEmpty) return '';
    final collapsed = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    return collapsed;
  }
}
