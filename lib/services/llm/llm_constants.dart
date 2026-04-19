import 'package:flutter_dotenv/flutter_dotenv.dart';

/// LLM configuration constants for NilamAI.
///
/// Production backend is the Google Gemini API (`gemini-2.5-flash`) via
/// `generativelanguage.googleapis.com`; see [GeminiGenerator].
class LlmConstants {
  LlmConstants._();

  // -- Inference --
  static const int maxOutputTokens = 300;
  static const int maxContextTokens = 600;
  static const double temperature = 0.3;
  static const int inferenceTimeoutSeconds = 30;

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
