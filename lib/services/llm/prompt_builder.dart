import '../../core/exceptions/app_exception.dart';
import '../retrieval/knowledge_chunk.dart';

/// Result of building a Gemma prompt: the final prompt string ready for
/// inference, plus the raw query for later persistence in `QueryHistory`.
class BuiltPrompt {
  const BuiltPrompt({required this.text, required this.query});

  /// The fully-assembled prompt sent to the LLM.
  final String text;

  /// The raw user query (unmodified), retained for DB persistence.
  final String query;
}

/// Top-K chunks pulled from the knowledge base by [KnowledgeRetriever] for
/// the current query. Rendered as a "Reference notes:" block before the
/// farmer's question.
class RetrievedContext {
  const RetrievedContext({required this.chunks});

  final List<KnowledgeChunk> chunks;

  bool get isEmpty => chunks.isEmpty;

  String render() {
    if (chunks.isEmpty) return '';
    final buf = StringBuffer('Reference notes:\n');
    for (final c in chunks) {
      buf.writeln('- [${_tagFor(c)}] ${c.text}');
    }
    return buf.toString().trimRight();
  }

  static String _tagFor(KnowledgeChunk c) {
    final crop = c.cropIds.isEmpty ? 'general' : c.cropIds.first;
    final stage = c.stageIds.isEmpty ? null : c.stageIds.first;
    return stage == null ? crop : '$crop/$stage';
  }
}

/// Optional grounding context drawn from a tracked crop profile + the
/// bundled crop knowledge JSON. Lets the LLM produce stage-aware advice
/// without us needing a full RAG pipeline.
class CropContext {
  const CropContext({
    required this.cropName,
    this.variety,
    this.stageName,
    this.dayInStage,
    this.totalDurationDays,
    this.keyActivities = const [],
    this.commonDiseases = const [],
    this.recommendedFertilizer,
  });

  final String cropName;
  final String? variety;
  final String? stageName;
  final int? dayInStage;
  final int? totalDurationDays;
  final List<String> keyActivities;
  final List<String> commonDiseases;
  final String? recommendedFertilizer;

  String render() {
    final parts = <String>[];
    parts.add('Crop: $cropName${variety != null ? ' ($variety)' : ''}');
    if (stageName != null) {
      final dayStr = dayInStage != null ? ' (day $dayInStage)' : '';
      parts.add('Current growth stage: $stageName$dayStr');
    }
    if (totalDurationDays != null) {
      parts.add('Typical lifecycle: $totalDurationDays days from sowing.');
    }
    if (keyActivities.isNotEmpty) {
      parts.add('Activities for this stage:');
      for (final a in keyActivities) {
        parts.add('- $a');
      }
    }
    if (commonDiseases.isNotEmpty) {
      parts.add('Common problems at this stage: ${commonDiseases.join(', ')}.');
    }
    if (recommendedFertilizer != null) {
      parts.add('Recommended fertilizer: $recommendedFertilizer');
    }
    return parts.join('\n');
  }
}

/// Assembles the system prompt + user context for Gemma 4.
class PromptBuilder {
  PromptBuilder._();

  static const String _systemLine =
      'You are NilamAI, an English-speaking agricultural advisor for small farmers in Tamil Nadu, India.';
  static const String _instructionLine =
      'Reply in clear, concise English. When relevant, include practical steps, approximate cost in rupees, and timing. Prefer low-cost local solutions and mention an organic alternative when applicable.';

  /// Builds an English prompt for Gemma. Throws [LlmException.invalidQuery]
  /// (E012) when [query] is empty after trimming.
  static BuiltPrompt build({
    required String query,
    String? cropType,
    CropContext? cropContext,
    RetrievedContext? retrieved,
  }) {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      throw LlmException.invalidQuery('query is empty');
    }

    final buf = StringBuffer()
      ..writeln(_systemLine)
      ..writeln();

    if (cropContext != null) {
      buf
        ..writeln('Context:')
        ..writeln(cropContext.render())
        ..writeln();
    } else {
      final trimmedCrop = cropType?.trim();
      if (trimmedCrop != null && trimmedCrop.isNotEmpty) {
        buf
          ..writeln('Context: Crop is $trimmedCrop.')
          ..writeln();
      }
    }

    if (retrieved != null && !retrieved.isEmpty) {
      buf
        ..writeln(retrieved.render())
        ..writeln();
    }

    buf
      ..writeln('Farmer question: $trimmedQuery')
      ..writeln()
      ..write(_instructionLine);

    return BuiltPrompt(text: buf.toString(), query: trimmedQuery);
  }
}
