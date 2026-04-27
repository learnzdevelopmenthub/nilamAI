/// Base exception class for NilamAI application errors.
///
/// Error codes follow the SRS convention:
/// - E003: LLM errors (generic)
/// - E004: TTS errors
/// - E005: Database errors
/// - E009: Gemma model not loaded
/// - E010: Gemma inference timeout (>30s)
/// - E011: Gemma out of memory during inference
/// - E012: Invalid query for Gemma
/// - E013: LLM network offline (API mode)
///
/// E001/E002/E006–E008 (mic + STT) were removed with the voice pipeline; they
/// will be restored if STT returns.
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

  LlmException.networkOffline({Object? originalError})
      : this(
          code: 'E013',
          message: 'No internet connection — try again when online',
          originalError: originalError,
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
