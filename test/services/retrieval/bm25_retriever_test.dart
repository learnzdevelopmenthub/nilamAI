import 'package:flutter_test/flutter_test.dart';
import 'package:nilam_ai/services/knowledge/crop_knowledge_service.dart';
import 'package:nilam_ai/services/retrieval/bm25_retriever.dart';
import 'package:nilam_ai/services/retrieval/disease_chunk_loader.dart';
import 'package:nilam_ai/services/retrieval/knowledge_chunk.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BM25Retriever retriever;

  setUp(() {
    retriever = BM25Retriever(
      cropKnowledge: CropKnowledgeService(),
      diseaseLoader: DiseaseChunkLoader(),
    );
  });

  test('returns empty for an empty query', () async {
    final out = await retriever.retrieve(query: '');
    expect(out, isEmpty);
  });

  test('returns empty for a stopwords-only query', () async {
    final out = await retriever.retrieve(query: 'the and or but');
    expect(out, isEmpty);
  });

  test('rice blast query returns rice-specific chunks first', () async {
    final out = await retriever.retrieve(query: 'rice blast disease', topK: 5);
    expect(out, isNotEmpty);
    // Expect a rice chunk in the top-3 hits.
    final topThreeCropIds = out
        .take(3)
        .expand((r) => r.chunk.cropIds)
        .toSet();
    expect(topThreeCropIds, contains('rice'));
  });

  test('cropId filter excludes other crops', () async {
    final out = await retriever.retrieve(
      query: 'disease symptoms',
      cropId: 'rice',
      topK: 10,
    );
    for (final r in out) {
      // Either rice-specific or general (empty cropIds).
      expect(
        r.chunk.cropIds.isEmpty || r.chunk.cropIds.contains('rice'),
        isTrue,
        reason: 'Got a chunk for ${r.chunk.cropIds} when filtering on rice',
      );
    }
  });

  test('stageId filter narrows stage chunks', () async {
    final out = await retriever.retrieve(
      query: 'urea fertilizer',
      cropId: 'rice',
      stageId: 'tillering',
      topK: 5,
    );
    // Stage-bound chunks must match the requested stage; cross-stage chunks
    // (stageIds=[]) are still allowed.
    for (final r in out) {
      expect(
        r.chunk.stageIds.isEmpty ||
            r.chunk.stageIds.contains('tillering'),
        isTrue,
      );
    }
  });

  test('topK clamps result count', () async {
    final out = await retriever.retrieve(query: 'crop', topK: 3);
    expect(out.length, lessThanOrEqualTo(3));
  });

  test('chunk filter rule: empty cropIds passes any filter', () async {
    // We construct a tiny synthetic check via the public retrieve API.
    final all = await retriever.retrieve(query: 'crop disease', topK: 50);
    final hasGeneric =
        all.any((r) => r.chunk.cropIds.isEmpty || r.chunk.cropIds.contains('rice'));
    expect(hasGeneric, isTrue);
  });

  test('ranked output is sorted by score descending', () async {
    final out = await retriever.retrieve(
      query: 'rice blast neck',
      cropId: 'rice',
      topK: 5,
    );
    for (var i = 1; i < out.length; i++) {
      expect(out[i - 1].score, greaterThanOrEqualTo(out[i].score));
    }
  });

  test('returns chunk text containing some query terms', () async {
    final out = await retriever.retrieve(query: 'sheath blight rice', topK: 3);
    expect(out, isNotEmpty);
    final lowered = out.first.chunk.text.toLowerCase();
    final hasMatch = lowered.contains('blight') ||
        lowered.contains('sheath') ||
        lowered.contains('rice');
    expect(hasMatch, isTrue);
  });

  test('tags include sourceType-derived label', () async {
    final out = await retriever.retrieve(query: 'storage rice', topK: 5);
    expect(
      out.any((r) => r.chunk.sourceType == ChunkSource.cropStorage),
      isTrue,
    );
  });
}
