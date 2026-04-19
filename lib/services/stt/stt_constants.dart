/// Whisper STT configuration constants for NilamAI.
///
/// Uses the ggml-base-q8_0 model (~82 MB, INT8-quantized base Whisper).
/// Bundled in the APK via `assets/models/` and copied to app documents on
/// first launch by [WhisperModelLoader].
class SttConstants {
  SttConstants._();

  // -- Model --
  static const String modelAssetPath = 'assets/models/ggml-base-q8_0.bin';
  static const String modelFileName = 'ggml-base-q8_0.bin';
  static const String modelsSubDir = 'models';

  // -- Language --
  static const String language = 'ta';

  // -- Review-based confidence --
  static const double confidenceUnedited = 1.0;
  static const double confidenceEdited = 0.5;

  // -- Timeouts --
  static const int maxTranscribeSeconds = 30;

  // -- Validation --
  static const String wavExtension = '.wav';
  static const int minAudioFileBytes = 1024;
}
