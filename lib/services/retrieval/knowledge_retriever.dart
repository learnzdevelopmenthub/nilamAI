import 'knowledge_chunk.dart';

/// Strategy interface. The shipping implementation is sparse (BM25); a
/// future dense (vector / sqlite-vec / embeddings) implementation drops in
/// via a Riverpod provider override without touching call sites.
abstract class KnowledgeRetriever {
  /// Returns up to [topK] chunks ranked by relevance to [query]. Optional
  /// [cropId]/[stageId] narrow the candidate set BEFORE scoring.
  ///
  /// Filter semantics: a chunk passes the [cropId] filter iff its
  /// `cropIds` is empty (general / cross-crop) OR contains [cropId]. Same
  /// rule for [stageId]. Null filter = no filter.
  Future<List<RankedChunk>> retrieve({
    required String query,
    String? cropId,
    String? stageId,
    int topK = 5,
  });
}
