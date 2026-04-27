import 'package:flutter_dotenv/flutter_dotenv.dart';

/// LLM configuration constants for NilamAI.
///
/// Production backend is DeepInfra-hosted Gemma 4 via the OpenAI-compatible
/// chat-completions endpoint; see [DeepInfraGenerator].
class LlmConstants {
  LlmConstants._();

  // -- Inference --
  static const int maxOutputTokens = 300;
  static const int maxContextTokens = 600;
  static const double temperature = 0.3;
  static const int inferenceTimeoutSeconds = 30;

  // -- DeepInfra (Gemma 4, OpenAI-compatible endpoint) --
  static const String deepInfraBaseUrl =
      'https://api.deepinfra.com/v1/openai/chat/completions';

  /// Primary: MoE variant, 4B active params — lower latency/cost.
  static const String deepInfraModel = 'google/gemma-4-26B-A4B-it';

  /// Fallback (dense 31B) — swap the line above if Tamil quality is weak.
  // static const String deepInfraModel = 'google/gemma-4-31B-it';

  /// Loaded from `.env` (see `.env.example`) at app start via `dotenv.load()`.
  /// Falls back to the compile-time `--dart-define=DEEPINFRA_API_KEY=...` if
  /// set so CI and release builds can still inject a key without a `.env`
  /// file.
  static String get deepInfraApiKey {
    final fromDotenv = dotenv.maybeGet('DEEPINFRA_API_KEY') ?? '';
    if (fromDotenv.isNotEmpty) return fromDotenv;
    return const String.fromEnvironment('DEEPINFRA_API_KEY', defaultValue: '');
  }

  // -- Language --
  static const String language = 'en';

  // -- Vision (multimodal) --
  /// Whether the configured DeepInfra model accepts image inputs. Gemma 4
  /// MoE on DeepInfra is multimodal; flip to false if a future model swap
  /// drops vision support.
  static const bool deepInfraVisionCapable = true;

  // -- Market prices (data.gov.in OGD AgMarknet) --
  static const String agMarknetBaseUrl = 'https://api.data.gov.in';
  static const String agMarknetResourceId =
      '9ef84268-d588-465a-a308-a864a43d0070';

  /// Loaded from `.env` at app start. Falls back to `--dart-define`.
  /// Free key: register at https://data.gov.in to get one.
  static String get agMarknetApiKey {
    final fromDotenv = dotenv.maybeGet('DATA_GOV_IN_API_KEY') ?? '';
    if (fromDotenv.isNotEmpty) return fromDotenv;
    return const String.fromEnvironment(
      'DATA_GOV_IN_API_KEY',
      defaultValue: '',
    );
  }
}
