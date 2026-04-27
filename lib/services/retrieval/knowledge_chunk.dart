// Domain model for the retrieval layer. A `KnowledgeChunk` is the unit
// returned by [KnowledgeRetriever] and rendered into the LLM prompt as a
// reference note.

enum ChunkSource { cropStage, disease, cropHarvest, cropStorage }

class KnowledgeChunk {
  const KnowledgeChunk({
    required this.id,
    required this.text,
    required this.cropIds,
    required this.stageIds,
    required this.tags,
    required this.sourceType,
    required this.sourceId,
  });

  /// Stable id, e.g. `rice/stage/tillering`, `disease/rice_blast`.
  final String id;

  /// Human-readable passage that gets scored and rendered.
  final String text;

  /// Crop ids the chunk applies to. Empty = general / cross-crop.
  final List<String> cropIds;

  /// Stage ids within the crop. Empty = stage-agnostic.
  final List<String> stageIds;

  /// Lowercase short tokens for downstream filtering or boosting.
  final List<String> tags;

  final ChunkSource sourceType;

  /// Pointer back to the originating record (crop+stage, disease entry,
  /// etc.) — useful for click-through later.
  final String sourceId;
}

class RankedChunk {
  const RankedChunk({required this.chunk, required this.score});
  final KnowledgeChunk chunk;
  final double score;
}
