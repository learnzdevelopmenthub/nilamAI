import 'package:flutter_dotenv/flutter_dotenv.dart';

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

  // -- Gemini API (production backend) --
  static const String geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';
  static const String geminiModel = 'gemini-2.5-flash';

  /// Loaded from `.env` (see `.env.example`) at app start via `dotenv.load()`.
  /// Falls back to the compile-time `--dart-define=GEMINI_API_KEY=...` if set
  /// so CI and release builds can still inject a key without a `.env` file.
  static String get geminiApiKey {
    final fromDotenv = dotenv.maybeGet('GEMINI_API_KEY') ?? '';
    if (fromDotenv.isNotEmpty) return fromDotenv;
    return const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  }

  // -- Language --
  static const String language = 'ta';
}
