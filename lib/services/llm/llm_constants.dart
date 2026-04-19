/// Gemma LLM configuration constants for NilamAI.
///
/// Uses Gemma 4 E2B model (~2.6 GB, `.litertlm` format) from
/// litert-community/gemma-4-E2B-it-litert-lm. Bundled in the APK via
/// `assets/models/` and copied to app documents on first launch by
/// [GemmaModelLoader].
///
/// Values follow `docs/srs_1.0.md` §8 (revised 2026-04-16) where they differ
/// from GitHub issue #6.
class LlmConstants {
  LlmConstants._();

  // -- Model --
  static const String modelAssetPath =
      'assets/models/gemma-4-E2B-it.litertlm';
  static const String modelFileName = 'gemma-4-E2B-it.litertlm';
  static const String modelsSubDir = 'models';

  // -- Inference --
  static const int maxOutputTokens = 300;
  static const int maxContextTokens = 600;
  static const double temperature = 0.3;
  static const int inferenceTimeoutSeconds = 30;

  // -- Ollama dev bridge --
  static const String ollamaDefaultUrl = 'http://localhost:11434';
  static const String ollamaDefaultModel = 'gemma2:2b';

  // -- Language --
  static const String language = 'ta';
}
