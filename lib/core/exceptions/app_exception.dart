/// Base exception class for NilamAI application errors.
///
/// Error codes follow the SRS convention:
/// - E001: Microphone errors
/// - E002: STT errors (generic)
/// - E003: LLM errors (generic)
/// - E004: TTS errors
/// - E005: Database errors
/// - E006: Whisper model not loaded
/// - E007: Transcription failed
/// - E008: Low confidence transcription
/// - E009: Gemma model not loaded
/// - E010: Gemma inference timeout (>30s)
/// - E011: Gemma out of memory during inference
/// - E012: Invalid query for Gemma
sealed class AppException implements Exception {
  const AppException({
    required this.code,
    required this.message,
    this.originalError,
  });

  final String code;
  final String message;
  final Object? originalError;

  @override
  String toString() => 'AppException($code): $message';
}

class AudioException extends AppException {
  const AudioException({
    required super.message,
    super.originalError,
  }) : super(code: 'E001');
}

class SttException extends AppException {
  const SttException({
    required super.message,
    super.originalError,
    super.code = 'E002',
  });

  SttException.modelNotLoaded({Object? originalError})
      : this(
          code: 'E006',
          message: 'Whisper model not loaded',
          originalError: originalError,
        );

  SttException.transcriptionFailed(String detail, {Object? originalError})
      : this(
          code: 'E007',
          message: 'Transcription failed: $detail',
          originalError: originalError,
        );

  SttException.lowConfidence(double score)
      : this(
          code: 'E008',
          message: 'Low confidence: ${score.toStringAsFixed(2)}',
        );
}

class LlmException extends AppException {
  const LlmException({
    required super.message,
    super.originalError,
    super.code = 'E003',
  });

  LlmException.modelNotLoaded({Object? originalError})
      : this(
          code: 'E009',
          message: 'Gemma model not loaded',
          originalError: originalError,
        );

  LlmException.inferenceTimeout({Object? originalError})
      : this(
          code: 'E010',
          message: 'Gemma inference timed out after 30s',
          originalError: originalError,
        );

  LlmException.outOfMemory({Object? originalError})
      : this(
          code: 'E011',
          message: 'Gemma inference ran out of memory',
          originalError: originalError,
        );

  LlmException.invalidQuery(String detail)
      : this(
          code: 'E012',
          message: 'Invalid query for Gemma: $detail',
        );
}

class TtsException extends AppException {
  const TtsException({
    required super.message,
    super.originalError,
  }) : super(code: 'E004');
}

class DatabaseException extends AppException {
  const DatabaseException({
    required super.message,
    super.originalError,
  }) : super(code: 'E005');
}
