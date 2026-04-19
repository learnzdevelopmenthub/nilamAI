import 'llm_constants.dart';
import '../../core/exceptions/app_exception.dart';

/// Result of building a Gemma prompt: the final prompt string ready for
/// inference, plus the raw query for later persistence in `QueryHistory`.
class BuiltPrompt {
  const BuiltPrompt({required this.text, required this.query});

  /// The fully-assembled prompt sent to the LLM.
  final String text;

  /// The raw user query (unmodified), retained for DB persistence.
  final String query;
}

/// Assembles the Tamil system prompt + user context for Gemma 4 E2B.
///
/// The SRS (§8) does not prescribe a specific Tamil prompt template — only
/// the English "selling advice" example. This builder produces a generic
/// agricultural-advisor prompt that works for disease, crop, and pricing
/// queries; iterate post-merge as real responses surface.
///
/// Only `cropType` is injected as context in this phase. Geolocation,
/// season, and mandi prices (SRS FR-4.2 "if available") are tracked as
/// separate tickets.
class PromptBuilder {
  PromptBuilder._();

  static const String _systemLine =
      'நீ NilamAI (நிலம்AI) — தமிழ்நாட்டு விவசாயிகளுக்கான ஆலோசகர்.';
  static const String _instructionLine =
      'தமிழில் சுருக்கமாக பதில் சொல். செயல்முறை படிகள், செலவு, மற்றும் நேரம் ஆகியவற்றைச் சேர்.';

  /// Builds a Tamil prompt for Gemma.
  ///
  /// Throws [LlmException.invalidQuery] (E012) when [query] is empty
  /// after trimming.
  static BuiltPrompt build({required String query, String? cropType}) {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      throw LlmException.invalidQuery('query is empty');
    }

    final trimmedCrop = cropType?.trim();
    final cropLine =
        (trimmedCrop != null && trimmedCrop.isNotEmpty) ? 'பயிர்: $trimmedCrop\n' : '';

    final prompt = '''$_systemLine

கேள்வி: $trimmedQuery
$cropLine
$_instructionLine
(மொழி: ${LlmConstants.language})''';

    return BuiltPrompt(text: prompt, query: trimmedQuery);
  }
}
