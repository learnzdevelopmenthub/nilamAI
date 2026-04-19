/// Gemma LLM configuration constants for NilamAI.
///
/// Uses Gemma 4 E2B INT4 quantized model (~1.3 GB, `.litertlm` format).
/// Bundled in the APK via `assets/models/` and copied to app documents on
/// first launch by [GemmaModelLoader].
///
/// Values follow `docs/srs_1.0.md` §8 (revised 2026-04-16) where they differ
/// from GitHub issue #6.
class LlmConstants {
  LlmConstants._();

  // -- Model --
  static const String modelAssetPath =
      'assets/models/gemma_4_e2b_int4.litertlm';
  static const String modelFileName = 'gemma_4_e2b_int4.litertlm';
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
