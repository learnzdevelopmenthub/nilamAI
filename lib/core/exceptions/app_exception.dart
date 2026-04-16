/// Base exception class for NilamAI application errors.
///
/// Error codes follow the SRS convention:
/// - E001: Microphone errors
/// - E002: STT errors
/// - E003: LLM errors
/// - E004: TTS errors
/// - E005: Database errors
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
  }) : super(code: 'E002');
}

class LlmException extends AppException {
  const LlmException({
    required super.message,
    super.originalError,
  }) : super(code: 'E003');
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
